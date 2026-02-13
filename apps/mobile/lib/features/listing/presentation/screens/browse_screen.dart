import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/listing_card.dart';
import '../../../search/application/saved_search_provider.dart';
import '../../application/listing_provider.dart';
import '../../application/category_provider.dart';
import '../../domain/entities/listing.dart';

/// Browse/Search screen with filters
class BrowseScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String? initialSearch;

  const BrowseScreen({super.key, this.initialCategoryId, this.initialSearch});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String? _selectedCategoryId;
  String? _selectedCityId;
  String? _selectedDivisionId;
  ItemCondition? _selectedCondition;
  int? _minPrice;
  int? _maxPrice;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    // Load categories & cities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  ListingsFilter get _currentFilter => ListingsFilter(
    categoryId: _selectedCategoryId,
    cityId: _selectedCityId,
    divisionId: _selectedDivisionId,
    condition: _selectedCondition,
    minPrice: _minPrice,
    maxPrice: _maxPrice,
    searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
    sortBy: _sortBy,
    sortOrder: _sortOrder,
    limit: 50,
  );

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategoryId = null;
      _selectedCityId = null;
      _selectedDivisionId = null;
      _selectedCondition = null;
      _minPrice = null;
      _maxPrice = null;
      _sortBy = 'createdAt';
      _sortOrder = 'desc';
    });
  }

  bool get _hasActiveFilters =>
      _selectedCategoryId != null ||
      _selectedCityId != null ||
      _selectedCondition != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final listingsAsync = ref.watch(listingsFeedProvider(_currentFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Browse'),
        actions: [
          if (_hasActiveFilters) ...[
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Save Search',
              onPressed: () => _saveSearch(context, ref),
            ),
            TextButton(onPressed: _clearFilters, child: const Text('Clear')),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: AppSpacing.screenPadding,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search fashion items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () => _showFilterSheet(categoryState),
                    ),
                  ],
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => setState(() {}),
              onChanged: (_) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) setState(() {});
                });
              },
            ),
          ),

          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screenHorizontal,
              children: [
                _FilterChip(
                  label: _getCategoryLabel(categoryState),
                  isActive: _selectedCategoryId != null,
                  onTap: () => _showCategoryPicker(categoryState),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _selectedCondition?.displayName ?? 'Condition',
                  isActive: _selectedCondition != null,
                  onTap: _showConditionPicker,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _getPriceLabel(),
                  isActive: _minPrice != null || _maxPrice != null,
                  onTap: _showPricePicker,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _getLocationLabel(categoryState),
                  isActive: _selectedCityId != null,
                  onTap: () => _showLocationPicker(categoryState),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _getSortLabel(),
                  isActive: _sortBy != 'createdAt' || _sortOrder != 'desc',
                  onTap: _showSortPicker,
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(listingsFeedProvider(_currentFilter));
              },
              child: listingsAsync.when(
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error),
                data: (listings) {
                  if (listings.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildResultsGrid(listings);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(CategoryState categoryState) {
    if (_selectedCategoryId == null) return 'Category';
    // Try main categories first
    for (final main in categoryState.mainCategories) {
      if (main.id == _selectedCategoryId) return main.name;
      for (final sub in main.activeChildren) {
        if (sub.id == _selectedCategoryId) return sub.name;
      }
    }
    return 'Category';
  }

  String _getLocationLabel(CategoryState categoryState) {
    if (_selectedCityId == null) return 'Location';
    final city = categoryState.activeCities
        .where((c) => c.id == _selectedCityId)
        .firstOrNull;
    if (city == null) return 'Location';
    if (_selectedDivisionId != null) {
      final division = city.activeDivisions
          .where((d) => d.id == _selectedDivisionId)
          .firstOrNull;
      if (division != null) return '${city.name}, ${division.name}';
    }
    return city.name;
  }

  String _getSortLabel() {
    if (_sortBy == 'price' && _sortOrder == 'asc') return 'Price: Low-High';
    if (_sortBy == 'price' && _sortOrder == 'desc') return 'Price: High-Low';
    if (_sortBy == 'viewCount' && _sortOrder == 'desc') return 'Most Viewed';
    return 'Newest';
  }

  String _getPriceLabel() {
    if (_minPrice != null && _maxPrice != null) {
      return '${_formatPrice(_minPrice!)} - ${_formatPrice(_maxPrice!)}';
    } else if (_minPrice != null) {
      return '${_formatPrice(_minPrice!)}+';
    } else if (_maxPrice != null) {
      return 'Under ${_formatPrice(_maxPrice!)}';
    }
    return 'Price';
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toString();
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: AppSpacing.screenPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _LoadingCard(),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text('Failed to load listings', style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: () =>
                  ref.invalidate(listingsFeedProvider(_currentFilter)),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.space4),
            Text('No results found', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space2),
            Text(
              _hasActiveFilters
                  ? 'Try adjusting your filters'
                  : 'Be the first to list something!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: AppSpacing.space4),
              OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsGrid(List<Listing> listings) {
    return GridView.builder(
      padding: AppSpacing.screenPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
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

  // ============================================
  // FILTER PICKERS
  // ============================================

  void _showFilterSheet(CategoryState categoryState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        categoryState: categoryState,
        selectedCategoryId: _selectedCategoryId,
        selectedCityId: _selectedCityId,
        selectedDivisionId: _selectedDivisionId,
        selectedCondition: _selectedCondition,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        onApply:
            (
              categoryId,
              cityId,
              divisionId,
              condition,
              minPrice,
              maxPrice,
              sortBy,
              sortOrder,
            ) {
              setState(() {
                _selectedCategoryId = categoryId;
                _selectedCityId = cityId;
                _selectedDivisionId = divisionId;
                _selectedCondition = condition;
                _minPrice = minPrice;
                _maxPrice = maxPrice;
                _sortBy = sortBy;
                _sortOrder = sortOrder;
              });
              Navigator.pop(context);
            },
      ),
    );
  }

  void _showCategoryPicker(CategoryState categoryState) {
    final mainCategories = categoryState.mainCategories;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? expandedMainId;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.3,
                maxChildSize: 0.8,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.gray200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Category',
                          style: AppTypography.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            ListTile(
                              title: const Text('All Categories'),
                              trailing: _selectedCategoryId == null
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _selectedCategoryId = null);
                                Navigator.pop(context);
                              },
                            ),
                            ...mainCategories.map((mainCat) {
                              final isExpanded = expandedMainId == mainCat.id;
                              final subs = mainCat.activeChildren;
                              final isSelected =
                                  _selectedCategoryId == mainCat.id;
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      mainCat.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.primary
                                            : null,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected)
                                          const Icon(
                                            Icons.check,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        if (subs.isNotEmpty)
                                          Icon(
                                            isExpanded
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      if (subs.isNotEmpty) {
                                        setSheetState(() {
                                          expandedMainId = isExpanded
                                              ? null
                                              : mainCat.id;
                                        });
                                      } else {
                                        setState(
                                          () =>
                                              _selectedCategoryId = mainCat.id,
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                  if (isExpanded && subs.isNotEmpty) ...[
                                    // Select entire main category
                                    ListTile(
                                      contentPadding: const EdgeInsets.only(
                                        left: 40,
                                        right: 16,
                                      ),
                                      title: Text('All ${mainCat.name}'),
                                      trailing:
                                          _selectedCategoryId == mainCat.id
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.primary,
                                              size: 20,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(
                                          () =>
                                              _selectedCategoryId = mainCat.id,
                                        );
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ...subs.map((sub) {
                                      final isSubSelected =
                                          _selectedCategoryId == sub.id;
                                      return ListTile(
                                        contentPadding: const EdgeInsets.only(
                                          left: 40,
                                          right: 16,
                                        ),
                                        title: Text(
                                          sub.name,
                                          style: TextStyle(
                                            color: isSubSelected
                                                ? AppColors.primary
                                                : null,
                                            fontWeight: isSubSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: isSubSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: AppColors.primary,
                                                size: 20,
                                              )
                                            : null,
                                        onTap: () {
                                          setState(
                                            () => _selectedCategoryId = sub.id,
                                          );
                                          Navigator.pop(context);
                                        },
                                      );
                                    }),
                                  ],
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showConditionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Any Condition'),
              trailing: _selectedCondition == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedCondition = null);
                Navigator.pop(context);
              },
            ),
            ...ItemCondition.values.map((cond) {
              return ListTile(
                title: Text(cond.displayName),
                trailing: _selectedCondition == cond
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedCondition = cond);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPricePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Any Price'),
              trailing: _minPrice == null && _maxPrice == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = null;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Under UGX 50K'),
              onTap: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = 50000;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('UGX 50K - 100K'),
              onTap: () {
                setState(() {
                  _minPrice = 50000;
                  _maxPrice = 100000;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('UGX 100K - 200K'),
              onTap: () {
                setState(() {
                  _minPrice = 100000;
                  _maxPrice = 200000;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Over UGX 200K'),
              onTap: () {
                setState(() {
                  _minPrice = 200000;
                  _maxPrice = null;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker(CategoryState categoryState) {
    final activeCities = categoryState.activeCities;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? tempCityId = _selectedCityId;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedCity = activeCities
                .where((c) => c.id == tempCityId)
                .firstOrNull;
            final activeDivisions = selectedCity?.activeDivisions ?? [];

            return SafeArea(
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.3,
                maxChildSize: 0.7,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.gray200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          tempCityId == null
                              ? 'Select City'
                              : 'Select Division',
                          style: AppTypography.titleLarge,
                        ),
                      ),
                      if (tempCityId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() => tempCityId = null);
                                },
                                child: Text(
                                  'Back to cities',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            if (tempCityId == null) ...[
                              // City selection
                              ListTile(
                                title: const Text('All Locations'),
                                trailing: _selectedCityId == null
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedCityId = null;
                                    _selectedDivisionId = null;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              ...activeCities.map((city) {
                                return ListTile(
                                  title: Text(city.name),
                                  trailing: city.activeDivisions.isNotEmpty
                                      ? const Icon(
                                          Icons.chevron_right,
                                          color: AppColors.onSurfaceVariant,
                                        )
                                      : (_selectedCityId == city.id
                                            ? const Icon(
                                                Icons.check,
                                                color: AppColors.primary,
                                              )
                                            : null),
                                  onTap: () {
                                    if (city.activeDivisions.isNotEmpty) {
                                      setSheetState(() => tempCityId = city.id);
                                    } else {
                                      setState(() {
                                        _selectedCityId = city.id;
                                        _selectedDivisionId = null;
                                      });
                                      Navigator.pop(context);
                                    }
                                  },
                                );
                              }),
                            ] else ...[
                              // Division selection
                              ListTile(
                                title: Text('All ${selectedCity?.name ?? ''}'),
                                trailing:
                                    _selectedCityId == tempCityId &&
                                        _selectedDivisionId == null
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedCityId = tempCityId;
                                    _selectedDivisionId = null;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              ...activeDivisions.map((division) {
                                final isSelected =
                                    _selectedCityId == tempCityId &&
                                    _selectedDivisionId == division.id;
                                return ListTile(
                                  title: Text(division.name),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCityId = tempCityId;
                                      _selectedDivisionId = division.id;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SortOption(
              title: 'Newest',
              isSelected: _sortBy == 'createdAt' && _sortOrder == 'desc',
              onTap: () {
                setState(() {
                  _sortBy = 'createdAt';
                  _sortOrder = 'desc';
                });
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Price: Low to High',
              isSelected: _sortBy == 'price' && _sortOrder == 'asc',
              onTap: () {
                setState(() {
                  _sortBy = 'price';
                  _sortOrder = 'asc';
                });
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Price: High to Low',
              isSelected: _sortBy == 'price' && _sortOrder == 'desc',
              onTap: () {
                setState(() {
                  _sortBy = 'price';
                  _sortOrder = 'desc';
                });
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Most Viewed',
              isSelected: _sortBy == 'viewCount' && _sortOrder == 'desc',
              onTap: () {
                setState(() {
                  _sortBy = 'viewCount';
                  _sortOrder = 'desc';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveSearch(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save This Search'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get notified when new items match:',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.space3),
            if (_searchController.text.isNotEmpty)
              _SearchDetailRow(
                icon: Icons.search,
                label: '"${_searchController.text}"',
              ),
            if (_selectedCategoryId != null)
              _SearchDetailRow(
                icon: Icons.category_outlined,
                label: _getCategoryLabel(ref.read(categoryProvider)),
              ),
            if (_minPrice != null || _maxPrice != null)
              _SearchDetailRow(
                icon: Icons.attach_money,
                label: _getPriceLabel(),
              ),
            if (_selectedCityId != null)
              _SearchDetailRow(
                icon: Icons.location_on_outlined,
                label: _getLocationLabel(ref.read(categoryProvider)),
              ),
            if (_selectedCondition != null)
              _SearchDetailRow(
                icon: Icons.star_outline,
                label: _selectedCondition!.displayName,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(savedSearchProvider.notifier)
                  .saveSearch(
                    query: _searchController.text,
                    categoryId: _selectedCategoryId,
                    categoryName: _getCategoryLabel(ref.read(categoryProvider)),
                    minPrice: _minPrice?.toDouble(),
                    maxPrice: _maxPrice?.toDouble(),
                    location: _getLocationLabel(ref.read(categoryProvider)),
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Search saved! You\'ll be notified of new matches.'
                          : 'Failed to save search',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                    action: success
                        ? SnackBarAction(
                            label: 'View',
                            textColor: AppColors.white,
                            onPressed: () =>
                                context.push(AppRoutes.savedSearches),
                          )
                        : null,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

class _SortOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _SearchDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SearchDetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isActive ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ],
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

// ============================================
// FULL FILTER SHEET
// ============================================

class _FilterSheet extends StatefulWidget {
  final CategoryState categoryState;
  final String? selectedCategoryId;
  final String? selectedCityId;
  final String? selectedDivisionId;
  final ItemCondition? selectedCondition;
  final int? minPrice;
  final int? maxPrice;
  final String sortBy;
  final String sortOrder;
  final void Function(
    String? categoryId,
    String? cityId,
    String? divisionId,
    ItemCondition? condition,
    int? minPrice,
    int? maxPrice,
    String sortBy,
    String sortOrder,
  )
  onApply;

  const _FilterSheet({
    required this.categoryState,
    this.selectedCategoryId,
    this.selectedCityId,
    this.selectedDivisionId,
    this.selectedCondition,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _categoryId;
  late String? _cityId;
  late String? _divisionId;
  late ItemCondition? _condition;
  late int? _minPrice;
  late int? _maxPrice;
  late String _sortBy;
  late String _sortOrder;

  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoryId = widget.selectedCategoryId;
    _cityId = widget.selectedCityId;
    _divisionId = widget.selectedDivisionId;
    _condition = widget.selectedCondition;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _sortBy = widget.sortBy;
    _sortOrder = widget.sortOrder;

    if (_minPrice != null) _minPriceController.text = _minPrice.toString();
    if (_maxPrice != null) _maxPriceController.text = _maxPrice.toString();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _categoryId = null;
      _cityId = null;
      _divisionId = null;
      _condition = null;
      _minPrice = null;
      _maxPrice = null;
      _sortBy = 'createdAt';
      _sortOrder = 'desc';
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainCategories = widget.categoryState.mainCategories;
    final activeCities = widget.categoryState.activeCities;
    final selectedCity = activeCities.where((c) => c.id == _cityId).firstOrNull;
    final activeDivisions = selectedCity?.activeDivisions ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: AppTypography.titleLarge),
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear All'),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space4),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Sort
                    Text('Sort By', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Newest'),
                          selected:
                              _sortBy == 'createdAt' && _sortOrder == 'desc',
                          onSelected: (_) => setState(() {
                            _sortBy = 'createdAt';
                            _sortOrder = 'desc';
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Price: Low-High'),
                          selected: _sortBy == 'price' && _sortOrder == 'asc',
                          onSelected: (_) => setState(() {
                            _sortBy = 'price';
                            _sortOrder = 'asc';
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Price: High-Low'),
                          selected: _sortBy == 'price' && _sortOrder == 'desc',
                          onSelected: (_) => setState(() {
                            _sortBy = 'price';
                            _sortOrder = 'desc';
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Most Viewed'),
                          selected:
                              _sortBy == 'viewCount' && _sortOrder == 'desc',
                          onSelected: (_) => setState(() {
                            _sortBy = 'viewCount';
                            _sortOrder = 'desc';
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Category
                    Text('Category', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _categoryId == null,
                          onSelected: (_) => setState(() => _categoryId = null),
                        ),
                        ...mainCategories.map((mainCat) {
                          return ChoiceChip(
                            label: Text(mainCat.name),
                            selected: _categoryId == mainCat.id,
                            onSelected: (_) =>
                                setState(() => _categoryId = mainCat.id),
                          );
                        }),
                      ],
                    ),

                    // Sub-categories (if main category selected)
                    if (_categoryId != null) ...[
                      Builder(
                        builder: (context) {
                          final mainCat = mainCategories
                              .where((c) => c.id == _categoryId)
                              .firstOrNull;
                          if (mainCat == null) return const SizedBox.shrink();
                          final subs = mainCat.activeChildren;
                          if (subs.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: subs.map((sub) {
                                return ChoiceChip(
                                  label: Text(sub.name),
                                  selected: _categoryId == sub.id,
                                  onSelected: (_) =>
                                      setState(() => _categoryId = sub.id),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: AppSpacing.space6),

                    // Condition
                    Text('Condition', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _condition == null,
                          onSelected: (_) => setState(() => _condition = null),
                        ),
                        ...ItemCondition.values.map((cond) {
                          return ChoiceChip(
                            label: Text(cond.displayName),
                            selected: _condition == cond,
                            onSelected: (_) =>
                                setState(() => _condition = cond),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Price Range
                    Text('Price Range (UGX)', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            decoration: const InputDecoration(
                              hintText: 'Min',
                              prefixText: 'UGX ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _minPrice = int.tryParse(value);
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('-'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            decoration: const InputDecoration(
                              hintText: 'Max',
                              prefixText: 'UGX ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _maxPrice = int.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // City
                    Text('City', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _cityId == null,
                          onSelected: (_) => setState(() {
                            _cityId = null;
                            _divisionId = null;
                          }),
                        ),
                        ...activeCities.map((city) {
                          return ChoiceChip(
                            label: Text(city.name),
                            selected: _cityId == city.id,
                            onSelected: (_) => setState(() {
                              _cityId = city.id;
                              _divisionId = null;
                            }),
                          );
                        }),
                      ],
                    ),

                    // Division (when city selected)
                    if (_cityId != null && activeDivisions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text('Division', style: AppTypography.titleSmall),
                      const SizedBox(height: AppSpacing.space2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _divisionId == null,
                            onSelected: (_) =>
                                setState(() => _divisionId = null),
                          ),
                          ...activeDivisions.map((div) {
                            return ChoiceChip(
                              label: Text(div.name),
                              selected: _divisionId == div.id,
                              onSelected: (_) =>
                                  setState(() => _divisionId = div.id),
                            );
                          }),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.space10),
                  ],
                ),
              ),

              // Apply button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          _categoryId,
                          _cityId,
                          _divisionId,
                          _condition,
                          _minPrice,
                          _maxPrice,
                          _sortBy,
                          _sortOrder,
                        );
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
