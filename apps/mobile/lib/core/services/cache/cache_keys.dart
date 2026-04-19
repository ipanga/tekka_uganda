/// Central registry of cache keys + TTLs.
///
/// Keeping all of this in one file so it's obvious what's cached, for how
/// long, and how to invalidate related data after mutations. Grouped by
/// feature. Keys nest with `:` so `invalidatePrefix('listings:')` wipes
/// every listings entry.
library;

class CacheKeys {
  CacheKeys._();

  // -------- Listings --------
  static const String listingsPrefix = 'listings:';

  /// Key for a listings feed/search result. The filter fingerprint is
  /// whatever `ListingsFilter.toCacheKey()` produces.
  static String listingsFeed(String filterFingerprint) =>
      'listings:feed:$filterFingerprint';

  static String listingDetail(String id) => 'listings:detail:$id';

  static const String savedListings = 'listings:saved';

  // -------- Reference data (rarely change) --------
  static const String categoriesRoot = 'ref:categories:root';
  static String categoryChildren(String parentId) =>
      'ref:categories:children:$parentId';
  static String categoryAttributes(String categoryId) =>
      'ref:categories:attrs:$categoryId';
  static const String cities = 'ref:locations:cities';
  static String divisions(String cityId) => 'ref:locations:divisions:$cityId';

  // -------- User --------
  static const String currentUser = 'user:me';

  // -------- Cache TTLs --------
  /// Listings feed — short; users expect fresh results.
  static const Duration listingsFeedTtl = Duration(minutes: 2);

  /// Listing detail — slightly longer; images etc. don't change often.
  static const Duration listingDetailTtl = Duration(minutes: 5);

  /// Reference data — long; categories/locations barely change.
  static const Duration referenceTtl = Duration(hours: 24);

  /// Current user profile — short; tied to a live session.
  static const Duration userProfileTtl = Duration(minutes: 5);
}
