import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../report/application/report_provider.dart';
import '../../../report/presentation/widgets/report_user_sheet.dart';
import '../../../reviews/application/review_provider.dart';
import '../../../reviews/domain/entities/review.dart';
import '../../application/privacy_provider.dart';
import '../../domain/entities/privacy_preferences.dart';

/// Public user profile screen for viewing other users
class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userAsync = ref.watch(publicUserProvider(userId));
    final listingsAsync = ref.watch(userListingsProvider(userId));
    final ratingAsync = ref.watch(userRatingProvider(userId));
    final reviewsAsync = ref.watch(userReviewsProvider(userId));
    final canViewAsync = ref.watch(canViewProfileProvider(userId));
    final privacyAsync = ref.watch(userPrivacyPreferencesProvider(userId));

    // If viewing own profile, redirect to profile screen
    if (currentUser?.uid == userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.profile);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text('User not found', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.space4),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // Check if user can view this profile
          final canView = canViewAsync.valueOrNull ?? true;
          final privacy =
              privacyAsync.valueOrNull ?? const PrivacyPreferences();

          if (!canView) {
            return _PrivateProfileView(user: user, userId: userId);
          }

          return CustomScrollView(
            slivers: [
              // App bar with user name
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  _ProfileActionsMenu(
                    userId: userId,
                    userName: user.displayName ?? 'User',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: AppColors.white,
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: AppColors.primaryContainer,
                              backgroundImage: user.photoUrl != null
                                  ? CachedNetworkImageProvider(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? Text(
                                      user.displayName?.isNotEmpty == true
                                          ? user.displayName![0].toUpperCase()
                                          : '?',
                                      style: AppTypography.displaySmall
                                          .copyWith(color: AppColors.primary),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          Text(
                            user.displayName ?? 'User',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          if (user.location != null &&
                              privacy.showLocation) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppColors.white.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.location!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Stats row
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (privacy.showListingsCount) ...[
                        listingsAsync.when(
                          data: (listings) {
                            final activeCount = listings
                                .where((l) => l.status == ListingStatus.active)
                                .length;
                            return _StatItem(
                              value: activeCount.toString(),
                              label: 'Listings',
                            );
                          },
                          loading: () =>
                              const _StatItem(value: '-', label: 'Listings'),
                          error: (_, _) =>
                              const _StatItem(value: '-', label: 'Listings'),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.outline,
                        ),
                        listingsAsync.when(
                          data: (listings) {
                            final soldCount = listings
                                .where((l) => l.status == ListingStatus.sold)
                                .length;
                            return _StatItem(
                              value: soldCount.toString(),
                              label: 'Sold',
                            );
                          },
                          loading: () =>
                              const _StatItem(value: '-', label: 'Sold'),
                          error: (_, _) =>
                              const _StatItem(value: '-', label: 'Sold'),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.outline,
                        ),
                      ],
                      ratingAsync.when(
                        data: (rating) => _StatItem(
                          value: rating.totalReviews > 0
                              ? rating.averageRating.toStringAsFixed(1)
                              : '-',
                          label: '${rating.totalReviews} Reviews',
                          icon: rating.totalReviews > 0 ? Icons.star : null,
                          iconColor: AppColors.warning,
                        ),
                        loading: () =>
                            const _StatItem(value: '-', label: 'Reviews'),
                        error: (_, _) =>
                            const _StatItem(value: '-', label: 'Reviews'),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space4),
              ),

              // Action buttons (Message, Contact, Review)
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: AppSpacing.screenPadding,
                  child: _ActionButtons(
                    userId: userId,
                    user: user,
                    privacy: privacy,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space4),
              ),

              // Member since
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: AppSpacing.screenPadding,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        'Member since ${_formatMemberSince(user.createdAt)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space4),
              ),

              // Reviews section
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: AppSpacing.screenPadding,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reviews', style: AppTypography.titleMedium),
                            TextButton(
                              onPressed: () {
                                context.push(
                                  AppRoutes.reviews.replaceFirst(
                                    ':userId',
                                    userId,
                                  ),
                                  extra: user.displayName ?? 'User',
                                );
                              },
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ),
                      reviewsAsync.when(
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return Padding(
                              padding: AppSpacing.screenPadding,
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.rate_review_outlined,
                                      size: 40,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: AppSpacing.space2),
                                    Text(
                                      'No reviews yet',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Show first 3 reviews
                          final displayReviews = reviews.take(3).toList();
                          return Column(
                            children: displayReviews.map((review) {
                              return _ReviewPreviewCard(review: review);
                            }).toList(),
                          );
                        },
                        loading: () => const Padding(
                          padding: AppSpacing.screenPadding,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => const Padding(
                          padding: AppSpacing.screenPadding,
                          child: Text('Failed to load reviews'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space4),
              ),

              // Listings section
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Text('Listings', style: AppTypography.titleMedium),
                  ),
                ),
              ),

              // Listings grid
              listingsAsync.when(
                data: (listings) {
                  final activeListings = listings
                      .where((l) => l.status == ListingStatus.active)
                      .toList();

                  if (activeListings.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        color: AppColors.surface,
                        padding: AppSpacing.screenPadding,
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.space2),
                              Text(
                                'No active listings',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: AppSpacing.screenPadding,
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.space3,
                        crossAxisSpacing: AppSpacing.space3,
                        childAspectRatio: AppSpacing.listingCardAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final listing = activeListings[index];
                        return _ListingCard(
                          listing: listing,
                          onTap: () {
                            context.push(
                              AppRoutes.listingDetail.replaceFirst(
                                ':id',
                                listing.id,
                              ),
                            );
                          },
                        );
                      }, childCount: activeListings.length),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const SliverToBoxAdapter(
                  child: Center(child: Text('Failed to load listings')),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space10),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatMemberSince(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}

class _ReviewPreviewCard extends StatelessWidget {
  final Review review;

  const _ReviewPreviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: review.reviewerPhotoUrl != null
                    ? CachedNetworkImageProvider(review.reviewerPhotoUrl!)
                    : null,
                child: review.reviewerPhotoUrl == null
                    ? Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : '?',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName, style: AppTypography.labelMedium),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: AppColors.warning,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              review.comment!,
              style: AppTypography.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    } else {
      return '${(diff.inDays / 30).floor()}mo ago';
    }
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: listing.imageUrls.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            listing.imageUrls.first,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: listing.imageUrls.isEmpty
                    ? const Center(
                        child: Icon(Icons.image, color: AppColors.gray400),
                      )
                    : null,
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      listing.formattedPrice,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionsMenu extends ConsumerWidget {
  final String userId;
  final String userName;

  const _ProfileActionsMenu({required this.userId, required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlockedAsync = ref.watch(isBlockedProvider(userId));

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.white),
      onSelected: (value) => _handleAction(context, ref, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 20),
              SizedBox(width: 12),
              Text('Report user'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: isBlockedAsync.when(
            data: (isBlocked) => Row(
              children: [
                Icon(
                  isBlocked ? Icons.person_add_outlined : Icons.block_outlined,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(isBlocked ? 'Unblock user' : 'Block user'),
              ],
            ),
            loading: () => const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading...'),
              ],
            ),
            error: (_, __) => const Row(
              children: [
                Icon(Icons.block_outlined, size: 20),
                SizedBox(width: 12),
                Text('Block user'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'report':
        _showReportSheet(context);
        break;
      case 'block':
        _toggleBlock(context, ref);
        break;
    }
  }

  void _showReportSheet(BuildContext context) async {
    final result = await showReportUserSheet(
      context,
      reportedUserId: userId,
      reportedUserName: userName,
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report submitted successfully. Thank you for keeping Tekka safe.',
          ),
        ),
      );
    }
  }

  void _toggleBlock(BuildContext context, WidgetRef ref) async {
    final isBlocked = await ref.read(isBlockedProvider(userId).future);
    final notifier = ref.read(reportActionsProvider.notifier);

    if (isBlocked) {
      // Unblock
      await notifier.unblockUser(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$userName has been unblocked')));
      }
    } else {
      // Show confirmation dialog before blocking
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Block $userName?'),
          content: const Text(
            'They won\'t be able to contact you or see your listings. You can unblock them later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Block'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await notifier.blockUser(userId);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$userName has been blocked')));
        }
      }
    }

    // Refresh the blocked status
    ref.invalidate(isBlockedProvider(userId));
  }
}

/// Widget shown when a user's profile is private
/// Action buttons for messaging, contact, and review
class _ActionButtons extends ConsumerStatefulWidget {
  final String userId;
  final dynamic user;
  final PrivacyPreferences privacy;

  const _ActionButtons({
    required this.userId,
    required this.user,
    required this.privacy,
  });

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _showingPhoneNumber = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isLoggedIn = currentUser != null;
    final existingReviewAsync = isLoggedIn
        ? ref.watch(existingReviewProvider(widget.userId))
        : null;

    final hasExistingReview = existingReviewAsync?.valueOrNull != null;

    return Row(
      children: [
        // Message button
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _handleMessage(context),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Message'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),

        // Show Contact button (only if seller allows it)
        if (widget.user.showPhoneNumber == true) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showingPhoneNumber = !_showingPhoneNumber;
                });
              },
              icon: const Icon(Icons.phone_outlined, size: 18),
              label: Text(
                _showingPhoneNumber
                    ? widget.user.phoneNumber ?? 'N/A'
                    : 'Contact',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ],

        // Review button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoggedIn
                ? () => _handleReview(context, existingReviewAsync?.valueOrNull)
                : () => _showLoginRequired(context),
            icon: Icon(
              hasExistingReview
                  ? Icons.edit_outlined
                  : Icons.rate_review_outlined,
              size: 18,
            ),
            label: Text(hasExistingReview ? 'Edit Review' : 'Review'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tap on a listing below to start a chat with this seller',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleReview(
    BuildContext context,
    Review? existingReview,
  ) async {
    final result = await context.push<bool>(
      AppRoutes.createReview,
      extra: {
        'revieweeId': widget.userId,
        'revieweeName': widget.user.displayName ?? 'User',
        if (existingReview != null) 'existingReview': existingReview,
      },
    );

    if (result == true) {
      // Refresh reviews, rating, and existing review state
      ref.invalidate(userReviewsProvider(widget.userId));
      ref.invalidate(userRatingProvider(widget.userId));
      ref.invalidate(existingReviewProvider(widget.userId));
    }
  }

  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please sign in to continue'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () {
            context.push(AppRoutes.phoneInput);
          },
        ),
      ),
    );
  }
}

class _PrivateProfileView extends StatelessWidget {
  final dynamic user;
  final String userId;

  const _PrivateProfileView({required this.user, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: AppColors.white,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      user.displayName ?? 'User',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.cardRadius,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        Text(
                          'Private Profile',
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          'This user has set their profile to private. You cannot view their listings or details.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
