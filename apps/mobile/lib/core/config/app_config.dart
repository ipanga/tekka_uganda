import 'dart:io' show Platform;

import 'environment.dart';

/// App configuration — environment-aware
class AppConfig {
  /// API Base URL
  static String get apiBaseUrl {
    switch (EnvironmentConfig.current) {
      case Environment.dev:
        final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
        return 'http://$host:4000/api/v1';
      case Environment.staging:
      case Environment.prod:
        return 'https://api.tekka.ug/api/v1';
    }
  }

  /// Cloudinary configuration
  static String get cloudinaryCloudName => 'tekka';
  static String get cloudinaryUploadPreset => 'tekka_listings';

  /// Feature flags
  static bool get enableAnalytics => EnvironmentConfig.isProd;
  static bool get enableCrashlytics => EnvironmentConfig.isProd;

  /// App display name
  static String get appName {
    switch (EnvironmentConfig.current) {
      case Environment.dev:
        return 'Tekka Dev';
      case Environment.staging:
        return 'Tekka Staging';
      case Environment.prod:
        return 'Tekka';
    }
  }

  static const String appVersion = '1.0.0';

  /// Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration imageUploadTimeout = Duration(minutes: 2);

  /// Limits
  static const int maxPhotosPerListing = 6;
  static const int minPhotosPerListing = 3;
  static const int maxListingsPerUser = 15;
  static const int maxDescriptionLength = 1000;
  static const int maxTitleLength = 150;

  /// Image settings
  static const int maxImageWidth = 1200;
  static const int maxImageHeight = 1200;
  static const int imageQuality = 85;
  static const double maxImageSizeMB = 5.0;

  /// Cache durations
  static const Duration listingCacheDuration = Duration(minutes: 5);
  static const Duration userCacheDuration = Duration(hours: 1);
}
