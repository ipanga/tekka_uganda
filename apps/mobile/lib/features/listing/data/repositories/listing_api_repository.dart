import '../../../../core/services/api_client.dart';
import '../../domain/entities/listing.dart';

/// Paginated response from API
class PaginatedListings {
  final List<Listing> listings;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  PaginatedListings({
    required this.listings,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory PaginatedListings.fromJson(Map<String, dynamic> json) {
    // Handle backend response format: { listings: [...], pagination: {...} }
    final listingsData =
        json['listings'] as List<dynamic>? ??
        json['data'] as List<dynamic>? ??
        [];
    final pagination = json['pagination'] as Map<String, dynamic>?;

    final page = pagination?['page'] as int? ?? json['page'] as int? ?? 1;
    final limit = pagination?['limit'] as int? ?? json['limit'] as int? ?? 20;
    final total = pagination?['total'] as int? ?? json['total'] as int? ?? 0;
    final totalPages =
        pagination?['totalPages'] as int? ?? json['totalPages'] as int? ?? 1;

    return PaginatedListings(
      listings: listingsData
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
      page: page,
      limit: limit,
      hasMore: page < totalPages,
    );
  }
}

/// Repository for listing-related API calls
class ListingApiRepository {
  final ApiClient _apiClient;

  ListingApiRepository(this._apiClient);

  /// Search/browse listings
  Future<PaginatedListings> search({
    String? query,
    ListingCategory? category,
    String? categoryId, // New hierarchical category ID
    ItemCondition? condition,
    Occasion? occasion,
    int? minPrice,
    int? maxPrice,
    String? location,
    String? cityId,
    String? divisionId,
    String? sellerId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (query != null && query.isNotEmpty) queryParams['search'] = query;
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (category != null && categoryId == null)
      queryParams['category'] = category.apiValue;
    if (condition != null) queryParams['condition'] = condition.apiValue;
    if (occasion != null) queryParams['occasion'] = occasion.apiValue;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (location != null) queryParams['location'] = location;
    if (cityId != null) queryParams['cityId'] = cityId;
    if (divisionId != null) queryParams['divisionId'] = divisionId;
    if (sellerId != null) queryParams['sellerId'] = sellerId;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/listings',
      queryParameters: queryParams,
    );
    return PaginatedListings.fromJson(response);
  }

  /// Get current user's listings
  Future<List<Listing>> getMyListings({ListingStatus? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status.apiValue;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/listings/my',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    // Backend returns { data: [...], total, ... }
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get saved/favorited listings
  Future<List<Listing>> getSavedListings() async {
    final response = await _apiClient.get<List<dynamic>>('/listings/saved');
    return response
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific listing by ID
  Future<Listing> getById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/listings/$id',
    );
    return Listing.fromJson(response);
  }

  /// Create a new listing (legacy method - kept for backward compatibility)
  Future<Listing> create({
    required String title,
    required String description,
    required int price,
    required ListingCategory category,
    required ItemCondition condition,
    required List<String> imageUrls,
    String? size,
    String? brand,
    String? color,
    String? material,
    String? location,
    Occasion? occasion,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/listings',
      data: {
        'title': title,
        'description': description,
        'price': price,
        'category': category.apiValue,
        'condition': condition.apiValue,
        'imageUrls': imageUrls,
        if (size != null) 'size': size,
        if (brand != null) 'brand': brand,
        if (color != null) 'color': color,
        if (material != null) 'material': material,
        if (location != null) 'location': location,
        if (occasion != null) 'occasion': occasion.apiValue,
      },
    );
    return Listing.fromJson(response);
  }

  /// Create a new listing with new hierarchical category system
  Future<Listing> createWithCategory({
    required String title,
    required String description,
    required int price,
    int? originalPrice,
    required ItemCondition condition,
    required List<String> imageUrls,
    required String categoryId,
    Map<String, dynamic>? attributes,
    String? cityId,
    String? divisionId,
    bool isDraft = false,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/listings',
      data: {
        'title': title,
        'description': description,
        'price': price,
        if (originalPrice != null) 'originalPrice': originalPrice,
        'condition': condition.apiValue,
        'imageUrls': imageUrls,
        'categoryId': categoryId,
        if (attributes != null) 'attributes': attributes,
        if (cityId != null) 'cityId': cityId,
        if (divisionId != null) 'divisionId': divisionId,
        'isDraft': isDraft,
      },
    );
    return Listing.fromJson(response);
  }

  /// Search/browse listings with new category system
  Future<PaginatedListings> searchWithCategory({
    String? query,
    String? categoryId, // New hierarchical category ID
    ItemCondition? condition,
    int? minPrice,
    int? maxPrice,
    String? cityId,
    String? divisionId,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (query != null && query.isNotEmpty) queryParams['search'] = query;
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (condition != null) queryParams['condition'] = condition.apiValue;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (cityId != null) queryParams['cityId'] = cityId;
    if (divisionId != null) queryParams['divisionId'] = divisionId;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/listings',
      queryParameters: queryParams,
    );
    return PaginatedListings.fromJson(response);
  }

  /// Update an existing listing
  Future<Listing> update(
    String id, {
    String? title,
    String? description,
    int? price,
    ListingCategory? category,
    ItemCondition? condition,
    List<String>? imageUrls,
    String? size,
    String? brand,
    String? color,
    String? material,
    String? location,
    Occasion? occasion,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (category != null) data['category'] = category.apiValue;
    if (condition != null) data['condition'] = condition.apiValue;
    if (imageUrls != null) data['imageUrls'] = imageUrls;
    if (size != null) data['size'] = size;
    if (brand != null) data['brand'] = brand;
    if (color != null) data['color'] = color;
    if (material != null) data['material'] = material;
    if (location != null) data['location'] = location;
    if (occasion != null) data['occasion'] = occasion.apiValue;

    final response = await _apiClient.put<Map<String, dynamic>>(
      '/listings/$id',
      data: data,
    );
    return Listing.fromJson(response);
  }

  /// Update an existing listing with new hierarchical category system
  Future<Listing> updateWithCategory(
    String id, {
    String? title,
    String? description,
    int? price,
    ItemCondition? condition,
    List<String>? imageUrls,
    String? categoryId,
    Map<String, dynamic>? attributes,
    String? cityId,
    String? divisionId,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (condition != null) data['condition'] = condition.apiValue;
    if (imageUrls != null) data['imageUrls'] = imageUrls;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (attributes != null) data['attributes'] = attributes;
    if (cityId != null) data['cityId'] = cityId;
    if (divisionId != null) data['divisionId'] = divisionId;

    final response = await _apiClient.put<Map<String, dynamic>>(
      '/listings/$id',
      data: data,
    );
    return Listing.fromJson(response);
  }

  /// Delete a listing
  Future<void> delete(String id) async {
    await _apiClient.delete('/listings/$id');
  }

  /// Publish a draft listing (DRAFT → PENDING)
  Future<void> publishDraft(String id) async {
    await _apiClient.post<Map<String, dynamic>>('/listings/$id/publish');
  }

  /// Archive a listing
  Future<Listing> archive(String id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/listings/$id/archive',
    );
    return Listing.fromJson(response);
  }

  /// Mark listing as sold
  Future<Listing> markAsSold(String id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/listings/$id/sold',
    );
    return Listing.fromJson(response);
  }

  /// Save/favorite a listing
  Future<void> save(String id) async {
    await _apiClient.post('/listings/$id/save');
  }

  /// Unsave/unfavorite a listing
  Future<void> unsave(String id) async {
    await _apiClient.delete('/listings/$id/save');
  }

  /// Check if a listing is saved
  Future<bool> isSaved(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/listings/$id/saved',
    );
    return response['isSaved'] as bool? ?? false;
  }

  /// Get listings by a specific seller
  Future<List<Listing>> getListingsBySeller(String sellerId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/listings/seller/$sellerId',
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get purchase history (items bought by current user)
  Future<List<Listing>> getPurchaseHistory() async {
    final response = await _apiClient.get<List<dynamic>>('/listings/purchases');
    return response
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Toggle favorite (returns new state)
  Future<bool> toggleFavorite(String id) async {
    final isSavedNow = await isSaved(id);
    if (isSavedNow) {
      await unsave(id);
      return false;
    } else {
      await save(id);
      return true;
    }
  }
}
