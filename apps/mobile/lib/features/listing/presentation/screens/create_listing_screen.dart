import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../application/listing_provider.dart';
import '../../application/category_provider.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/location.dart';
import '../widgets/searchable_picker.dart';

/// Create/Edit listing screen with multi-step wizard
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key, this.listingId});

  /// If provided, the screen operates in edit mode for this listing.
  final String? listingId;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
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

  // Edit mode
  bool get isEditMode => widget.listingId != null;
  bool _editInitialized = false;
  ListingStatus? _editingListingStatus;

  /// Returns the appropriate provider based on mode
  AutoDisposeStateNotifierProvider<
    CreateListingNotifierV2,
    CreateListingStateV2
  >
  get _provider {
    if (isEditMode) {
      return editListingProviderV2(widget.listingId!);
    }
    return createListingProviderV2;
  }

  @override
  void initState() {
    super.initState();
    // Load categories and cities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).loadData();
      if (isEditMode) {
        _initEditMode();
      }
    });
  }

  Future<void> _initEditMode() async {
    if (_editInitialized) return;
    _editInitialized = true;

    try {
      final listing = await ref.read(listingProvider(widget.listingId!).future);
      if (listing == null || !mounted) return;

      setState(() => _editingListingStatus = listing.status);

      final notifier = ref.read(_provider.notifier);
      notifier.initFromListing(listing);

      // Pre-fill text controllers
      _titleController.text = listing.title;
      _priceController.text = listing.price.toString();
      _descriptionController.text = listing.description;

      // Resolve category hierarchy from categories tree
      final categoryState = ref.read(categoryProvider);
      if (listing.categoryId != null) {
        _resolveCategoryPath(listing.categoryId!, categoryState.mainCategories);
      }

      // Resolve location from cities
      if (listing.cityId != null) {
        _resolveLocation(
          listing.cityId!,
          listing.divisionId,
          categoryState.activeCities,
        );
      }
    } catch (e) {
      // Listing load failed - error will be shown via provider
    }
  }

  /// Walk the category tree to find and pre-select the category hierarchy
  void _resolveCategoryPath(String categoryId, List<Category> mainCategories) {
    for (final main in mainCategories) {
      if (main.id == categoryId) {
        setState(() => _selectedMainCategory = main);
        return;
      }
      for (final sub in main.activeChildren) {
        if (sub.id == categoryId) {
          setState(() {
            _selectedMainCategory = main;
            _selectedSubCategory = sub;
          });
          return;
        }
        for (final product in sub.activeChildren) {
          if (product.id == categoryId) {
            setState(() {
              _selectedMainCategory = main;
              _selectedSubCategory = sub;
              _selectedProductType = product;
            });
            return;
          }
        }
      }
    }
  }

  /// Resolve city and division from the loaded cities list
  void _resolveLocation(String cityId, String? divisionId, List<City> cities) {
    for (final city in cities) {
      if (city.id == cityId) {
        setState(() => _selectedCity = city);
        if (divisionId != null) {
          for (final div in city.activeDivisions) {
            if (div.id == divisionId) {
              setState(() => _selectedDivision = div);
              break;
            }
          }
        }
        return;
      }
    }
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
    final state = ref.read(_provider);
    switch (_currentStep) {
      case 0: // Photos
        return state.selectedImages.isNotEmpty ||
            state.uploadedImageUrls.isNotEmpty;
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
    final createState = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final categoryState = ref.watch(categoryProvider);

    // Resolve category/location when data becomes available in edit mode
    if (isEditMode &&
        createState.categoryId != null &&
        _selectedMainCategory == null &&
        categoryState.mainCategories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveCategoryPath(
          createState.categoryId!,
          categoryState.mainCategories,
        );
        if (createState.cityId != null) {
          _resolveLocation(
            createState.cityId!,
            createState.divisionId,
            categoryState.activeCities,
          );
        }
      });
    }

    // Listen for errors and success
    ref.listen<CreateListingStateV2>(_provider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        notifier.clearError();
      }

      if (next.createdListing != null && prev?.createdListing == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Listing updated successfully!'
                  : 'Listing submitted for review!',
            ),
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
          if (!isEditMode && _currentStep < _totalSteps - 1)
            TextButton(
              onPressed: createState.isLoading
                  ? null
                  : () => _saveDraft(notifier),
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
                  localImages: createState.selectedImages,
                  existingImageUrls: createState.uploadedImageUrls,
                  onAddFromGallery: notifier.pickImages,
                  onTakePhoto: notifier.takePhoto,
                  onRemoveLocal: notifier.removeImage,
                  onRemoveExisting: notifier.removeUploadedImage,
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
                  isEditMode: isEditMode,
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
        return isEditMode ? 'Edit Photos' : 'Add Photos';
      case 1:
        return 'Select Category';
      case 2:
        return 'Item Details';
      case 3:
        return 'Price & Location';
      case 4:
        return 'Review';
      default:
        return isEditMode ? 'Edit Listing' : 'Create Listing';
    }
  }

  String _getCategoryPath() {
    final parts = <String>[];
    if (_selectedMainCategory != null) parts.add(_selectedMainCategory!.name);
    if (_selectedSubCategory != null) parts.add(_selectedSubCategory!.name);
    if (_selectedProductType != null) parts.add(_selectedProductType!.name);
    return parts.join(' > ');
  }

  Widget _buildBottomBar(
    CreateListingStateV2 state,
    CreateListingNotifierV2 notifier,
  ) {
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
            if (isEditMode &&
                _editingListingStatus == ListingStatus.draft &&
                _currentStep == _totalSteps - 1) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isLoading || !_canProceed()
                      ? null
                      : () => _publishListing(notifier),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isLoading || !_canProceed()
                      ? null
                      : () => _publishDraft(notifier),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Publish'),
                ),
              ),
            ] else
              Expanded(
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
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? (isEditMode ? 'Save Changes' : 'Publish')
                              : 'Continue',
                        ),
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
        title: Text(isEditMode ? 'Discard changes?' : 'Discard listing?'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved')));
    }
  }

  Future<void> _publishListing(CreateListingNotifierV2 notifier) async {
    await notifier.submitListing();
  }

  Future<void> _publishDraft(CreateListingNotifierV2 notifier) async {
    // Save changes first, then publish
    final listing = await notifier.submitListing();
    if (listing != null && mounted) {
      try {
        final repo = ref.read(listingApiRepositoryProvider);
        await repo.publishDraft(listing.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing submitted for review!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to publish: $e')));
        }
      }
    }
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
    required this.localImages,
    required this.existingImageUrls,
    required this.onAddFromGallery,
    required this.onTakePhoto,
    required this.onRemoveLocal,
    required this.onRemoveExisting,
  });

  final List<File> localImages;
  final List<String> existingImageUrls;
  final VoidCallback onAddFromGallery;
  final VoidCallback onTakePhoto;
  final void Function(int) onRemoveLocal;
  final void Function(int) onRemoveExisting;

  int get _totalImages => existingImageUrls.length + localImages.length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add up to 10 photos', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'First photo will be the cover image. Tap and hold to reorder.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _PhotoGrid(
            localImages: localImages,
            existingImageUrls: existingImageUrls,
            onAddFromGallery: onAddFromGallery,
            onTakePhoto: onTakePhoto,
            onRemoveLocal: onRemoveLocal,
            onRemoveExisting: onRemoveExisting,
          ),
          if (_totalImages == 0) ...[
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
    required this.localImages,
    required this.existingImageUrls,
    required this.onAddFromGallery,
    required this.onTakePhoto,
    required this.onRemoveLocal,
    required this.onRemoveExisting,
  });

  final List<File> localImages;
  final List<String> existingImageUrls;
  final VoidCallback onAddFromGallery;
  final VoidCallback onTakePhoto;
  final void Function(int) onRemoveLocal;
  final void Function(int) onRemoveExisting;

  int get _totalImages => existingImageUrls.length + localImages.length;

  @override
  Widget build(BuildContext context) {
    final showAddButton = _totalImages < 10;
    final itemCount = _totalImages + (showAddButton ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.space3,
        crossAxisSpacing: AppSpacing.space3,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Existing network images come first
        if (index < existingImageUrls.length) {
          return _NetworkPhotoPreview(
            url: existingImageUrls[index],
            index: index,
            onRemove: () => onRemoveExisting(index),
          );
        }

        // Then local images
        final localIndex = index - existingImageUrls.length;
        if (localIndex < localImages.length) {
          return _PhotoPreview(
            file: localImages[localIndex],
            index: index,
            onRemove: () => onRemoveLocal(localIndex),
          );
        }

        // Add button at the end
        return _PhotoAddButton(
          onGallery: onAddFromGallery,
          onCamera: onTakePhoto,
        );
      },
    );
  }
}

