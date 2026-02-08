import '../../../../core/services/api_client.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/location.dart';

/// Repository for category and location API calls
class CategoryApiRepository {
  final ApiClient _apiClient;

  CategoryApiRepository(this._apiClient);

  // ============================================
  // CATEGORY ENDPOINTS
  // ============================================

  /// Get all categories (hierarchical tree)
  Future<List<Category>> getCategories() async {
    final response = await _apiClient.get<List<dynamic>>('/categories');
    return response
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single category by ID
  Future<Category> getCategory(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/categories/$id',
    );
    return Category.fromJson(response);
  }

  /// Get a category by slug
  Future<Category> getCategoryBySlug(String slug) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/categories/slug/$slug',
    );
    return Category.fromJson(response);
  }

  /// Get children of a category
  Future<List<Category>> getCategoryChildren(String id) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/categories/$id/children',
    );
    return response
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get attributes for a category (includes inherited attributes)
  Future<List<AttributeDefinition>> getCategoryAttributes(
    String categoryId,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/categories/$categoryId/attributes',
    );
    return response
        .map((e) => AttributeDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get breadcrumb path for a category
  Future<List<Category>> getCategoryBreadcrumb(String id) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/categories/$id/breadcrumb',
    );
    return response
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================
  // ATTRIBUTE ENDPOINTS
  // ============================================

  /// Get all attribute definitions
  Future<List<AttributeDefinition>> getAttributes() async {
    final response = await _apiClient.get<List<dynamic>>('/attributes');
    return response
        .map((e) => AttributeDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get an attribute by slug with its values
  Future<AttributeDefinition> getAttributeBySlug(String slug) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/attributes/$slug',
    );
    return AttributeDefinition.fromJson(response);
  }

  /// Get values for an attribute
  Future<AttributeDefinition> getAttributeValues(String slug) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/attributes/$slug/values',
    );
    return AttributeDefinition.fromJson(response);
  }

  // ============================================
  // LOCATION ENDPOINTS
  // ============================================

  /// Get all cities
  Future<List<City>> getCities() async {
    final response = await _apiClient.get<List<dynamic>>('/locations/cities');
    return response
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all cities with their divisions
  Future<List<City>> getCitiesWithDivisions() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/locations/cities/with-divisions',
    );
    return response
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get divisions for a city
  Future<List<Division>> getDivisions(String cityId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/locations/cities/$cityId/divisions',
    );
    return response
        .map((e) => Division.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
