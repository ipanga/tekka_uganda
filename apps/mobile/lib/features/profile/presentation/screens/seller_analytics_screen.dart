import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../application/profile_provider.dart';

/// Seller Analytics Dashboard
class SellerAnalyticsScreen extends ConsumerWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(sellerAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load analytics', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(sellerAnalyticsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (analytics) {
          if (analytics.totalListings == 0) {
            return _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerAnalyticsProvider),
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                // Quick Stats Cards
                _QuickStatsSection(analytics: analytics),

                const SizedBox(height: AppSpacing.space6),

                // Revenue Card
                _RevenueCard(analytics: analytics),

                const SizedBox(height: AppSpacing.space6),

                // Engagement Stats
                _EngagementCard(analytics: analytics),

                const SizedBox(height: AppSpacing.space6),

                // Category Breakdown
                if (analytics.categorySales.isNotEmpty) ...[
                  _CategoryBreakdownCard(categories: analytics.categorySales),
                  const SizedBox(height: AppSpacing.space6),
                ],

                // Views Chart
                if (analytics.monthlyViews.isNotEmpty) ...[
                  _ViewsChartCard(monthlyViews: analytics.monthlyViews),
                  const SizedBox(height: AppSpacing.space6),
                ],

                // Top Performing Listings
                if (analytics.topListings.isNotEmpty) ...[
                  _TopListingsCard(listings: analytics.topListings),
                  const SizedBox(height: AppSpacing.space6),
                ],

                // Recent Listings Performance
                if (analytics.recentListings.isNotEmpty) ...[
                  _RecentListingsCard(listings: analytics.recentListings),
                  const SizedBox(height: AppSpacing.space6),
                ],

                const SizedBox(height: AppSpacing.space10),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'No listings yet',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Start selling to see your analytics',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.createListing),
              icon: const Icon(Icons.add),
              label: const Text('Create Listing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection({required this.analytics});

  final SellerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.primary,
                value: analytics.totalListings.toString(),
                label: 'Total',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
                value: analytics.activeListings.toString(),
                label: 'Active',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                icon: Icons.pending_outlined,
                iconColor: AppColors.gold,
                value: analytics.pendingListings.toString(),
                label: 'Pending',
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _StatCard(
                icon: Icons.sell_outlined,
                iconColor: AppColors.secondary,
                value: analytics.soldListings.toString(),
                label: 'Sold',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: AppSpacing.iconMedium),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.analytics});

  final SellerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: AppColors.white),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'Total Revenue',
                style: AppTypography.titleMedium.copyWith(color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            _formatCurrency(analytics.totalRevenue),
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg. Price',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      _formatCurrency(analytics.averagePrice.round()),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conversion Rate',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '${analytics.conversionRate.toStringAsFixed(1)}%',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return 'UGX ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'UGX ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'UGX $amount';
  }
}

class _EngagementCard extends StatelessWidget {
  const _EngagementCard({required this.analytics});

  final SellerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Engagement', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: _EngagementItem(
                  icon: Icons.visibility_outlined,
                  value: analytics.totalViews.toString(),
                  label: 'Total Views',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.outline,
              ),
              Expanded(
                child: _EngagementItem(
                  icon: Icons.favorite_border,
                  value: analytics.totalFavorites.toString(),
                  label: 'Favorites',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.outline,
              ),
              Expanded(
                child: _EngagementItem(
                  icon: Icons.star_border,
                  value: analytics.rating > 0
                      ? analytics.rating.toStringAsFixed(1)
                      : '-',
                  label: '${analytics.reviewCount} reviews',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EngagementItem extends StatelessWidget {
  const _EngagementItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: AppSpacing.iconMedium),
        const SizedBox(height: AppSpacing.space2),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.categories});

  final Map<String, int> categories;

  @override
  Widget build(BuildContext context) {
    final total = categories.values.fold<int>(0, (sum, v) => sum + v);
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sales by Category', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space4),
          ...sortedCategories.map((entry) {
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: AppTypography.bodyMedium),
                      Text(
                        '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ViewsChartCard extends StatelessWidget {
  const _ViewsChartCard({required this.monthlyViews});

  final Map<String, int> monthlyViews;

  @override
  Widget build(BuildContext context) {
    final maxViews = monthlyViews.values.isEmpty
        ? 1
        : monthlyViews.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Views', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space4),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyViews.entries.map((entry) {
                final height = maxViews > 0 ? (entry.value / maxViews) * 80 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.value.toString(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Container(
                          height: height.clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          entry.key,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopListingsCard extends StatelessWidget {
  const _TopListingsCard({required this.listings});

  final List<ListingPerformance> listings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.space2),
              Text('Top Performers', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          ...listings.asMap().entries.map((entry) {
            return _ListingPerformanceRow(
              listing: entry.value,
              rank: entry.key + 1,
            );
          }),
        ],
      ),
    );
  }
}

class _RecentListingsCard extends StatelessWidget {
  const _RecentListingsCard({required this.listings});

  final List<ListingPerformance> listings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.space2),
              Text('Recent Listings', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          ...listings.map((listing) {
            return _ListingPerformanceRow(listing: listing);
          }),
        ],
      ),
    );
  }
}

class _ListingPerformanceRow extends StatelessWidget {
  const _ListingPerformanceRow({
    required this.listing,
    this.rank,
  });

  final ListingPerformance listing;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.listingDetail.replaceFirst(':id', listing.id));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space3),
        child: Row(
          children: [
            // Rank badge (optional)
            if (rank != null) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? AppColors.gold
                      : rank == 2
                          ? AppColors.gray400
                          : AppColors.secondary.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
            ],

            // Image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
                image: listing.imageUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(listing.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: listing.imageUrl == null
                  ? const Icon(Icons.image, color: AppColors.gray400, size: 20)
                  : null,
            ),
            const SizedBox(width: AppSpacing.space3),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      _StatusBadge(status: listing.status),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        _formatPrice(listing.price),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      listing.views.toString(),
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      listing.favorites.toString(),
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.space2),
            const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return 'UGX ${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return 'UGX ${(price / 1000).toStringAsFixed(0)}K';
    }
    return 'UGX $price';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String text;

    switch (status) {
      case ListingStatus.active:
        backgroundColor = AppColors.success;
        text = 'Active';
        break;
      case ListingStatus.pending:
        backgroundColor = AppColors.gold;
        text = 'Pending';
        break;
      case ListingStatus.sold:
        backgroundColor = AppColors.secondary;
        text = 'Sold';
        break;
      case ListingStatus.draft:
        backgroundColor = AppColors.gray400;
        text = 'Draft';
        break;
      case ListingStatus.archived:
        backgroundColor = AppColors.gray400;
        text = 'Archived';
        break;
      case ListingStatus.rejected:
        backgroundColor = AppColors.error;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: backgroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
