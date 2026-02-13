import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../application/profile_provider.dart';

/// Saved items / Favorites screen
class SavedItemsScreen extends ConsumerWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final favoritesAsync = ref.watch(myFavoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Items'),
        automaticallyImplyLeading: false,
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Failed to load saved items',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(myFavoritesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myFavoritesProvider);
            },
            child: GridView.builder(
              padding: AppSpacing.screenPadding,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: AppSpacing.space3,
                mainAxisSpacing: AppSpacing.space3,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                return _FavoriteCard(
                  listing: favorites[index],
                  userId: user?.uid ?? '',
                  onRemoved: () {
                    ref.invalidate(myFavoritesProvider);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text('No saved items yet', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Items you save will appear here',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Browse Listings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends ConsumerWidget {
  const _FavoriteCard({
    required this.listing,
    required this.userId,
    required this.onRemoved,
  });

  final Listing listing;
  final String userId;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // Image with favorite button
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
                  // Status badge if not active
                  if (listing.status != ListingStatus.active)
                    Positioned(
                      top: AppSpacing.space2,
                      left: AppSpacing.space2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: listing.status == ListingStatus.sold
                              ? AppColors.success
                              : AppColors.gray400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          listing.status == ListingStatus.sold
                              ? 'Sold'
                              : 'Unavailable',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Remove favorite button
                  Positioned(
                    top: AppSpacing.space2,
                    right: AppSpacing.space2,
                    child: GestureDetector(
                      onTap: () => _removeFavorite(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppColors.error,
                          size: 18,
                        ),
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
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.displayLocation ?? 'Unknown',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFavorite(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Saved'),
        content: const Text(
          'Are you sure you want to remove this item from your saved items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(listingActionsProvider(listing.id).notifier)
          .toggleFavorite();
      onRemoved();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from saved items'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}
