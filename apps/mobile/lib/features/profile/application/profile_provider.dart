import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../listing/application/listing_provider.dart';
import '../../listing/domain/entities/listing.dart';
import '../../reviews/application/review_provider.dart';

/// User profile stats
class UserProfileStats {
  final int totalListings;
  final int soldCount;
  final double rating;
  final int reviewCount;

  const UserProfileStats({
    this.totalListings = 0,
    this.soldCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
  });
}

/// Current user's profile stats provider
final profileStatsProvider = FutureProvider<UserProfileStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const UserProfileStats();

  final listings = await ref.watch(userListingsProvider(user.uid).future);

  final totalListings = listings.length;
  final soldCount = listings
      .where((l) => l.status == ListingStatus.sold)
      .length;

  // Get actual rating from reviews
  final userRating = await ref.watch(userRatingProvider(user.uid).future);

  return UserProfileStats(
    totalListings: totalListings,
    soldCount: soldCount,
    rating: userRating.averageRating,
    reviewCount: userRating.totalReviews,
  );
});

/// Current user's listings (limited for profile preview)
final myListingsPreviewProvider = FutureProvider<List<Listing>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final listings = await ref.watch(userListingsProvider(user.uid).future);

  // Sort by created date, newest first, limit to 5
  final sorted = [...listings]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted.take(5).toList();
});

/// Current user's favorite listings
final myFavoritesProvider = FutureProvider<List<Listing>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  return ref.watch(favoriteListingsProvider(user.uid).future);
});

/// Profile update notifier
class ProfileUpdateNotifier extends StateNotifier<ProfileUpdateState> {
  final AuthNotifier _authNotifier;

  ProfileUpdateNotifier(this._authNotifier) : super(const ProfileUpdateState());

  void setDisplayName(String value) {
    state = state.copyWith(displayName: value);
  }

  void setLocation(String value) {
    state = state.copyWith(location: value);
  }

  void setPhotoUrl(String? value) {
    state = state.copyWith(photoUrl: value);
  }

  void initFromUser(AppUser user) {
    state = ProfileUpdateState(
      displayName: user.displayName ?? '',
      location: user.location ?? '',
      photoUrl: user.photoUrl,
    );
  }

