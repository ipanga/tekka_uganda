import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages in Tekka
enum AppLanguage {
  english,
  luganda,
  swahili,
}

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.luganda:
        return 'lg';
      case AppLanguage.swahili:
        return 'sw';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.luganda:
        return 'Luganda';
      case AppLanguage.swahili:
        return 'Kiswahili';
    }
  }

  String get nativeName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.luganda:
        return 'Oluganda';
      case AppLanguage.swahili:
        return 'Kiswahili';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.english:
        return '🇬🇧';
      case AppLanguage.luganda:
        return '🇺🇬';
      case AppLanguage.swahili:
        return '🇹🇿';
    }
  }

  Locale get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.luganda:
        return const Locale('lg');
      case AppLanguage.swahili:
        return const Locale('sw');
    }
  }

  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'lg':
        return AppLanguage.luganda;
      case 'sw':
        return AppLanguage.swahili;
      default:
        return AppLanguage.english;
    }
  }
}

/// State for language preferences
class LanguageState {
  final AppLanguage selectedLanguage;
  final bool isLoading;
  final String? error;

  const LanguageState({
    this.selectedLanguage = AppLanguage.english,
    this.isLoading = false,
    this.error,
  });

  LanguageState copyWith({
    AppLanguage? selectedLanguage,
    bool? isLoading,
    String? error,
  }) {
    return LanguageState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Storage key for language preference
const String _languageKey = 'app_language';

/// Provider for language state
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>(
  (ref) => LanguageNotifier(),
);

/// Provider for just the current locale (for MaterialApp)
final currentLocaleProvider = Provider<Locale>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.selectedLanguage.locale;
});

/// Notifier for managing language preferences
class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier() : super(const LanguageState()) {
    _loadLanguage();
  }

  /// Load saved language preference
  Future<void> _loadLanguage() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      if (languageCode != null) {
        final language = AppLanguageX.fromCode(languageCode);
        state = state.copyWith(
          selectedLanguage: language,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load language preference',
      );
    }
  }

  /// Set the app language
  Future<bool> setLanguage(AppLanguage language) async {
    if (state.selectedLanguage == language) return true;

    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);

      state = state.copyWith(
        selectedLanguage: language,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save language preference',
      );
      return false;
    }
  }
}
