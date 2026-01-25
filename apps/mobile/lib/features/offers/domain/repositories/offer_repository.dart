import '../entities/offer.dart';

/// Repository interface for offer operations
abstract class OfferRepository {
  /// Create a new offer
  Future<Offer> createOffer(CreateOfferRequest request, String buyerId, String buyerName, String? buyerPhotoUrl);

  /// Get offer by ID
  Future<Offer?> getOfferById(String offerId);

  /// Get offers made by a user (as buyer)
  Future<List<Offer>> getOffersByBuyer(String buyerId);

  /// Get offers received by a user (as seller)
  Future<List<Offer>> getOffersBySeller(String sellerId);

  /// Get offers for a specific listing
  Future<List<Offer>> getOffersForListing(String listingId);

  /// Get pending offers count for seller
  Future<int> getPendingOffersCount(String sellerId);

  /// Accept an offer
  Future<void> acceptOffer(String offerId);

  /// Decline an offer
  Future<void> declineOffer(String offerId);

  /// Counter an offer
  Future<void> counterOffer(String offerId, int counterAmount, String? message);

  /// Withdraw an offer (by buyer)
  Future<void> withdrawOffer(String offerId);

  /// Check if user has pending offer on listing
  Future<bool> hasPendingOffer(String listingId, String buyerId);

  /// Stream of offers for buyer
  Stream<List<Offer>> watchOffersByBuyer(String buyerId);

  /// Stream of offers for seller
  Stream<List<Offer>> watchOffersBySeller(String sellerId);
}
