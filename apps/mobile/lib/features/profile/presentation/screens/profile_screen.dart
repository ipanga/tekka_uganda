import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../application/profile_provider.dart';

/// User profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final listingsAsync = ref.watch(myListingsPreviewProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileStatsProvider);
          ref.invalidate(myListingsPreviewProvider);
        },
        child: ListView(
          children: [
            // Profile header
            Container(
              color: AppColors.surface,
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  // Avatar with edit button
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: AppSpacing.avatarLarge / 2,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: user.photoUrl != null
                            ? CachedNetworkImageProvider(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => context.push(AppRoutes.editProfile),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Name
                  Text(
                    user.displayName ?? 'User',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.space1),

                  // Location
                  if (user.location != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: AppSpacing.iconSmall,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          user.location!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.space2),

                  // Member since
                  Text(
                    'Member since ${_formatMemberSince(user.createdAt)}',
                    style: AppTypography.bodySmall,
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Stats row
                  statsAsync.when(
                    loading: () => const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (stats) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          count: stats.totalListings.toString(),
                          label: 'Listings',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.outline,
                        ),
                        _StatItem(
                          count: stats.soldCount.toString(),
                          label: 'Sold',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.outline,
                        ),
                        _StatItem(
                          count: stats.rating > 0
                              ? stats.rating.toStringAsFixed(1)
                              : '-',
                          label: 'Rating',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // My Listings section
            Container(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: AppSpacing.screenPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('My Listings', style: AppTypography.titleMedium),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.myListings),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ),
                  listingsAsync.when(
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => const SizedBox(
                      height: 120,
                      child: Center(child: Text('Failed to load listings')),
                    ),
                    data: (listings) {
                      if (listings.isEmpty) {
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppColors.onSurfaceVariant,
                                  size: 32,
                                ),
                                const SizedBox(height: AppSpacing.space2),
                                Text(
                                  'No listings yet',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.space2),
                                TextButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.createListing),
                                  child: const Text(
                                    'Create your first listing',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: AppSpacing.screenHorizontal,
                          itemCount: listings.length,
                          itemBuilder: (context, index) {
                            final listing = listings[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < listings.length - 1
                                    ? AppSpacing.space3
                                    : 0,
                              ),
                              child: _ListingThumbnail(
                                listing: listing,
                                onTap: () {
                                  context.push(
                                    AppRoutes.listingDetail.replaceFirst(
                                      ':id',
                                      listing.id,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Menu items
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.analytics_outlined,
                    title: 'Seller Dashboard',
                    onTap: () => context.push(AppRoutes.sellerAnalytics),
                  ),
                  _MenuItem(
                    icon: Icons.saved_search,
                    title: 'Saved Searches',
                    onTap: () => context.push(AppRoutes.savedSearches),
                  ),
                  _MenuItem(
                    icon: Icons.trending_down,
                    title: 'Price Alerts',
                    onTap: () => context.push(AppRoutes.priceAlerts),
                  ),
                  _MenuItem(
                    icon: Icons.history,
                    title: 'Purchase History',
                    onTap: () => context.push(AppRoutes.purchaseHistory),
                  ),
                  _MenuItem(
                    icon: Icons.star_border,
                    title: 'Reviews',
                    onTap: () {
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        context.push(
                          AppRoutes.reviews.replaceFirst(':userId', user.uid),
                          extra: user.displayName ?? 'User',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Support section
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => context.push(AppRoutes.help),
                  ),
                  _MenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Safety Tips',
                    onTap: () => context.push(AppRoutes.safetyTips),
                  ),
                  _MenuItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    isDestructive: true,
                    onTap: () => _showSignOutDialog(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.space10),
          ],
        ),
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

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label});

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}

class _ListingThumbnail extends StatelessWidget {
  const _ListingThumbnail({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: AppSpacing.cardRadius,
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
                      ? const Icon(Icons.image, color: AppColors.gray400)
                      : null,
                ),
                if (listing.status == ListingStatus.sold)
                  Positioned(
                    top: AppSpacing.space2,
                    left: AppSpacing.space2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Sold',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (listing.status == ListingStatus.pending)
                  Positioned(
                    top: AppSpacing.space2,
                    left: AppSpacing.space2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              listing.title,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              listing.formattedPrice,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: isDestructive ? AppColors.error : AppColors.onSurface,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
