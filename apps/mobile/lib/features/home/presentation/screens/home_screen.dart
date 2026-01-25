import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/listing_card.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../notifications/application/notification_provider.dart';

/// Home screen with featured and recent listings
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ListingCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final filter = ListingsFilter(
      category: _selectedCategory,
      limit: 20,
    );
    final listingsAsync = ref.watch(listingsFeedProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tekka',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [
          _NotificationButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(listingsFeedProvider(filter));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.browse),
                  child: Container(
                    height: AppSpacing.searchBarHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.searchBarRadius,
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Search fashion items...',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space5),

              // Quick Access - Traditional Wear
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: Text('Quick Access', style: AppTypography.titleSmall),
              ),

              const SizedBox(height: AppSpacing.space3),

              Padding(
                padding: AppSpacing.screenHorizontal,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = ListingCategory.traditionalWear);
                  },
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppSpacing.cardRadius,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Traditional Wear',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space5),

              // Categories
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: Text('Categories', style: AppTypography.titleSmall),
              ),

              const SizedBox(height: AppSpacing.space3),

              // Category chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.screenHorizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      isSelected: _selectedCategory == null,
                      onSelected: () => setState(() => _selectedCategory = null),
                    ),
                    ...ListingCategory.values.map((category) {
                      return _CategoryChip(
                        label: category.displayName,
                        isSelected: _selectedCategory == category,
                        onSelected: () => setState(() => _selectedCategory = category),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space5),

              // Recent Listings
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: Text(
                  _selectedCategory != null
                      ? _selectedCategory!.displayName
                      : 'Recent Listings',
                  style: AppTypography.titleSmall,
                ),
              ),

              const SizedBox(height: AppSpacing.space3),

              // Listing grid
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: listingsAsync.when(
                  loading: () => _buildLoadingGrid(),
                  error: (error, _) => _buildErrorState(error, filter),
                  data: (listings) {
                    if (listings.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildListingGrid(listings);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => _LoadingCard(),
    );
  }

  Widget _buildErrorState(Object error, ListingsFilter filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Failed to load listings',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: () => ref.invalidate(listingsFeedProvider(filter)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              _selectedCategory != null
                  ? 'No ${_selectedCategory!.displayName.toLowerCase()} found'
                  : 'No listings yet',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Be the first to list something!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.createListing),
              child: const Text('Create Listing'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingGrid(List<Listing> listings) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return ListingCard(
          listing: listing,
          onTap: () => context.push(
            AppRoutes.listingDetail.replaceFirst(':id', listing.id),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primaryContainer,
        checkmarkColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.outline,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends ConsumerWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream directly to avoid rebuild issues during initialization
    final unreadAsync = ref.watch(unreadNotificationsStreamProvider);
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 9 ? '9+' : unreadCount.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => context.push(AppRoutes.notifications),
    );
  }
}
