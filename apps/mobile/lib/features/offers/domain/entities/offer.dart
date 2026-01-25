/// Status of an offer
enum OfferStatus {
  pending('Pending'),
  accepted('Accepted'),
  declined('Declined'),
  countered('Countered'),
  expired('Expired'),
  withdrawn('Withdrawn');

  final String displayName;
  const OfferStatus(this.displayName);
}

/// Represents an offer on a listing
class Offer {
  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final int listingPrice;
  final String buyerId;
  final String buyerName;
  final String? buyerPhotoUrl;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final int amount;
  final String? message;
  final OfferStatus status;
  final int? counterAmount; // If seller counters
  final String? counterMessage;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;
  final String? chatId; // Associated chat if any

  const Offer({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    this.listingImageUrl,
    required this.listingPrice,
    required this.buyerId,
    required this.buyerName,
    this.buyerPhotoUrl,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    required this.amount,
    this.message,
    this.status = OfferStatus.pending,
    this.counterAmount,
    this.counterMessage,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
    this.chatId,
  });

  /// Check if offer is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt) && status == OfferStatus.pending;

  /// Get actual status considering expiry
  OfferStatus get effectiveStatus => isExpired ? OfferStatus.expired : status;

  /// Calculate discount percentage
  int get discountPercent {
    if (listingPrice <= 0) return 0;
    return (((listingPrice - amount) / listingPrice) * 100).round();
  }

  /// Get formatted amount
  String get formattedAmount => 'UGX ${_formatNumber(amount)}';

  /// Get formatted listing price
  String get formattedListingPrice => 'UGX ${_formatNumber(listingPrice)}';

  /// Get formatted counter amount
  String? get formattedCounterAmount =>
      counterAmount != null ? 'UGX ${_formatNumber(counterAmount!)}' : null;

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  /// Get time remaining until expiry
  String get timeRemaining {
    if (effectiveStatus != OfferStatus.pending) return '';

    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Expiring soon';
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Offer copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    int? listingPrice,
    String? buyerId,
    String? buyerName,
    String? buyerPhotoUrl,
    String? sellerId,
    String? sellerName,
    String? sellerPhotoUrl,
    int? amount,
    String? message,
    OfferStatus? status,
    int? counterAmount,
    String? counterMessage,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
    String? chatId,
  }) {
    return Offer(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      listingPrice: listingPrice ?? this.listingPrice,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhotoUrl: buyerPhotoUrl ?? this.buyerPhotoUrl,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhotoUrl: sellerPhotoUrl ?? this.sellerPhotoUrl,
      amount: amount ?? this.amount,
      message: message ?? this.message,
      status: status ?? this.status,
      counterAmount: counterAmount ?? this.counterAmount,
      counterMessage: counterMessage ?? this.counterMessage,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      chatId: chatId ?? this.chatId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImageUrl': listingImageUrl,
      'listingPrice': listingPrice,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhotoUrl': buyerPhotoUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhotoUrl': sellerPhotoUrl,
      'amount': amount,
      'message': message,
      'status': status.name,
      'counterAmount': counterAmount,
      'counterMessage': counterMessage,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'chatId': chatId,
    };
  }

  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'] as String,
      listingId: map['listingId'] as String,
      listingTitle: map['listingTitle'] as String,
      listingImageUrl: map['listingImageUrl'] as String?,
      listingPrice: map['listingPrice'] as int,
      buyerId: map['buyerId'] as String,
      buyerName: map['buyerName'] as String,
      buyerPhotoUrl: map['buyerPhotoUrl'] as String?,
      sellerId: map['sellerId'] as String,
      sellerName: map['sellerName'] as String,
      sellerPhotoUrl: map['sellerPhotoUrl'] as String?,
      amount: map['amount'] as int,
      message: map['message'] as String?,
      status: OfferStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OfferStatus.pending,
      ),
      counterAmount: map['counterAmount'] as int?,
      counterMessage: map['counterMessage'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'] as String)
          : null,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      chatId: map['chatId'] as String?,
    );
  }

  /// Create from API JSON response
  factory Offer.fromJson(Map<String, dynamic> json) {
    // Handle embedded objects from API
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final seller = json['seller'] as Map<String, dynamic>?;
    final listing = json['listing'] as Map<String, dynamic>?;

    // Parse status from API format (uppercase)
    OfferStatus parseStatus(String? value) {
      if (value == null) return OfferStatus.pending;
      return OfferStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () => OfferStatus.pending,
      );
    }

    return Offer(
      id: json['id'] as String,
      listingId: listing?['id'] ?? json['listingId'] as String,
      listingTitle: listing?['title'] ?? json['listingTitle'] as String? ?? 'Item',
      listingImageUrl: listing?['imageUrls']?[0] ?? json['listingImageUrl'] as String?,
      listingPrice: listing?['price'] ?? json['listingPrice'] as int? ?? 0,
      buyerId: buyer?['id'] ?? json['buyerId'] as String,
      buyerName: buyer?['displayName'] ?? json['buyerName'] as String? ?? 'Buyer',
      buyerPhotoUrl: buyer?['photoUrl'] ?? json['buyerPhotoUrl'] as String?,
      sellerId: seller?['id'] ?? json['sellerId'] as String,
      sellerName: seller?['displayName'] ?? json['sellerName'] as String? ?? 'Seller',
      sellerPhotoUrl: seller?['photoUrl'] ?? json['sellerPhotoUrl'] as String?,
      amount: json['amount'] as int,
      message: json['message'] as String?,
      status: parseStatus(json['status'] as String?),
      counterAmount: json['counterAmount'] as int?,
      counterMessage: json['counterMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      chatId: json['chatId'] as String?,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'listingId': listingId,
      'amount': amount,
      if (message != null) 'message': message,
      if (chatId != null) 'chatId': chatId,
    };
  }
}

/// Request to create an offer
class CreateOfferRequest {
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final int listingPrice;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final int amount;
  final String? message;
  final String? chatId;

  const CreateOfferRequest({
    required this.listingId,
    required this.listingTitle,
    this.listingImageUrl,
    required this.listingPrice,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    required this.amount,
    this.message,
    this.chatId,
  });
}
