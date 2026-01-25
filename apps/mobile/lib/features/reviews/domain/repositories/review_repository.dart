import '../entities/review.dart';

/// Repository interface for review operations
abstract class ReviewRepository {
  /// Get reviews for a user (reviews they received)
  Future<List<Review>> getReviewsForUser(String userId, {int limit = 20});

  /// Get reviews by a user (reviews they wrote)
  Future<List<Review>> getReviewsByUser(String reviewerId, {int limit = 20});

  /// Get a single review by ID
  Future<Review?> getReviewById(String reviewId);

  /// Check if user can review another user for a specific listing
  Future<bool> canReview({
    required String reviewerId,
    required String revieweeId,
    required String listingId,
  });

  /// Create a new review
  Future<Review> createReview({
    required String reviewerId,
    required String reviewerName,
    String? reviewerPhotoUrl,
    required String revieweeId,
    required String listingId,
    required String listingTitle,
    required int rating,
    String? comment,
    required ReviewType type,
  });

  /// Get user's rating summary
  Future<UserRating> getUserRating(String userId);

  /// Stream of user's rating (for real-time updates)
  Stream<UserRating> getUserRatingStream(String userId);
}
