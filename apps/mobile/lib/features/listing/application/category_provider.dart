import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../domain/entities/category.dart';
import '../domain/entities/location.dart';

/// State for category data
class CategoryState {
  final List<Category> categories;
  final List<City> cities;
  final bool isLoading;
  final String? error;

  const CategoryState({
    this.categories = const [],
    this.cities = const [],
    this.isLoading = false,
    this.error,
  });

  CategoryState copyWith({
    List<Category>? categories,
    List<City>? cities,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      cities: cities ?? this.cities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get main categories (Level 1)
  List<Category> get mainCategories =>
      categories.where((c) => c.level == 1 && c.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Get sub-categories for a main category
  List<Category> getSubCategories(String parentId) {
    final parent = categories.firstWhere(
      (c) => c.id == parentId,
      orElse: () => throw Exception('Category not found'),
    );
    return parent.activeChildren;
  }

  /// Get active cities
  List<City> get activeCities =>
      cities.where((c) => c.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

/// Notifier for category data
class CategoryNotifier extends StateNotifier<CategoryState> {
  final Ref _ref;

  CategoryNotifier(this._ref) : super(const CategoryState());

  /// Load categories and cities
  Future<void> loadData() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final categoryRepo = _ref.read(categoryApiRepositoryProvider);

      final results = await Future.wait([
        categoryRepo.getCategories(),
        categoryRepo.getCitiesWithDivisions(),
      ]);

      state = state.copyWith(
        categories: results[0] as List<Category>,
        cities: results[1] as List<City>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get attributes for a category
  Future<List<AttributeDefinition>> getAttributesForCategory(
    String categoryId,
  ) async {
    final categoryRepo = _ref.read(categoryApiRepositoryProvider);
    return categoryRepo.getCategoryAttributes(categoryId);
  }
}

/// Provider for category data
final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>(
  (ref) {
    return CategoryNotifier(ref);
  },
);

/// Provider for category attributes (by category ID)
final categoryAttributesProvider =
    FutureProvider.family<List<AttributeDefinition>, String>((
      ref,
      categoryId,
    ) async {
      final categoryRepo = ref.watch(categoryApiRepositoryProvider);
      return categoryRepo.getCategoryAttributes(categoryId);
    });
