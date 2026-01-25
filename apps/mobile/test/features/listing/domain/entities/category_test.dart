import 'package:flutter_test/flutter_test.dart';
import 'package:tekka/features/listing/domain/entities/category.dart';

void main() {
  group('AttributeType', () {
    test('fromApi converts SINGLE_SELECT correctly', () {
      expect(AttributeType.fromApi('SINGLE_SELECT'), AttributeType.singleSelect);
    });

    test('fromApi converts MULTI_SELECT correctly', () {
      expect(AttributeType.fromApi('MULTI_SELECT'), AttributeType.multiSelect);
    });

    test('fromApi converts TEXT correctly', () {
      expect(AttributeType.fromApi('TEXT'), AttributeType.text);
    });

    test('fromApi converts NUMBER correctly', () {
      expect(AttributeType.fromApi('NUMBER'), AttributeType.number);
    });

    test('fromApi handles lowercase input', () {
      expect(AttributeType.fromApi('single_select'), AttributeType.singleSelect);
    });

    test('fromApi defaults to text for unknown values', () {
      expect(AttributeType.fromApi('UNKNOWN'), AttributeType.text);
    });

    test('apiValue returns correct string', () {
      expect(AttributeType.singleSelect.apiValue, 'SINGLE_SELECT');
      expect(AttributeType.multiSelect.apiValue, 'MULTI_SELECT');
      expect(AttributeType.text.apiValue, 'TEXT');
      expect(AttributeType.number.apiValue, 'NUMBER');
    });
  });

  group('AttributeValue', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 'attr-val-1',
        'attributeId': 'attr-1',
        'value': 'M',
        'displayValue': 'Medium',
        'sortOrder': 2,
        'isActive': true,
        'metadata': {'hex': '#000000'},
      };

      final attributeValue = AttributeValue.fromJson(json);

      expect(attributeValue.id, 'attr-val-1');
      expect(attributeValue.attributeId, 'attr-1');
      expect(attributeValue.value, 'M');
      expect(attributeValue.displayValue, 'Medium');
      expect(attributeValue.sortOrder, 2);
      expect(attributeValue.isActive, true);
      expect(attributeValue.metadata?['hex'], '#000000');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'attr-val-1',
        'attributeId': 'attr-1',
        'value': 'S',
      };

      final attributeValue = AttributeValue.fromJson(json);

      expect(attributeValue.displayValue, isNull);
      expect(attributeValue.sortOrder, 0);
      expect(attributeValue.isActive, true);
      expect(attributeValue.metadata, isNull);
    });

    test('display returns displayValue when available', () {
      final attributeValue = AttributeValue(
        id: '1',
        attributeId: '1',
        value: 'M',
        displayValue: 'Medium',
      );

      expect(attributeValue.display, 'Medium');
    });

    test('display returns value when displayValue is null', () {
      final attributeValue = AttributeValue(
        id: '1',
        attributeId: '1',
        value: 'M',
      );

      expect(attributeValue.display, 'M');
    });

    test('toJson returns correct map', () {
      final attributeValue = AttributeValue(
        id: 'attr-val-1',
        attributeId: 'attr-1',
        value: 'M',
        displayValue: 'Medium',
        sortOrder: 2,
        isActive: true,
      );

      final json = attributeValue.toJson();

      expect(json['id'], 'attr-val-1');
      expect(json['attributeId'], 'attr-1');
      expect(json['value'], 'M');
      expect(json['displayValue'], 'Medium');
      expect(json['sortOrder'], 2);
      expect(json['isActive'], true);
    });
  });

  group('AttributeDefinition', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 'attr-1',
        'name': 'Size',
        'slug': 'size',
        'type': 'SINGLE_SELECT',
        'isRequired': true,
        'sortOrder': 1,
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
        'values': [
          {'id': 'v1', 'attributeId': 'attr-1', 'value': 'S'},
          {'id': 'v2', 'attributeId': 'attr-1', 'value': 'M'},
          {'id': 'v3', 'attributeId': 'attr-1', 'value': 'L'},
        ],
      };

      final attribute = AttributeDefinition.fromJson(json);

      expect(attribute.id, 'attr-1');
      expect(attribute.name, 'Size');
      expect(attribute.slug, 'size');
      expect(attribute.type, AttributeType.singleSelect);
      expect(attribute.isRequired, true);
      expect(attribute.sortOrder, 1);
      expect(attribute.isActive, true);
      expect(attribute.values.length, 3);
      expect(attribute.values[0].value, 'S');
      expect(attribute.values[1].value, 'M');
      expect(attribute.values[2].value, 'L');
    });

    test('fromJson handles empty values array', () {
      final json = {
        'id': 'attr-1',
        'name': 'Brand',
        'slug': 'brand',
        'type': 'TEXT',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final attribute = AttributeDefinition.fromJson(json);

      expect(attribute.values, isEmpty);
      expect(attribute.type, AttributeType.text);
    });

    test('toJson returns correct map', () {
      final now = DateTime.now();
      final attribute = AttributeDefinition(
        id: 'attr-1',
        name: 'Size',
        slug: 'size',
        type: AttributeType.singleSelect,
        isRequired: true,
        sortOrder: 1,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        values: [
          AttributeValue(id: 'v1', attributeId: 'attr-1', value: 'S'),
        ],
      );

      final json = attribute.toJson();

      expect(json['id'], 'attr-1');
      expect(json['name'], 'Size');
      expect(json['slug'], 'size');
      expect(json['type'], 'SINGLE_SELECT');
      expect(json['isRequired'], true);
      expect(json['values'], isA<List>());
      expect((json['values'] as List).length, 1);
    });
  });

  group('CategoryAttribute', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 'cat-attr-1',
        'categoryId': 'cat-1',
        'attributeId': 'attr-1',
        'isRequired': true,
        'sortOrder': 1,
        'attribute': {
          'id': 'attr-1',
          'name': 'Size',
          'slug': 'size',
          'type': 'SINGLE_SELECT',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        },
      };

      final categoryAttribute = CategoryAttribute.fromJson(json);

      expect(categoryAttribute.id, 'cat-attr-1');
      expect(categoryAttribute.categoryId, 'cat-1');
      expect(categoryAttribute.attributeId, 'attr-1');
      expect(categoryAttribute.isRequired, true);
      expect(categoryAttribute.sortOrder, 1);
      expect(categoryAttribute.attribute, isNotNull);
      expect(categoryAttribute.attribute!.name, 'Size');
    });

    test('fromJson handles missing attribute', () {
      final json = {
        'id': 'cat-attr-1',
        'categoryId': 'cat-1',
        'attributeId': 'attr-1',
      };

      final categoryAttribute = CategoryAttribute.fromJson(json);

      expect(categoryAttribute.attribute, isNull);
      expect(categoryAttribute.isRequired, false);
      expect(categoryAttribute.sortOrder, 0);
    });
  });

  group('Category', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 'cat-1',
        'name': 'Women',
        'slug': 'women',
        'level': 1,
        'parentId': null,
        'imageUrl': 'https://example.com/women.jpg',
        'iconName': 'woman',
        'sortOrder': 1,
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
        'children': [
          {
            'id': 'cat-2',
            'name': 'Clothing',
            'slug': 'women-clothing',
            'level': 2,
            'parentId': 'cat-1',
            'sortOrder': 1,
            'isActive': true,
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z',
          },
        ],
      };

      final category = Category.fromJson(json);

      expect(category.id, 'cat-1');
      expect(category.name, 'Women');
      expect(category.slug, 'women');
      expect(category.level, 1);
      expect(category.parentId, isNull);
      expect(category.imageUrl, 'https://example.com/women.jpg');
      expect(category.iconName, 'woman');
      expect(category.sortOrder, 1);
      expect(category.isActive, true);
      expect(category.children.length, 1);
      expect(category.children[0].name, 'Clothing');
      expect(category.children[0].level, 2);
    });

    test('isMainCategory returns true for level 1', () {
      final category = Category(
        id: '1',
        name: 'Women',
        slug: 'women',
        level: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(category.isMainCategory, true);
      expect(category.isSubCategory, false);
      expect(category.isProductType, false);
    });

    test('isSubCategory returns true for level 2', () {
      final category = Category(
        id: '1',
        name: 'Clothing',
        slug: 'clothing',
        level: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(category.isMainCategory, false);
      expect(category.isSubCategory, true);
      expect(category.isProductType, false);
    });

    test('isProductType returns true for level 3', () {
      final category = Category(
        id: '1',
        name: 'Dresses',
        slug: 'dresses',
        level: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(category.isMainCategory, false);
      expect(category.isSubCategory, false);
      expect(category.isProductType, true);
    });

    test('hasChildren returns correct value', () {
      final categoryWithChildren = Category(
        id: '1',
        name: 'Women',
        slug: 'women',
        level: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        children: [
          Category(
            id: '2',
            name: 'Clothing',
            slug: 'clothing',
            level: 2,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final categoryWithoutChildren = Category(
        id: '1',
        name: 'Dresses',
        slug: 'dresses',
        level: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(categoryWithChildren.hasChildren, true);
      expect(categoryWithoutChildren.hasChildren, false);
    });

    test('activeChildren filters inactive and sorts by sortOrder', () {
      final now = DateTime.now();
      final category = Category(
        id: '1',
        name: 'Women',
        slug: 'women',
        level: 1,
        createdAt: now,
        updatedAt: now,
        children: [
          Category(
            id: '2',
            name: 'Shoes',
            slug: 'shoes',
            level: 2,
            sortOrder: 3,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          Category(
            id: '3',
            name: 'Inactive',
            slug: 'inactive',
            level: 2,
            sortOrder: 1,
            isActive: false,
            createdAt: now,
            updatedAt: now,
          ),
          Category(
            id: '4',
            name: 'Clothing',
            slug: 'clothing',
            level: 2,
            sortOrder: 1,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
          Category(
            id: '5',
            name: 'Bags',
            slug: 'bags',
            level: 2,
            sortOrder: 2,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final activeChildren = category.activeChildren;

      expect(activeChildren.length, 3);
      expect(activeChildren[0].name, 'Clothing'); // sortOrder: 1
      expect(activeChildren[1].name, 'Bags'); // sortOrder: 2
      expect(activeChildren[2].name, 'Shoes'); // sortOrder: 3
    });

    test('equality based on id', () {
      final now = DateTime.now();
      final category1 = Category(
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        createdAt: now,
        updatedAt: now,
      );

      final category2 = Category(
        id: 'cat-1',
        name: 'Women Updated',
        slug: 'women-updated',
        level: 1,
        createdAt: now,
        updatedAt: now,
      );

      final category3 = Category(
        id: 'cat-2',
        name: 'Women',
        slug: 'women',
        level: 1,
        createdAt: now,
        updatedAt: now,
      );

      expect(category1, equals(category2)); // Same ID
      expect(category1, isNot(equals(category3))); // Different ID
    });

    test('toJson returns correct map', () {
      final now = DateTime.now();
      final category = Category(
        id: 'cat-1',
        name: 'Women',
        slug: 'women',
        level: 1,
        sortOrder: 1,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        children: [
          Category(
            id: 'cat-2',
            name: 'Clothing',
            slug: 'clothing',
            level: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final json = category.toJson();

      expect(json['id'], 'cat-1');
      expect(json['name'], 'Women');
      expect(json['slug'], 'women');
      expect(json['level'], 1);
      expect(json['children'], isA<List>());
      expect((json['children'] as List).length, 1);
    });
  });
}
