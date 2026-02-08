import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/providers/repository_providers.dart';

/// Two-factor authentication methods
enum TwoFactorMethod { sms, authenticatorApp }

extension TwoFactorMethodX on TwoFactorMethod {
  String get displayName {
    switch (this) {
      case TwoFactorMethod.sms:
        return 'SMS';
      case TwoFactorMethod.authenticatorApp:
        return 'Authenticator App';
    }
  }

  String get description {
    switch (this) {
      case TwoFactorMethod.sms:
        return 'Receive verification codes via SMS to your phone number';
      case TwoFactorMethod.authenticatorApp:
        return 'Use an authenticator app like Google Authenticator or Authy';
    }
  }

  String get apiValue {
    switch (this) {
      case TwoFactorMethod.sms:
        return 'sms';
      case TwoFactorMethod.authenticatorApp:
        return 'authenticatorApp';
    }
  }

  static TwoFactorMethod? fromString(String? value) {
    if (value == 'sms') return TwoFactorMethod.sms;
    if (value == 'authenticatorApp') return TwoFactorMethod.authenticatorApp;
    return null;
  }
}

/// State for 2FA setup/management
enum TwoFactorState {
  initial,
  loading,
  methodSelection,
  setupSms,
  setupAuthenticator,
  verifyingCode,
  enabled,
  disabled,
  error,
}

/// Status class for 2FA
class TwoFactorStatus {
  final TwoFactorState state;
  final bool isEnabled;
  final TwoFactorMethod? activeMethod;
  final String? phoneNumber;
  final String? secretKey;
  final String? qrCodeUrl;
  final List<String>? backupCodes;
  final String? errorMessage;
  final bool isLoading;

  const TwoFactorStatus({
    this.state = TwoFactorState.initial,
    this.isEnabled = false,
    this.activeMethod,
    this.phoneNumber,
    this.secretKey,
    this.qrCodeUrl,
    this.backupCodes,
    this.errorMessage,
    this.isLoading = false,
  });

