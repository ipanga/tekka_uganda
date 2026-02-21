import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../application/profile_provider.dart';

/// Saved items / Favorites screen
class SavedItemsScreen extends ConsumerStatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  ConsumerState<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends ConsumerState<SavedItemsScreen> {
  /// IDs removed optimistically — filtered out of the displayed list instantly
  final _removedIds = <String>{};

  void _onItemRemoved(String listingId, WidgetRef ref) async {
    // Optimistic: remove from UI immediately
    setState(() => _removedIds.add(listingId));

    try {
      await ref
          .read(listingActionsProvider(listingId).notifier)
          .toggleFavorite();

      // Sync providers in background
      ref.invalidate(savedListingsProvider);
      ref.invalidate(myFavoritesProvider);
      ref.invalidate(isFavoritedProvider(listingId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from saved items'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {
      // Rollback on failure
      if (mounted) {
        setState(() => _removedIds.remove(listingId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to remove item')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  _removedIds.clear();
                  ref.invalidate(savedListingsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (favorites) {
          // Filter out optimistically removed items
          final visible = favorites
              .where((l) => !_removedIds.contains(l.id))
              .toList();

          // Clear removedIds once provider data reflects removals
          if (_removedIds.isNotEmpty &&
              visible.length == favorites.length - _removedIds.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _removedIds.clear());
            });
          }

          if (visible.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              _removedIds.clear();
              ref.invalidate(savedListingsProvider);
              ref.invalidate(myFavoritesProvider);
            },
            child: GridView.builder(
              padding: AppSpacing.screenPadding,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: AppSpacing.listingCardAspectRatio,
                crossAxisSpacing: AppSpacing.space3,
                mainAxisSpacing: AppSpacing.space3,
              ),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                return _FavoriteCard(
                  listing: visible[index],
                  onRemove: () => _onItemRemoved(visible[index].id, ref),
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

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.listing, required this.onRemove});

  final Listing listing;
  final VoidCallback onRemove;

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
                      onTap: () => _confirmRemove(context),
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

  void _confirmRemove(BuildContext context) async {
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
      onRemove();
    }
  }
}
