/// App-wide constants
abstract class AppConstants {
  AppConstants._();

  /// Storage keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String fcmTokenKey = 'fcm_token';

  /// Collection names (Firestore)
  static const String usersCollection = 'users';
  static const String listingsCollection = 'listings';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String ratingsCollection = 'ratings';
  static const String favoritesCollection = 'favorites';

  /// Listing limits
  static const int maxActiveListings = 15;

  /// Uganda phone country code
  static const String ugandaCountryCode = '+256';

  /// OTP settings
  static const int otpLength = 6;
  static const Duration otpResendDelay = Duration(seconds: 60);
  static const Duration otpTimeout = Duration(minutes: 2);

  /// Listing statuses
  static const String statusPending = 'pending';
  static const String statusActive = 'active';
  static const String statusSold = 'sold';
  static const String statusRejected = 'rejected';

  /// Size options
  static const List<String> sizeOptions = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'Custom',
  ];

  /// Condition options
  static const List<String> conditionOptions = [
    'New with tags',
    'Like new',
    'Good',
    'Fair',
  ];

  /// Condition descriptions
  static const Map<String, String> conditionDescriptions = {
    'New with tags': 'Never worn, original tags attached',
    'Like new': 'Worn once or twice, no visible wear',
    'Good': 'Light wear, minor signs of use',
    'Fair': 'Visible wear but still wearable',
  };

  /// Category slugs
  static const String categoryTraditional = 'traditional';
  static const String categoryCasual = 'casual';
  static const String categoryFormal = 'formal';
  static const String categoryShoes = 'shoes';
  static const String categoryAccessories = 'accessories';

  /// Occasion tags
  static const List<String> occasionTags = [
    'Wedding',
    'Kwanjula',
    'Church',
    'Corporate',
    'Party',
    'Casual',
  ];

  /// Style categories
  static const List<String> styleCategories = [
    'Traditional Wear',
    'Casual',
    'Formal',
    'Shoes',
    'Accessories',
  ];

  /// Safe meetup locations (Kampala)
  static const List<Map<String, dynamic>> safeMeetupLocations = [
    {'name': 'Garden City Mall', 'area': 'Kampala Central'},
    {'name': 'Acacia Mall', 'area': 'Kisementi'},
    {'name': 'Village Mall', 'area': 'Bugolobi'},
    {'name': 'Forest Mall', 'area': 'Lugogo'},
    {'name': 'Shoprite Lugogo', 'area': 'Lugogo'},
    {'name': 'Shell Petrol Station', 'area': 'Various'},
    {'name': 'Total Petrol Station', 'area': 'Various'},
    {'name': 'Stanbic Bank', 'area': 'Various'},
  ];

  /// Rating window after marking as sold
  static const Duration ratingWindowDuration = Duration(hours: 48);

  /// Moderation
  static const Duration expectedModerationTime = Duration(hours: 4);
}
