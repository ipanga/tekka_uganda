import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'biometric_auth_provider.dart';
import 'pin_provider.dart';

/// App lock modes
enum AppLockMode { off, pinOnly, biometricOnly, biometricOrPin }

extension AppLockModeX on AppLockMode {
  String get displayName {
    switch (this) {
      case AppLockMode.off:
        return 'Off';
      case AppLockMode.pinOnly:
        return 'PIN Only';
      case AppLockMode.biometricOnly:
        return 'Biometric Only';
      case AppLockMode.biometricOrPin:
        return 'Biometric or PIN';
    }
  }

  String get description {
    switch (this) {
      case AppLockMode.off:
        return 'App will not be locked';
      case AppLockMode.pinOnly:
        return 'Require PIN to unlock';
      case AppLockMode.biometricOnly:
        return 'Require biometric to unlock';
      case AppLockMode.biometricOrPin:
        return 'Use biometric or PIN to unlock';
    }
  }
}

/// App lock status
class AppLockStatus {
  final AppLockMode mode;
  final bool isLocked;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUnlockedAt;
  final int lockTimeoutMinutes;

  const AppLockStatus({
    this.mode = AppLockMode.off,
    this.isLocked = false,
    this.isLoading = false,
    this.errorMessage,
    this.lastUnlockedAt,
    this.lockTimeoutMinutes = 1,
  });

  AppLockStatus copyWith({
    AppLockMode? mode,
    bool? isLocked,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUnlockedAt,
    int? lockTimeoutMinutes,
  }) {
    return AppLockStatus(
      mode: mode ?? this.mode,
      isLocked: isLocked ?? this.isLocked,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastUnlockedAt: lastUnlockedAt ?? this.lastUnlockedAt,
      lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
    );
  }

  /// Check if app lock is enabled
  bool get isEnabled => mode != AppLockMode.off;

  /// Check if PIN is an unlock option
  bool get canUsePin =>
      mode == AppLockMode.pinOnly || mode == AppLockMode.biometricOrPin;

  /// Check if biometric is an unlock option
  bool get canUseBiometric =>
      mode == AppLockMode.biometricOnly || mode == AppLockMode.biometricOrPin;
}

/// Storage keys
class _AppLockKeys {
  static const String mode = 'tekka_app_lock_mode';
  static const String timeout = 'tekka_app_lock_timeout';
  static const String lastUnlocked = 'tekka_app_last_unlocked';
}

/// Provider for app lock status
final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockStatus>(
  (ref) => AppLockNotifier(ref),
);

/// Notifier for managing app lock
class AppLockNotifier extends StateNotifier<AppLockStatus> {
  final Ref _ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AppLockNotifier(this._ref) : super(const AppLockStatus()) {
    _initialize();
  }

  /// Initialize app lock status
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Load saved mode
      final modeStr = await _secureStorage.read(key: _AppLockKeys.mode);
      final mode = _parseMode(modeStr);

      // Load timeout
      final timeoutStr = await _secureStorage.read(key: _AppLockKeys.timeout);
      final timeout = int.tryParse(timeoutStr ?? '1') ?? 1;

      // Load last unlocked time
      final lastUnlockedStr = await _secureStorage.read(
        key: _AppLockKeys.lastUnlocked,
      );
      DateTime? lastUnlocked;
      if (lastUnlockedStr != null) {
        lastUnlocked = DateTime.tryParse(lastUnlockedStr);
      }

      // Determine if app should be locked
      final shouldLock = _shouldLockApp(mode, lastUnlocked, timeout);

