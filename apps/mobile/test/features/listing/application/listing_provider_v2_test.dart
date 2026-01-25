import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tekka/features/listing/application/listing_provider.dart';
import 'package:tekka/features/listing/domain/entities/listing.dart';

void main() {
  group('CreateListingStateV2', () {
    test('default state has correct initial values', () {
      const state = CreateListingStateV2();

      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.selectedImages, isEmpty);
      expect(state.uploadedImageUrls, isEmpty);
      expect(state.title, isNull);
      expect(state.description, isNull);
      expect(state.price, isNull);
      expect(state.condition, isNull);
      expect(state.categoryId, isNull);
      expect(state.categoryName, isNull);
      expect(state.attributes, isEmpty);
      expect(state.cityId, isNull);
      expect(state.cityName, isNull);
      expect(state.divisionId, isNull);
      expect(state.divisionName, isNull);
      expect(state.createdListing, isNull);
    });

    test('copyWith updates specified fields', () {
      const state = CreateListingStateV2();

      final newState = state.copyWith(
        isLoading: true,
        title: 'Test Title',
        description: 'Test Description',
        price: 50000,
        condition: ItemCondition.good,
        categoryId: 'cat-1',
        categoryName: 'Dresses',
        attributes: {'size': 'M', 'color': ['Red', 'Blue']},
        cityId: 'city-1',
        cityName: 'Kampala',
        divisionId: 'div-1',
        divisionName: 'Makindye',
      );

      expect(newState.isLoading, true);
      expect(newState.title, 'Test Title');
      expect(newState.description, 'Test Description');
      expect(newState.price, 50000);
      expect(newState.condition, ItemCondition.good);
      expect(newState.categoryId, 'cat-1');
      expect(newState.categoryName, 'Dresses');
      expect(newState.attributes['size'], 'M');
      expect(newState.attributes['color'], ['Red', 'Blue']);
      expect(newState.cityId, 'city-1');
      expect(newState.cityName, 'Kampala');
      expect(newState.divisionId, 'div-1');
      expect(newState.divisionName, 'Makindye');
    });

    test('copyWith preserves unspecified fields', () {
      final state = CreateListingStateV2(
        title: 'Existing Title',
        price: 30000,
        categoryId: 'cat-1',
      );

      final newState = state.copyWith(
        condition: ItemCondition.newWithTags,
      );

      expect(newState.title, 'Existing Title');
      expect(newState.price, 30000);
      expect(newState.categoryId, 'cat-1');
      expect(newState.condition, ItemCondition.newWithTags);
    });

    test('copyWith clears error when set to null', () {
      final state = CreateListingStateV2(error: 'Previous error');
      final newState = state.copyWith(error: null);

      expect(newState.error, isNull);
    });

    group('isValid', () {
      test('returns false when images are empty', () {
        final state = CreateListingStateV2(
          title: 'Test',
          price: 50000,
          categoryId: 'cat-1',
          condition: ItemCondition.good,
        );

        expect(state.isValid, false);
      });

      test('returns false when title is null', () {
        final tempFile = File('test.jpg');
        final state = CreateListingStateV2(
          selectedImages: [tempFile],
          price: 50000,
          categoryId: 'cat-1',
          condition: ItemCondition.good,
        );

        expect(state.isValid, false);
      });

      test('returns false when title is empty', () {
        final tempFile = File('test.jpg');
        final state = CreateListingStateV2(
          selectedImages: [tempFile],
          title: '',
          price: 50000,
          categoryId: 'cat-1',
          condition: ItemCondition.good,
        );

        expect(state.isValid, false);
      });

      test('returns false when price is null', () {
        final tempFile = File('test.jpg');
        final state = CreateListingStateV2(
          selectedImages: [tempFile],
          title: 'Test',
          categoryId: 'cat-1',
          condition: ItemCondition.good,
        );

        expect(state.isValid, false);
      });

      test('returns false when price is zero or negative', () {
        final tempFile = File('test.jpg');
        final stateZero = CreateListingStateV2(
          selectedImages: [tempFile],
          title: 'Test',
          price: 0,
          categoryId: 'cat-1',
          condition: ItemCondition.good,
        );

        final stateNegative = CreateListingStateV2(
          selectedImages: [tempFile],
          title: 'Test',
          price: -100,
          categoryId: 'cat-1',
          condition: ItemCondition.good,
        );

        expect(stateZero.isValid, false);
        expect(stateNegative.isValid, false);
      });

      test('returns false when categoryId is null', () {
        final tempFile = File('test.jpg');
        final state = CreateListingStateV2(
          selectedImages: [tempFile],
          title: 'Test',
          price: 50000,
          condition: ItemCondition.good,
        );

        expect(state.isValid, false);
      });

      test('returns false when condition is null', () {
        final tempFile = File('test.jpg');
        final state = CreateListingStateV2(
          selectedImages: [tempFile],
          title: 'Test',
          price: 50000,
          categoryId: 'cat-1',
        );

        expect(state.isValid, false);
      });

      test('returns true when all required fields are set with selectedImages', () {
        final tempFile = File('test.jpg');
        final state = CreateListingStateV2(
          selectedImages: [tempFile],
          title: 'Test Title',
          price: 50000,
          categoryId: 'cat-1',
          condition: ItemCondition.good,
        );

        expect(state.isValid, true);
      });

      test('returns true when all required fields are set with uploadedImageUrls', () {
        final state = CreateListingStateV2(
          uploadedImageUrls: ['https://example.com/image.jpg'],
          title: 'Test Title',
          price: 50000,
          categoryId: 'cat-1',
          condition: ItemCondition.good,
        );

        expect(state.isValid, true);
      });
    });

    group('locationDisplay', () {
      test('returns empty string when cityName is null', () {
        const state = CreateListingStateV2();

        expect(state.locationDisplay, '');
      });

      test('returns city name only when division is null', () {
        final state = CreateListingStateV2(
          cityId: 'city-1',
          cityName: 'Kampala',
        );

        expect(state.locationDisplay, 'Kampala');
      });

      test('returns city and division when both are set', () {
        final state = CreateListingStateV2(
          cityId: 'city-1',
          cityName: 'Kampala',
          divisionId: 'div-1',
          divisionName: 'Makindye',
        );

        expect(state.locationDisplay, 'Kampala, Makindye');
      });
    });
  });

  group('ListingsFilter', () {
    test('default values are correct', () {
      const filter = ListingsFilter();

      expect(filter.category, isNull);
      expect(filter.condition, isNull);
      expect(filter.occasion, isNull);
      expect(filter.location, isNull);
      expect(filter.minPrice, isNull);
      expect(filter.maxPrice, isNull);
      expect(filter.searchQuery, isNull);
      expect(filter.sortBy, isNull);
      expect(filter.sortOrder, isNull);
      expect(filter.page, 1);
      expect(filter.limit, 20);
    });

    test('copyWith updates specified fields', () {
      const filter = ListingsFilter();

      final newFilter = filter.copyWith(
        category: ListingCategory.dresses,
        condition: ItemCondition.newWithTags,
        minPrice: 10000,
        maxPrice: 100000,
        searchQuery: 'dress',
        page: 2,
      );

      expect(newFilter.category, ListingCategory.dresses);
      expect(newFilter.condition, ItemCondition.newWithTags);
      expect(newFilter.minPrice, 10000);
      expect(newFilter.maxPrice, 100000);
      expect(newFilter.searchQuery, 'dress');
      expect(newFilter.page, 2);
      expect(newFilter.limit, 20); // preserved
    });

    test('equality works correctly', () {
      const filter1 = ListingsFilter(
        category: ListingCategory.dresses,
        page: 1,
      );

      const filter2 = ListingsFilter(
        category: ListingCategory.dresses,
        page: 1,
      );

      const filter3 = ListingsFilter(
        category: ListingCategory.tops,
        page: 1,
      );

      expect(filter1, equals(filter2));
      expect(filter1, isNot(equals(filter3)));
    });

    test('hashCode is consistent with equality', () {
      const filter1 = ListingsFilter(
        category: ListingCategory.dresses,
        minPrice: 10000,
      );

      const filter2 = ListingsFilter(
        category: ListingCategory.dresses,
        minPrice: 10000,
      );

      expect(filter1.hashCode, equals(filter2.hashCode));
    });
  });
}
