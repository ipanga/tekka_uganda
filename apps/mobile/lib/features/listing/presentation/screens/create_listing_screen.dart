import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/config/app_config.dart';
import '../../application/listing_provider.dart';
import '../../application/category_provider.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/location.dart';
import '../widgets/searchable_picker.dart';

/// Create/Edit listing screen with multi-step wizard
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController();

  int _currentStep = 0;
  static const int _totalSteps = 5;

  // Category selection state
  Category? _selectedMainCategory;
  Category? _selectedSubCategory;
  Category? _selectedProductType;

  // Location selection state
  City? _selectedCity;
  Division? _selectedDivision;

  @override
  void initState() {
    super.initState();
    // Load categories and cities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    final state = ref.read(createListingProviderV2);
    switch (_currentStep) {
      case 0: // Photos
        return state.selectedImages.isNotEmpty || state.uploadedImageUrls.isNotEmpty;
      case 1: // Category
        return state.categoryId != null;
      case 2: // Details
        return state.title != null &&
            state.title!.isNotEmpty &&
            state.condition != null;
      case 3: // Pricing & Location
        return state.price != null && state.price! > 0 && state.cityId != null;
      case 4: // Review
        return state.isValid;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createListingProviderV2);
    final notifier = ref.read(createListingProviderV2.notifier);
    final categoryState = ref.watch(categoryProvider);

    // Listen for errors and success
    ref.listen<CreateListingStateV2>(createListingProviderV2, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        notifier.clearError();
      }

      if (next.createdListing != null && prev?.createdListing == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing submitted for review!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getStepTitle()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context),
        ),
        actions: [
          if (_currentStep < _totalSteps - 1)
            TextButton(
              onPressed: createState.isLoading ? null : () => _saveDraft(notifier),
              child: const Text('Save Draft'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _StepProgressIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),

          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PhotoStep(
                  images: createState.selectedImages,
                  onAddFromGallery: notifier.pickImages,
                  onTakePhoto: notifier.takePhoto,
                  onRemove: notifier.removeImage,
                ),
                _CategoryStep(
                  categories: categoryState.mainCategories,
                  selectedMainCategory: _selectedMainCategory,
                  selectedSubCategory: _selectedSubCategory,
                  selectedProductType: _selectedProductType,
                  onMainCategorySelected: (cat) {
                    setState(() {
                      _selectedMainCategory = cat;
                      _selectedSubCategory = null;
                      _selectedProductType = null;
                    });
                  },
                  onSubCategorySelected: (cat) {
                    setState(() {
                      _selectedSubCategory = cat;
                      _selectedProductType = null;
                    });
                    // If sub-category has no children, use it as final selection
                    if (cat.activeChildren.isEmpty) {
                      notifier.updateCategory(cat.id, cat.name);
                    }
                  },
                  onProductTypeSelected: (cat) {
                    setState(() {
                      _selectedProductType = cat;
                    });
                    // Update the provider with final category
                    notifier.updateCategory(cat.id, cat.name);
                  },
                ),
                _DetailsStep(
                  categoryId: createState.categoryId,
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  condition: createState.condition,
                  attributes: createState.attributes,
                  onTitleChanged: notifier.updateTitle,
                  onDescriptionChanged: notifier.updateDescription,
                  onConditionChanged: notifier.updateCondition,
                  onAttributeChanged: notifier.updateAttribute,
                ),
                _PricingLocationStep(
                  priceController: _priceController,
                  cities: categoryState.activeCities,
                  selectedCity: _selectedCity,
                  selectedDivision: _selectedDivision,
                  onPriceChanged: (value) {
                    final price = int.tryParse(value);
                    if (price != null) notifier.updatePrice(price);
                  },
                  onCitySelected: (city) {
                    setState(() {
                      _selectedCity = city;
                      _selectedDivision = null;
                    });
                    notifier.updateLocation(
                      cityId: city.id,
                      cityName: city.name,
                    );
                  },
                  onDivisionSelected: (division) {
                    setState(() => _selectedDivision = division);
                    if (_selectedCity != null) {
                      notifier.updateLocation(
                        cityId: _selectedCity!.id,
                        cityName: _selectedCity!.name,
                        divisionId: division?.id,
                        divisionName: division?.name,
                      );
                    }
                  },
                ),
                _ReviewStep(
                  state: createState,
                  categoryPath: _getCategoryPath(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(createState, notifier),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Add Photos';
      case 1:
        return 'Select Category';
      case 2:
        return 'Item Details';
      case 3:
        return 'Price & Location';
      case 4:
        return 'Review';
      default:
        return 'Create Listing';
    }
  }

  String _getCategoryPath() {
    final parts = <String>[];
    if (_selectedMainCategory != null) parts.add(_selectedMainCategory!.name);
    if (_selectedSubCategory != null) parts.add(_selectedSubCategory!.name);
    if (_selectedProductType != null) parts.add(_selectedProductType!.name);
    return parts.join(' > ');
  }

  Widget _buildBottomBar(CreateListingStateV2 state, CreateListingNotifierV2 notifier) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppTheme.stickyShadow,
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isLoading ? null : _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSpacing.space3),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: state.isLoading || !_canProceed()
                    ? null
                    : () {
                        if (_currentStep == _totalSteps - 1) {
                          _publishListing(notifier);
                        } else {
                          _nextStep();
                        }
                      },
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_currentStep == _totalSteps - 1 ? 'Publish' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard listing?'),
        content: const Text('Your changes will be lost if you exit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft(CreateListingNotifierV2 notifier) async {
    await notifier.submitListing(isDraft: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved')),
      );
    }
  }

  Future<void> _publishListing(CreateListingNotifierV2 notifier) async {
    await notifier.submitListing();
  }
}