      state = state.copyWith(
        mode: mode,
        isLocked: shouldLock,
        lockTimeoutMinutes: timeout,
        lastUnlockedAt: lastUnlocked,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize app lock',
      );
    }
  }

  AppLockMode _parseMode(String? modeStr) {
    switch (modeStr) {
      case 'pinOnly':
        return AppLockMode.pinOnly;
      case 'biometricOnly':
        return AppLockMode.biometricOnly;
      case 'biometricOrPin':
        return AppLockMode.biometricOrPin;
      default:
        return AppLockMode.off;
    }
  }

  bool _shouldLockApp(AppLockMode mode, DateTime? lastUnlocked, int timeout) {
    if (mode == AppLockMode.off) return false;
    if (lastUnlocked == null) return true;

    final now = DateTime.now();
    final diff = now.difference(lastUnlocked);
    return diff.inMinutes >= timeout;
  }

  /// Set app lock mode
  Future<bool> setMode(AppLockMode mode) async {
    // Validate that required auth methods are available
    if (mode == AppLockMode.pinOnly || mode == AppLockMode.biometricOrPin) {
      final pinStatus = _ref.read(pinProvider);
      if (!pinStatus.hasPinSet) {
        state = state.copyWith(errorMessage: 'Please set up a PIN first');
        return false;
      }
    }

    if (mode == AppLockMode.biometricOnly ||
        mode == AppLockMode.biometricOrPin) {
      final biometricStatus = _ref.read(biometricAuthProvider);
      if (!biometricStatus.isAvailable || !biometricStatus.isEnrolled) {
        state = state.copyWith(
          errorMessage: 'Biometric authentication is not available',
        );
        return false;
      }
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _secureStorage.write(key: _AppLockKeys.mode, value: mode.name);

      // If enabling, mark as unlocked now
      if (mode != AppLockMode.off) {
        final now = DateTime.now();
        await _secureStorage.write(
          key: _AppLockKeys.lastUnlocked,
          value: now.toIso8601String(),
        );
        state = state.copyWith(
          mode: mode,
          isLocked: false,
          lastUnlockedAt: now,
          isLoading: false,
        );
      } else {
        state = state.copyWith(mode: mode, isLocked: false, isLoading: false);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save app lock settings',
      );
      return false;
    }
  }

  /// Set lock timeout
  Future<bool> setTimeout(int minutes) async {
    if (minutes < 0 || minutes > 60) {
      state = state.copyWith(errorMessage: 'Invalid timeout value');
      return false;
    }

    try {
      await _secureStorage.write(
        key: _AppLockKeys.timeout,
        value: minutes.toString(),
      );
      state = state.copyWith(lockTimeoutMinutes: minutes);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save timeout setting');
      return false;
    }
  }

  /// Unlock with PIN
  Future<bool> unlockWithPin(String pin) async {
    if (!state.canUsePin) {
      state = state.copyWith(errorMessage: 'PIN unlock is not enabled');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final pinNotifier = _ref.read(pinProvider.notifier);
      final isValid = await pinNotifier.verifyCurrentPin(pin);

      if (isValid) {
        await _markUnlocked();
        return true;
      } else {
        final pinStatus = _ref.read(pinProvider);
        state = state.copyWith(
          isLoading: false,
          errorMessage: pinStatus.errorMessage ?? 'Incorrect PIN',
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

  /// Unlock with biometric
  Future<bool> unlockWithBiometric() async {
    if (!state.canUseBiometric) {
      state = state.copyWith(errorMessage: 'Biometric unlock is not enabled');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final biometricNotifier = _ref.read(biometricAuthProvider.notifier);
      final isAuthenticated = await biometricNotifier.authenticate(
        reason: 'Authenticate to unlock Tekka',
      );

      if (isAuthenticated) {
        await _markUnlocked();
        return true;
      } else {
        final biometricStatus = _ref.read(biometricAuthProvider);
        state = state.copyWith(
          isLoading: false,
          errorMessage: biometricStatus.errorMessage ?? 'Authentication failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to authenticate',
      );
      return false;
    }
  }

  /// Mark app as unlocked
  Future<void> _markUnlocked() async {
    final now = DateTime.now();
    await _secureStorage.write(
      key: _AppLockKeys.lastUnlocked,
      value: now.toIso8601String(),
    );
    state = state.copyWith(
      isLocked: false,
      lastUnlockedAt: now,
      isLoading: false,
    );
  }

  /// Lock the app manually
  void lock() {
    if (state.isEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  /// Called when app comes to foreground
  Future<void> onAppResumed() async {
    if (!state.isEnabled) return;

    final shouldLock = _shouldLockApp(
      state.mode,
      state.lastUnlockedAt,
      state.lockTimeoutMinutes,
    );

    if (shouldLock) {
      state = state.copyWith(isLocked: true);
    }
  }

  /// Called when app goes to background
  void onAppPaused() {
    // Nothing special needed here, timeout is checked on resume
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh app lock status
  Future<void> refresh() async {
    await _initialize();
  }
}

/// Provider to check if app should show lock screen
final shouldShowLockScreenProvider = Provider<bool>((ref) {
  final appLockStatus = ref.watch(appLockProvider);
  return appLockStatus.isEnabled && appLockStatus.isLocked;
});
