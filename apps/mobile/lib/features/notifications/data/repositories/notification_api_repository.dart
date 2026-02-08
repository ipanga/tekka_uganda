import 'dart:async';

import '../../../../core/services/api_client.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// API-based implementation of NotificationRepository
class NotificationApiRepository implements NotificationRepository {
  final ApiClient _apiClient;
  final Duration _pollInterval;

  NotificationApiRepository(this._apiClient, {Duration? pollInterval})
    : _pollInterval = pollInterval ?? const Duration(seconds: 15);

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'limit': 50},
    );
    final notifications = response['data'] as List<dynamic>? ?? [];
    return notifications
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _createPollingStream(
      () => getNotifications(userId),
      interval: _pollInterval,
    );
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      return response['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _createPollingStream(
      () => getUnreadCount(userId),
      interval: _pollInterval,
    );
  }

  @override
  Future<AppNotification> createNotification(
    AppNotification notification,
    String userId,
  ) async {
    // Notifications are created server-side, this is not typically called from client
    // But we keep the interface for compatibility
    throw UnsupportedError(
      'Client cannot create notifications directly. Use server-side notification service.',
    );
  }

  @override
  Future<void> markAsRead(String notificationId, String userId) async {
    await _apiClient.post('/notifications/$notificationId/read');
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _apiClient.post('/notifications/read-all');
  }

  @override
  Future<void> deleteNotification(String notificationId, String userId) async {
    await _apiClient.delete('/notifications/$notificationId');
  }

  @override
  Future<void> clearAll(String userId) async {
    await _apiClient.delete('/notifications');
  }

  /// Helper to create a polling stream from an async function
  Stream<T> _createPollingStream<T>(
    Future<T> Function() fetcher, {
    required Duration interval,
  }) {
    late StreamController<T> controller;
    Timer? timer;
    bool isDisposed = false;

    Future<void> poll() async {
      if (isDisposed) return;
      try {
        final data = await fetcher();
        if (!isDisposed) {
          controller.add(data);
        }
      } catch (e) {
        if (!isDisposed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<T>(
      onListen: () {
        poll(); // Initial fetch
        timer = Timer.periodic(interval, (_) => poll());
      },
      onCancel: () {
        isDisposed = true;
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}
