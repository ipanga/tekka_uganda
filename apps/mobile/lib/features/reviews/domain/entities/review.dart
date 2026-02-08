/// Review entity representing a user review
class Review {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final String revieweeId;
  final String? listingId;
  final String? listingTitle;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final ReviewType type;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.revieweeId,
    this.listingId,
    this.listingTitle,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.type,
  });

  /// Factory for parsing API JSON response
  factory Review.fromJson(Map<String, dynamic> json) {
    // API returns embedded reviewer and listing objects
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    final listing = json['listing'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String,
      reviewerId: reviewer?['id'] ?? json['reviewerId'] as String,
      reviewerName:
          reviewer?['displayName'] ??
          json['reviewerName'] as String? ??
          'Unknown',
      reviewerPhotoUrl:
          reviewer?['photoUrl'] ?? json['reviewerPhotoUrl'] as String?,
      revieweeId: json['revieweeId'] as String,
      listingId: listing?['id'] ?? json['listingId'] as String?,
      listingTitle: listing?['title'] ?? json['listingTitle'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: _parseReviewType(json['type'] as String?),
    );
  }

  static ReviewType _parseReviewType(String? type) {
    if (type == null) return ReviewType.seller;
    switch (type.toUpperCase()) {
      case 'BUYER':
        return ReviewType.buyer;
      case 'SELLER':
      default:
        return ReviewType.seller;
    }
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'revieweeId': revieweeId,
      'listingId': listingId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    DateTime createdAt;
    if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else {
      createdAt = DateTime.now();
    }

    return Review(
      id: map['id'] as String,
      reviewerId: map['reviewerId'] as String,
      reviewerName: map['reviewerName'] as String,
      reviewerPhotoUrl: map['reviewerPhotoUrl'] as String?,
      revieweeId: map['revieweeId'] as String,
      listingId: map['listingId'] as String?,
      listingTitle: map['listingTitle'] as String?,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      createdAt: createdAt,
      type: ReviewType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReviewType.seller,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'revieweeId': revieweeId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
    };
  }

  Review copyWith({
    String? id,
    String? reviewerId,
    String? reviewerName,
    String? reviewerPhotoUrl,
    String? revieweeId,
    String? listingId,
    String? listingTitle,
    int? rating,
    String? comment,
    DateTime? createdAt,
    ReviewType? type,
  }) {
    return Review(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerPhotoUrl: reviewerPhotoUrl ?? this.reviewerPhotoUrl,
      revieweeId: revieweeId ?? this.revieweeId,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }
}

/// Type of review
enum ReviewType { seller, buyer }

/// User rating summary
class UserRating {
  final String userId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  const UserRating({
    required this.userId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory UserRating.empty(String userId) {
    return UserRating(
      userId: userId,
      averageRating: 0.0,
      totalReviews: 0,
      ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }

  /// Factory for parsing API JSON response
  factory UserRating.fromJson(String userId, Map<String, dynamic> json) {
    final distributionRaw = json['distribution'] as Map<String, dynamic>? ?? {};
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    distributionRaw.forEach((key, value) {
      final rating = int.tryParse(key);
      if (rating != null && rating >= 1 && rating <= 5) {
        distribution[rating] = value as int? ?? 0;
      }
    });

    return UserRating(
      userId: userId,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      ratingDistribution: distribution,
    );
  }

  factory UserRating.fromReviews(String userId, List<Review> reviews) {
    if (reviews.isEmpty) {
      return UserRating.empty(userId);
    }

    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    int totalRating = 0;

    for (final review in reviews) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      totalRating += review.rating;
    }

    return UserRating(
      userId: userId,
      averageRating: totalRating / reviews.length,
      totalReviews: reviews.length,
      ratingDistribution: distribution,
    );
  }
}