// =============================================================================
// STEP PROGRESS INDICATOR
// =============================================================================

class _StepProgressIndicator extends StatelessWidget {
  const _StepProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
// STEP 1: PHOTOS
// =============================================================================

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.images,
    required this.onAddFromGallery,
    required this.onTakePhoto,
    required this.onRemove,
  });

  final List<File> images;
  final VoidCallback onAddFromGallery;
  final VoidCallback onTakePhoto;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add up to 10 photos',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'First photo will be the cover image. Tap and hold to reorder.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _PhotoGrid(
            images: images,
            onAddFromGallery: onAddFromGallery,
            onTakePhoto: onTakePhoto,
            onRemove: onRemove,
          ),
          if (images.isEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    'Add at least 1 photo to continue',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.images,
    required this.onAddFromGallery,
    required this.onTakePhoto,
    required this.onRemove,
  });

  final List<File> images;
  final VoidCallback onAddFromGallery;
  final VoidCallback onTakePhoto;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.space3,
        crossAxisSpacing: AppSpacing.space3,
      ),
      itemCount: images.length < 10 ? images.length + 1 : images.length,
      itemBuilder: (context, index) {
        if (index == images.length && images.length < 10) {
          return _PhotoAddButton(
            onGallery: onAddFromGallery,
            onCamera: onTakePhoto,
          );
        }
        return _PhotoPreview(
          file: images[index],
          index: index,
          onRemove: () => onRemove(index),
        );
      },
    );
  }
}

class _PhotoAddButton extends StatelessWidget {
  const _PhotoAddButton({
    required this.onGallery,
    required this.onCamera,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: AppSpacing.iconLarge,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.space1),
            Text(
              'Add Photo',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                onGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                onCamera();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.file,
    required this.index,
    required this.onRemove,
  });

