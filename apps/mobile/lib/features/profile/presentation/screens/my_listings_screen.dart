import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/domain/entities/listing.dart';

/// My listings screen - shows all user's listings with filters
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final listingsAsync = ref.watch(userListingsProvider(user?.uid ?? ''));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Listings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Under Review'),
            Tab(text: 'Sold'),
          ],
        ),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load listings', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () =>
                    ref.invalidate(userListingsProvider(user?.uid ?? '')),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (listings) {
          final activeListings = listings
              .where((l) => l.status == ListingStatus.active)
              .toList();
          // Include both pending and rejected listings in "Under Review" tab
          final underReviewListings = listings
              .where(
                (l) =>
                    l.status == ListingStatus.pending ||
                    l.status == ListingStatus.rejected,
              )
              .toList();
          final soldListings = listings
              .where((l) => l.status == ListingStatus.sold)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ListingsGrid(
                listings: listings,
                emptyMessage: 'No listings yet',
                emptyAction: 'Create your first listing',
                onEmptyAction: () => context.push(AppRoutes.createListing),
              ),
              _ListingsGrid(
                listings: activeListings,
                emptyMessage: 'No active listings',
                emptyAction: 'Create a new listing',
                onEmptyAction: () => context.push(AppRoutes.createListing),
              ),
              _ListingsGrid(
                listings: underReviewListings,
                emptyMessage: 'No listings under review',
                emptyAction: null,
                onEmptyAction: null,
              ),
              _ListingsGrid(
                listings: soldListings,
                emptyMessage: 'No sold listings yet',
                emptyAction: null,
                onEmptyAction: null,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createListing),
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
    );
  }
}

class _ListingsGrid extends StatelessWidget {
  const _ListingsGrid({
    required this.listings,
    required this.emptyMessage,
    this.emptyAction,
    this.onEmptyAction,
  });

  final List<Listing> listings;
  final String emptyMessage;
  final String? emptyAction;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(emptyMessage, style: AppTypography.titleMedium),
              if (emptyAction != null && onEmptyAction != null) ...[
                const SizedBox(height: AppSpacing.space4),
                ElevatedButton(
                  onPressed: onEmptyAction,
                  child: Text(emptyAction!),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Parent will handle refresh via provider invalidation
      },
      child: GridView.builder(
        padding: AppSpacing.screenPadding,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppSpacing.space3,
          mainAxisSpacing: AppSpacing.space3,
        ),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          return _ListingCard(listing: listings[index]);
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.listingDetail.replaceFirst(':id', listing.id));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: listing.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.gray100,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.gray100,
                              child: const Icon(
                                Icons.broken_image,
                                color: AppColors.gray400,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.gray100,
                            child: const Icon(
                              Icons.image,
                              color: AppColors.gray400,
                              size: 40,
                            ),
                          ),
                  ),
                  // Status badge
                  Positioned(
                    top: AppSpacing.space2,
                    left: AppSpacing.space2,
                    child: _StatusBadge(status: listing.status),
                  ),
                  // View count
                  Positioned(
                    bottom: AppSpacing.space2,
                    right: AppSpacing.space2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            listing.viewCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: AppTypography.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.formattedPrice,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.timeAgo,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      case ListingStatus.pending:
        backgroundColor = AppColors.gold;
        text = 'Pending';
      case ListingStatus.sold:
        backgroundColor = AppColors.primary;
        text = 'Sold';
      case ListingStatus.rejected:
        backgroundColor = AppColors.error;
        text = 'Rejected';
      case ListingStatus.archived:
        backgroundColor = AppColors.gray400;
        text = 'Archived';
      case ListingStatus.draft:
        backgroundColor = AppColors.gray400;
        text = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
