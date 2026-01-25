import 'dart:async';

import '../../../../core/services/api_client.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';

/// API-based implementation of OfferRepository
class OfferApiRepository implements OfferRepository {
  final ApiClient _apiClient;
  final Duration _pollInterval;

  OfferApiRepository(this._apiClient, {Duration? pollInterval})
      : _pollInterval = pollInterval ?? const Duration(seconds: 10);

  @override
  Future<Offer> createOffer(
    CreateOfferRequest request,
    String buyerId,
    String buyerName,
    String? buyerPhotoUrl,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/offers',
      data: {
        'listingId': request.listingId,
        'amount': request.amount,
        if (request.message != null) 'message': request.message,
      },
    );
    return Offer.fromJson(response);
  }

  @override
  Future<Offer?> getOfferById(String offerId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/offers/$offerId');
      return Offer.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Offer>> getOffersByBuyer(String buyerId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/offers',
      queryParameters: {'role': 'buyer'},
    );
    return response.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Offer>> getOffersBySeller(String sellerId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/offers',
      queryParameters: {'role': 'seller'},
    );
    return response.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Offer>> getOffersForListing(String listingId) async {
    final response = await _apiClient.get<List<dynamic>>('/offers/listing/$listingId');
    return response.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> getPendingOffersCount(String sellerId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/offers/stats');
      return response['pendingCount'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> acceptOffer(String offerId) async {
    await _apiClient.post('/offers/$offerId/accept');
  }

  @override
  Future<void> declineOffer(String offerId) async {
    await _apiClient.post('/offers/$offerId/reject');
  }

  @override
  Future<void> counterOffer(String offerId, int counterAmount, String? message) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/offers/$offerId/counter',
      data: {
        'counterAmount': counterAmount,
        if (message != null) 'counterMessage': message,
      },
    );
  }

  @override
  Future<void> withdrawOffer(String offerId) async {
    await _apiClient.delete('/offers/$offerId');
  }

  @override
  Future<bool> hasPendingOffer(String listingId, String buyerId) async {
    try {
      final offers = await getOffersForListing(listingId);
      return offers.any((o) => o.buyerId == buyerId && o.status == OfferStatus.pending);
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<Offer>> watchOffersByBuyer(String buyerId) {
    return _createPollingStream(
      () => getOffersByBuyer(buyerId),
      interval: _pollInterval,
    );
  }

  @override
  Stream<List<Offer>> watchOffersBySeller(String sellerId) {
    return _createPollingStream(
      () => getOffersBySeller(sellerId),
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
