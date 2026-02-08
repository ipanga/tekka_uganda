/// Attribute type enum
enum AttributeType {
  singleSelect('SINGLE_SELECT'),
  multiSelect('MULTI_SELECT'),
  text('TEXT'),
  number('NUMBER');

  final String apiValue;
  const AttributeType(this.apiValue);

  static AttributeType fromApi(String value) {
    return AttributeType.values.firstWhere(
      (e) => e.apiValue == value.toUpperCase(),
      orElse: () => AttributeType.text,
    );
  }
}

/// Attribute value (option within an attribute)
class AttributeValue {
  final String? id;
  final String? attributeId;
  final String value;
  final String? displayValue;
  final int sortOrder;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const AttributeValue({
    this.id,
    this.attributeId,
    required this.value,
    this.displayValue,
    this.sortOrder = 0,
    this.isActive = true,
    this.metadata,
  });

  /// Display text (uses displayValue if available, otherwise value)
  String get display => displayValue ?? value;

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      id: json['id'] as String?,
      attributeId: json['attributeId'] as String?,
      value: json['value'] as String,
      displayValue: json['displayValue'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'attributeId': attributeId,
    'value': value,
    'displayValue': displayValue,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'metadata': metadata,
  };
}

/// Attribute definition (e.g., "Size", "Brand", "Color")
class AttributeDefinition {
  final String id;
  final String name;
  final String slug;
  final AttributeType type;
  final bool isRequired;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AttributeValue> values;

  const AttributeDefinition({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    this.isRequired = false,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.values = const [],
  });

  factory AttributeDefinition.fromJson(Map<String, dynamic> json) {
    final valuesJson = json['values'] as List<dynamic>? ?? [];
    return AttributeDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      type: AttributeType.fromApi(json['type'] as String),
      isRequired: json['isRequired'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      values: valuesJson
          .map((e) => AttributeValue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'type': type.apiValue,
    'isRequired': isRequired,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'values': values.map((v) => v.toJson()).toList(),
  };
}

/// Category-attribute mapping
class CategoryAttribute {
  final String id;
  final String categoryId;
  final String attributeId;
  final bool isRequired;
  final int sortOrder;
  final AttributeDefinition? attribute;

  const CategoryAttribute({
    required this.id,
    required this.categoryId,
    required this.attributeId,
    this.isRequired = false,
    this.sortOrder = 0,
    this.attribute,
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    return CategoryAttribute(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      attributeId: json['attributeId'] as String,
      isRequired: json['isRequired'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      attribute: json['attribute'] != null
          ? AttributeDefinition.fromJson(
              json['attribute'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Hierarchical category (Women > Clothing > Dresses)
class Category {
  final String id;
  final String name;
  final String slug;
  final int level; // 1 = Main, 2 = Sub, 3 = ProductType
  final String? parentId;
  final String? imageUrl;
  final String? iconName;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? parent;
  final List<Category> children;
  final List<CategoryAttribute> attributes;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.level,
    this.parentId,
    this.imageUrl,
    this.iconName,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.parent,
    this.children = const [],
    this.attributes = const [],
  });

  /// Check if this is a main category (Level 1)
  bool get isMainCategory => level == 1;

  /// Check if this is a sub-category (Level 2)
  bool get isSubCategory => level == 2;

  /// Check if this is a product type (Level 3)
  bool get isProductType => level == 3;

  /// Check if this category has children
  bool get hasChildren => children.isNotEmpty;

  /// Get active children only
  List<Category> get activeChildren =>
      children.where((c) => c.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  factory Category.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    final attributesJson = json['attributes'] as List<dynamic>? ?? [];

    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      level: json['level'] as int,
      parentId: json['parentId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      iconName: json['iconName'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      parent: json['parent'] != null
          ? Category.fromJson(json['parent'] as Map<String, dynamic>)
          : null,
      children: childrenJson
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      attributes: attributesJson
          .map((e) => CategoryAttribute.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'level': level,
    'parentId': parentId,
    'imageUrl': imageUrl,
    'iconName': iconName,
    'sortOrder': sortOrder,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'children': children.map((c) => c.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
