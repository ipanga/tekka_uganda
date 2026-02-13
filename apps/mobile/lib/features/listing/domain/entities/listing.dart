/// Listing status
enum ListingStatus {
  draft,
  pending, // Awaiting moderation
  active,
  sold,
  archived,
  rejected;

  /// Get API value (uppercase)
  String get apiValue => name.toUpperCase();

  /// Parse from API string
  static ListingStatus fromApi(String value) {
    return ListingStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => ListingStatus.draft,
    );
  }
}

/// Item condition
enum ItemCondition {
  newWithTags('New with Tags', 'NEW'),
  likeNew('Like New', 'LIKE_NEW'),
  good('Good', 'GOOD'),
  fair('Fair', 'FAIR');

  final String displayName;
  final String apiValue;
  const ItemCondition(this.displayName, this.apiValue);

  /// Parse from API string
  static ItemCondition fromApi(String value) {
    return ItemCondition.values.firstWhere(
      (e) => e.apiValue == value.toUpperCase(),
      orElse: () => ItemCondition.good,
    );
  }
}

/// Listing category
enum ListingCategory {
  dresses('Dresses', 'DRESSES'),
  tops('Tops', 'TOPS'),
  bottoms('Bottoms', 'BOTTOMS'),
  traditionalWear('Traditional Wear', 'TRADITIONAL_WEAR'),
  shoes('Shoes', 'SHOES'),
  accessories('Accessories', 'ACCESSORIES'),
  bags('Bags', 'BAGS'),
  other('Other', 'OTHER');

  final String displayName;
  final String apiValue;
  const ListingCategory(this.displayName, this.apiValue);

  /// Parse from API string
  static ListingCategory fromApi(String value) {
    return ListingCategory.values.firstWhere(
      (e) => e.apiValue == value.toUpperCase(),
      orElse: () => ListingCategory.other,
    );
  }
}

/// Occasion tags for listings
enum Occasion {
  wedding('Wedding', 'WEDDING'),
  kwanjula('Kwanjula', 'KWANJULA'),
  church('Church', 'CHURCH'),
  corporate('Corporate/Office', 'CORPORATE'),
  casual('Casual', 'CASUAL'),
  party('Party/Night Out', 'PARTY'),
  graduation('Graduation', 'OTHER'),
  funeral('Funeral', 'OTHER'),
  everyday('Everyday', 'OTHER');

  final String displayName;
  final String apiValue;
  const Occasion(this.displayName, this.apiValue);

  /// Parse from API string
  static Occasion fromApi(String? value) {
    if (value == null) return Occasion.everyday;
    return Occasion.values.firstWhere(
      (e) => e.apiValue == value.toUpperCase(),
      orElse: () => Occasion.everyday,
    );
  }
}

/// Seller info embedded in listing
class SellerInfo {
  final String id;
  final String? displayName;
  final String? photoUrl;
  final String? location;
  final bool isVerified;

