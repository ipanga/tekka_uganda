import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/listing_card.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/application/category_provider.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/domain/entities/category.dart' as cat;
import '../../../notifications/application/notification_provider.dart';

/// Home screen with featured and recent listings
class HomeScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String? initialSearch;

  const HomeScreen({super.key, this.initialCategoryId, this.initialSearch});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategoryId;
  String? _searchQuery;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize from widget parameters
    _selectedCategoryId = widget.initialCategoryId;
    _searchQuery = widget.initialSearch;
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    // Load categories on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final filter = ListingsFilter(
      categoryId: _selectedCategoryId,
      searchQuery: _searchQuery,
      limit: 24,
    );
    final listingsAsync = ref.watch(listingsFeedProvider(filter));

    // Check if any filters are active
    final hasFilters =
        _selectedCategoryId != null ||
        (_searchQuery != null && _searchQuery!.isNotEmpty);

    // Get main categories (level 1) from state
    final mainCategories = categoryState.mainCategories;

    // Get all subcategories for name lookups
    final allSubcategories = <cat.Category>[];
    for (final mainCat in mainCategories) {
      allSubcategories.addAll(mainCat.activeChildren);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tekka.ug',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [_NotificationButton()],
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
                      Icon(Icons.search, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search fashion items...',
                            hintStyle: AppTypography.bodyLarge.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: AppTypography.bodyLarge,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            setState(() {
                              _searchQuery = value.isEmpty ? null : value;
                            });
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = null;
                            });
                          },
                          child: Icon(
                            Icons.clear,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space5),

              // Main Categories from database
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: Text('Categories', style: AppTypography.titleSmall),
              ),

              const SizedBox(height: AppSpacing.space3),

              // Main category chips (level 1) - horizontal scroll
              if (categoryState.isLoading)
                const SizedBox(
                  height: 44,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (mainCategories.isEmpty)
                const SizedBox(height: 44)
              else
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: AppSpacing.screenHorizontal,
                    itemCount: mainCategories.length,
                    itemBuilder: (context, index) {
                      final category = mainCategories[index];
                      return _MainCategoryCard(
                        name: category.name,
                        isSelected: _selectedCategoryId == category.id,
                        onTap: () {
                          setState(() {
                            _selectedCategoryId =
                                _selectedCategoryId == category.id
                                ? null
                                : category.id;
                          });
                        },
                      );
                    },
                  ),
                ),

              // Subcategories - shown when a main category is selected
              if (_selectedCategoryId != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Builder(
                  builder: (context) {
                    final selectedMain = mainCategories
                        .where((c) => c.id == _selectedCategoryId)
                        .firstOrNull;
                    if (selectedMain == null) return const SizedBox.shrink();
                    final subs = selectedMain.activeChildren;
                    if (subs.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: AppSpacing.screenHorizontal,
                        itemCount: subs.length,
                        itemBuilder: (context, index) {
                          final subcategory = subs[index];
                          return _SubcategoryChip(
                            label: subcategory.name,
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = subcategory.id;
                              });
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.space5),

              // Listings header
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _searchQuery != null && _searchQuery!.isNotEmpty
                            ? 'Results for "$_searchQuery"'
                            : _selectedCategoryId != null
                            ? mainCategories
                                      .where((c) => c.id == _selectedCategoryId)
                                      .firstOrNull
                                      ?.name ??
                                  allSubcategories
                                      .where((c) => c.id == _selectedCategoryId)
                                      .firstOrNull
                                      ?.name ??
                                  'Recent Listings'
                            : 'Recent Listings',
                        style: AppTypography.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasFilters)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _selectedCategoryId = null;
                            _searchQuery = null;
                          });
                        },
                        child: Text(
                          'Clear filters',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
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
            Text('Failed to load listings', style: AppTypography.bodyLarge),
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
            Text('No listings yet', style: AppTypography.titleMedium),
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

class _MainCategoryCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _MainCategoryCard({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Center(
            child: Text(
              name,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubcategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SubcategoryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
