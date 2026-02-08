import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/image_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/image_service_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';
import '../data/repositories/listing_api_repository.dart';
import '../domain/entities/listing.dart';

// Re-export providers from image_service_provider.dart to avoid breaking imports
export '../../../core/services/image_service_provider.dart' show storageServiceProvider, imageServiceProvider;

/// Listings feed provider with pagination (filters blocked users)
final listingsFeedProvider = FutureProvider.family<List<Listing>, ListingsFilter>(
  (ref, filter) async {
    final repository = ref.watch(listingApiRepositoryProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Get listings from API
    final result = await repository.search(
      query: filter.searchQuery,
      category: filter.category,
      categoryId: filter.categoryId,
      condition: filter.condition,
      occasion: filter.occasion,
      minPrice: filter.minPrice,
      maxPrice: filter.maxPrice,
      location: filter.location,
      cityId: filter.cityId,
      divisionId: filter.divisionId,
      sortBy: filter.sortBy,
      sortOrder: filter.sortOrder,
      page: filter.page,
      limit: filter.limit,
    );

    var listings = result.listings;

    // If no user is logged in, return all listings
    if (currentUser == null) return listings;

    // Get blocked users and filter them out
    try {
      final blockedUsers = await ref.watch(blockedUsersProvider.future);
      if (blockedUsers.isNotEmpty) {
        final blockedUserIds = blockedUsers.map((u) => u.uid).toSet();
        listings = listings.where((listing) => !blockedUserIds.contains(listing.sellerId)).toList();
      }
    } catch (_) {
      // If blocked users can't be fetched, continue without filtering
    }

    return listings;
  },
);

/// Single listing provider
final listingProvider = FutureProvider.family<Listing?, String>(
  (ref, listingId) async {
    final repository = ref.watch(listingApiRepositoryProvider);
    try {
      return await repository.getById(listingId);
    } catch (_) {
      return null;
    }
  },
);

/// User's listings provider (my listings)
final myListingsProvider = FutureProvider.family<List<Listing>, ListingStatus?>(
  (ref, status) async {
    final repository = ref.watch(listingApiRepositoryProvider);
    return repository.getMyListings(status: status);
  },
);

/// Any user's listings provider
final userListingsProvider = FutureProvider.family<List<Listing>, String>(
  (ref, sellerId) async {
    final repository = ref.watch(listingApiRepositoryProvider);
    final currentUser = ref.watch(currentUserProvider);

    // If requesting current user's listings, use the dedicated endpoint
    if (currentUser != null && sellerId == currentUser.uid) {
      return repository.getMyListings();
    }

    // For other users, use search with seller filter
    final result = await repository.search(sellerId: sellerId);
    return result.listings;
  },
);

/// Saved/Favorite listings provider
final savedListingsProvider = FutureProvider<List<Listing>>(
  (ref) async {
    final repository = ref.watch(listingApiRepositoryProvider);
    return repository.getSavedListings();
  },
);

/// Legacy alias for backward compatibility
final favoriteListingsProvider = FutureProvider.family<List<Listing>, String>(
  (ref, userId) async {
    final repository = ref.watch(listingApiRepositoryProvider);
    return repository.getSavedListings();
  },
);

/// Check if listing is saved
final isListingSavedProvider = FutureProvider.family<bool, String>(
  (ref, listingId) async {
    final savedListings = await ref.watch(savedListingsProvider.future);
    return savedListings.any((l) => l.id == listingId);
  },
);

/// Purchase history provider - listings bought by the user
final purchaseHistoryProvider = FutureProvider.family<List<Listing>, String>(
  (ref, userId) async {
    final repository = ref.watch(listingApiRepositoryProvider);
    return repository.getPurchaseHistory();
  },
);

/// Filter for listings query
class ListingsFilter {
  final ListingCategory? category; // Legacy enum
  final String? categoryId; // New hierarchical category ID
  final ItemCondition? condition;
  final Occasion? occasion;
  final String? location;
  final String? cityId;
  final String? divisionId;
  final int? minPrice;
  final int? maxPrice;
  final String? searchQuery;
  final String? sortBy;
  final String? sortOrder;
  final int page;
  final int limit;

  const ListingsFilter({
    this.category,
    this.categoryId,
    this.condition,
    this.occasion,
    this.location,
    this.cityId,
    this.divisionId,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
    this.sortBy,
    this.sortOrder,
    this.page = 1,
    this.limit = 20,
  });

  ListingsFilter copyWith({
    ListingCategory? category,
    String? categoryId,
    ItemCondition? condition,
    Occasion? occasion,
    String? location,
    String? cityId,
    String? divisionId,
    int? minPrice,
    int? maxPrice,
    String? searchQuery,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) {
    return ListingsFilter(
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      condition: condition ?? this.condition,
      occasion: occasion ?? this.occasion,
      location: location ?? this.location,
      cityId: cityId ?? this.cityId,
      divisionId: divisionId ?? this.divisionId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListingsFilter &&
        other.category == category &&
        other.categoryId == categoryId &&
        other.condition == condition &&
        other.occasion == occasion &&
        other.location == location &&
        other.cityId == cityId &&
        other.divisionId == divisionId &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.searchQuery == searchQuery &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(
      category,
      categoryId,
      condition,
      occasion,
      location,
      cityId,
      divisionId,
      minPrice,
      maxPrice,
      searchQuery,
      sortBy,
      sortOrder,
      page,
      limit,
    );
  }
}

/// Create listing state
class CreateListingState {
  final bool isLoading;
  final String? error;
  final List<File> selectedImages;
  final List<String> uploadedImageUrls;
  final String? title;
  final String? description;
  final int? price;
  final ListingCategory? category;
  final String? size;
  final String? brand;
  final String? color;
  final String? material;
  final ItemCondition? condition;
  final String? location;
  final Occasion? occasion;
  final Listing? createdListing;

  const CreateListingState({
    this.isLoading = false,
    this.error,
    this.selectedImages = const [],
    this.uploadedImageUrls = const [],
    this.title,
    this.description,
    this.price,
    this.category,
    this.size,
    this.brand,
    this.color,
    this.material,
    this.condition,
    this.location,
    this.occasion,
    this.createdListing,
  });

  CreateListingState copyWith({
    bool? isLoading,
    String? error,
    List<File>? selectedImages,
    List<String>? uploadedImageUrls,
    String? title,
    String? description,
    int? price,
    ListingCategory? category,
    String? size,
    String? brand,
    String? color,
    String? material,
    ItemCondition? condition,
    String? location,
    Occasion? occasion,
    Listing? createdListing,
  }) {
    return CreateListingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedImages: selectedImages ?? this.selectedImages,
      uploadedImageUrls: uploadedImageUrls ?? this.uploadedImageUrls,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      material: material ?? this.material,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      occasion: occasion ?? this.occasion,
      createdListing: createdListing ?? this.createdListing,
    );
  }

  bool get isValid {
    return (selectedImages.isNotEmpty || uploadedImageUrls.isNotEmpty) &&
        title != null &&
        title!.isNotEmpty &&
        price != null &&
        price! > 0 &&
        category != null &&
        condition != null &&
        location != null;
  }
}

/// Create listing notifier
class CreateListingNotifier extends StateNotifier<CreateListingState> {
  final ListingApiRepository _repository;
  final ImageService _imageService;
  final StorageService _storageService;
  final String _userId;

  CreateListingNotifier(this._repository, this._imageService, this._storageService, this._userId)
      : super(const CreateListingState());

  /// Add images from gallery
  Future<void> pickImages() async {
    final maxRemaining = 5 - state.selectedImages.length - state.uploadedImageUrls.length;
    if (maxRemaining <= 0) {
      state = state.copyWith(error: 'Maximum 5 images allowed');
      return;
    }

    final images = await _imageService.pickMultipleImages(maxImages: maxRemaining);
    if (images.isNotEmpty) {
      final validImages = <File>[];
      for (final image in images) {
        final error = _imageService.validateImage(image);
        if (error != null) {
          state = state.copyWith(error: error);
          return;
        }
        final compressed = await _imageService.compressImage(image);
        if (compressed != null) {
          validImages.add(compressed);
        }
      }

      state = state.copyWith(
        selectedImages: [...state.selectedImages, ...validImages],
        error: null,
      );
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    if (state.selectedImages.length + state.uploadedImageUrls.length >= 5) {
      state = state.copyWith(error: 'Maximum 5 images allowed');
      return;
    }

    final image = await _imageService.takePhoto();
    if (image != null) {
      final error = _imageService.validateImage(image);
      if (error != null) {
        state = state.copyWith(error: error);
        return;
      }

      final compressed = await _imageService.compressImage(image);
      if (compressed != null) {
        state = state.copyWith(
          selectedImages: [...state.selectedImages, compressed],
          error: null,
        );
      }
    }
  }

  /// Remove image at index
  void removeImage(int index) {
    final images = [...state.selectedImages];
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      state = state.copyWith(selectedImages: images);
    }
  }

  /// Reorder images
  void reorderImages(int oldIndex, int newIndex) {
    final images = [...state.selectedImages];
    if (newIndex > oldIndex) newIndex--;
    final item = images.removeAt(oldIndex);
    images.insert(newIndex, item);
    state = state.copyWith(selectedImages: images);
  }

  /// Update form fields
  void updateTitle(String value) => state = state.copyWith(title: value);
  void updateDescription(String value) => state = state.copyWith(description: value);
  void updatePrice(int value) => state = state.copyWith(price: value);
  void updateCategory(ListingCategory value) => state = state.copyWith(category: value);
  void updateSize(String? value) => state = state.copyWith(size: value);
  void updateBrand(String? value) => state = state.copyWith(brand: value);
  void updateColor(String? value) => state = state.copyWith(color: value);
  void updateMaterial(String? value) => state = state.copyWith(material: value);
  void updateCondition(ItemCondition value) => state = state.copyWith(condition: value);
  void updateLocation(String value) => state = state.copyWith(location: value);
  void updateOccasion(Occasion? value) => state = state.copyWith(occasion: value);

  /// Clear error
  void clearError() => state = state.copyWith(error: null);

  /// Submit listing
  Future<Listing?> submitListing() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Upload images to Firebase Storage
      final imageUrls = <String>[...state.uploadedImageUrls];

      // Generate a temporary listing ID for the upload path
      final tempListingId = const Uuid().v4();

      for (final imageFile in state.selectedImages) {
        final url = await _storageService.uploadListingImage(
          imageFile: imageFile,
          userId: _userId,
          listingId: tempListingId,
        );
        if (url != null) {
          imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to upload images. Please try again.',
        );
        return null;
      }

      final listing = await _repository.create(
        title: state.title!,
        description: state.description ?? '',
        price: state.price!,
        category: state.category!,
        condition: state.condition!,
        imageUrls: imageUrls,
        size: state.size,
        brand: state.brand,
        color: state.color,
        material: state.material,
        location: state.location,
        occasion: state.occasion,
      );

      state = state.copyWith(
        isLoading: false,
        createdListing: listing,
      );

      return listing;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Reset state
  void reset() {
    _imageService.cleanupTempFiles(state.selectedImages);
    state = const CreateListingState();
  }
}

/// Create listing notifier provider
final createListingProvider =
    StateNotifierProvider.autoDispose<CreateListingNotifier, CreateListingState>(
  (ref) {
    final repository = ref.watch(listingApiRepositoryProvider);
    final imageService = ref.watch(imageServiceProvider);
    final storageService = ref.watch(storageServiceProvider);
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.uid ?? '';
    return CreateListingNotifier(repository, imageService, storageService, userId);
  },
);

/// Listing actions notifier (for detail screen)
class ListingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ListingApiRepository _repository;
  final String listingId;

  ListingActionsNotifier(this._repository, this.listingId)
      : super(const AsyncValue.data(null));

  /// Increment view count (called when listing is opened)
  Future<void> incrementView() async {
    // View count is typically tracked server-side when fetching the listing
    // This is a no-op on the client, the server handles it
  }

  /// Toggle favorite/save status
  Future<bool> toggleFavorite() async {
    return toggleSave();
  }

  Future<bool> toggleSave() async {
    state = const AsyncValue.loading();
    try {
      // Check if currently saved and toggle
      // This is simplified - in real app, check current state first
      await _repository.save(listingId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, _) {
      // If save fails, try unsave (toggle behavior)
      try {
        await _repository.unsave(listingId);
        state = const AsyncValue.data(null);
        return false;
      } catch (e2, st2) {
        state = AsyncValue.error(e2, st2);
        return false;
      }
    }
  }

  Future<void> saveListing() async {
    state = const AsyncValue.loading();
    try {
      await _repository.save(listingId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unsaveListing() async {
    state = const AsyncValue.loading();
    try {
      await _repository.unsave(listingId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsSold() async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAsSold(listingId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> archive() async {
    state = const AsyncValue.loading();
    try {
      await _repository.archive(listingId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteListing() async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(listingId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Listing actions provider
final listingActionsProvider = StateNotifierProvider.family
    .autoDispose<ListingActionsNotifier, AsyncValue<void>, String>(
  (ref, listingId) {
    final repository = ref.watch(listingApiRepositoryProvider);
    return ListingActionsNotifier(repository, listingId);
  },
);

/// Provider to check if a listing is favorited/saved by current user
final isFavoritedProvider = FutureProvider.family<bool, String>(
  (ref, listingId) async {
    final listing = await ref.watch(listingProvider(listingId).future);
    return listing?.isSaved ?? false;
  },
);

/// Edit listing state
class EditListingState {
  final bool isLoading;
  final String? error;
  final String? title;
  final String? description;
  final int? price;
  final ListingCategory? category;
  final String? size;
  final String? brand;
  final String? color;
  final String? material;
  final ItemCondition? condition;
  final String? location;
  final Occasion? occasion;
  final bool isUpdated;

  const EditListingState({
    this.isLoading = false,
    this.error,
    this.title,
    this.description,
    this.price,
    this.category,
    this.size,
    this.brand,
    this.color,
    this.material,
    this.condition,
    this.location,
    this.occasion,
    this.isUpdated = false,
  });

  EditListingState copyWith({
    bool? isLoading,
    String? error,
    String? title,
    String? description,
    int? price,
    ListingCategory? category,
    String? size,
    String? brand,
    String? color,
    String? material,
    ItemCondition? condition,
    String? location,
    Occasion? occasion,
    bool? isUpdated,
  }) {
    return EditListingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      material: material ?? this.material,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      occasion: occasion ?? this.occasion,
      isUpdated: isUpdated ?? this.isUpdated,
    );
  }
}

/// Edit listing notifier
class EditListingNotifier extends StateNotifier<EditListingState> {
  final ListingApiRepository _repository;
  final String listingId;

  EditListingNotifier(this._repository, this.listingId)
      : super(const EditListingState());

  void initFromListing(Listing listing) {
    state = EditListingState(
      title: listing.title,
      description: listing.description,
      price: listing.price,
      category: listing.category,
      size: listing.size,
      brand: listing.brand,
      color: listing.color,
      material: listing.material,
      condition: listing.condition,
      location: listing.location,
      occasion: listing.occasion,
    );
  }

  void updateTitle(String value) => state = state.copyWith(title: value);
  void updateDescription(String value) => state = state.copyWith(description: value);
  void updatePrice(int value) => state = state.copyWith(price: value);
  void updateCategory(ListingCategory value) => state = state.copyWith(category: value);
  void updateSize(String? value) => state = state.copyWith(size: value);
  void updateBrand(String? value) => state = state.copyWith(brand: value);
  void updateColor(String? value) => state = state.copyWith(color: value);
  void updateMaterial(String? value) => state = state.copyWith(material: value);
  void updateCondition(ItemCondition value) => state = state.copyWith(condition: value);
  void updateLocation(String value) => state = state.copyWith(location: value);
  void updateOccasion(Occasion? value) => state = state.copyWith(occasion: value);

  void clearError() => state = state.copyWith(error: null);

  Future<bool> save() async {
    if (state.title == null || state.title!.isEmpty) {
      state = state.copyWith(error: 'Title is required');
      return false;
    }
    if (state.price == null || state.price! <= 0) {
      state = state.copyWith(error: 'Valid price is required');
      return false;
    }
    if (state.category == null) {
      state = state.copyWith(error: 'Category is required');
      return false;
    }
    if (state.condition == null) {
      state = state.copyWith(error: 'Condition is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.update(
        listingId,
        title: state.title,
        description: state.description,
        price: state.price,
        category: state.category,
        condition: state.condition,
        size: state.size,
        brand: state.brand,
        color: state.color,
        material: state.material,
        location: state.location,
        occasion: state.occasion,
      );
      state = state.copyWith(isLoading: false, isUpdated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

/// Edit listing provider
final editListingProvider = StateNotifierProvider.family
    .autoDispose<EditListingNotifier, EditListingState, String>(
  (ref, listingId) {
    final repository = ref.watch(listingApiRepositoryProvider);
    return EditListingNotifier(repository, listingId);
  },
);

// ============================================
// NEW HIERARCHICAL CATEGORY SYSTEM
// ============================================

/// Create listing state with new category system
class CreateListingStateV2 {
  final bool isLoading;
  final String? error;
  final List<File> selectedImages;
  final List<String> uploadedImageUrls;
  final String? title;
  final String? description;
  final int? price;
  final ItemCondition? condition;
  // New hierarchical category
  final String? categoryId;
  final String? categoryName; // For display
  final Map<String, dynamic> attributes;
  // New location
  final String? cityId;
  final String? cityName;
  final String? divisionId;
  final String? divisionName;
  final Listing? createdListing;

  const CreateListingStateV2({
    this.isLoading = false,
    this.error,
    this.selectedImages = const [],
    this.uploadedImageUrls = const [],
    this.title,
    this.description,
    this.price,
    this.condition,
    this.categoryId,
    this.categoryName,
    this.attributes = const {},
    this.cityId,
    this.cityName,
    this.divisionId,
    this.divisionName,
    this.createdListing,
  });

  CreateListingStateV2 copyWith({
    bool? isLoading,
    String? error,
    List<File>? selectedImages,
    List<String>? uploadedImageUrls,
    String? title,
    String? description,
    int? price,
    ItemCondition? condition,
    String? categoryId,
    String? categoryName,
    Map<String, dynamic>? attributes,
    String? cityId,
    String? cityName,
    String? divisionId,
    String? divisionName,
    Listing? createdListing,
  }) {
    return CreateListingStateV2(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedImages: selectedImages ?? this.selectedImages,
      uploadedImageUrls: uploadedImageUrls ?? this.uploadedImageUrls,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      attributes: attributes ?? this.attributes,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      divisionId: divisionId ?? this.divisionId,
      divisionName: divisionName ?? this.divisionName,
      createdListing: createdListing ?? this.createdListing,
    );
  }

  bool get isValid {
    return (selectedImages.isNotEmpty || uploadedImageUrls.isNotEmpty) &&
        title != null &&
        title!.isNotEmpty &&
        price != null &&
        price! > 0 &&
        categoryId != null &&
        condition != null;
  }

  String get locationDisplay {
    if (cityName == null) return '';
    if (divisionName != null) return '$cityName, $divisionName';
    return cityName!;
  }
}

/// Create listing notifier with new category system
class CreateListingNotifierV2 extends StateNotifier<CreateListingStateV2> {
  final ListingApiRepository _repository;
  final ImageService _imageService;
  final StorageService _storageService;
  final String _userId;

  CreateListingNotifierV2(this._repository, this._imageService, this._storageService, this._userId)
      : super(const CreateListingStateV2());

  /// Add images from gallery
  Future<void> pickImages() async {
    final maxRemaining = 10 - state.selectedImages.length - state.uploadedImageUrls.length;
    if (maxRemaining <= 0) {
      state = state.copyWith(error: 'Maximum 10 images allowed');
      return;
    }

    final images = await _imageService.pickMultipleImages(maxImages: maxRemaining);
    if (images.isNotEmpty) {
      final validImages = <File>[];
      for (final image in images) {
        final error = _imageService.validateImage(image);
        if (error != null) {
          state = state.copyWith(error: error);
          return;
        }
        final compressed = await _imageService.compressImage(image);
        if (compressed != null) {
          validImages.add(compressed);
        }
      }

      state = state.copyWith(
        selectedImages: [...state.selectedImages, ...validImages],
        error: null,
      );
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    if (state.selectedImages.length + state.uploadedImageUrls.length >= 10) {
      state = state.copyWith(error: 'Maximum 10 images allowed');
      return;
    }

    final image = await _imageService.takePhoto();
    if (image != null) {
      final error = _imageService.validateImage(image);
      if (error != null) {
        state = state.copyWith(error: error);
        return;
      }

      final compressed = await _imageService.compressImage(image);
      if (compressed != null) {
        state = state.copyWith(
          selectedImages: [...state.selectedImages, compressed],
          error: null,
        );
      }
    }
  }

  /// Remove image at index
  void removeImage(int index) {
    final images = [...state.selectedImages];
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      state = state.copyWith(selectedImages: images);
    }
  }

  /// Update form fields
  void updateTitle(String value) => state = state.copyWith(title: value);
  void updateDescription(String value) => state = state.copyWith(description: value);
  void updatePrice(int value) => state = state.copyWith(price: value);
  void updateCondition(ItemCondition value) => state = state.copyWith(condition: value);

  /// Update category (new system)
  void updateCategory(String categoryId, String categoryName) {
    state = state.copyWith(
      categoryId: categoryId,
      categoryName: categoryName,
      attributes: {}, // Reset attributes when category changes
    );
  }

  /// Update a single attribute value
  void updateAttribute(String slug, dynamic value) {
    final newAttributes = Map<String, dynamic>.from(state.attributes);
    if (value == null || (value is String && value.isEmpty) || (value is List && value.isEmpty)) {
      newAttributes.remove(slug);
    } else {
      newAttributes[slug] = value;
    }
    state = state.copyWith(attributes: newAttributes);
  }

  /// Update location (new system)
  void updateLocation({
    required String cityId,
    required String cityName,
    String? divisionId,
    String? divisionName,
  }) {
    state = state.copyWith(
      cityId: cityId,
      cityName: cityName,
      divisionId: divisionId,
      divisionName: divisionName,
    );
  }

  /// Clear location
  void clearLocation() {
    state = CreateListingStateV2(
      isLoading: state.isLoading,
      error: state.error,
      selectedImages: state.selectedImages,
      uploadedImageUrls: state.uploadedImageUrls,
      title: state.title,
      description: state.description,
      price: state.price,
      condition: state.condition,
      categoryId: state.categoryId,
      categoryName: state.categoryName,
      attributes: state.attributes,
      createdListing: state.createdListing,
    );
  }

  /// Clear error
  void clearError() => state = state.copyWith(error: null);

  /// Submit listing
  Future<Listing?> submitListing({bool isDraft = false}) async {
    if (!isDraft && !state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Upload images to Firebase Storage
      final imageUrls = <String>[...state.uploadedImageUrls];
      final tempListingId = const Uuid().v4();

      for (final imageFile in state.selectedImages) {
        final url = await _storageService.uploadListingImage(
          imageFile: imageFile,
          userId: _userId,
          listingId: tempListingId,
        );
        if (url != null) {
          imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty && !isDraft) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to upload images. Please try again.',
        );
        return null;
      }

      final listing = await _repository.createWithCategory(
        title: state.title ?? '',
        description: state.description ?? '',
        price: state.price ?? 0,
        condition: state.condition ?? ItemCondition.good,
        imageUrls: imageUrls,
        categoryId: state.categoryId!,
        attributes: state.attributes.isNotEmpty ? state.attributes : null,
        cityId: state.cityId,
        divisionId: state.divisionId,
        isDraft: isDraft,
      );

      state = state.copyWith(
        isLoading: false,
        createdListing: listing,
      );

      return listing;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Reset state
  void reset() {
    _imageService.cleanupTempFiles(state.selectedImages);
    state = const CreateListingStateV2();
  }
}

/// Create listing provider with new category system
final createListingProviderV2 =
    StateNotifierProvider.autoDispose<CreateListingNotifierV2, CreateListingStateV2>(
  (ref) {
    final repository = ref.watch(listingApiRepositoryProvider);
    final imageService = ref.watch(imageServiceProvider);
    final storageService = ref.watch(storageServiceProvider);
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.uid ?? '';
    return CreateListingNotifierV2(repository, imageService, storageService, userId);
  },
);
