/// App configuration for different environments
enum Environment { dev, staging, prod }

class AppConfig {
  static Environment _environment = Environment.dev;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// API Base URL
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.dev:
        // Use 127.0.0.1 for iOS simulator compatibility (localhost doesn't work on iOS sim)
        return 'http://127.0.0.1:3000/api/v1';
      case Environment.staging:
        return 'https://staging-api.tekka.ug/api/v1';
      case Environment.prod:
        return 'https://api.tekka.ug/api/v1';
    }
  }

  /// Cloudinary configuration
  static String get cloudinaryCloudName => 'tekka';
  static String get cloudinaryUploadPreset => 'tekka_listings';

  /// Feature flags
  static bool get enableAnalytics => _environment == Environment.prod;
  static bool get enableCrashlytics => _environment == Environment.prod;

  /// App info
  static const String appName = 'Tekka';
  static const String appVersion = '1.0.0';

  /// Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration imageUploadTimeout = Duration(minutes: 2);

  /// Limits
  static const int maxPhotosPerListing = 6;
  static const int minPhotosPerListing = 3;
  static const int maxListingsPerUser = 15;
  static const int maxDescriptionLength = 1000;
  static const int maxTitleLength = 100;

  /// Image settings
  static const int maxImageWidth = 1200;
  static const int maxImageHeight = 1200;
  static const int imageQuality = 85;
  static const double maxImageSizeMB = 5.0;

  /// Cache durations
  static const Duration listingCacheDuration = Duration(minutes: 5);
  static const Duration userCacheDuration = Duration(hours: 1);
}
