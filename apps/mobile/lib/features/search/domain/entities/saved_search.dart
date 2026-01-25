/// Saved search entity for search alerts
class SavedSearch {
  final String id;
  final String query;
  final String? categoryId;
  final String? categoryName;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final String? condition;
  final bool notificationsEnabled;
  final int newMatchCount;
  final DateTime createdAt;
  final DateTime? lastNotifiedAt;

  const SavedSearch({
    required this.id,
    required this.query,
    this.categoryId,
    this.categoryName,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.condition,
    this.notificationsEnabled = true,
    this.newMatchCount = 0,
    required this.createdAt,
    this.lastNotifiedAt,
  });

  SavedSearch copyWith({
    String? id,
    String? query,
    String? categoryId,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? condition,
    bool? notificationsEnabled,
    int? newMatchCount,
    DateTime? createdAt,
    DateTime? lastNotifiedAt,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
      condition: condition ?? this.condition,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      newMatchCount: newMatchCount ?? this.newMatchCount,
      createdAt: createdAt ?? this.createdAt,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
    );
  }

  /// Get a display-friendly summary of the search filters
  String get filterSummary {
    final parts = <String>[];

    if (categoryName != null) {
      parts.add(categoryName!);
    }

    if (minPrice != null && maxPrice != null) {
      parts.add('UGX ${_formatPrice(minPrice!)} - ${_formatPrice(maxPrice!)}');
    } else if (minPrice != null) {
      parts.add('Min UGX ${_formatPrice(minPrice!)}');
    } else if (maxPrice != null) {
      parts.add('Max UGX ${_formatPrice(maxPrice!)}');
    }

    if (location != null) {
      parts.add(location!);
    }

    if (condition != null) {
      parts.add(condition!);
    }

    return parts.isEmpty ? 'All items' : parts.join(' • ');
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'location': location,
      'condition': condition,
      'notificationsEnabled': notificationsEnabled,
      'newMatchCount': newMatchCount,
      'createdAt': createdAt.toIso8601String(),
      'lastNotifiedAt': lastNotifiedAt?.toIso8601String(),
    };
  }

  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    return SavedSearch(
      id: map['id'] as String,
      query: map['query'] as String,
      categoryId: map['categoryId'] as String?,
      categoryName: map['categoryName'] as String?,
      minPrice: (map['minPrice'] as num?)?.toDouble(),
      maxPrice: (map['maxPrice'] as num?)?.toDouble(),
      location: map['location'] as String?,
      condition: map['condition'] as String?,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      newMatchCount: map['newMatchCount'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastNotifiedAt: map['lastNotifiedAt'] != null
          ? DateTime.parse(map['lastNotifiedAt'] as String)
          : null,
    );
  }

  /// Factory for parsing API JSON response
  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      query: json['query'] as String,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      location: json['location'] as String?,
      condition: json['condition'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      newMatchCount: json['newMatchCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastNotifiedAt: json['lastNotifiedAt'] != null
          ? DateTime.parse(json['lastNotifiedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();
}