  TwoFactorStatus copyWith({
    TwoFactorState? state,
    bool? isEnabled,
    TwoFactorMethod? activeMethod,
    String? phoneNumber,
    String? secretKey,
    String? qrCodeUrl,
    List<String>? backupCodes,
    String? errorMessage,
    bool? isLoading,
  }) {
    return TwoFactorStatus(
      state: state ?? this.state,
      isEnabled: isEnabled ?? this.isEnabled,
      activeMethod: activeMethod ?? this.activeMethod,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      secretKey: secretKey ?? this.secretKey,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      backupCodes: backupCodes ?? this.backupCodes,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider for 2FA state
final twoFactorAuthProvider =
    StateNotifierProvider<TwoFactorAuthNotifier, TwoFactorStatus>(
      (ref) => TwoFactorAuthNotifier(ref),
    );

/// Notifier for managing 2FA
class TwoFactorAuthNotifier extends StateNotifier<TwoFactorStatus> {
  final Ref _ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _secretKeyStorageKey = 'tekka_2fa_secret';
  static const String _backupCodesStorageKey = 'tekka_2fa_backup_codes';

  TwoFactorAuthNotifier(this._ref) : super(const TwoFactorStatus()) {
    _loadStatus();
  }

  /// Load 2FA status from API
  Future<void> _loadStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = _ref.read(userApiRepositoryProvider);
      final status = await repository.get2FAStatus();

      final isEnabled = status['isEnabled'] as bool? ?? false;
      final methodStr = status['method'] as String?;
      final method = TwoFactorMethodX.fromString(methodStr);

      if (isEnabled) {
        state = state.copyWith(
          state: TwoFactorState.enabled,
          isEnabled: true,
          activeMethod: method,
          phoneNumber: status['phoneNumber'] as String?,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          state: TwoFactorState.disabled,
          isEnabled: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: TwoFactorState.error,
        errorMessage: 'Failed to load 2FA status',
        isLoading: false,
      );
    }
  }

  /// Start 2FA setup process
  void startSetup() {
    state = state.copyWith(state: TwoFactorState.methodSelection);
  }

  /// Select 2FA method and proceed to setup
  Future<void> selectMethod(TwoFactorMethod method) async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = _ref.read(userApiRepositoryProvider);
      final response = await repository.setup2FA(method.apiValue);

      if (method == TwoFactorMethod.sms) {
        state = state.copyWith(
          state: TwoFactorState.setupSms,
          activeMethod: method,
          phoneNumber: response['phoneNumber'] as String?,
          isLoading: false,
        );
      } else {
        final secret = response['secretKey'] as String?;
        final qrCodeUrl = response['qrCodeUrl'] as String?;
        final backupCodes = (response['backupCodes'] as List<dynamic>?)
            ?.cast<String>();

        // Store secret securely
        if (secret != null) {
          await _secureStorage.write(key: _secretKeyStorageKey, value: secret);
        }
        if (backupCodes != null) {
          await _secureStorage.write(
            key: _backupCodesStorageKey,
            value: jsonEncode(backupCodes),
          );
        }

        state = state.copyWith(
          state: TwoFactorState.setupAuthenticator,
          activeMethod: method,
          secretKey: secret,
          qrCodeUrl: qrCodeUrl,
          backupCodes: backupCodes,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: TwoFactorState.error,
        errorMessage: 'Failed to initialize 2FA setup',
        isLoading: false,
      );
    }
  }

  /// Send SMS verification code
  Future<bool> sendSmsCode() async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = _ref.read(userApiRepositoryProvider);
      await repository.send2FASmsCode();

      state = state.copyWith(
        state: TwoFactorState.verifyingCode,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to send verification code',
        isLoading: false,
      );
      return false;
    }
  }

  /// Verify the code entered by user
  Future<bool> verifyCode(String enteredCode) async {
    if (state.activeMethod == null) {
      state = state.copyWith(
        errorMessage: 'No method selected',
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final repository = _ref.read(userApiRepositoryProvider);
      final response = await repository.verify2FACode(
        enteredCode,
        state.activeMethod!.apiValue,
      );

      final backupCodes = (response['backupCodes'] as List<dynamic>?)
          ?.cast<String>();

      // Store backup codes securely
      if (backupCodes != null) {
        await _secureStorage.write(
          key: _backupCodesStorageKey,
          value: jsonEncode(backupCodes),
        );
      }

      state = state.copyWith(
        state: TwoFactorState.enabled,
        isEnabled: true,
        backupCodes: backupCodes,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Verification failed',
        isLoading: false,
      );
      return false;
    }
  }

  /// Disable 2FA
  Future<bool> disable2FA() async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = _ref.read(userApiRepositoryProvider);
      await repository.disable2FA();

      // Clear stored secrets
      await _secureStorage.delete(key: _secretKeyStorageKey);
      await _secureStorage.delete(key: _backupCodesStorageKey);

      state = state.copyWith(
        state: TwoFactorState.disabled,
        isEnabled: false,
        activeMethod: null,
        secretKey: null,
        qrCodeUrl: null,
        backupCodes: null,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to disable 2FA',
        isLoading: false,
      );
      return false;
    }
  }

  /// Regenerate backup codes
  Future<List<String>?> regenerateBackupCodes() async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = _ref.read(userApiRepositoryProvider);
      final backupCodes = await repository.regenerateBackupCodes();

      await _secureStorage.write(
        key: _backupCodesStorageKey,
        value: jsonEncode(backupCodes),
      );

      state = state.copyWith(backupCodes: backupCodes, isLoading: false);
      return backupCodes;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to regenerate backup codes',
        isLoading: false,
      );
      return null;
    }
  }

  /// Cancel setup process
  void cancelSetup() {
    state = state.copyWith(
      state: state.isEnabled ? TwoFactorState.enabled : TwoFactorState.disabled,
      secretKey: null,
      qrCodeUrl: null,
      backupCodes: null,
    );
  }

  /// Move to code verification state (used after QR code scan)
  void proceedToCodeVerification() {
    state = state.copyWith(state: TwoFactorState.verifyingCode);
  }
}
