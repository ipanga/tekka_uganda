import '../entities/app_notification.dart';

/// One page of notifications + the cursor to request the next page.
/// `nextCursor` is null when there are no more rows.
class NotificationPage {
  final List<AppNotification> items;
  final String? nextCursor;
  final bool hasMore;

  const NotificationPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}

/// Repository interface for notification operations
abstract class NotificationRepository {
  /// Get all notifications for a user
  Future<List<AppNotification>> getNotifications(String userId);

  /// Fetch a single notification by id. Returns null if the server replies
  /// 404 (notification was deleted, never existed, or belongs to another
  /// user). Throws on transport / 5xx errors.
  Future<AppNotification?> getNotification(String notificationId);

  /// Get one page of notifications. Used by the infinite-scroll notifier;
  /// pass the previous page's `nextCursor` to fetch the next page.
  Future<NotificationPage> getNotificationsPage(
    String userId, {
    int limit = 20,
    String? cursor,
  });

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
