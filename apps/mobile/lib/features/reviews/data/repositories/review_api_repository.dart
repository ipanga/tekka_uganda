import 'dart:async';

import '../../../../core/services/api_client.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

/// API-based implementation of ReviewRepository
class ReviewApiRepository implements ReviewRepository {
  final ApiClient _apiClient;
  final Duration _pollInterval;

  ReviewApiRepository(this._apiClient, {Duration? pollInterval})
    : _pollInterval = pollInterval ?? const Duration(seconds: 30);

  @override
  Future<List<Review>> getReviewsForUser(
    String userId, {
    int limit = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/reviews/user/$userId',
      queryParameters: {'type': 'received', 'limit': limit},
    );
    final reviews = response['reviews'] as List<dynamic>? ?? [];
    return reviews
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Review>> getReviewsByUser(
    String reviewerId, {
    int limit = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/reviews/user/$reviewerId',
      queryParameters: {'type': 'given', 'limit': limit},
    );
    final reviews = response['reviews'] as List<dynamic>? ?? [];
    return reviews
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Review?> getReviewById(String reviewId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/reviews/$reviewId',
      );
      return Review.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> canReview({
    required String reviewerId,
    required String revieweeId,
    String? listingId,
  }) async {
    // Check if user has already reviewed this listing or seller
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/reviews/user/$reviewerId',
        queryParameters: {'type': 'given'},
      );
      final reviews = response['reviews'] as List<dynamic>? ?? [];

      if (listingId != null) {
        // Check for specific listing review
        return !reviews.any(
          (r) =>
              (r as Map<String, dynamic>)['listingId'] == listingId ||
              (r['listing'] as Map<String, dynamic>?)?['id'] == listingId,
        );
      } else {
        // Check if already reviewed this seller (any review)
        return !reviews.any(
          (r) => (r as Map<String, dynamic>)['revieweeId'] == revieweeId,
        );
      }
    } catch (_) {
      return true; // Assume can review if check fails
    }
  }

  @override
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
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/reviews',
      data: {
        'revieweeId': revieweeId,
        if (listingId != null) 'listingId': listingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );
    return Review.fromJson(response);
  }

  @override
  Future<UserRating> getUserRating(String userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/reviews/user/$userId/stats',
      );
      return UserRating.fromJson(userId, response);
    } catch (_) {
      return UserRating.empty(userId);
    }
  }

  @override
  Stream<UserRating> getUserRatingStream(String userId) {
    return _createPollingStream(
      () => getUserRating(userId),
      interval: _pollInterval,
    );
  }

  /// Helper to create a polling stream from an async function
  Stream<T> _createPollingStream<T>(
    Future<T> Function() fetcher, {
    required Duration interval,
  }) {
    late StreamController<T> controller;
    Timer? timer;
    bool isDisposed = false;

    Future<void> poll() async {
      if (isDisposed) return;
      try {
        final data = await fetcher();
        if (!isDisposed) {
          controller.add(data);
        }
      } catch (e) {
        if (!isDisposed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<T>(
      onListen: () {
        poll(); // Initial fetch
        timer = Timer.periodic(interval, (_) => poll());
      },
      onCancel: () {
        isDisposed = true;
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}
