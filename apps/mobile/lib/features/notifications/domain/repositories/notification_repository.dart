import '../entities/app_notification.dart';

/// Repository interface for notification operations
abstract class NotificationRepository {
  /// Get all notifications for a user
  Future<List<AppNotification>> getNotifications(String userId);

  /// Stream of notifications for a user
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Get unread count for a user
  Future<int> getUnreadCount(String userId);

  /// Stream of unread count
  Stream<int> watchUnreadCount(String userId);

  /// Create a notification
  Future<AppNotification> createNotification(
    AppNotification notification,
    String userId,
  );

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId, String userId);

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId, String userId);

  /// Clear all notifications
  Future<void> clearAll(String userId);
}
