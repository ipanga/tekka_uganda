import 'package:flutter/material.dart';

/// Tekka Design System - Color Tokens
///
/// Ecommerce-first orange identity tuned for CTA clarity.
/// Light mode only.
abstract class AppColors {
  AppColors._();

  // Primary brand scale
  static const Color primary = Color(0xFFF97316);
  static const Color primaryHover = Color(0xFFEA580C);
  static const Color primaryPressed = Color(0xFFC2410C);
  static const Color primaryLight = Color(0xFFFDBA74);
  static const Color primaryDark = Color(0xFF9A3412);
  static const Color primaryDisabled = Color(0xFFFED7AA);

  static const Color primaryContainer = Color(0xFFFFEDD5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF7C2D12);

  // Secondary and semantic tones
  static const Color secondary = Color(0xFF334155);
  static const Color secondaryLight = Color(0xFF475569);
  static const Color secondaryContainer = Color(0xFFE2E8F0);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF14532D);

  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  // Neutral scale
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray900 = Color(0xFF0F172A);

  // Light mode surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFF1F5F9);

  // Accent
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldDark = Color(0xFFB45309);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryHover],
  );

  static const LinearGradient primaryPressedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPressed, primaryDark],
  );

  // Material color schemes
  static ColorScheme get lightColorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: Color(0xFFE2E8F0),
    onSecondaryContainer: secondary,
    tertiary: gold,
    onTertiary: gray900,
    tertiaryContainer: Color(0xFFFEF3C7),
    onTertiaryContainer: goldDark,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: Color(0x1F000000),
    scrim: Color(0x52000000),
    inverseSurface: gray900,
    onInverseSurface: white,
    inversePrimary: primaryLight,
    surfaceContainerHighest: surfaceElevated,
  );
}
