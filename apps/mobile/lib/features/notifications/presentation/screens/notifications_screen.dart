import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/notification_provider.dart';
import '../../domain/entities/app_notification.dart';

/// Notifications screen
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => _markAllAsRead(context, ref),
              child: const Text('Mark all read'),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Notification settings'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear all'),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load notifications', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(notificationsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _handleNotificationTap(context, ref, notification),
                onDismiss: () => _deleteNotification(context, ref, notification.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'No notifications',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              "You're all caught up! We'll notify you when something happens.",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationActionsProvider.notifier).markAsRead(notification.id);
    }

    // Navigate to notification detail screen
    context.push(
      AppRoutes.notificationDetail.replaceFirst(':id', notification.id),
    );
  }

  void _markAllAsRead(BuildContext context, WidgetRef ref) {
    ref.read(notificationActionsProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _deleteNotification(BuildContext context, WidgetRef ref, String id) {
    ref.read(notificationActionsProvider.notifier).deleteNotification(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'settings':
        context.push(AppRoutes.settings);
        break;
      case 'clear':
        _showClearAllDialog(context, ref);
        break;
    }
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationActionsProvider.notifier).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: AppColors.white,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead ? AppColors.surface : AppColors.primaryContainer.withAlpha(30),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or image
              _buildLeading(),
              const SizedBox(width: AppSpacing.space3),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight:
                                  notification.isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead) ...[
                const SizedBox(width: AppSpacing.space2),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (notification.imageUrl != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: CachedNetworkImageProvider(notification.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getNotificationIcon(),
        color: _getIconColor(),
        size: 24,
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.offer:
        return Icons.local_offer_outlined;
      case NotificationType.offerAccepted:
        return Icons.check_circle_outline;
      case NotificationType.offerDeclined:
        return Icons.cancel_outlined;
      case NotificationType.listingApproved:
        return Icons.verified_outlined;
      case NotificationType.listingRejected:
        return Icons.block_outlined;
      case NotificationType.listingSold:
        return Icons.sell_outlined;
      case NotificationType.newFollower:
        return Icons.person_add_outlined;
      case NotificationType.priceDropped:
        return Icons.trending_down;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _getIconBackgroundColor() {
    switch (notification.type) {
      case NotificationType.message:
        return AppColors.primaryContainer;
      case NotificationType.offer:
        return AppColors.gold.withAlpha(50);
      case NotificationType.offerAccepted:
      case NotificationType.listingApproved:
      case NotificationType.listingSold:
        return AppColors.success.withAlpha(50);
      case NotificationType.offerDeclined:
      case NotificationType.listingRejected:
        return AppColors.error.withAlpha(50);
      case NotificationType.newFollower:
        return AppColors.secondary.withAlpha(50);
      case NotificationType.priceDropped:
        return AppColors.secondaryLight.withAlpha(50);
      case NotificationType.system:
        return AppColors.gray100;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.offer:
        return AppColors.gold;
      case NotificationType.offerAccepted:
      case NotificationType.listingApproved:
      case NotificationType.listingSold:
        return AppColors.success;
      case NotificationType.offerDeclined:
      case NotificationType.listingRejected:
        return AppColors.error;
      case NotificationType.newFollower:
        return AppColors.secondary;
      case NotificationType.priceDropped:
        return AppColors.secondaryLight;
      case NotificationType.system:
        return AppColors.onSurfaceVariant;
    }
  }
}
