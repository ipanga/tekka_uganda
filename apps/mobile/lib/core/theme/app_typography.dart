import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tekka Design System - Typography
///
/// Based on Material Design 3 type scale.
/// Uses Roboto (default) for cross-platform consistency.
abstract class AppTypography {
  AppTypography._();

  // ==========================================================================
  // FONT FAMILY
  // ==========================================================================

  static const String fontFamily = 'Roboto';

  // ==========================================================================
  // DISPLAY STYLES
  // ==========================================================================

  /// Display Large - Hero text
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    height: 64 / 57,
    letterSpacing: -0.25,
    color: AppColors.onSurface,
  );

  /// Display Medium - Large headers
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 52 / 45,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  /// Display Small
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 44 / 36,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  // ==========================================================================
  // HEADLINE STYLES
  // ==========================================================================

  /// Headline Large - Screen titles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 40 / 32,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  /// Headline Medium - Section headers
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 36 / 28,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  /// Headline Small
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 32 / 24,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  // ==========================================================================
  // TITLE STYLES
  // ==========================================================================

  /// Title Large - Card titles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 28 / 22,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  /// Title Medium - Listing titles
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    letterSpacing: 0.15,
    color: AppColors.onSurface,
  );

  /// Title Small - Subtitles
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  // ==========================================================================
  // BODY STYLES
  // ==========================================================================

  /// Body Large - Primary body text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0.5,
    color: AppColors.onSurface,
  );

  /// Body Medium - Secondary body text
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.25,
    color: AppColors.onSurface,
  );

  /// Body Small - Captions
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.4,
    color: AppColors.onSurfaceVariant,
  );

  // ==========================================================================
  // LABEL STYLES
  // ==========================================================================

  /// Label Large - Buttons
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  /// Label Medium - Chips, badges
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.5,
    color: AppColors.onSurface,
  );

  /// Label Small - Small labels
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  // ==========================================================================
  // TEXT THEME
  // ==========================================================================

  /// Complete Material text theme
  static TextTheme get textTheme => const TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  // ==========================================================================
  // SEMANTIC HELPERS
  // ==========================================================================

  /// Price text style
  static TextStyle get price => titleMedium.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.w600,
  );

  /// Large price (detail screen)
  static TextStyle get priceLarge => headlineLarge.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.w700,
  );

  /// Location/time metadata
  static TextStyle get metadata =>
      bodySmall.copyWith(color: AppColors.onSurfaceVariant);

  /// Section label
  static TextStyle get sectionLabel =>
      titleSmall.copyWith(color: AppColors.onSurface);

  /// Hint/placeholder text
  static TextStyle get hint => bodyLarge.copyWith(color: AppColors.gray400);

  /// Error text
  static TextStyle get errorText => bodySmall.copyWith(color: AppColors.error);

  /// Success text
  static TextStyle get successText =>
      bodySmall.copyWith(color: AppColors.success);
}
