import 'package:flutter_test/flutter_test.dart';
import 'package:tekka/features/listing/application/category_provider.dart';
import 'package:tekka/features/listing/domain/entities/category.dart';
import 'package:tekka/features/listing/domain/entities/location.dart';

void main() {
  group('CategoryState', () {
    test('default state has empty lists and is not loading', () {
      const state = CategoryState();

      expect(state.categories, isEmpty);
      expect(state.cities, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('copyWith updates specified fields', () {
      const state = CategoryState();
      final now = DateTime.now();

      final categories = [
        Category(
          id: 'cat-1',
          name: 'Women',
          slug: 'women',
          level: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final cities = [
        City(id: 'city-1', name: 'Kampala'),
      ];

      final newState = state.copyWith(
        categories: categories,
        cities: cities,
        isLoading: true,
        error: 'Test error',
      );

      expect(newState.categories, equals(categories));
      expect(newState.cities, equals(cities));
      expect(newState.isLoading, true);
      expect(newState.error, 'Test error');
    });

    test('copyWith preserves unspecified fields', () {
      final now = DateTime.now();
      final categories = [
        Category(
          id: 'cat-1',
          name: 'Women',
          slug: 'women',
          level: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = CategoryState(categories: categories, isLoading: true);
      final newState = state.copyWith(error: 'Error');

      expect(newState.categories, equals(categories));
      expect(newState.isLoading, true);
      expect(newState.error, 'Error');
    });

    test('copyWith clears error when set to null', () {
      final state = CategoryState(error: 'Previous error');
      final newState = state.copyWith(error: null);

      expect(newState.error, isNull);
    });

    group('mainCategories', () {
      test('returns only level 1 active categories sorted by sortOrder', () {
        final now = DateTime.now();
        final state = CategoryState(
          categories: [
            Category(
              id: 'cat-1',
              name: 'Electronics',
              slug: 'electronics',
              level: 1,
              sortOrder: 5,
              isActive: true,
              createdAt: now,
              updatedAt: now,
            ),
            Category(
              id: 'cat-2',
              name: 'Sub Category',
              slug: 'sub',
              level: 2,
              sortOrder: 1,
              isActive: true,
              createdAt: now,
              updatedAt: now,
            ),
            Category(
              id: 'cat-3',
              name: 'Women',
              slug: 'women',
              level: 1,
              sortOrder: 1,
              isActive: true,
              createdAt: now,
              updatedAt: now,
            ),
            Category(
              id: 'cat-4',
              name: 'Inactive Main',
              slug: 'inactive',
              level: 1,
              sortOrder: 2,
              isActive: false,
              createdAt: now,
              updatedAt: now,
            ),
            Category(
              id: 'cat-5',
              name: 'Men',
              slug: 'men',
              level: 1,
              sortOrder: 2,
              isActive: true,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        final mainCategories = state.mainCategories;

        expect(mainCategories.length, 3);
        expect(mainCategories[0].name, 'Women'); // sortOrder: 1
        expect(mainCategories[1].name, 'Men'); // sortOrder: 2
        expect(mainCategories[2].name, 'Electronics'); // sortOrder: 5
      });

      test('returns empty list when no level 1 categories', () {
        final now = DateTime.now();
        final state = CategoryState(
          categories: [
            Category(
              id: 'cat-1',
              name: 'Sub Category',
              slug: 'sub',
              level: 2,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        expect(state.mainCategories, isEmpty);
      });
    });

    group('getSubCategories', () {
      test('returns active children of specified parent category', () {
        final now = DateTime.now();
        final subCategories = [
          Category(
            id: 'sub-1',
            name: 'Clothing',
            slug: 'clothing',
            level: 2,
            parentId: 'cat-1',
            sortOrder: 1,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          Category(
            id: 'sub-2',
            name: 'Shoes',
            slug: 'shoes',
            level: 2,
            parentId: 'cat-1',
            sortOrder: 2,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          Category(
            id: 'sub-3',
            name: 'Inactive',
            slug: 'inactive',
            level: 2,
            parentId: 'cat-1',
            sortOrder: 3,
            isActive: false,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final state = CategoryState(
          categories: [
            Category(
              id: 'cat-1',
              name: 'Women',
              slug: 'women',
              level: 1,
              createdAt: now,
              updatedAt: now,
              children: subCategories,
            ),
          ],
        );

        final children = state.getSubCategories('cat-1');

        expect(children.length, 2);
        expect(children[0].name, 'Clothing');
        expect(children[1].name, 'Shoes');
      });

      test('throws exception when parent not found', () {
        const state = CategoryState();

        expect(
          () => state.getSubCategories('non-existent'),
          throwsException,
        );
      });
    });

    group('activeCities', () {
      test('returns only active cities sorted by sortOrder', () {
        final state = CategoryState(
          cities: [
            City(id: 'city-1', name: 'Jinja', sortOrder: 3, isActive: true),
            City(id: 'city-2', name: 'Inactive', sortOrder: 1, isActive: false),
            City(id: 'city-3', name: 'Kampala', sortOrder: 1, isActive: true),
            City(id: 'city-4', name: 'Entebbe', sortOrder: 2, isActive: true),
          ],
        );

        final activeCities = state.activeCities;

        expect(activeCities.length, 3);
        expect(activeCities[0].name, 'Kampala'); // sortOrder: 1
        expect(activeCities[1].name, 'Entebbe'); // sortOrder: 2
        expect(activeCities[2].name, 'Jinja'); // sortOrder: 3
      });

      test('returns empty list when no active cities', () {
        final state = CategoryState(
          cities: [
            City(id: 'city-1', name: 'Inactive', isActive: false),
          ],
        );

        expect(state.activeCities, isEmpty);
      });
    });
  });
}
