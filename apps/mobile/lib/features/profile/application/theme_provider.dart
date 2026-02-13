import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported theme modes in Tekka
enum AppThemeMode {
  light,
  dark,
  system;

  String get code {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
      case AppThemeMode.system:
        return Icons.settings_brightness_outlined;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  static AppThemeMode fromCode(String code) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.code == code,
      orElse: () => AppThemeMode.system,
    );
  }
}

/// State for theme preferences
class ThemeState {
  final AppThemeMode selectedTheme;
  final bool isLoading;
  final String? error;

  const ThemeState({
    this.selectedTheme = AppThemeMode.system,
    this.isLoading = false,
    this.error,
  });

  ThemeState copyWith({
    AppThemeMode? selectedTheme,
    bool? isLoading,
    String? error,
  }) {
    return ThemeState(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Storage key for theme preference
const String _themeKey = 'app_theme';

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

/// Provider for just the current ThemeMode (for MaterialApp)
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.selectedTheme.themeMode;
});

/// Notifier for managing theme preferences
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadTheme();
  }

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final themeCode = prefs.getString(_themeKey) ?? 'system';
      final theme = AppThemeMode.fromCode(themeCode);
      state = state.copyWith(selectedTheme: theme, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set the app theme
  Future<bool> setTheme(AppThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.code);
      state = state.copyWith(selectedTheme: theme);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
