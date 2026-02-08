import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';
import '../../auth/data/repositories/user_api_repository.dart';
import '../domain/entities/privacy_preferences.dart';

/// Stream of privacy preferences for current user (using polling)
final privacyPreferencesStreamProvider = StreamProvider<PrivacyPreferences>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const PrivacyPreferences());

  final repository = ref.watch(userApiRepositoryProvider);

  late StreamController<PrivacyPreferences> controller;
  Timer? timer;
  bool isDisposed = false;

  Future<void> poll() async {
    if (isDisposed) return;
    try {
      final data = await repository.getPrivacySettings();
      if (!isDisposed) {
        controller.add(PrivacyPreferences.fromMap(data));
      }
    } catch (e) {
      if (!isDisposed) {
        controller.addError(e);
      }
    }
  }

  controller = StreamController<PrivacyPreferences>(
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

/// One-time fetch of privacy preferences
final privacyPreferencesProvider = FutureProvider<PrivacyPreferences>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const PrivacyPreferences();

  final repository = ref.watch(userApiRepositoryProvider);
  final data = await repository.getPrivacySettings();
  return PrivacyPreferences.fromMap(data);
});

/// Fetch privacy preferences for a specific user (for checking if we can view their profile)
final userPrivacyPreferencesProvider =
    FutureProvider.family<PrivacyPreferences, String>((ref, userId) async {
      final repository = ref.watch(userApiRepositoryProvider);
      final data = await repository.getUserPrivacySettings(userId);
      return PrivacyPreferences.fromMap(data);
    });

/// Privacy preferences notifier for updating settings
class PrivacyPreferencesNotifier
    extends StateNotifier<AsyncValue<PrivacyPreferences>> {
  final UserApiRepository _repository;

  PrivacyPreferencesNotifier(this._repository, PrivacyPreferences initial)
    : super(AsyncValue.data(initial));

  Future<void> updatePreferences(PrivacyPreferences preferences) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePrivacySettings(
        profileVisibility: preferences.profileVisibility.name,
        showLocation: preferences.showLocation,
        showPhoneNumber: preferences.showPhoneNumber,
        messagePermission: preferences.messagePermission.name,
        showOnlineStatus: preferences.showOnlineStatus,
        showPurchaseHistory: preferences.showPurchaseHistory,
        showListingsCount: preferences.showListingsCount,
        appearInSearch: preferences.appearInSearch,
        allowProfileSharing: preferences.allowProfileSharing,
      );
      state = AsyncValue.data(preferences);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setProfileVisibility(ProfileVisibility visibility) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(profileVisibility: visibility));
  }

  Future<void> setShowLocation(bool show) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(showLocation: show));
  }

  Future<void> setShowPhoneNumber(bool show) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(showPhoneNumber: show));
  }

  Future<void> setMessagePermission(MessagePermission permission) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(messagePermission: permission));
  }

  Future<void> setShowOnlineStatus(bool show) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(showOnlineStatus: show));
  }

  Future<void> setShowPurchaseHistory(bool show) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(showPurchaseHistory: show));
  }

  Future<void> setShowListingsCount(bool show) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(showListingsCount: show));
  }

  Future<void> setAppearInSearch(bool appear) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(appearInSearch: appear));
  }

  Future<void> setAllowProfileSharing(bool allow) async {
    final current = state.valueOrNull ?? const PrivacyPreferences();
    await updatePreferences(current.copyWith(allowProfileSharing: allow));
  }
}

final privacyPreferencesNotifierProvider =
    StateNotifierProvider<
      PrivacyPreferencesNotifier,
      AsyncValue<PrivacyPreferences>
    >((ref) {
      final repository = ref.watch(userApiRepositoryProvider);
      final prefsAsync = ref.watch(privacyPreferencesProvider);

      final initialPrefs = prefsAsync.maybeWhen(
        data: (prefs) => prefs,
        orElse: () => const PrivacyPreferences(),
      );

      return PrivacyPreferencesNotifier(repository, initialPrefs);
    });

/// Check if current user can view another user's profile
final canViewProfileProvider = FutureProvider.family<bool, String>((
  ref,
  targetUserId,
) async {
  final currentUser = ref.watch(currentUserProvider);

  // Can always view own profile
  if (currentUser?.uid == targetUserId) return true;
  if (currentUser == null) return false;

  final repository = ref.watch(userApiRepositoryProvider);
  return repository.canViewProfile(targetUserId);
});

/// Check if current user can message another user
final canMessageUserProvider = FutureProvider.family<bool, String>((
  ref,
  targetUserId,
) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;

  // Can't message yourself
  if (currentUser.uid == targetUserId) return false;

  final repository = ref.watch(userApiRepositoryProvider);
  return repository.canMessageUser(targetUserId);
});
