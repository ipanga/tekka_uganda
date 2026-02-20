import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/theme.dart';
import '../../features/listing/domain/entities/listing.dart';
import '../../features/listing/application/listing_provider.dart';
import '../../features/auth/application/auth_provider.dart';

/// Listing card widget for displaying items in grid
class ListingCard extends ConsumerStatefulWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final Function(bool isSaved)? onSaveChanged;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onSaveChanged,
  });

  @override
  ConsumerState<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<ListingCard> {
  late bool _isSaved;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.listing.isSaved;
  }

  @override
  void didUpdateWidget(ListingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listing.isSaved != widget.listing.isSaved) {
      _isSaved = widget.listing.isSaved;
    }
  }

  Future<void> _handleSaveToggle() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      // User not logged in - could show login prompt
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save items')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(listingApiRepositoryProvider);
      if (_isSaved) {
        await repository.unsave(widget.listing.id);
        if (mounted) setState(() => _isSaved = false);
        widget.onSaveChanged?.call(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await repository.save(widget.listing.id);
        if (mounted) setState(() => _isSaved = true);
        widget.onSaveChanged?.call(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
      // Invalidate saved listings cache
      ref.invalidate(savedListingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final imageUrl = listing.imageUrls.isNotEmpty
        ? listing.imageUrls.first
        : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _ImagePlaceholder(),
                      errorWidget: (context, url, error) => _ImagePlaceholder(),
                    )
                  else
                    _ImagePlaceholder(),

                  // Save button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _handleSaveToggle,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isSaved
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: _isSaved
                                    ? AppColors.primary
                                    : AppColors.gray500,
                              ),
                      ),
                    ),
                  ),

                  // Status badge (only for non-active)
                  if (listing.status != ListingStatus.active)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _StatusBadge(status: listing.status),
                    ),

                  // Featured badge
                  if (listing.isFeatured)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXs,
                          ),
                        ),
                        child: Text(
                          'Featured',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(listing.formattedPrice, style: AppTypography.price),
                  if (listing.displayLocation != null) ...[
                    const SizedBox(height: 4),
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
                            listing.displayLocation!,
                            style: AppTypography.metadata,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray100,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ListingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case ListingStatus.pending:
        backgroundColor = AppColors.warningContainer;
        textColor = AppColors.onWarningContainer;
        label = 'Pending';
        break;
      case ListingStatus.sold:
        backgroundColor = AppColors.gray200;
        textColor = AppColors.gray500;
        label = 'Sold';
        break;
      case ListingStatus.rejected:
        backgroundColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        label = 'Rejected';
        break;
      case ListingStatus.archived:
        backgroundColor = AppColors.gray200;
        textColor = AppColors.gray500;
        label = 'Archived';
        break;
      case ListingStatus.draft:
        backgroundColor = AppColors.gray200;
        textColor = AppColors.gray500;
        label = 'Draft';
        break;
      case ListingStatus.active:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
