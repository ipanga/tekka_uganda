import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../reviews/application/review_provider.dart';
import '../../../reviews/domain/entities/review.dart';

/// Screen showing user's purchase history
class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase History')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    final purchasesAsync = ref.watch(purchaseHistoryProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purchase History'),
      ),
      body: purchasesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load purchases: $e'),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.invalidate(purchaseHistoryProvider(user.uid)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (purchases) {
          if (purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'No purchases yet',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Items you buy will appear here',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.browse),
                    child: const Text('Browse Items'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(purchaseHistoryProvider(user.uid));
            },
            child: ListView.builder(
              padding: AppSpacing.screenPadding,
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                return _PurchaseCard(
                  listing: purchase,
                  currentUserId: user.uid,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseCard extends ConsumerWidget {
  final Listing listing;
  final String currentUserId;

  const _PurchaseCard({
    required this.listing,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user can review seller
    final canReviewAsync = ref.watch(canReviewProvider(CanReviewParams(
      revieweeId: listing.sellerId,
      listingId: listing.id,
    )));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          // Main content - tappable
          InkWell(
            onTap: () {
              context.push(AppRoutes.listingDetail.replaceFirst(':id', listing.id));
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                      image: listing.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(listing.imageUrls.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: listing.imageUrls.isEmpty
                        ? const Icon(Icons.image, color: AppColors.gray400)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.space3),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: AppTypography.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing.formattedPrice,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'From ${listing.sellerName}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (listing.soldAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Purchased ${_formatDate(listing.soldAt!)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Review action
          canReviewAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (canReview) {
              if (!canReview) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space2,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            'Leave a review for the seller',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push(
                              AppRoutes.createReview,
                              extra: {
                                'revieweeId': listing.sellerId,
                                'revieweeName': listing.sellerName,
                                'listingId': listing.id,
                                'listingTitle': listing.title,
                                'reviewType': ReviewType.seller,
                              },
                            );
                          },
                          child: const Text('Review'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
