import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';
import '../data/repositories/review_api_repository.dart';
import '../domain/entities/review.dart';
import '../domain/repositories/review_repository.dart';

/// Review repository provider - uses API backend
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReviewApiRepository(apiClient);
});

/// Reviews for a specific user (reviews they received)
final userReviewsProvider = FutureProvider.family<List<Review>, String>((ref, userId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewsForUser(userId);
});

/// Reviews written by a specific user
final reviewsByUserProvider = FutureProvider.family<List<Review>, String>((ref, userId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getReviewsByUser(userId);
});

/// User rating summary
final userRatingProvider = FutureProvider.family<UserRating, String>((ref, userId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getUserRating(userId);
});

/// User rating stream (real-time updates)
final userRatingStreamProvider = StreamProvider.family<UserRating, String>((ref, userId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getUserRatingStream(userId);
});

/// Check if current user can review another user for a listing
final canReviewProvider = FutureProvider.family<bool, CanReviewParams>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final repository = ref.watch(reviewRepositoryProvider);
  return repository.canReview(
    reviewerId: user.uid,
    revieweeId: params.revieweeId,
    listingId: params.listingId,
  );
});

/// Parameters for canReviewProvider
class CanReviewParams {
  final String revieweeId;
  final String listingId;

  const CanReviewParams({
    required this.revieweeId,
    required this.listingId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanReviewParams &&
          runtimeType == other.runtimeType &&
          revieweeId == other.revieweeId &&
          listingId == other.listingId;

  @override
  int get hashCode => revieweeId.hashCode ^ listingId.hashCode;
}

/// Create review notifier
class CreateReviewNotifier extends StateNotifier<CreateReviewState> {
  final ReviewRepository _repository;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  CreateReviewNotifier(
    this._repository,
    this.userId,
    this.userName,
    this.userPhotoUrl,
  ) : super(const CreateReviewState());

  void setRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void setComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  Future<bool> submit({
    required String revieweeId,
    required String listingId,
    required String listingTitle,
    required ReviewType type,
  }) async {
    if (state.rating == 0) {
      state = state.copyWith(error: 'Please select a rating');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.createReview(
        reviewerId: userId,
        reviewerName: userName,
        reviewerPhotoUrl: userPhotoUrl,
        revieweeId: revieweeId,
        listingId: listingId,
        listingTitle: listingTitle,
        rating: state.rating,
        comment: state.comment.isEmpty ? null : state.comment,
        type: type,
      );

      state = state.copyWith(isLoading: false, isSubmitted: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const CreateReviewState();
  }
}

/// Create review state
class CreateReviewState {
  final int rating;
  final String comment;
  final bool isLoading;
  final bool isSubmitted;
  final String? error;

  const CreateReviewState({
    this.rating = 0,
    this.comment = '',
    this.isLoading = false,
    this.isSubmitted = false,
    this.error,
  });

  CreateReviewState copyWith({
    int? rating,
    String? comment,
    bool? isLoading,
    bool? isSubmitted,
    String? error,
  }) {
    return CreateReviewState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      error: error,
    );
  }
}

/// Create review provider
final createReviewProvider =
    StateNotifierProvider.autoDispose<CreateReviewNotifier, CreateReviewState>((ref) {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(reviewRepositoryProvider);

  return CreateReviewNotifier(
    repository,
    user?.uid ?? '',
    user?.displayName ?? 'User',
    user?.photoUrl,
  );
});
