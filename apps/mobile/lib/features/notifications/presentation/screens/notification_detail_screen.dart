import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/notification_provider.dart';
import '../../domain/entities/app_notification.dart';

/// Single notification provider
final singleNotificationProvider =
    FutureProvider.family<AppNotification?, String>((ref, id) async {
      final notifications = await ref.watch(notificationsProvider.future);
      try {
        return notifications.firstWhere((n) => n.id == id);
      } catch (_) {
        return null;
      }
    });

/// Screen showing notification details
class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notificationActionsProvider.notifier)
          .markAsRead(widget.notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationAsync = ref.watch(
      singleNotificationProvider(widget.notificationId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteNotification(context),
          ),
        ],
      ),
      body: notificationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Failed to load notification',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(
                  singleNotificationProvider(widget.notificationId),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notification) {
          if (notification == null) {
            return Center(
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
                    'Notification not found',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return _buildContent(context, notification);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppNotification notification) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge and time
          Row(
            children: [
              _TypeBadge(type: notification.type),
              const Spacer(),
              Text(
                notification.timeAgo,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space6),

          // Icon/Image
          Center(child: _buildNotificationIcon(notification)),

          const SizedBox(height: AppSpacing.space6),

          // Title
          Text(
            notification.title,
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space3),

          // Body
          Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(
              notification.body,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Date info
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Received on',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Action buttons based on type
          if (notification.targetId != null) ...[
            _buildActionButton(context, notification),
          ],

          // Additional context based on type
          if (_getAdditionalInfo(notification.type) != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withAlpha(30),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      _getAdditionalInfo(notification.type)!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    if (notification.imageUrl != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          image: DecorationImage(
            image: CachedNetworkImageProvider(notification.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(notification.type),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getIconColor(notification.type).withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        _getNotificationIcon(notification.type),
        color: _getIconColor(notification.type),
        size: 48,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    AppNotification notification,
  ) {
    final targetType = notification.targetType;
    final targetId = notification.targetId;

    if (targetId == null) return const SizedBox.shrink();

    String buttonText;
    IconData buttonIcon;
    VoidCallback onPressed;

    switch (targetType) {
      case 'chat':
        buttonText = 'Open Chat';
        buttonIcon = Icons.chat_bubble_outline;
        onPressed = () {
          context.push(AppRoutes.chat.replaceFirst(':id', targetId));
        };
        break;
      case 'listing':
        buttonText = 'View Listing';
        buttonIcon = Icons.shopping_bag_outlined;
        onPressed = () {
          context.push(AppRoutes.listingDetail.replaceFirst(':id', targetId));
        };
        break;
      case 'user':
        buttonText = 'View Profile';
        buttonIcon = Icons.person_outline;
        onPressed = () {
          context.push(AppRoutes.userProfile.replaceFirst(':userId', targetId));
        };
        break;
      case 'meetup':
        buttonText = 'View Meetup';
        buttonIcon = Icons.handshake_outlined;
        onPressed = () {
          context.push(AppRoutes.meetupDetail.replaceFirst(':id', targetId));
        };
        break;
      default:
        // Fallback based on notification type
        switch (notification.type) {
          case NotificationType.message:
            buttonText = 'Open Chat';
            buttonIcon = Icons.chat_bubble_outline;
            onPressed = () {
              context.push(AppRoutes.chat.replaceFirst(':id', targetId));
            };
            break;
          case NotificationType.listingApproved:
          case NotificationType.listingRejected:
          case NotificationType.listingSold:
          case NotificationType.priceDropped:
            buttonText = 'View Listing';
            buttonIcon = Icons.shopping_bag_outlined;
            onPressed = () {
              context.push(
                AppRoutes.listingDetail.replaceFirst(':id', targetId),
              );
            };
            break;
          case NotificationType.newFollower:
            buttonText = 'View Profile';
            buttonIcon = Icons.person_outline;
            onPressed = () {
              context.push(
                AppRoutes.userProfile.replaceFirst(':userId', targetId),
              );
            };
            break;
          case NotificationType.offer:
          case NotificationType.offerAccepted:
          case NotificationType.offerDeclined:
          case NotificationType.system:
            return const SizedBox.shrink();
        }
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(buttonIcon),
        label: Text(buttonText),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
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

  Color _getIconBackgroundColor(NotificationType type) {
    switch (type) {
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

  Color _getIconColor(NotificationType type) {
    switch (type) {
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

  String? _getAdditionalInfo(NotificationType type) {
    switch (type) {
      case NotificationType.offer:
        return 'Offers expire after 48 hours if not responded to.';
      case NotificationType.offerAccepted:
        return 'Message the buyer to arrange a meetup!';
      case NotificationType.listingApproved:
        return 'Your listing is now visible to buyers.';
      case NotificationType.listingRejected:
        return 'Please review and update your listing.';
      case NotificationType.priceDropped:
        return 'Be quick - items can sell fast when prices drop!';
      case NotificationType.newFollower:
        return 'They will be notified when you post new listings.';
      default:
        return null;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute $period';
  }

  void _deleteNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(notificationActionsProvider.notifier)
                  .deleteNotification(widget.notificationId);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification deleted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Badge showing notification type
class _TypeBadge extends StatelessWidget {
  final NotificationType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 14, color: _getColor()),
          const SizedBox(width: 4),
          Text(
            _getLabel(),
            style: AppTypography.labelSmall.copyWith(
              color: _getColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel() {
    switch (type) {
      case NotificationType.message:
        return 'Message';
      case NotificationType.offer:
        return 'Offer';
      case NotificationType.offerAccepted:
        return 'Offer Accepted';
      case NotificationType.offerDeclined:
        return 'Offer Declined';
      case NotificationType.listingApproved:
        return 'Approved';
      case NotificationType.listingRejected:
        return 'Rejected';
      case NotificationType.listingSold:
        return 'Sold';
      case NotificationType.newFollower:
        return 'New Follower';
      case NotificationType.priceDropped:
        return 'Price Drop';
      case NotificationType.system:
        return 'System';
    }
  }

  IconData _getIcon() {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.offer:
        return Icons.local_offer;
      case NotificationType.offerAccepted:
        return Icons.check_circle;
      case NotificationType.offerDeclined:
        return Icons.cancel;
      case NotificationType.listingApproved:
        return Icons.verified;
      case NotificationType.listingRejected:
        return Icons.block;
      case NotificationType.listingSold:
        return Icons.sell;
      case NotificationType.newFollower:
        return Icons.person_add;
      case NotificationType.priceDropped:
        return Icons.trending_down;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getColor() {
    switch (type) {
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

  Color _getBackgroundColor() {
    switch (type) {
      case NotificationType.message:
        return AppColors.primaryContainer;
      case NotificationType.offer:
        return AppColors.gold.withAlpha(30);
      case NotificationType.offerAccepted:
      case NotificationType.listingApproved:
      case NotificationType.listingSold:
        return AppColors.success.withAlpha(30);
      case NotificationType.offerDeclined:
      case NotificationType.listingRejected:
        return AppColors.error.withAlpha(30);
      case NotificationType.newFollower:
        return AppColors.secondary.withAlpha(30);
      case NotificationType.priceDropped:
        return AppColors.secondaryLight.withAlpha(30);
      case NotificationType.system:
        return AppColors.gray100;
    }
  }
}
