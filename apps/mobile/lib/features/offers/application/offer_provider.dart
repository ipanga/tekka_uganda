import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';
import '../data/repositories/offer_api_repository.dart';
import '../domain/entities/offer.dart';
import '../domain/repositories/offer_repository.dart';

/// Offer repository provider - uses API backend
final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OfferApiRepository(apiClient);
});

/// Stream of offers made by current user (as buyer)
final myOffersStreamProvider = StreamProvider<List<Offer>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(offerRepositoryProvider);
  return repository.watchOffersByBuyer(user.uid);
});

/// Stream of offers received by current user (as seller)
final receivedOffersStreamProvider = StreamProvider<List<Offer>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(offerRepositoryProvider);
  return repository.watchOffersBySeller(user.uid);
});

/// Offers for a specific listing
final listingOffersProvider = FutureProvider.family<List<Offer>, String>(
  (ref, listingId) async {
    final repository = ref.watch(offerRepositoryProvider);
    return repository.getOffersForListing(listingId);
  },
);

/// Check if user has pending offer on listing
final hasPendingOfferProvider = FutureProvider.family<bool, String>(
  (ref, listingId) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return false;

    final repository = ref.watch(offerRepositoryProvider);
    return repository.hasPendingOffer(listingId, user.uid);
  },
);

/// Pending offers count for seller
final pendingOffersCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  final repository = ref.watch(offerRepositoryProvider);
  return repository.getPendingOffersCount(user.uid);
});

/// Single offer provider
final offerProvider = FutureProvider.family<Offer?, String>(
  (ref, offerId) async {
    final repository = ref.watch(offerRepositoryProvider);
    return repository.getOfferById(offerId);
  },
);

/// State for creating an offer
class CreateOfferState {
  final bool isLoading;
  final String? error;
  final int? amount;
  final String? message;
  final Offer? createdOffer;

  const CreateOfferState({
    this.isLoading = false,
    this.error,
    this.amount,
    this.message,
    this.createdOffer,
  });

  CreateOfferState copyWith({
    bool? isLoading,
    String? error,
    int? amount,
    String? message,
    Offer? createdOffer,
  }) {
    return CreateOfferState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      amount: amount ?? this.amount,
      message: message ?? this.message,
      createdOffer: createdOffer ?? this.createdOffer,
    );
  }
}

/// Notifier for creating offers
class CreateOfferNotifier extends StateNotifier<CreateOfferState> {
  final OfferRepository _repository;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  CreateOfferNotifier(
    this._repository,
    this.userId,
    this.userName,
    this.userPhotoUrl,
  ) : super(const CreateOfferState());

  void setAmount(int amount) {
    state = state.copyWith(amount: amount);
  }

  void setMessage(String? message) {
    state = state.copyWith(message: message);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<Offer?> createOffer(CreateOfferRequest request) async {
    if (state.amount == null || state.amount! <= 0) {
      state = state.copyWith(error: 'Please enter a valid offer amount');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final offer = await _repository.createOffer(
        CreateOfferRequest(
          listingId: request.listingId,
          listingTitle: request.listingTitle,
          listingImageUrl: request.listingImageUrl,
          listingPrice: request.listingPrice,
          sellerId: request.sellerId,
          sellerName: request.sellerName,
          sellerPhotoUrl: request.sellerPhotoUrl,
          amount: state.amount!,
          message: state.message,
          chatId: request.chatId,
        ),
        userId,
        userName,
        userPhotoUrl,
      );

      state = state.copyWith(isLoading: false, createdOffer: offer);
      return offer;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const CreateOfferState();
  }
}

/// Create offer provider
final createOfferProvider =
    StateNotifierProvider.autoDispose<CreateOfferNotifier, CreateOfferState>(
  (ref) {
    final user = ref.watch(currentUserProvider);
    final repository = ref.watch(offerRepositoryProvider);

    return CreateOfferNotifier(
      repository,
      user?.uid ?? '',
      user?.displayName ?? 'User',
      user?.photoUrl,
    );
  },
);

/// Offer actions notifier
class OfferActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final OfferRepository _repository;
  final String offerId;

  OfferActionsNotifier(this._repository, this.offerId)
      : super(const AsyncValue.data(null));

  Future<void> accept() async {
    state = const AsyncValue.loading();
    try {
      await _repository.acceptOffer(offerId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> decline() async {
    state = const AsyncValue.loading();
    try {
      await _repository.declineOffer(offerId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> counter(int amount, String? message) async {
    state = const AsyncValue.loading();
    try {
      await _repository.counterOffer(offerId, amount, message);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> withdraw() async {
    state = const AsyncValue.loading();
    try {
      await _repository.withdrawOffer(offerId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Offer actions provider
final offerActionsProvider = StateNotifierProvider.family
    .autoDispose<OfferActionsNotifier, AsyncValue<void>, String>(
  (ref, offerId) {
    final repository = ref.watch(offerRepositoryProvider);
    return OfferActionsNotifier(repository, offerId);
  },
);