  Future<bool> save() async {
    if (state.displayName.isEmpty || state.location.isEmpty) {
      state = state.copyWith(error: 'Name and location are required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authNotifier.updateProfile(
        displayName: state.displayName,
        location: state.location,
        photoUrl: state.photoUrl,
      );
      state = state.copyWith(isLoading: false, isSaved: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const ProfileUpdateState();
  }
}

/// Profile update state
class ProfileUpdateState {
  final String displayName;
  final String location;
  final String? photoUrl;
  final bool isLoading;
  final bool isSaved;
  final String? error;

  const ProfileUpdateState({
    this.displayName = '',
    this.location = '',
    this.photoUrl,
    this.isLoading = false,
    this.isSaved = false,
    this.error,
  });

  ProfileUpdateState copyWith({
    String? displayName,
    String? location,
    String? photoUrl,
    bool? isLoading,
    bool? isSaved,
    String? error,
  }) {
    return ProfileUpdateState(
      displayName: displayName ?? this.displayName,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
      error: error,
    );
  }
}

/// Profile update provider
final profileUpdateProvider =
    StateNotifierProvider.autoDispose<
      ProfileUpdateNotifier,
      ProfileUpdateState
    >((ref) {
      final authNotifier = ref.watch(authNotifierProvider.notifier);
      return ProfileUpdateNotifier(authNotifier);
    });

/// Seller analytics data
class SellerAnalytics {
  final int totalListings;
  final int activeListings;
  final int pendingListings;
  final int soldListings;
  final int totalViews;
  final int totalFavorites;
  final int totalRevenue;
  final double averagePrice;
  final double conversionRate;
  final double rating;
  final int reviewCount;
  final Map<String, int> categorySales;
  final Map<String, int> monthlyViews;
  final List<ListingPerformance> topListings;
  final List<ListingPerformance> recentListings;

  const SellerAnalytics({
    this.totalListings = 0,
    this.activeListings = 0,
    this.pendingListings = 0,
    this.soldListings = 0,
    this.totalViews = 0,
    this.totalFavorites = 0,
    this.totalRevenue = 0,
    this.averagePrice = 0.0,
    this.conversionRate = 0.0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.categorySales = const {},
    this.monthlyViews = const {},
    this.topListings = const [],
    this.recentListings = const [],
  });
}

/// Individual listing performance data
class ListingPerformance {
  final String id;
  final String title;
  final String? imageUrl;
  final int price;
  final int views;
  final int favorites;
  final ListingStatus status;
  final DateTime createdAt;
  final double engagementRate;

  const ListingPerformance({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.price,
    required this.views,
    required this.favorites,
    required this.status,
    required this.createdAt,
    required this.engagementRate,
  });
}

/// Seller analytics provider
final sellerAnalyticsProvider = FutureProvider<SellerAnalytics>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const SellerAnalytics();

  final listings = await ref.watch(userListingsProvider(user.uid).future);

  if (listings.isEmpty) return const SellerAnalytics();

  // Calculate basic stats
  final activeListings = listings
      .where((l) => l.status == ListingStatus.active)
      .length;
  // Include both pending and rejected listings in the "under review" count
  final pendingListings = listings
      .where(
        (l) =>
            l.status == ListingStatus.pending ||
            l.status == ListingStatus.rejected,
      )
      .length;
  final soldListings = listings
      .where((l) => l.status == ListingStatus.sold)
      .toList();
  final soldCount = soldListings.length;

  // Calculate totals
  final totalViews = listings.fold<int>(0, (sum, l) => sum + l.viewCount);
  final totalFavorites = listings.fold<int>(
    0,
    (sum, l) => sum + l.favoriteCount,
  );
  final totalRevenue = soldListings.fold<int>(0, (sum, l) => sum + l.price);

  // Calculate averages
  final avgPrice = listings.isNotEmpty
      ? listings.fold<int>(0, (sum, l) => sum + l.price) / listings.length
      : 0.0;
  final conversionRate = listings.isNotEmpty
      ? (soldCount / listings.length) * 100
      : 0.0;

  // Get rating
  final userRating = await ref.watch(userRatingProvider(user.uid).future);

  // Category breakdown for sold items
  final categorySales = <String, int>{};
  for (final listing in soldListings) {
    final category = listing.category.displayName;
    categorySales[category] = (categorySales[category] ?? 0) + 1;
  }

  // Monthly views (last 6 months approximation based on listing creation)
  final monthlyViews = <String, int>{};
  final now = DateTime.now();
  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final monthKey = _getMonthKey(month);
    monthlyViews[monthKey] = 0;
  }
  // Distribute views across months proportionally based on listing age
  for (final listing in listings) {
    final monthKey = _getMonthKey(listing.createdAt);
    if (monthlyViews.containsKey(monthKey)) {
      monthlyViews[monthKey] =
          (monthlyViews[monthKey] ?? 0) + listing.viewCount;
    }
  }

  // Top performing listings (by views + favorites)
  final listingsWithPerformance = listings.map((l) {
    final engagementRate = l.viewCount > 0
        ? (l.favoriteCount / l.viewCount) * 100
        : 0.0;
    return ListingPerformance(
      id: l.id,
      title: l.title,
      imageUrl: l.imageUrls.isNotEmpty ? l.imageUrls.first : null,
      price: l.price,
      views: l.viewCount,
      favorites: l.favoriteCount,
      status: l.status,
      createdAt: l.createdAt,
      engagementRate: engagementRate,
    );
  }).toList();

  // Sort by engagement (views + favorites)
  final topListings = [...listingsWithPerformance]
    ..sort((a, b) => (b.views + b.favorites).compareTo(a.views + a.favorites));

  // Recent listings
  final recentListings = [...listingsWithPerformance]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return SellerAnalytics(
    totalListings: listings.length,
    activeListings: activeListings,
    pendingListings: pendingListings,
    soldListings: soldCount,
    totalViews: totalViews,
    totalFavorites: totalFavorites,
    totalRevenue: totalRevenue,
    averagePrice: avgPrice,
    conversionRate: conversionRate,
    rating: userRating.averageRating,
    reviewCount: userRating.totalReviews,
    categorySales: categorySales,
    monthlyViews: monthlyViews,
    topListings: topListings.take(5).toList(),
    recentListings: recentListings.take(5).toList(),
  );
});

String _getMonthKey(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[date.month - 1];
}
