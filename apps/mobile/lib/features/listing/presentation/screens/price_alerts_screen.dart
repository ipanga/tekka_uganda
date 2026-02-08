import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../application/price_alert_provider.dart';
import '../../domain/entities/price_alert.dart';

/// Screen showing price drop alerts for saved items
class PriceAlertsScreen extends ConsumerWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(priceAlertsStreamProvider);
    final state = ref.watch(priceAlertProvider);
    final unreadCount = ref.watch(unreadPriceAlertsCountProvider);

    // Listen for errors
    ref.listen<PriceAlertState>(priceAlertProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(priceAlertProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Price Alerts'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(priceAlertProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      state.priceAlertsEnabled
                          ? Icons.notifications_off_outlined
                          : Icons.notifications_active_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.priceAlertsEnabled
                          ? 'Disable alerts'
                          : 'Enable alerts',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load alerts', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(priceAlertsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return _buildEmptyState(context, state.priceAlertsEnabled);
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _PriceAlertTile(
                    alert: alert,
                    onTap: () => _handleAlertTap(context, ref, alert),
                    onDelete: () => ref
                        .read(priceAlertProvider.notifier)
                        .deleteAlert(alert.id),
                  );
                },
              ),
              if (state.isLoading)
                Container(
                  color: AppColors.gray900.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool alertsEnabled) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: alertsEnabled
                    ? AppColors.primaryContainer
                    : AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                alertsEnabled
                    ? Icons.trending_down
                    : Icons.notifications_off_outlined,
                size: 40,
                color: alertsEnabled ? AppColors.primary : AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              alertsEnabled ? 'No Price Drops Yet' : 'Alerts Disabled',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              alertsEnabled
                  ? 'When items you\'ve saved drop in price, you\'ll see them here.'
                  : 'Enable price alerts to get notified when saved items drop in price.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            if (alertsEnabled)
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.saved),
                icon: const Icon(Icons.favorite_border),
                label: const Text('View Saved Items'),
              ),
          ],
        ),
      ),
    );
  }

  void _handleAlertTap(BuildContext context, WidgetRef ref, PriceAlert alert) {
    // Mark as read
    if (!alert.isRead) {
      ref.read(priceAlertProvider.notifier).markAsRead(alert.id);
    }

    // Navigate to listing
    context.push(AppRoutes.listingDetail.replaceFirst(':id', alert.listingId));
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'toggle':
        final currentState = ref.read(priceAlertProvider);
        ref
            .read(priceAlertProvider.notifier)
            .togglePriceAlerts(!currentState.priceAlertsEnabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentState.priceAlertsEnabled
                  ? 'Price alerts disabled'
                  : 'Price alerts enabled',
            ),
          ),
        );
        break;
      case 'clear_all':
        _showClearAllDialog(context, ref);
        break;
    }
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Alerts'),
        content: const Text('Are you sure you want to clear all price alerts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(priceAlertProvider.notifier).clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _PriceAlertTile extends StatelessWidget {
  const _PriceAlertTile({
    required this.alert,
    required this.onTap,
    required this.onDelete,
  });

  final PriceAlert alert;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      child: InkWell(
        onTap: alert.isExpired ? null : onTap,
        child: Container(
          color: alert.isRead || alert.isExpired
              ? AppColors.surface
              : AppColors.primaryContainer.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.gray100,
                    ),
                    child: alert.listingImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: alert.listingImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: AppColors.gray400,
                              ),
                            ),
                          )
                        : const Icon(Icons.image, color: AppColors.gray400),
                  ),
                  // Price drop badge
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: alert.isExpired
                            ? AppColors.gray400
                            : AppColors.success,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '-${alert.formattedDropPercent}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.space3),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.listingTitle,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: alert.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: alert.isExpired
                                  ? AppColors.gray400
                                  : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          alert.timeAgo,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Price comparison
                    Row(
                      children: [
                        Text(
                          alert.formattedOriginalPrice,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.gray400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          alert.formattedNewPrice,
                          style: AppTypography.titleSmall.copyWith(
                            color: alert.isExpired
                                ? AppColors.gray400
                                : AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Savings and seller
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: alert.isExpired
                                ? AppColors.gray100
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Save ${alert.formattedDropAmount}',
                            style: AppTypography.labelSmall.copyWith(
                              color: alert.isExpired
                                  ? AppColors.gray400
                                  : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'by ${alert.sellerName}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    if (alert.isExpired) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Item no longer available',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.gray400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Unread indicator
              if (!alert.isRead && !alert.isExpired) ...[
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
}