  const SellerInfo({
    required this.id,
    this.displayName,
    this.photoUrl,
    this.location,
    this.isVerified = false,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      location: json['location'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

/// Represents a fashion listing
class Listing {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final bool? sellerIsVerified;
  final String title;
  final String description;
  final int price; // In UGX
  final int? originalPrice;
  final ListingCategory
  category; // Legacy category (kept for backward compatibility)
  final String? size;
  final String? brand;
  final String? color;
  final String? material;
  final ItemCondition condition;
  final Occasion? occasion;
  final List<String> imageUrls;
  final String? location; // Legacy location (kept for backward compatibility)
  final ListingStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final int saveCount;
  final String? buyerId;
  final DateTime? soldAt;
  final DateTime? archivedAt;
  final bool isSaved; // Whether current user saved this listing
  final bool isFeatured; // Whether this listing is featured/promoted
  // New hierarchical category system fields
  final String? categoryId;
  final Map<String, dynamic>? attributes; // Dynamic attributes JSON
  final String? cityId;
  final String? divisionId;
  final String? cityName; // Resolved city name for display
  final String? divisionName; // Resolved division name for display
  final String? categoryName; // Resolved category name for display

  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    this.sellerIsVerified,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    this.size,
    this.brand,
    this.color,
    this.material,
    required this.condition,
    this.occasion,
    required this.imageUrls,
    this.location,
    this.status = ListingStatus.draft,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.saveCount = 0,
    this.buyerId,
    this.soldAt,
    this.archivedAt,
    this.isSaved = false,
    this.isFeatured = false,
    // New fields
    this.categoryId,
    this.attributes,
    this.cityId,
    this.divisionId,
    this.cityName,
    this.divisionName,
    this.categoryName,
  });

  /// Create a copy with updated fields
  Listing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? sellerPhotoUrl,
    bool? sellerIsVerified,
    String? title,
    String? description,
    int? price,
    int? originalPrice,
    ListingCategory? category,
    String? size,
    String? brand,
    String? color,
    String? material,
    ItemCondition? condition,
    Occasion? occasion,
    List<String>? imageUrls,
    String? location,
    ListingStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    int? saveCount,
    String? buyerId,
    DateTime? soldAt,
    DateTime? archivedAt,
    bool? isSaved,
    bool? isFeatured,
    String? categoryId,
    Map<String, dynamic>? attributes,
    String? cityId,
    String? divisionId,
    String? cityName,
    String? divisionName,
    String? categoryName,
  }) {
    return Listing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhotoUrl: sellerPhotoUrl ?? this.sellerPhotoUrl,
      sellerIsVerified: sellerIsVerified ?? this.sellerIsVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      material: material ?? this.material,
      condition: condition ?? this.condition,
      occasion: occasion ?? this.occasion,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      saveCount: saveCount ?? this.saveCount,
      buyerId: buyerId ?? this.buyerId,
      soldAt: soldAt ?? this.soldAt,
      archivedAt: archivedAt ?? this.archivedAt,
      isSaved: isSaved ?? this.isSaved,
      isFeatured: isFeatured ?? this.isFeatured,
      categoryId: categoryId ?? this.categoryId,
      attributes: attributes ?? this.attributes,
      cityId: cityId ?? this.cityId,
      divisionId: divisionId ?? this.divisionId,
      cityName: cityName ?? this.cityName,
      divisionName: divisionName ?? this.divisionName,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category.apiValue,
      'size': size,
      'brand': brand,
      'color': color,
      'material': material,
      'condition': condition.apiValue,
      'occasion': occasion?.apiValue,
      'imageUrls': imageUrls,
      'location': location,
      'status': status.apiValue,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'viewCount': viewCount,
      'saveCount': saveCount,
      'buyerId': buyerId,
      'soldAt': soldAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      // New fields
      if (categoryId != null) 'categoryId': categoryId,
      if (attributes != null) 'attributes': attributes,
      if (cityId != null) 'cityId': cityId,
      if (divisionId != null) 'divisionId': divisionId,
    };
  }

  /// Create from API response JSON
  factory Listing.fromJson(Map<String, dynamic> json) {
    // Handle seller info - can be embedded object or separate fields
    final seller = json['seller'] as Map<String, dynamic>?;
    final sellerId = seller?['id'] ?? json['sellerId'] as String;
    final sellerName =
        seller?['displayName'] ?? json['sellerName'] ?? 'Unknown';
    final sellerPhotoUrl = seller?['photoUrl'] ?? json['sellerPhotoUrl'];
    final sellerIsVerified = seller?['isVerified'] ?? json['sellerIsVerified'];

    // Handle category - new system has categoryData, legacy has category string
    final categoryData = json['categoryData'] as Map<String, dynamic>?;
    final categoryName = categoryData?['name'] as String?;

    // Handle location - new system has city/division objects
    final cityData = json['city'] as Map<String, dynamic>?;
    final divisionData = json['division'] as Map<String, dynamic>?;

    return Listing(
      id: json['id'] as String,
      sellerId: sellerId,
      sellerName: sellerName as String,
      sellerPhotoUrl: sellerPhotoUrl as String?,
      sellerIsVerified: sellerIsVerified as bool?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      originalPrice: json['originalPrice'] as int?,
      category: ListingCategory.fromApi(json['category'] as String? ?? 'OTHER'),
      size: json['size'] as String?,
      brand: json['brand'] as String?,
      color: json['color'] as String?,
      material: json['material'] as String?,
      condition: ItemCondition.fromApi(json['condition'] as String? ?? 'GOOD'),
      occasion: json['occasion'] != null
          ? Occasion.fromApi(json['occasion'] as String)
          : null,
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      location: json['location'] as String?,
      status: ListingStatus.fromApi(json['status'] as String? ?? 'DRAFT'),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      viewCount: json['viewCount'] as int? ?? 0,
      saveCount: json['saveCount'] as int? ?? 0,
      buyerId: json['buyerId'] as String?,
      soldAt: json['soldAt'] != null
          ? DateTime.parse(json['soldAt'] as String)
          : null,
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'] as String)
          : null,
      isSaved: json['isSaved'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      // New hierarchical category system fields
      categoryId: json['categoryId'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>?,
      cityId: json['cityId'] as String?,
      divisionId: json['divisionId'] as String?,
      cityName: cityData?['name'] as String?,
      divisionName: divisionData?['name'] as String?,
      categoryName: categoryName,
    );
  }

  /// Legacy map factory (for backward compatibility)
  factory Listing.fromMap(Map<String, dynamic> map) {
    // Try API format first, fall back to legacy
    if (map.containsKey('category') && map['category'] is String) {
      final categoryStr = map['category'] as String;
      if (categoryStr == categoryStr.toUpperCase()) {
        return Listing.fromJson(map);
      }
    }

    return Listing(
      id: map['id'] as String,
      sellerId: map['sellerId'] as String,
      sellerName: map['sellerName'] as String? ?? 'Unknown',
      sellerPhotoUrl: map['sellerPhotoUrl'] as String?,
      title: map['title'] as String,
      description: map['description'] as String,
      price: map['price'] as int,
      category: ListingCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ListingCategory.other,
      ),
      size: map['size'] as String?,
      condition: ItemCondition.values.firstWhere(
        (e) => e.name == map['condition'],
        orElse: () => ItemCondition.good,
      ),
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
      location: map['location'] as String?,
      status: ListingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ListingStatus.draft,
      ),
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      viewCount: map['viewCount'] as int? ?? 0,
      saveCount: map['favoriteCount'] as int? ?? map['saveCount'] as int? ?? 0,
      buyerId: map['buyerId'] as String?,
      soldAt: map['soldAt'] != null
          ? DateTime.parse(map['soldAt'] as String)
          : null,
    );
  }

  /// Convert to map (legacy)
  Map<String, dynamic> toMap() => toJson();

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get display location (prefers city/division, falls back to legacy location)
  String? get displayLocation {
    final parts = <String>[];
    if (divisionName != null && divisionName!.isNotEmpty) {
      parts.add(divisionName!);
    }
    if (cityName != null && cityName!.isNotEmpty) parts.add(cityName!);
    if (parts.isNotEmpty) return parts.join(', ');
    if (location != null && location!.isNotEmpty) return location;
    return null;
  }

  /// Get formatted price
  String get formattedPrice => 'UGX ${_formatNumber(price)}';

  /// Check if price dropped
  bool get hasPriceDrop => originalPrice != null && originalPrice! > price;

  /// Get price drop percentage
  int get priceDropPercent {
    if (!hasPriceDrop) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Alias for backward compatibility
  int get favoriteCount => saveCount;
}

/// Create listing request DTO
class CreateListingRequest {
  final String title;
  final String description;
  final int price;
  final ListingCategory? category; // Legacy - optional when using new system
  final String? size;
  final ItemCondition condition;
  final List<String> localImagePaths;
  final String? location; // Legacy - optional when using new system
  final Occasion? occasion;
  // New hierarchical category system
  final String? categoryId;
  final Map<String, dynamic>? attributes;
  final String? cityId;
  final String? divisionId;

  const CreateListingRequest({
    required this.title,
    required this.description,
    required this.price,
    this.category, // Made optional
    this.size,
    required this.condition,
    required this.localImagePaths,
    this.location, // Made optional
    this.occasion,
    // New fields
    this.categoryId,
    this.attributes,
    this.cityId,
    this.divisionId,
  });

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'condition': condition.apiValue,
      if (category != null) 'category': category!.apiValue,
      if (size != null) 'size': size,
      if (location != null) 'location': location,
      if (occasion != null) 'occasion': occasion!.apiValue,
      // New system fields
      if (categoryId != null) 'categoryId': categoryId,
      if (attributes != null) 'attributes': attributes,
      if (cityId != null) 'cityId': cityId,
      if (divisionId != null) 'divisionId': divisionId,
    };
  }
}
