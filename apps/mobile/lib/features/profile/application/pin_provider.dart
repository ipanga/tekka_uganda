import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/providers/repository_providers.dart';

/// State for PIN management
enum PinState {
  initial,
  loading,
  noPinSet,
  pinSet,
  enteringCurrentPin,
  enteringNewPin,
  confirmingNewPin,
  verifying,
  success,
  error,
}

/// Status class for PIN operations
class PinStatus {
  final PinState state;
  final bool hasPinSet;
  final String? errorMessage;
  final bool isLoading;
  final int failedAttempts;
  final DateTime? lockedUntil;

  const PinStatus({
    this.state = PinState.initial,
    this.hasPinSet = false,
    this.errorMessage,
    this.isLoading = false,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  PinStatus copyWith({
    PinState? state,
    bool? hasPinSet,
    String? errorMessage,
    bool? isLoading,
    int? failedAttempts,
    DateTime? lockedUntil,
  }) {
    return PinStatus(
      state: state ?? this.state,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  /// Check if account is locked due to too many failed attempts
  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  /// Get remaining lock time in seconds
  int get remainingLockSeconds {
    if (lockedUntil == null) return 0;
    final diff = lockedUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}

/// Storage keys
class _PinKeys {
  static const String pinHash = 'tekka_pin_hash';
  static const String pinSalt = 'tekka_pin_salt';
  static const String failedAttempts = 'tekka_pin_failed_attempts';
  static const String lockedUntil = 'tekka_pin_locked_until';
}

/// Provider for PIN state
final pinProvider = StateNotifierProvider<PinNotifier, PinStatus>(
  (ref) => PinNotifier(ref),
);

/// Notifier for managing PIN
class PinNotifier extends StateNotifier<PinStatus> {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const int _maxFailedAttempts = 5;
  static const int _lockDurationMinutes = 15;

  String? _newPin; // Temporarily store new PIN for confirmation

  PinNotifier(this._ref) : super(const PinStatus()) {
    _loadPinStatus();
  }

  /// Load PIN status
  Future<void> _loadPinStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check for existing PIN
      final pinHash = await _secureStorage.read(key: _PinKeys.pinHash);
      final hasPinSet = pinHash != null && pinHash.isNotEmpty;

      // Check for lock status
      final lockedUntilStr = await _secureStorage.read(
        key: _PinKeys.lockedUntil,
      );
      DateTime? lockedUntil;
      if (lockedUntilStr != null) {
        lockedUntil = DateTime.tryParse(lockedUntilStr);
      }

      // Get failed attempts
      final attemptsStr = await _secureStorage.read(
        key: _PinKeys.failedAttempts,
      );
      final failedAttempts = int.tryParse(attemptsStr ?? '0') ?? 0;

      state = state.copyWith(
        state: hasPinSet ? PinState.pinSet : PinState.noPinSet,
        hasPinSet: hasPinSet,
        isLoading: false,
        failedAttempts: failedAttempts,
        lockedUntil: lockedUntil,
      );
    } catch (e) {
      state = state.copyWith(
        state: PinState.error,
        errorMessage: 'Failed to load PIN status',
        isLoading: false,
      );
    }
  }

  /// Start PIN change flow
  void startPinChange() {
    if (state.hasPinSet) {
      state = state.copyWith(state: PinState.enteringCurrentPin);
    } else {
      state = state.copyWith(state: PinState.enteringNewPin);
    }
  }

  /// Verify current PIN
  Future<bool> verifyCurrentPin(String pin) async {
    if (state.isLocked) {
      state = state.copyWith(
        errorMessage:
            'Too many failed attempts. Try again in ${state.remainingLockSeconds ~/ 60} minutes.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final storedHash = await _secureStorage.read(key: _PinKeys.pinHash);
      final storedSalt = await _secureStorage.read(key: _PinKeys.pinSalt);

      if (storedHash == null || storedSalt == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'PIN not set');
        return false;
      }

      final inputHash = _hashPin(pin, storedSalt);

      if (inputHash == storedHash) {
        // PIN is correct, reset failed attempts
        await _secureStorage.write(key: _PinKeys.failedAttempts, value: '0');
        await _secureStorage.delete(key: _PinKeys.lockedUntil);

        state = state.copyWith(
          state: PinState.enteringNewPin,
          isLoading: false,
          failedAttempts: 0,
          lockedUntil: null,
        );
        return true;
      } else {
        // Wrong PIN
        final newFailedAttempts = state.failedAttempts + 1;
        await _secureStorage.write(
          key: _PinKeys.failedAttempts,
          value: newFailedAttempts.toString(),
        );

        // Lock if too many attempts
        DateTime? lockedUntil;
        if (newFailedAttempts >= _maxFailedAttempts) {
          lockedUntil = DateTime.now().add(
            Duration(minutes: _lockDurationMinutes),
          );
          await _secureStorage.write(
            key: _PinKeys.lockedUntil,
            value: lockedUntil.toIso8601String(),
          );
        }

        state = state.copyWith(
          isLoading: false,
          failedAttempts: newFailedAttempts,
          lockedUntil: lockedUntil,
          errorMessage: lockedUntil != null
              ? 'Too many failed attempts. Locked for $_lockDurationMinutes minutes.'
              : 'Incorrect PIN. ${_maxFailedAttempts - newFailedAttempts} attempts remaining.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to verify PIN',
      );
      return false;
    }
  }

  /// Set new PIN (first entry)
  void setNewPin(String pin) {
    if (!_isValidPin(pin)) {
      state = state.copyWith(errorMessage: 'PIN must be 4-6 digits');
      return;
    }

    _newPin = pin;
    state = state.copyWith(
      state: PinState.confirmingNewPin,
      errorMessage: null,
    );
  }

  /// Confirm new PIN
  Future<bool> confirmNewPin(String pin) async {
    if (_newPin == null) {
      state = state.copyWith(
        state: PinState.enteringNewPin,
        errorMessage: 'Please enter your new PIN first',
      );
      return false;
    }

    if (pin != _newPin) {
      state = state.copyWith(
        errorMessage: 'PINs do not match. Please try again.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Generate salt and hash
      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);

      // Store securely
      await _secureStorage.write(key: _PinKeys.pinHash, value: hash);
      await _secureStorage.write(key: _PinKeys.pinSalt, value: salt);
      await _secureStorage.write(key: _PinKeys.failedAttempts, value: '0');
      await _secureStorage.delete(key: _PinKeys.lockedUntil);

      // Update server via API
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final userApiRepository = _ref.read(userApiRepositoryProvider);
          await userApiRepository.updateSettings(pinEnabled: true);
        } catch (_) {
          // Non-critical - PIN still works locally
        }
      }

      _newPin = null;
      state = state.copyWith(
        state: PinState.success,
        hasPinSet: true,
        isLoading: false,
        failedAttempts: 0,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        state: PinState.error,
        errorMessage: 'Failed to save PIN',
        isLoading: false,
      );
      return false;
    }
  }

  /// Remove PIN
  Future<bool> removePin(String currentPin) async {
    // First verify current PIN
    final isValid = await verifyCurrentPin(currentPin);
    if (!isValid) return false;

    state = state.copyWith(isLoading: true);

    try {
      // Clear stored PIN
      await _secureStorage.delete(key: _PinKeys.pinHash);
      await _secureStorage.delete(key: _PinKeys.pinSalt);
      await _secureStorage.write(key: _PinKeys.failedAttempts, value: '0');
      await _secureStorage.delete(key: _PinKeys.lockedUntil);

      // Update server via API
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final userApiRepository = _ref.read(userApiRepositoryProvider);
          await userApiRepository.updateSettings(pinEnabled: false);
        } catch (_) {
          // Non-critical - PIN still removed locally
        }
      }

      state = state.copyWith(
        state: PinState.noPinSet,
        hasPinSet: false,
        isLoading: false,
        failedAttempts: 0,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        state: PinState.error,
        errorMessage: 'Failed to remove PIN',
        isLoading: false,
      );
      return false;
    }
  }

  /// Cancel PIN operation
  void cancel() {
    _newPin = null;
    state = state.copyWith(
      state: state.hasPinSet ? PinState.pinSet : PinState.noPinSet,
      errorMessage: null,
    );
  }

  /// Reset to initial state
  void reset() {
    _newPin = null;
    _loadPinStatus();
  }

  // Helper methods

  bool _isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return RegExp(r'^\d{4,6}$').hasMatch(pin);
  }

  String _generateSalt() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    final random = timestamp.toString() + userId;
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  String _hashPin(String pin, String salt) {
    final combined = pin + salt;
    return sha256.convert(utf8.encode(combined)).toString();
  }
}
