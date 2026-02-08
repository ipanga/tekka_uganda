import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';
import '../../auth/data/repositories/user_api_repository.dart';
import '../domain/entities/security_preferences.dart';

/// Stream of security preferences for current user (using polling)
final securityPreferencesStreamProvider = StreamProvider<SecurityPreferences>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const SecurityPreferences());

  final repository = ref.watch(userApiRepositoryProvider);

  late StreamController<SecurityPreferences> controller;
  Timer? timer;
  bool isDisposed = false;

  Future<void> poll() async {
    if (isDisposed) return;
    try {
      final settings = await repository.getSettings();
      if (!isDisposed) {
        controller.add(SecurityPreferences.fromMap(settings));
      }
    } catch (e) {
      if (!isDisposed) {
        controller.addError(e);
      }
    }
  }

  controller = StreamController<SecurityPreferences>(
    onListen: () {
      poll();
      timer = Timer.periodic(const Duration(seconds: 60), (_) => poll());
    },
    onCancel: () {
      isDisposed = true;
      timer?.cancel();
    },
  );

  return controller.stream;
});

/// One-time fetch of security preferences
final securityPreferencesProvider = FutureProvider<SecurityPreferences>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const SecurityPreferences();

  final repository = ref.watch(userApiRepositoryProvider);
  final settings = await repository.getSettings();
  return SecurityPreferences.fromMap(settings);
});

/// Verification status provider (using polling)
final verificationStatusProvider = StreamProvider<VerificationStatus>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const VerificationStatus());

  final repository = ref.watch(userApiRepositoryProvider);

  late StreamController<VerificationStatus> controller;
  Timer? timer;
  bool isDisposed = false;

  Future<void> poll() async {
    if (isDisposed) return;
    try {
      final status = await repository.getVerificationStatus();
      if (!isDisposed) {
        // Phone is verified if user authenticated via phone
        final phoneVerified = user.phoneNumber.isNotEmpty;

        controller.add(
          VerificationStatus(
            phoneVerified: phoneVerified,
            phoneVerifiedAt: phoneVerified ? user.createdAt : null,
            emailVerified: status['emailVerified'] as bool? ?? false,
            emailVerifiedAt: status['emailVerifiedAt'] != null
                ? DateTime.parse(status['emailVerifiedAt'] as String)
                : null,
            identityVerified: status['identityVerified'] as bool? ?? false,
            identityVerifiedAt: status['identityVerifiedAt'] != null
                ? DateTime.parse(status['identityVerifiedAt'] as String)
                : null,
          ),
        );
      }
    } catch (e) {
      if (!isDisposed) {
        controller.addError(e);
      }
    }
  }

  controller = StreamController<VerificationStatus>(
    onListen: () {
      poll();
      timer = Timer.periodic(const Duration(seconds: 60), (_) => poll());
    },
    onCancel: () {
      isDisposed = true;
      timer?.cancel();
    },
  );

  return controller.stream;
});

/// Login sessions provider
final loginSessionsProvider = FutureProvider<List<LoginSession>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(userApiRepositoryProvider);
  final sessions = await repository.getLoginSessions();

  return sessions.map((data) => LoginSession.fromMap(data)).toList();
});

/// Security preferences notifier
class SecurityPreferencesNotifier
    extends StateNotifier<AsyncValue<SecurityPreferences>> {
  final UserApiRepository _repository;

  SecurityPreferencesNotifier(this._repository, SecurityPreferences initial)
    : super(AsyncValue.data(initial));

  Future<void> updatePreferences(SecurityPreferences preferences) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSettings(
        biometricEnabled: preferences.biometricEnabled,
        loginAlerts: preferences.loginAlerts,
        requireTransactionConfirmation:
            preferences.requireTransactionConfirmation,
        transactionThreshold: preferences.transactionThreshold,
        twoFactorEnabled: preferences.twoFactorEnabled,
      );
      state = AsyncValue.data(preferences);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const SecurityPreferences();
    await updatePreferences(current.copyWith(biometricEnabled: enabled));
  }

  Future<void> setLoginAlerts(bool enabled) async {
    final current = state.valueOrNull ?? const SecurityPreferences();
    await updatePreferences(current.copyWith(loginAlerts: enabled));
  }

  Future<void> setTransactionConfirmation(bool required) async {
    final current = state.valueOrNull ?? const SecurityPreferences();
    await updatePreferences(
      current.copyWith(requireTransactionConfirmation: required),
    );
  }

  Future<void> setTransactionThreshold(int amount) async {
    final current = state.valueOrNull ?? const SecurityPreferences();
    await updatePreferences(current.copyWith(transactionThreshold: amount));
  }

  Future<void> setTwoFactorEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const SecurityPreferences();
    await updatePreferences(current.copyWith(twoFactorEnabled: enabled));
  }
}

final securityPreferencesNotifierProvider =
    StateNotifierProvider<
      SecurityPreferencesNotifier,
      AsyncValue<SecurityPreferences>
    >((ref) {
      final repository = ref.watch(userApiRepositoryProvider);
      final prefsAsync = ref.watch(securityPreferencesProvider);

      final initialPrefs = prefsAsync.maybeWhen(
        data: (prefs) => prefs,
        orElse: () => const SecurityPreferences(),
      );

      return SecurityPreferencesNotifier(repository, initialPrefs);
    });

/// Sign out from all devices action
final signOutAllDevicesProvider = Provider((ref) {
  return () async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repository = ref.read(userApiRepositoryProvider);
    await repository.signOutAllDevices();

    // Sign out current user
    await ref.read(authNotifierProvider.notifier).signOut();
  };
});

/// Terminate specific session
final terminateSessionProvider =
    Provider.family<Future<void> Function(), String>((ref, sessionId) {
      return () async {
        final user = ref.read(currentUserProvider);
        if (user == null) return;

        final repository = ref.read(userApiRepositoryProvider);
        await repository.terminateSession(sessionId);

        // Refresh sessions list
        ref.invalidate(loginSessionsProvider);
      };
    });