class _PhotoAddButton extends StatelessWidget {
  const _PhotoAddButton({required this.onGallery, required this.onCamera});

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
          border: Border.all(color: AppColors.primary, width: 2),
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
              style: TextStyle(color: AppColors.primary, fontSize: 12),
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
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
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
              child: const Icon(Icons.close, size: 14, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _NetworkPhotoPreview extends StatelessWidget {
  const _NetworkPhotoPreview({
    required this.url,
    required this.index,
    required this.onRemove,
  });

  final String url;
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
              image: CachedNetworkImageProvider(url),
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
              child: const Icon(Icons.close, size: 14, color: AppColors.white),
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
                TextSpan(
                  text: 'Main Category',
                  style: AppTypography.titleMedium,
                ),
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
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
                  TextSpan(
                    text: 'Sub-Category',
                    style: AppTypography.titleMedium,
                  ),
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.error),
                  ),
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
                  TextSpan(
                    text: 'Product Type',
                    style: AppTypography.titleMedium,
                  ),
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.error),
                  ),
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
          Text('Condition *', style: AppTypography.titleSmall),
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
            Text('Additional Details', style: AppTypography.titleMedium),
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
        final filteredAttributes = attributes
            .where((attr) => attr.slug != 'condition')
            .toList();

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
        return PickerOption(value: v.value, label: v.display);
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
        decoration: InputDecoration(labelText: label, enabled: false),
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
        return DropdownMenuItem(value: v.value, child: Text(v.display));
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
        return DropdownMenuItem(value: v.value, child: Text(v.display));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelect() {
    final label = '${attribute.name}${attribute.isRequired ? ' *' : ''}';
    final selectedValues = currentValue is List
        ? List<String>.from(currentValue)
        : <String>[];

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
          Text('Price', style: AppTypography.titleMedium),
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
          Text('Meetup Location', style: AppTypography.titleMedium),
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
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
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
            Text('Area (Optional)', style: AppTypography.titleSmall),
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
    this.isEditMode = false,
  });

  final CreateListingStateV2 state;
  final String categoryPath;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final allImageCount =
        state.uploadedImageUrls.length + state.selectedImages.length;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review your listing', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space2),
          Text(
            isEditMode
                ? 'Review your changes before saving.'
                : 'Make sure everything looks good before publishing.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Photos preview (existing URLs + local files)
          if (allImageCount > 0) ...[
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allImageCount,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.space2),
                itemBuilder: (context, index) {
                  if (index < state.uploadedImageUrls.length) {
                    return Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: AppSpacing.cardRadius,
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            state.uploadedImageUrls[index],
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  final localIndex = index - state.uploadedImageUrls.length;
                  return Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.cardRadius,
                      image: DecorationImage(
                        image: FileImage(state.selectedImages[localIndex]),
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
                  _ReviewRow(
                    label: 'Category',
                    value: categoryPath.isNotEmpty ? categoryPath : '-',
                  ),
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
                    Text('Attributes', style: AppTypography.titleSmall),
                    const SizedBox(height: AppSpacing.space2),
                    ...state.attributes.entries.map((entry) {
                      final value = entry.value is List
                          ? (entry.value as List).join(', ')
                          : entry.value.toString();
                      return _ReviewRow(label: entry.key, value: value);
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
                    isEditMode
                        ? 'If you changed the title or description, your listing may be reviewed again.'
                        : 'Your listing will be reviewed before it goes live.',
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
                Expanded(child: Text(value, style: AppTypography.bodyMedium)),
              ],
            ),
    );
  }
}