  final File file;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: AppSpacing.cardRadius,
            image: DecorationImage(
              image: FileImage(file),
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
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STEP 2: CATEGORY SELECTION
// =============================================================================

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    required this.categories,
    required this.selectedMainCategory,
    required this.selectedSubCategory,
    required this.selectedProductType,
    required this.onMainCategorySelected,
    required this.onSubCategorySelected,
    required this.onProductTypeSelected,
  });

  final List<Category> categories;
  final Category? selectedMainCategory;
  final Category? selectedSubCategory;
  final Category? selectedProductType;
  final void Function(Category) onMainCategorySelected;
  final void Function(Category) onSubCategorySelected;
  final void Function(Category) onProductTypeSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Category (Level 1)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Main Category', style: AppTypography.titleMedium),
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          _CategoryChips(
            categories: categories,
            selectedCategory: selectedMainCategory,
            onSelected: onMainCategorySelected,
          ),

          // Sub Category (Level 2)
          if (selectedMainCategory != null &&
              selectedMainCategory!.activeChildren.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Sub-Category', style: AppTypography.titleMedium),
                  const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _CategoryChips(
              categories: selectedMainCategory!.activeChildren,
              selectedCategory: selectedSubCategory,
              onSelected: onSubCategorySelected,
            ),
          ],

          // Product Type (Level 3)
          if (selectedSubCategory != null &&
              selectedSubCategory!.activeChildren.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Product Type', style: AppTypography.titleMedium),
                  const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _CategoryChips(
              categories: selectedSubCategory!.activeChildren,
              selectedCategory: selectedProductType,
              onSelected: onProductTypeSelected,
            ),
          ],

          // If sub-category has no children, use it as final selection
          if (selectedSubCategory != null &&
              selectedSubCategory!.activeChildren.isEmpty &&
              selectedProductType == null) ...[
            const SizedBox(height: AppSpacing.space4),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: AppSpacing.cardRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      'Selected: ${selectedMainCategory!.name} > ${selectedSubCategory!.name}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<Category> categories;
  final Category? selectedCategory;
  final void Function(Category) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: categories.map((category) {
        final isSelected = selectedCategory?.id == category.id;
        return ChoiceChip(
          label: Text(category.name),
          selected: isSelected,
          onSelected: (_) => onSelected(category),
          selectedColor: AppColors.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.onSurface,
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// STEP 3: DETAILS
// =============================================================================

class _DetailsStep extends ConsumerWidget {
  const _DetailsStep({
    required this.categoryId,
    required this.titleController,
    required this.descriptionController,
    required this.condition,
    required this.attributes,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onConditionChanged,
    required this.onAttributeChanged,
  });

  final String? categoryId;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final ItemCondition? condition;
  final Map<String, dynamic> attributes;
  final void Function(String) onTitleChanged;
  final void Function(String) onDescriptionChanged;
  final void Function(ItemCondition) onConditionChanged;
  final void Function(String, dynamic) onAttributeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'e.g., Floral Summer Dress',
            ),
            maxLength: AppConfig.maxTitleLength,
            onChanged: onTitleChanged,
          ),

          const SizedBox(height: AppSpacing.space4),

          // Condition
          Text(
            'Condition *',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: ItemCondition.values.map((cond) {
              final isSelected = condition == cond;
              return ChoiceChip(
                label: Text(cond.displayName),
                selected: isSelected,
                onSelected: (_) => onConditionChanged(cond),
                selectedColor: AppColors.primaryContainer,
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Description
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe your item...',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: AppConfig.maxDescriptionLength,
            onChanged: onDescriptionChanged,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Dynamic Attributes
          if (categoryId != null) ...[
            Text(
              'Additional Details',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.space3),
            _DynamicAttributeFields(
              categoryId: categoryId!,
              currentValues: attributes,
              onValueChanged: onAttributeChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _DynamicAttributeFields extends ConsumerWidget {
  const _DynamicAttributeFields({
    required this.categoryId,
    required this.currentValues,
    required this.onValueChanged,
  });

  final String categoryId;
  final Map<String, dynamic> currentValues;
  final void Function(String, dynamic) onValueChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attributesAsync = ref.watch(categoryAttributesProvider(categoryId));

    return attributesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Error loading attributes: $err'),
      data: (attributes) {
        // Filter out 'condition' as it's already handled by the dedicated Condition field
        final filteredAttributes = attributes.where((attr) => attr.slug != 'condition').toList();

        if (filteredAttributes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: filteredAttributes.map((attr) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space4),
              child: _AttributeField(
                attribute: attr,
                currentValue: currentValues[attr.slug],
                allValues: currentValues,
                onChanged: (value) => onValueChanged(attr.slug, value),
                onClearDependentField: (slug) => onValueChanged(slug, null),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AttributeField extends StatelessWidget {
  const _AttributeField({
    required this.attribute,
    required this.currentValue,
    required this.allValues,
    required this.onChanged,
    required this.onClearDependentField,
  });

  final AttributeDefinition attribute;
  final dynamic currentValue;
  final Map<String, dynamic> allValues;
  final void Function(dynamic) onChanged;
  final void Function(String slug) onClearDependentField;

  @override
  Widget build(BuildContext context) {
    switch (attribute.type) {
      case AttributeType.singleSelect:
        // Use searchable picker for brand fields
        if (attribute.slug.startsWith('brand-')) {
          return _buildSearchablePicker();
        }
        // Handle console-model filtering based on brand-consoles
        if (attribute.slug == 'console-model') {
          return _buildFilteredConsoleModel();
        }
        return _buildSingleSelect();
      case AttributeType.multiSelect:
        return _buildMultiSelect();
      case AttributeType.text:
        return _buildTextField();
      case AttributeType.number:
        return _buildNumberField();
    }
  }

  Widget _buildSearchablePicker() {
    return SearchablePicker(
      label: attribute.name,
      options: attribute.values.map((v) {
        return PickerOption(
          value: v.value,
          label: v.display,
        );
      }).toList(),
      selectedValue: currentValue as String?,
      onChanged: (value) {
        onChanged(value);
        // Clear console-model when console brand changes
        if (attribute.slug == 'brand-consoles') {
          onClearDependentField('console-model');
        }
      },
      placeholder: 'Search ${attribute.name.toLowerCase()}...',
      isRequired: attribute.isRequired,
    );
  }

  Widget _buildFilteredConsoleModel() {
    final label = '${attribute.name}${attribute.isRequired ? ' *' : ''}';
    final selectedBrand = allValues['brand-consoles'] as String?;

    // Filter console models based on selected brand
    final filteredValues = selectedBrand != null && selectedBrand.isNotEmpty
        ? attribute.values.where((v) {
            final brandMeta = v.metadata?['brand'] as String?;
            return brandMeta == selectedBrand ||
                (selectedBrand == 'Other' && brandMeta == 'Other');
          }).toList()
        : <AttributeValue>[];

    if (selectedBrand == null || selectedBrand.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: false,
        ),
        child: const Text(
          'Select console brand first',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: currentValue as String?,
      decoration: InputDecoration(labelText: label),
      items: filteredValues.map((v) {
        return DropdownMenuItem(
          value: v.value,
          child: Text(v.display),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSingleSelect() {
    final label = '${attribute.name}${attribute.isRequired ? ' *' : ''}';
    return DropdownButtonFormField<String>(
      value: currentValue as String?,
      decoration: InputDecoration(labelText: label),
      items: attribute.values.map((v) {
        return DropdownMenuItem(
          value: v.value,
          child: Text(v.display),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelect() {
    final label = '${attribute.name}${attribute.isRequired ? ' *' : ''}';
    final selectedValues = (currentValue as List<String>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: attribute.values.map((v) {
            final isSelected = selectedValues.contains(v.value);
            return FilterChip(
              label: Text(v.display),
              selected: isSelected,
              onSelected: (_) {
                final newValues = List<String>.from(selectedValues);
                if (isSelected) {
                  newValues.remove(v.value);
                } else {
                  newValues.add(v.value);
                }
                onChanged(newValues.isEmpty ? null : newValues);
              },
              selectedColor: AppColors.primaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    final label = '${attribute.name}${attribute.isRequired ? ' *' : ''}';
    return TextFormField(
      initialValue: currentValue as String?,
      decoration: InputDecoration(labelText: label),
      onChanged: (value) => onChanged(value.isEmpty ? null : value),
    );
  }

  Widget _buildNumberField() {
    final label = '${attribute.name}${attribute.isRequired ? ' *' : ''}';
    return TextFormField(
      initialValue: currentValue?.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        final number = int.tryParse(value);
        onChanged(number);
      },
    );
  }
}

// =============================================================================
// STEP 4: PRICING & LOCATION
// =============================================================================

class _PricingLocationStep extends StatelessWidget {
  const _PricingLocationStep({
    required this.priceController,
    required this.cities,
    required this.selectedCity,
    required this.selectedDivision,
    required this.onPriceChanged,
    required this.onCitySelected,
    required this.onDivisionSelected,
  });

  final TextEditingController priceController;
  final List<City> cities;
  final City? selectedCity;
  final Division? selectedDivision;
  final void Function(String) onPriceChanged;
  final void Function(City) onCitySelected;
  final void Function(Division?) onDivisionSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Text(
            'Price',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space3),
          TextFormField(
            controller: priceController,
            decoration: const InputDecoration(
              labelText: 'Price (UGX) *',
              hintText: 'e.g., 50000',
              prefixText: 'UGX ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onPriceChanged,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Location
          Text(
            'Meetup Location',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Select where buyers can meet you',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // City selection
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'City', style: AppTypography.titleSmall),
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          if (cities.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: cities.map((city) {
                final isSelected = selectedCity?.id == city.id;
                return ChoiceChip(
                  label: Text(city.name),
                  selected: isSelected,
                  onSelected: (_) => onCitySelected(city),
                  selectedColor: AppColors.primaryContainer,
                );
              }).toList(),
            ),

          // Division selection
          if (selectedCity != null &&
              selectedCity!.activeDivisions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Area (Optional)',
              style: AppTypography.titleSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: selectedCity!.activeDivisions.map((division) {
                final isSelected = selectedDivision?.id == division.id;
                return FilterChip(
                  label: Text(division.name),
                  selected: isSelected,
                  onSelected: (_) {
                    onDivisionSelected(isSelected ? null : division);
                  },
                  selectedColor: AppColors.primaryContainer,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 5: REVIEW
// =============================================================================

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.state,
    required this.categoryPath,
  });

  final CreateListingStateV2 state;
  final String categoryPath;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your listing',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Make sure everything looks good before publishing.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Photos preview
          if (state.selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.selectedImages.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.space2),
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.cardRadius,
                      image: DecorationImage(
                        image: FileImage(state.selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],

          // Details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow(label: 'Title', value: state.title ?? '-'),
                  _ReviewRow(label: 'Price', value: 'UGX ${state.price ?? 0}'),
                  _ReviewRow(label: 'Category', value: categoryPath.isNotEmpty ? categoryPath : '-'),
                  _ReviewRow(
                    label: 'Condition',
                    value: state.condition?.displayName ?? '-',
                  ),
                  _ReviewRow(
                    label: 'Location',
                    value: state.locationDisplay.isNotEmpty
                        ? state.locationDisplay
                        : 'Not specified',
                  ),
                  if (state.description?.isNotEmpty ?? false)
                    _ReviewRow(
                      label: 'Description',
                      value: state.description!,
                      isMultiline: true,
                    ),
                  if (state.attributes.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      'Attributes',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    ...state.attributes.entries.map((entry) {
                      final value = entry.value is List
                          ? (entry.value as List).join(', ')
                          : entry.value.toString();
                      return _ReviewRow(
                        label: entry.key,
                        value: value,
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Warning/info
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    'Your listing will be reviewed before it goes live.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  final String label;
  final String value;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: isMultiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(value, style: AppTypography.bodyMedium),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(value, style: AppTypography.bodyMedium),
                ),
              ],
            ),
    );
  }
}
