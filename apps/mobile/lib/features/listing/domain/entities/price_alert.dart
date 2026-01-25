/// Price alert entity for tracking price drops on favorited items
class PriceAlert {
  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final String sellerName;
  final int originalPrice;
  final int newPrice;
  final int priceDropAmount;
  final double priceDropPercent;
  final DateTime createdAt;
  final bool isRead;
  final bool isExpired; // If the item is sold or unavailable

  const PriceAlert({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    this.listingImageUrl,
    required this.sellerName,
    required this.originalPrice,
    required this.newPrice,
    required this.priceDropAmount,
    required this.priceDropPercent,
    required this.createdAt,
    this.isRead = false,
    this.isExpired = false,
  });

  PriceAlert copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    String? sellerName,
    int? originalPrice,
    int? newPrice,
    int? priceDropAmount,
    double? priceDropPercent,
    DateTime? createdAt,
    bool? isRead,
    bool? isExpired,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      sellerName: sellerName ?? this.sellerName,
      originalPrice: originalPrice ?? this.originalPrice,
      newPrice: newPrice ?? this.newPrice,
      priceDropAmount: priceDropAmount ?? this.priceDropAmount,
      priceDropPercent: priceDropPercent ?? this.priceDropPercent,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  String get formattedOriginalPrice => 'UGX ${_formatNumber(originalPrice)}';
  String get formattedNewPrice => 'UGX ${_formatNumber(newPrice)}';
  String get formattedDropAmount => 'UGX ${_formatNumber(priceDropAmount)}';
  String get formattedDropPercent => '${priceDropPercent.toStringAsFixed(0)}%';

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImageUrl': listingImageUrl,
      'sellerName': sellerName,
      'originalPrice': originalPrice,
      'newPrice': newPrice,
      'priceDropAmount': priceDropAmount,
      'priceDropPercent': priceDropPercent,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isExpired': isExpired,
    };
  }

  factory PriceAlert.fromMap(Map<String, dynamic> map) {
    return PriceAlert(
      id: map['id'] as String,
      listingId: map['listingId'] as String,
      listingTitle: map['listingTitle'] as String,
      listingImageUrl: map['listingImageUrl'] as String?,
      sellerName: map['sellerName'] as String,
      originalPrice: map['originalPrice'] as int,
      newPrice: map['newPrice'] as int,
      priceDropAmount: map['priceDropAmount'] as int,
      priceDropPercent: (map['priceDropPercent'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isRead: map['isRead'] as bool? ?? false,
      isExpired: map['isExpired'] as bool? ?? false,
    );
  }

  /// Factory for parsing API JSON response
  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    // Handle embedded listing object from API
    final listing = json['listing'] as Map<String, dynamic>?;
    final imageUrls = listing?['imageUrls'] as List<dynamic>?;
    final listingImageUrl = imageUrls?.isNotEmpty == true
        ? imageUrls!.first as String
        : json['listingImageUrl'] as String?;

    return PriceAlert(
      id: json['id'] as String,
      listingId: listing?['id'] ?? json['listingId'] as String,
      listingTitle: json['listingTitle'] as String,
      listingImageUrl: listingImageUrl,
      sellerName: json['sellerName'] as String,
      originalPrice: json['originalPrice'] as int,
      newPrice: json['newPrice'] as int,
      priceDropAmount: json['priceDropAmount'] as int,
      priceDropPercent: (json['priceDropPercent'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isExpired: json['isExpired'] as bool? ?? false,
    );
  }
}
