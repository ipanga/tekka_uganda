import '../entities/review.dart';

/// Repository interface for review operations
abstract class ReviewRepository {
  /// Get reviews for a user (reviews they received)
  Future<List<Review>> getReviewsForUser(String userId, {int limit = 20});

  /// Get reviews by a user (reviews they wrote)
  Future<List<Review>> getReviewsByUser(String reviewerId, {int limit = 20});

  /// Get a single review by ID
  Future<Review?> getReviewById(String reviewId);

  /// Check if user can review another user (optionally for a specific listing)
  Future<bool> canReview({
    required String reviewerId,
    required String revieweeId,
    String? listingId,
  });

  /// Create a new review
  /// Note: listingId is now optional - users can review sellers without a specific listing
  Future<Review> createReview({
    required String reviewerId,
    required String reviewerName,
    String? reviewerPhotoUrl,
    required String revieweeId,
    String? listingId,
    String? listingTitle,
    required int rating,
    String? comment,
    required ReviewType type,
  });

  /// Update an existing review
  Future<Review> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  });

  /// Get existing review by current user for a specific reviewee
  Future<Review?> getExistingReview({
    required String reviewerId,
    required String revieweeId,
  });

  /// Get user's rating summary
  Future<UserRating> getUserRating(String userId);

  /// Stream of user's rating (for real-time updates)
  Stream<UserRating> getUserRatingStream(String userId);
}
