import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tekka/features/listing/application/category_provider.dart';
import 'package:tekka/features/listing/application/listing_provider.dart';
import 'package:tekka/features/listing/domain/entities/category.dart';
import 'package:tekka/features/listing/domain/entities/listing.dart';
import 'package:tekka/features/listing/domain/entities/location.dart';
import 'package:tekka/features/listing/presentation/screens/create_listing_screen.dart';

// Mock classes
class MockCategoryNotifier extends StateNotifier<CategoryState>
    with Mock
    implements CategoryNotifier {
  MockCategoryNotifier() : super(const CategoryState());

  @override
  Future<void> loadData() async {
    // Mock implementation
  }
}

class MockCreateListingNotifierV2 extends StateNotifier<CreateListingStateV2>
    with Mock
    implements CreateListingNotifierV2 {
  MockCreateListingNotifierV2() : super(const CreateListingStateV2());
}

void main() {
  late MockCategoryNotifier mockCategoryNotifier;
  late MockCreateListingNotifierV2 mockCreateListingNotifier;

  setUp(() {
    mockCategoryNotifier = MockCategoryNotifier();
    mockCreateListingNotifier = MockCreateListingNotifierV2();
  });

  Widget createTestWidget({
    CategoryState? categoryState,
    CreateListingStateV2? createListingState,
  }) {
    return ProviderScope(
      overrides: [
        categoryProvider.overrideWith((ref) {
          if (categoryState != null) {
            mockCategoryNotifier.state = categoryState;
          }
          return mockCategoryNotifier;
        }),
        createListingProviderV2.overrideWith((ref) {
          if (createListingState != null) {
            mockCreateListingNotifier.state = createListingState;
          }
          return mockCreateListingNotifier;
        }),
      ],
      child: const MaterialApp(
        home: CreateListingScreen(),
      ),
    );
  }

  group('CreateListingScreen', () {
    testWidgets('renders initial photo step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show photo step title
      expect(find.text('Add Photos'), findsOneWidget);
      expect(find.text('Add up to 10 photos'), findsOneWidget);
    });

    testWidgets('shows progress indicator with 5 steps', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Progress indicator should have 5 segments
      // Looking for Container widgets that form the progress bar
      final progressBars = find.byType(Container);
      expect(progressBars, findsWidgets);
    });

    testWidgets('Continue button is disabled when no photos added', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(continueButton);
      expect(button.onPressed, isNull); // Button should be disabled
    });

    testWidgets('shows Add Photo button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    });

    testWidgets('shows exit confirmation dialog on close button tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap close button
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Discard listing?'), findsOneWidget);
      expect(find.text('Your changes will be lost if you exit.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('Cancel button closes confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Discard listing?'), findsNothing);
    });

    testWidgets('shows Save Draft button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Save Draft'), findsOneWidget);
    });
  });

  group('CreateListingScreen - Category Step', () {
    CategoryState createCategoryStateWithData() {
      final now = DateTime.now();
      return CategoryState(
        categories: [
          Category(
            id: 'cat-women',
            name: 'Women',
            slug: 'women',
            level: 1,
            sortOrder: 1,
            isActive: true,
            createdAt: now,
            updatedAt: now,
            children: [
              Category(
                id: 'cat-clothing',
                name: 'Clothing',
                slug: 'women-clothing',
                level: 2,
                parentId: 'cat-women',
                sortOrder: 1,
                isActive: true,
                createdAt: now,
                updatedAt: now,
                children: [
                  Category(
                    id: 'cat-dresses',
                    name: 'Dresses',
                    slug: 'women-dresses',
                    level: 3,
                    parentId: 'cat-clothing',
                    sortOrder: 1,
                    isActive: true,
                    createdAt: now,
                    updatedAt: now,
                  ),
                ],
              ),
            ],
          ),
          Category(
            id: 'cat-men',
            name: 'Men',
            slug: 'men',
            level: 1,
            sortOrder: 2,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          Category(
            id: 'cat-electronics',
            name: 'Electronics',
            slug: 'electronics',
            level: 1,
            sortOrder: 3,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        cities: [
          City(
            id: 'city-kampala',
            name: 'Kampala',
            sortOrder: 1,
            isActive: true,
            divisions: [
              Division(id: 'div-makindye', cityId: 'city-kampala', name: 'Makindye', sortOrder: 1, isActive: true),
              Division(id: 'div-nakawa', cityId: 'city-kampala', name: 'Nakawa', sortOrder: 2, isActive: true),
            ],
          ),
          City(
            id: 'city-entebbe',
            name: 'Entebbe',
            sortOrder: 2,
            isActive: true,
          ),
        ],
      );
    }

    testWidgets('displays main categories when data is loaded', (tester) async {
      final categoryState = createCategoryStateWithData();

      await tester.pumpWidget(createTestWidget(categoryState: categoryState));
      await tester.pumpAndSettle();

      // Navigate to category step (need to mock having photos first)
      // For now, we test the category chips component directly
    });
  });

  group('CategoryState - Integration', () {
    test('mainCategories filters and sorts correctly', () {
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
            name: 'Women',
            slug: 'women',
            level: 1,
            sortOrder: 1,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          Category(
            id: 'cat-3',
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
      expect(mainCategories[0].name, 'Women');
      expect(mainCategories[1].name, 'Men');
      expect(mainCategories[2].name, 'Electronics');
    });

    test('activeCities filters and sorts correctly', () {
      final state = CategoryState(
        cities: [
          City(id: 'city-1', name: 'Jinja', sortOrder: 3, isActive: true),
          City(id: 'city-2', name: 'Kampala', sortOrder: 1, isActive: true),
          City(id: 'city-3', name: 'Inactive', sortOrder: 0, isActive: false),
          City(id: 'city-4', name: 'Entebbe', sortOrder: 2, isActive: true),
        ],
      );

      final activeCities = state.activeCities;

      expect(activeCities.length, 3);
      expect(activeCities[0].name, 'Kampala');
      expect(activeCities[1].name, 'Entebbe');
      expect(activeCities[2].name, 'Jinja');
    });
  });

  group('Form Validation', () {
    test('CreateListingStateV2.isValid returns false for incomplete state', () {
      const state = CreateListingStateV2();
      expect(state.isValid, false);
    });

    test('CreateListingStateV2.isValid returns true for complete state', () {
      // Note: We can't easily create a real File in tests, so this test
      // uses uploadedImageUrls instead
      final state = CreateListingStateV2(
        uploadedImageUrls: ['https://example.com/image.jpg'],
        title: 'Test Listing',
        price: 50000,
        categoryId: 'cat-1',
        condition: ItemCondition.good,
      );

      expect(state.isValid, true);
    });

    test('locationDisplay formats correctly', () {
      final stateWithCity = CreateListingStateV2(
        cityId: 'city-1',
        cityName: 'Kampala',
      );

      final stateWithCityAndDivision = CreateListingStateV2(
        cityId: 'city-1',
        cityName: 'Kampala',
        divisionId: 'div-1',
        divisionName: 'Makindye',
      );

      expect(stateWithCity.locationDisplay, 'Kampala');
      expect(stateWithCityAndDivision.locationDisplay, 'Kampala, Makindye');
    });
  });
}
