import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Keys for storing rate app preferences
class _RateAppKeys {
  static const String hasRated = 'rate_app_has_rated';
  static const String lastPromptDate = 'rate_app_last_prompt_date';
  static const String launchCount = 'rate_app_launch_count';
  static const String dontAskAgain = 'rate_app_dont_ask_again';
}

/// Store URLs for the app
class _StoreUrls {
  // Replace with actual app IDs when published
  static const String appStoreId = 'com.tekka.app';
  static const String playStoreId = 'com.tekka.app';

  static String get appStoreUrl => 'https://apps.apple.com/app/id$appStoreId';

  static String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$playStoreId';
}

/// State for rate app feature
class RateAppState {
  final bool hasRated;
  final bool dontAskAgain;
  final int launchCount;
  final DateTime? lastPromptDate;
  final bool isLoading;
  final String? error;

  const RateAppState({
    this.hasRated = false,
    this.dontAskAgain = false,
    this.launchCount = 0,
    this.lastPromptDate,
    this.isLoading = false,
    this.error,
  });

  RateAppState copyWith({
    bool? hasRated,
    bool? dontAskAgain,
    int? launchCount,
    DateTime? lastPromptDate,
    bool? isLoading,
    String? error,
  }) {
    return RateAppState(
      hasRated: hasRated ?? this.hasRated,
      dontAskAgain: dontAskAgain ?? this.dontAskAgain,
      launchCount: launchCount ?? this.launchCount,
      lastPromptDate: lastPromptDate ?? this.lastPromptDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Whether we should prompt the user to rate
  bool get shouldPrompt {
    if (hasRated || dontAskAgain) return false;

    // Require at least 3 app launches
    if (launchCount < 3) return false;

    // Don't prompt more than once per week
    if (lastPromptDate != null) {
      final daysSinceLastPrompt = DateTime.now()
          .difference(lastPromptDate!)
          .inDays;
      if (daysSinceLastPrompt < 7) return false;
    }

    return true;
  }
}

/// Provider for rate app functionality
final rateAppProvider = StateNotifierProvider<RateAppNotifier, RateAppState>(
  (ref) => RateAppNotifier(),
);

/// Notifier for rate app state management
class RateAppNotifier extends StateNotifier<RateAppState> {
  final InAppReview _inAppReview = InAppReview.instance;

  RateAppNotifier() : super(const RateAppState()) {
    _loadState();
  }

  /// Load saved state from preferences
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final hasRated = prefs.getBool(_RateAppKeys.hasRated) ?? false;
      final dontAskAgain = prefs.getBool(_RateAppKeys.dontAskAgain) ?? false;
      final launchCount = prefs.getInt(_RateAppKeys.launchCount) ?? 0;
      final lastPromptMillis = prefs.getInt(_RateAppKeys.lastPromptDate);

      DateTime? lastPromptDate;
      if (lastPromptMillis != null) {
        lastPromptDate = DateTime.fromMillisecondsSinceEpoch(lastPromptMillis);
      }

      state = state.copyWith(
        hasRated: hasRated,
        dontAskAgain: dontAskAgain,
        launchCount: launchCount,
        lastPromptDate: lastPromptDate,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load preferences');
    }
  }

  /// Increment launch count (call on app startup)
  Future<void> incrementLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newCount = state.launchCount + 1;
      await prefs.setInt(_RateAppKeys.launchCount, newCount);
      state = state.copyWith(launchCount: newCount);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Record that we prompted the user
  Future<void> recordPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setInt(
        _RateAppKeys.lastPromptDate,
        now.millisecondsSinceEpoch,
      );
      state = state.copyWith(lastPromptDate: now);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Set don't ask again preference
  Future<void> setDontAskAgain(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_RateAppKeys.dontAskAgain, value);
      state = state.copyWith(dontAskAgain: value);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save preference');
    }
  }

  /// Mark that user has rated the app
  Future<void> markAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_RateAppKeys.hasRated, true);
      state = state.copyWith(hasRated: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save preference');
    }
  }

  /// Request in-app review (native review dialog)
  Future<bool> requestInAppReview() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        await _inAppReview.requestReview();
        await markAsRated();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        // Fall back to opening store
        final success = await openStore();
        state = state.copyWith(isLoading: false);
        return success;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to open review dialog',
      );
      return false;
    }
  }

  /// Open the appropriate app store
  Future<bool> openStore() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final Uri storeUri;

      if (Platform.isIOS) {
        storeUri = Uri.parse(_StoreUrls.appStoreUrl);
      } else if (Platform.isAndroid) {
        storeUri = Uri.parse(_StoreUrls.playStoreUrl);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Platform not supported',
        );
        return false;
      }

      final canLaunch = await canLaunchUrl(storeUri);

      if (canLaunch) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
        await markAsRated();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Could not open store');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to open store: $e',
      );
      return false;
    }
  }

  /// Get the store name based on platform
  String get storeName {
    if (Platform.isIOS) return 'App Store';
    if (Platform.isAndroid) return 'Play Store';
    return 'Store';
  }
}
