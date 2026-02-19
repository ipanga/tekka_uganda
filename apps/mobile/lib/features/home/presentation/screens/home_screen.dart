import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/tekka_logo.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/listing_card.dart';
import '../../../listing/application/listing_provider.dart';
import '../../../listing/application/category_provider.dart';
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
  final _scrollController = ScrollController();
  bool _hasSearchText = false;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    // Initialize from widget parameters
    _selectedCategoryId = widget.initialCategoryId;
    _searchQuery = widget.initialSearch;
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
      _hasSearchText = widget.initialSearch!.isNotEmpty;
    }
    _searchController.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
    // Load categories on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadData();
    });
  }

  void _onSearchTextChanged() {
    final hasText = _searchController.text.isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() => _hasSearchText = hasText);
    }
  }

  void _onScroll() {
    // Scroll-to-top visibility
    final showTop = _scrollController.offset > 600;
    if (showTop != _showScrollToTop) {
      setState(() => _showScrollToTop = showTop);
    }

    // Infinite scroll: load more when near bottom
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (maxScroll - currentScroll < 200) {
      final filter = ListingsFilter(
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
        limit: 24,
      );
      ref.read(paginatedListingsProvider(filter).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
    final paginatedState = ref.watch(paginatedListingsProvider(filter));

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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(paginatedListingsProvider(filter).notifier)
                  .refresh();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Combined header: collapsible logo bar + pinned search bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeHeaderDelegate(
                    topPadding: MediaQuery.of(context).padding.top,
                    searchController: _searchController,
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value.isEmpty ? null : value;
                      });
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = null;
                      });
                    },
                    hasText: _hasSearchText,
                  ),
                ),

                // Categories + subcategories + header
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.space5),

                      // Main Categories from database
                      Padding(
                        padding: AppSpacing.screenHorizontal,
                        child: Text(
                          'Categories',
                          style: AppTypography.titleSmall,
                        ),
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
                            if (selectedMain == null) {
                              return const SizedBox.shrink();
                            }
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
                                              .where(
                                                (c) =>
                                                    c.id == _selectedCategoryId,
                                              )
                                              .firstOrNull
                                              ?.name ??
                                          allSubcategories
                                              .where(
                                                (c) =>
                                                    c.id == _selectedCategoryId,
                                              )
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
                    ],
                  ),
                ),

                // Listing grid as SliverGrid for efficient lazy rendering
                if (paginatedState.isInitialLoading)
                  SliverPadding(
                    padding: AppSpacing.screenHorizontal,
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: AppSpacing.listingCardAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _LoadingCard(),
                        childCount: 4,
                      ),
                    ),
                  )
                else if (paginatedState.error != null &&
                    paginatedState.listings.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.screenHorizontal,
                      child: _buildErrorState(paginatedState.error!, filter),
                    ),
                  )
                else if (paginatedState.listings.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.screenHorizontal,
                      child: _buildEmptyState(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: AppSpacing.screenHorizontal,
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: AppSpacing.listingCardAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final listing = paginatedState.listings[index];
                        return ListingCard(
                          listing: listing,
                          onTap: () => context.push(
                            AppRoutes.listingDetail.replaceFirst(
                              ':id',
                              listing.id,
                            ),
                          ),
                        );
                      }, childCount: paginatedState.listings.length),
                    ),
                  ),

                // Bottom loading indicator / end-of-list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: paginatedState.isLoadingMore
                          ? const SizedBox(
                              height: 32,
                              width: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : !paginatedState.hasMore &&
                                paginatedState.listings.isNotEmpty
                          ? Text(
                              'You\'ve seen all listings',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Bottom spacing for tab bar
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // Scroll-to-top FAB
          Positioned(
            bottom: 96,
            right: 16,
            child: AnimatedOpacity(
              opacity: _showScrollToTop ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showScrollToTop,
                child: FloatingActionButton.small(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.onSurface,
                  elevation: 3,
                  child: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ListingsFilter filter) {
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
              onPressed: () => ref
                  .read(paginatedListingsProvider(filter).notifier)
                  .refresh(),
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
}

/// Combined header delegate: collapsible logo bar + always-pinned search bar.
/// The logo + notification bar only reappears when the user scrolls fully
/// back to the top — not on any upward scroll gesture.
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final TextEditingController searchController;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool hasText;

  const _HomeHeaderDelegate({
    required this.topPadding,
    required this.searchController,
    required this.onSubmitted,
    required this.onClear,
    required this.hasText,
  });

  static const double _logoBarHeight = kToolbarHeight;
  static const double _searchSectionHeight = AppSpacing.searchBarHeight + 16;

  @override
  double get maxExtent => topPadding + _logoBarHeight + _searchSectionHeight;

  @override
  double get minExtent => topPadding + _searchSectionHeight;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return hasText != oldDelegate.hasText ||
        topPadding != oldDelegate.topPadding;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseExtent = maxExtent - minExtent;
    final collapseProgress = (shrinkOffset / collapseExtent).clamp(0.0, 1.0);
    final currentLogoHeight = _logoBarHeight * (1 - collapseProgress);
    final isScrolled = shrinkOffset > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Status bar safe area
          SizedBox(height: topPadding),
          // Collapsible logo + notification bar
          ClipRect(
            child: SizedBox(
              height: currentLogoHeight,
              child: Opacity(
                opacity: (1 - collapseProgress * 1.5).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const TekkaLogo(height: 28),
                      const Spacer(),
                      const _NotificationButton(),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Pinned search bar — always visible below status bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: AppSpacing.searchBarHeight,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.searchBarRadius,
                border: Border.all(color: AppColors.outline, width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search fashion items...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.gray400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.search,
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  if (hasText)
                    GestureDetector(
                      onTap: onClear,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 14,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 14),
                ],
              ),
            ),
          ),
        ],
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
