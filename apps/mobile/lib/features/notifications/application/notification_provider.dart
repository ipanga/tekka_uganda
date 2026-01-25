import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';
import '../../auth/data/repositories/user_api_repository.dart';
import '../data/repositories/notification_api_repository.dart';
import '../domain/entities/app_notification.dart';
import '../domain/entities/notification_preferences.dart';
import '../domain/repositories/notification_repository.dart';

/// Notification repository provider - uses API backend
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationApiRepository(apiClient);
});

/// Stream of notifications for current user
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications(user.uid);
});

/// Notifications list provider (one-time fetch)
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications(user.uid);
});

/// Stream of unread notifications count
final unreadNotificationsStreamProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUnreadCount(user.uid);
});

/// Unread notifications count provider (derived from stream)
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final countAsync = ref.watch(unreadNotificationsStreamProvider);
  return countAsync.maybeWhen(
    data: (count) => count,
    orElse: () => 0,
  );
});

/// Notification actions notifier
class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;
  final String _userId;

  NotificationActionsNotifier(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAsRead(notificationId, _userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAllAsRead(_userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteNotification(notificationId, _userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearAll(_userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(notificationRepositoryProvider);

  return NotificationActionsNotifier(
    repository,
    user?.uid ?? '',
  );
});

/// Create notification helper provider
final createNotificationProvider = Provider((ref) {
  final repository = ref.watch(notificationRepositoryProvider);

  return (AppNotification notification, String userId) async {
    return repository.createNotification(notification, userId);
  };
});

/// Stream of notification preferences for current user (using polling)
final notificationPreferencesStreamProvider =
    StreamProvider<NotificationPreferences>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const NotificationPreferences());

  final repository = ref.watch(userApiRepositoryProvider);

  // Create a polling stream
  late StreamController<NotificationPreferences> controller;
  Timer? timer;
  bool isDisposed = false;

  Future<void> poll() async {
    if (isDisposed) return;
    try {
      final settings = await repository.getSettings();
      if (!isDisposed) {
        controller.add(NotificationPreferences.fromMap(settings));
      }
    } catch (e) {
      if (!isDisposed) {
        controller.addError(e);
      }
    }
  }

  controller = StreamController<NotificationPreferences>(
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

/// One-time fetch of notification preferences
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const NotificationPreferences();

  final repository = ref.watch(userApiRepositoryProvider);
  final settings = await repository.getSettings();
  return NotificationPreferences.fromMap(settings);
});

/// Notification preferences notifier for updating settings
class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final UserApiRepository _repository;

  NotificationPreferencesNotifier(
      this._repository, NotificationPreferences initial)
      : super(AsyncValue.data(initial));

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSettings(
        pushEnabled: preferences.pushEnabled,
        emailEnabled: preferences.emailEnabled,
        marketingEnabled: preferences.marketingEnabled,
        messageNotifications: preferences.messageNotifications,
        offerNotifications: preferences.offerNotifications,
        reviewNotifications: preferences.reviewNotifications,
        listingNotifications: preferences.listingNotifications,
        systemNotifications: preferences.systemNotifications,
        doNotDisturb: preferences.doNotDisturb,
        dndStartHour: preferences.dndStartHour,
        dndEndHour: preferences.dndEndHour,
      );
      state = AsyncValue.data(preferences);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setPushEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(pushEnabled: enabled));
  }

  Future<void> setEmailEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(emailEnabled: enabled));
  }

  Future<void> setMarketingEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(marketingEnabled: enabled));
  }

  Future<void> setMessageNotifications(bool enabled) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(messageNotifications: enabled));
  }

  Future<void> setOfferNotifications(bool enabled) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(offerNotifications: enabled));
  }

  Future<void> setReviewNotifications(bool enabled) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(reviewNotifications: enabled));
  }

  Future<void> setListingNotifications(bool enabled) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(listingNotifications: enabled));
  }

  Future<void> setSystemNotifications(bool enabled) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(systemNotifications: enabled));
  }

  Future<void> setDoNotDisturb(bool enabled, {int? startHour, int? endHour}) async {
    final current = state.valueOrNull ?? const NotificationPreferences();
    await updatePreferences(current.copyWith(
      doNotDisturb: enabled,
      dndStartHour: startHour ?? current.dndStartHour,
      dndEndHour: endHour ?? current.dndEndHour,
    ));
  }
}

final notificationPreferencesNotifierProvider = StateNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferences>>((ref) {
  final repository = ref.watch(userApiRepositoryProvider);
  final prefsAsync = ref.watch(notificationPreferencesProvider);

  final initialPrefs = prefsAsync.maybeWhen(
    data: (prefs) => prefs,
    orElse: () => const NotificationPreferences(),
  );

  return NotificationPreferencesNotifier(
    repository,
    initialPrefs,
  );
});
