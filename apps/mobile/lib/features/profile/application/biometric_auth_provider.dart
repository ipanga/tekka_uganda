import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric types available on the device
enum AppBiometricType {
  fingerprint,
  faceId,
  iris,
  none,
}

/// Status for biometric authentication
class BiometricStatus {
  final bool isAvailable;
  final bool isEnrolled;
  final bool isEnabled;
  final List<AppBiometricType> availableTypes;
  final bool isLoading;
  final String? errorMessage;

  const BiometricStatus({
    this.isAvailable = false,
    this.isEnrolled = false,
    this.isEnabled = false,
    this.availableTypes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BiometricStatus copyWith({
    bool? isAvailable,
    bool? isEnrolled,
    bool? isEnabled,
    List<AppBiometricType>? availableTypes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BiometricStatus(
      isAvailable: isAvailable ?? this.isAvailable,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      isEnabled: isEnabled ?? this.isEnabled,
      availableTypes: availableTypes ?? this.availableTypes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Get the primary biometric type available
  AppBiometricType get primaryType {
    if (availableTypes.contains(AppBiometricType.faceId)) {
      return AppBiometricType.faceId;
    } else if (availableTypes.contains(AppBiometricType.fingerprint)) {
      return AppBiometricType.fingerprint;
    } else if (availableTypes.contains(AppBiometricType.iris)) {
      return AppBiometricType.iris;
    }
    return AppBiometricType.none;
  }

  /// Get display name for the primary biometric type
  String get biometricName {
    switch (primaryType) {
      case AppBiometricType.faceId:
        return 'Face ID';
      case AppBiometricType.fingerprint:
        return 'Fingerprint';
      case AppBiometricType.iris:
        return 'Iris';
      case AppBiometricType.none:
        return 'Biometric';
    }
  }
}

/// Storage keys
class _BiometricKeys {
  static const String enabled = 'tekka_biometric_enabled';
}

/// Provider for biometric status
final biometricAuthProvider =
    StateNotifierProvider<BiometricAuthNotifier, BiometricStatus>(
  (ref) => BiometricAuthNotifier(),
);

/// Notifier for managing biometric authentication
class BiometricAuthNotifier extends StateNotifier<BiometricStatus> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  BiometricAuthNotifier() : super(const BiometricStatus()) {
    _initialize();
  }

  /// Initialize biometric status
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check if device supports biometrics
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final isAvailable = canCheckBiometrics && isDeviceSupported;

      // Get available biometric types
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final availableTypes = _mapBiometricTypes(availableBiometrics);
      final isEnrolled = availableBiometrics.isNotEmpty;

      // Check if user has enabled biometric login
      final enabledStr = await _secureStorage.read(key: _BiometricKeys.enabled);
      final isEnabled = enabledStr == 'true';

      state = state.copyWith(
        isAvailable: isAvailable,
        isEnrolled: isEnrolled,
        isEnabled: isEnabled && isAvailable && isEnrolled,
        availableTypes: availableTypes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize biometric authentication',
      );
    }
  }

  /// Map platform biometric types to our enum
  List<AppBiometricType> _mapBiometricTypes(List<BiometricType> biometrics) {
    return biometrics.map((type) {
      switch (type) {
        case BiometricType.face:
          return AppBiometricType.faceId;
        case BiometricType.fingerprint:
          return AppBiometricType.fingerprint;
        case BiometricType.iris:
          return AppBiometricType.iris;
        case BiometricType.strong:
        case BiometricType.weak:
          return AppBiometricType.fingerprint; // Default to fingerprint for generic
      }
    }).toList();
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    if (!state.isAvailable || !state.isEnrolled) {
      state = state.copyWith(
        errorMessage: 'Biometric authentication is not available',
      );
      return false;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        state = state.copyWith(
          errorMessage: 'Authentication failed',
        );
      }

      return authenticated;
    } on PlatformException catch (e) {
      String message;
      switch (e.code) {
        case 'NotAvailable':
          message = 'Biometric authentication is not available';
          break;
        case 'NotEnrolled':
          message = 'No biometrics enrolled. Please set up biometrics in device settings.';
          break;
        case 'LockedOut':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'PermanentlyLockedOut':
          message = 'Biometrics permanently locked. Please unlock device first.';
          break;
        default:
          message = 'Authentication error: ${e.message}';
      }
      state = state.copyWith(errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'An unexpected error occurred',
      );
      return false;
    }
  }

  /// Enable biometric login
  Future<bool> enableBiometric() async {
    if (!state.isAvailable) {
      state = state.copyWith(
        errorMessage: 'Biometric authentication is not available on this device',
      );
      return false;
    }

    if (!state.isEnrolled) {
      state = state.copyWith(
        errorMessage: 'Please set up biometrics in your device settings first',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    // First, verify the user can authenticate
    final authenticated = await authenticate(
      reason: 'Authenticate to enable ${state.biometricName} login',
    );

    if (!authenticated) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    try {
      await _secureStorage.write(key: _BiometricKeys.enabled, value: 'true');
      state = state.copyWith(
        isEnabled: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save biometric preference',
      );
      return false;
    }
  }

  /// Disable biometric login
  Future<bool> disableBiometric() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _secureStorage.write(key: _BiometricKeys.enabled, value: 'false');
      state = state.copyWith(
        isEnabled: false,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save biometric preference',
      );
      return false;
    }
  }

  /// Toggle biometric login
  Future<bool> toggleBiometric() async {
    if (state.isEnabled) {
      return disableBiometric();
    } else {
      return enableBiometric();
    }
  }

  /// Verify user with biometrics for sensitive operations
  Future<bool> verifyForSensitiveOperation(String reason) async {
    if (!state.isEnabled) {
      // Biometrics not enabled, skip verification
      return true;
    }

    return authenticate(reason: reason);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh biometric status
  Future<void> refresh() async {
    await _initialize();
  }
}

/// Provider for checking if biometrics are available
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final localAuth = LocalAuthentication();
  final canCheck = await localAuth.canCheckBiometrics;
  final isSupported = await localAuth.isDeviceSupported();
  return canCheck && isSupported;
});

/// Provider for getting available biometric types
final availableBiometricsProvider = FutureProvider<List<AppBiometricType>>((ref) async {
  final localAuth = LocalAuthentication();
  final biometrics = await localAuth.getAvailableBiometrics();

  return biometrics.map((type) {
    switch (type) {
      case BiometricType.face:
        return AppBiometricType.faceId;
      case BiometricType.fingerprint:
        return AppBiometricType.fingerprint;
      case BiometricType.iris:
        return AppBiometricType.iris;
      case BiometricType.strong:
      case BiometricType.weak:
        return AppBiometricType.fingerprint;
    }
  }).toList();
});
