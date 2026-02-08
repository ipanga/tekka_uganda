import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/config/app_config.dart';
import '../../application/listing_provider.dart';
import '../../domain/entities/listing.dart';

/// Edit listing screen
class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initFromListing(Listing listing) {
    if (_isInitialized) return;

    _titleController.text = listing.title;
    _priceController.text = listing.price.toString();
    _descriptionController.text = listing.description;
    ref
        .read(editListingProvider(widget.listingId).notifier)
        .initFromListing(listing);
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingProvider(widget.listingId));
    final editState = ref.watch(editListingProvider(widget.listingId));
    final notifier = ref.read(editListingProvider(widget.listingId).notifier);

    // Listen for errors and success
    ref.listen<EditListingState>(editListingProvider(widget.listingId), (
      prev,
      next,
    ) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        notifier.clearError();
      }

      if (next.isUpdated && !prev!.isUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(listingProvider(widget.listingId));
        context.pop();
      }
    });

    return listingAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('Failed to load listing', style: AppTypography.bodyLarge),
              TextButton(
                onPressed: () =>
                    ref.invalidate(listingProvider(widget.listingId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (listing) {
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Listing not found')),
          );
        }

        _initFromListing(listing);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Edit Listing')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                // Current photos (read-only)
                Text('Photos', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.space3),
                _PhotosPreview(imageUrls: listing.imageUrls),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'Photo changes are not supported in edit mode.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Floral Summer Dress',
                  ),
                  maxLength: AppConfig.maxTitleLength,
                  onChanged: notifier.updateTitle,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.space4),

                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (UGX) *',
                    hintText: 'e.g., 50000',
                    prefixText: 'UGX ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final price = int.tryParse(value);
                    if (price != null) notifier.updatePrice(price);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    final price = int.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    if (price < 1000) {
                      return 'Minimum price is UGX 1,000';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.space4),

                // Category dropdown
                DropdownButtonFormField<ListingCategory>(
                  initialValue: editState.category,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: ListingCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) notifier.updateCategory(value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.space4),

                // Size and Condition row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: editState.size,
                        decoration: const InputDecoration(labelText: 'Size'),
                        items: const [
                          DropdownMenuItem(value: 'XS', child: Text('XS')),
                          DropdownMenuItem(value: 'S', child: Text('S')),
                          DropdownMenuItem(value: 'M', child: Text('M')),
                          DropdownMenuItem(value: 'L', child: Text('L')),
                          DropdownMenuItem(value: 'XL', child: Text('XL')),
                          DropdownMenuItem(value: 'XXL', child: Text('XXL')),
                          DropdownMenuItem(
                            value: 'One Size',
                            child: Text('One Size'),
                          ),
                        ],
                        onChanged: (value) => notifier.updateSize(value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space4),
                    Expanded(
                      child: DropdownButtonFormField<ItemCondition>(
                        initialValue: editState.condition,
                        decoration: const InputDecoration(
                          labelText: 'Condition *',
                        ),
                        items: ItemCondition.values.map((condition) {
                          return DropdownMenuItem(
                            value: condition,
                            child: Text(condition.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) notifier.updateCondition(value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.space4),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your item...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: AppConfig.maxDescriptionLength,
                  onChanged: notifier.updateDescription,
                ),

                const SizedBox(height: AppSpacing.space6),

                // Location
                _LocationSelector(
                  selectedLocation: editState.location,
                  onSelected: notifier.updateLocation,
                ),

                const SizedBox(height: AppSpacing.space10),
              ],
            ),
          ),

          // Save button
          bottomNavigationBar: Container(
            padding: AppSpacing.screenPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppTheme.stickyShadow,
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: editState.isLoading ? null : _saveChanges,
                child: editState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(editListingProvider(widget.listingId).notifier);
    await notifier.save();
  }
}

class _PhotosPreview extends StatelessWidget {
  const _PhotosPreview({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: AppSpacing.cardRadius,
        ),
        child: const Center(
          child: Icon(Icons.image, color: AppColors.gray400, size: 40),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < imageUrls.length - 1 ? AppSpacing.space3 : 0,
            ),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: AppSpacing.cardRadius,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(imageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    bottom: AppSpacing.space2,
                    left: AppSpacing.space2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Cover',
                        style: TextStyle(color: AppColors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({
    required this.selectedLocation,
    required this.onSelected,
  });

  final String? selectedLocation;
  final void Function(String) onSelected;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meetup Location *', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: _locations.map((location) {
            final isSelected = selectedLocation == location;
            return ChoiceChip(
              label: Text(location),
              selected: isSelected,
              onSelected: (_) => onSelected(location),
              selectedColor: AppColors.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
