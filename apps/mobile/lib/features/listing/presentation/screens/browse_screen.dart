import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/widgets/listing_card.dart';
import '../../../search/application/saved_search_provider.dart';
import '../../application/listing_provider.dart';
import '../../domain/entities/listing.dart';

/// Browse/Search screen with filters
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  ListingCategory? _selectedCategory;
  String? _selectedLocation;
  String? _selectedSize;
  int? _minPrice;
  int? _maxPrice;
  Occasion? _selectedOccasion;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  ListingsFilter get _currentFilter => ListingsFilter(
        category: _selectedCategory,
        location: _selectedLocation,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        occasion: _selectedOccasion,
        limit: 50,
      );

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedLocation = null;
      _selectedSize = null;
      _minPrice = null;
      _maxPrice = null;
      _selectedOccasion = null;
    });
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedLocation != null ||
      _selectedSize != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _selectedOccasion != null ||
      _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
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
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear'),
            ),
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
                      onPressed: _showFilterSheet,
                    ),
                  ],
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => setState(() {}),
              onChanged: (_) {
                // Debounce search
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
                  label: _selectedCategory?.displayName ?? 'Category',
                  isActive: _selectedCategory != null,
                  onTap: _showCategoryPicker,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _selectedOccasion?.displayName ?? 'Occasion',
                  isActive: _selectedOccasion != null,
                  onTap: _showOccasionPicker,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _selectedSize ?? 'Size',
                  isActive: _selectedSize != null,
                  onTap: _showSizePicker,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _getPriceLabel(),
                  isActive: _minPrice != null || _maxPrice != null,
                  onTap: _showPricePicker,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _selectedLocation ?? 'Location',
                  isActive: _selectedLocation != null,
                  onTap: _showLocationPicker,
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
        childAspectRatio: 0.7,
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
            Text(
              'Failed to load listings',
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: () => ref.invalidate(listingsFeedProvider(_currentFilter)),
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
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'No results found',
              style: AppTypography.titleMedium,
            ),
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        selectedCategory: _selectedCategory,
        selectedLocation: _selectedLocation,
        selectedSize: _selectedSize,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        selectedOccasion: _selectedOccasion,
        onApply: (category, location, size, minPrice, maxPrice, occasion) {
          setState(() {
            _selectedCategory = category;
            _selectedLocation = location;
            _selectedSize = size;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _selectedOccasion = occasion;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Categories'),
              trailing: _selectedCategory == null ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _selectedCategory = null);
                Navigator.pop(context);
              },
            ),
            ...ListingCategory.values.map((category) {
              return ListTile(
                title: Text(category.displayName),
                trailing: _selectedCategory == category ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedCategory = category);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSizePicker() {
    const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'One Size'];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Sizes'),
              trailing: _selectedSize == null ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _selectedSize = null);
                Navigator.pop(context);
              },
            ),
            ...sizes.map((size) {
              return ListTile(
                title: Text(size),
                trailing: _selectedSize == size ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedSize = size);
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
                  ? const Icon(Icons.check)
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

  void _showLocationPicker() {
    const locations = [
      'Kampala Central',
      'Kampala - Nakawa',
      'Kampala - Rubaga',
      'Kampala - Makindye',
      'Kampala - Kawempe',
      'Entebbe',
      'Jinja',
      'Mukono',
      'Wakiso',
    ];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Locations'),
              trailing: _selectedLocation == null ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _selectedLocation = null);
                Navigator.pop(context);
              },
            ),
            ...locations.map((location) {
              return ListTile(
                title: Text(location),
                trailing: _selectedLocation == location ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedLocation = location);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showOccasionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Occasions'),
              trailing: _selectedOccasion == null ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _selectedOccasion = null);
                Navigator.pop(context);
              },
            ),
            ...Occasion.values.map((occasion) {
              return ListTile(
                title: Text(occasion.displayName),
                trailing: _selectedOccasion == occasion ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedOccasion = occasion);
                  Navigator.pop(context);
                },
              );
            }),
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
            if (_selectedCategory != null)
              _SearchDetailRow(
                icon: Icons.category_outlined,
                label: _selectedCategory!.displayName,
              ),
            if (_minPrice != null || _maxPrice != null)
              _SearchDetailRow(
                icon: Icons.attach_money,
                label: _getPriceLabel(),
              ),
            if (_selectedLocation != null)
              _SearchDetailRow(
                icon: Icons.location_on_outlined,
                label: _selectedLocation!,
              ),
            if (_selectedOccasion != null)
              _SearchDetailRow(
                icon: Icons.event,
                label: _selectedOccasion!.displayName,
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
              final success = await ref.read(savedSearchProvider.notifier).saveSearch(
                query: _searchController.text,
                categoryId: _selectedCategory?.name,
                categoryName: _selectedCategory?.displayName,
                minPrice: _minPrice?.toDouble(),
                maxPrice: _maxPrice?.toDouble(),
                location: _selectedLocation,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Search saved! You\'ll be notified of new matches.'
                          : 'Failed to save search',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                    action: success
                        ? SnackBarAction(
                            label: 'View',
                            textColor: AppColors.white,
                            onPressed: () => context.push(AppRoutes.savedSearches),
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

class _SearchDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SearchDetailRow({
    required this.icon,
    required this.label,
  });

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

class _FilterSheet extends StatefulWidget {
  final ListingCategory? selectedCategory;
  final String? selectedLocation;
  final String? selectedSize;
  final int? minPrice;
  final int? maxPrice;
  final Occasion? selectedOccasion;
  final void Function(
    ListingCategory? category,
    String? location,
    String? size,
    int? minPrice,
    int? maxPrice,
    Occasion? occasion,
  ) onApply;

  const _FilterSheet({
    this.selectedCategory,
    this.selectedLocation,
    this.selectedSize,
    this.minPrice,
    this.maxPrice,
    this.selectedOccasion,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ListingCategory? _category;
  late String? _location;
  late String? _size;
  late int? _minPrice;
  late int? _maxPrice;
  late Occasion? _occasion;

  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  static const _locations = [
    'Kampala Central',
    'Kampala - Nakawa',
    'Kampala - Rubaga',
    'Kampala - Makindye',
    'Kampala - Kawempe',
    'Entebbe',
    'Jinja',
    'Mukono',
    'Wakiso',
  ];

  static const _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'One Size'];

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _location = widget.selectedLocation;
    _size = widget.selectedSize;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _occasion = widget.selectedOccasion;

    if (_minPrice != null) {
      _minPriceController.text = _minPrice.toString();
    }
    if (_maxPrice != null) {
      _maxPriceController.text = _maxPrice.toString();
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _category = null;
      _location = null;
      _size = null;
      _minPrice = null;
      _maxPrice = null;
      _occasion = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    // Category
                    Text('Category', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _category == null,
                          onSelected: (_) => setState(() => _category = null),
                        ),
                        ...ListingCategory.values.map((cat) {
                          return ChoiceChip(
                            label: Text(cat.displayName),
                            selected: _category == cat,
                            onSelected: (_) => setState(() => _category = cat),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Size
                    Text('Size', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _size == null,
                          onSelected: (_) => setState(() => _size = null),
                        ),
                        ..._sizes.map((s) {
                          return ChoiceChip(
                            label: Text(s),
                            selected: _size == s,
                            onSelected: (_) => setState(() => _size = s),
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

                    // Occasion
                    Text('Occasion', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _occasion == null,
                          onSelected: (_) => setState(() => _occasion = null),
                        ),
                        ...Occasion.values.map((occ) {
                          return ChoiceChip(
                            label: Text(occ.displayName),
                            selected: _occasion == occ,
                            onSelected: (_) => setState(() => _occasion = occ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Location
                    Text('Location', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _location == null,
                          onSelected: (_) => setState(() => _location = null),
                        ),
                        ..._locations.map((loc) {
                          return ChoiceChip(
                            label: Text(loc),
                            selected: _location == loc,
                            onSelected: (_) => setState(() => _location = loc),
                          );
                        }),
                      ],
                    ),

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
                          _category,
                          _location,
                          _size,
                          _minPrice,
                          _maxPrice,
                          _occasion,
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
