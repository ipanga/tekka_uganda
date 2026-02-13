import 'package:flutter/material.dart';

/// Tekka Design System - Color Tokens
///
/// Based on Material Design 3 with custom Tekka branding.
/// Primary: Tekka Blue (#0E64B1) - Fashion-forward, marketplace feel
/// Design Direction: Modern Fashion Marketplace
abstract class AppColors {
  AppColors._();

  // ==========================================================================
  // PRIMARY PALETTE
  // ==========================================================================

  /// Primary brand color - Tekka Blue
  static const Color primary = Color(0xFF0E64B1);

  /// Darker shade for pressed states
  static const Color primaryDark = Color(0xFF0B5499);

  /// Lighter shade for highlights
  static const Color primaryLight = Color(0xFF75ABDB);

  /// Very light shade for containers/backgrounds
  static const Color primaryContainer = Color(0xFFEBF2FA);

  /// Text color on primary
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text color on primary container
  static const Color onPrimaryContainer = Color(0xFF0B5499);

  // ==========================================================================
  // SECONDARY PALETTE
  // ==========================================================================

  /// Secondary color - Dark Blue Gray
  static const Color secondary = Color(0xFF3D405B);

  /// Lighter secondary
  static const Color secondaryLight = Color(0xFF5C5F7E);

  /// Secondary container
  static const Color secondaryContainer = Color(0xFFE8E8EE);

  /// Text color on secondary
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ==========================================================================
  // NEUTRAL PALETTE
  // ==========================================================================

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Off-white background
  static const Color gray50 = Color(0xFFFAFAFA);

  /// Light gray
  static const Color gray100 = Color(0xFFF5F5F5);

  /// Border/divider gray
  static const Color gray200 = Color(0xFFE0E0E0);

  /// Placeholder text gray
  static const Color gray400 = Color(0xFF9E9E9E);

  /// Secondary text gray
  static const Color gray500 = Color(0xFF757575);

  /// Primary text - near black
  static const Color gray900 = Color(0xFF212121);

  // ==========================================================================
  // SEMANTIC COLORS
  // ==========================================================================

  /// Surface color (cards, sheets)
  static const Color surface = white;

  /// Background color (screens)
  static const Color background = gray50;

  /// Primary text on surface
  static const Color onSurface = gray900;

  /// Secondary text on surface
  static const Color onSurfaceVariant = gray500;

  /// Borders and dividers
  static const Color outline = gray200;

  /// Subtle outlines
  static const Color outlineVariant = gray100;

  // ==========================================================================
  // STATUS COLORS
  // ==========================================================================

  /// Success green
  static const Color success = Color(0xFF28A745);

  /// Success container
  static const Color successContainer = Color(0xFFE8F5E9);

  /// Text on success
  static const Color onSuccess = Color(0xFFFFFFFF);

  /// Text on success container
  static const Color onSuccessContainer = Color(0xFF2E7D32);

  /// Error red
  static const Color error = Color(0xFFDC3545);

  /// Error container
  static const Color errorContainer = Color(0xFFFFEBEE);

  /// Text on error
  static const Color onError = Color(0xFFFFFFFF);

  /// Text on error container
  static const Color onErrorContainer = Color(0xFFC62828);

  /// Warning amber
  static const Color warning = Color(0xFFFFC107);

  /// Warning container
  static const Color warningContainer = Color(0xFFFFF8E1);

  /// Text on warning container
  static const Color onWarningContainer = Color(0xFFF57C00);

  // ==========================================================================
  // CELEBRATION / ACCENT
  // ==========================================================================

  /// Gold for ratings and achievements
  static const Color gold = Color(0xFFF2CC8F);

  /// Darker gold
  static const Color goldDark = Color(0xFFD4A84A);

  // ==========================================================================
  // GRADIENTS
  // ==========================================================================

  /// Primary button gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Pressed button gradient
  static const LinearGradient primaryPressedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, Color(0xFF094480)],
  );

  // ==========================================================================
  // DARK THEME COLORS
  // ==========================================================================

  /// Dark background
  static const Color darkBackground = Color(0xFF0F172A);

  /// Dark surface (cards, sheets)
  static const Color darkSurface = Color(0xFF1E293B);

  /// Dark surface variant (elevated elements)
  static const Color darkSurfaceVariant = Color(0xFF334155);

  /// Text on dark surface
  static const Color darkOnSurface = Color(0xFFF1F5F9);

  /// Secondary text on dark surface
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);

  /// Borders in dark theme
  static const Color darkOutline = Color(0xFF334155);

  /// Subtle borders in dark theme
  static const Color darkOutlineVariant = Color(0xFF1E293B);

  /// Primary color for dark theme (lighter variant for visibility)
  static const Color darkPrimary = Color(0xFF75ABDB);

  /// Primary container in dark theme
  static const Color darkPrimaryContainer = Color(0xFF063466);

  /// Text on primary container in dark theme
  static const Color darkOnPrimaryContainer = Color(0xFFD1E3F3);

  // ==========================================================================
  // MATERIAL COLOR SCHEME
  // ==========================================================================

  /// Light theme color scheme
  static ColorScheme get lightColorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: secondary,
    tertiary: gold,
    onTertiary: gray900,
    tertiaryContainer: Color(0xFFFFF8E1),
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
    shadow: Color(0x1A000000),
    scrim: Color(0x52000000),
    inverseSurface: gray900,
    onInverseSurface: white,
    inversePrimary: primaryLight,
    surfaceContainerHighest: gray100,
  );

  /// Dark theme color scheme
  static ColorScheme get darkColorScheme => const ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: Color(0xFF04244D),
    primaryContainer: darkPrimaryContainer,
    onPrimaryContainer: darkOnPrimaryContainer,
    secondary: Color(0xFF8B8FAE),
    onSecondary: Color(0xFF1E293B),
    secondaryContainer: Color(0xFF3D405B),
    onSecondaryContainer: Color(0xFFE8E8EE),
    tertiary: gold,
    onTertiary: Color(0xFF1E293B),
    tertiaryContainer: Color(0xFF5C4A1E),
    onTertiaryContainer: goldDark,
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3D0000),
    errorContainer: Color(0xFF5C1A1A),
    onErrorContainer: Color(0xFFFFB4B4),
    surface: darkSurface,
    onSurface: darkOnSurface,
    onSurfaceVariant: darkOnSurfaceVariant,
    outline: darkOutline,
    outlineVariant: darkOutlineVariant,
    shadow: Color(0x40000000),
    scrim: Color(0x73000000),
    inverseSurface: Color(0xFFF1F5F9),
    onInverseSurface: Color(0xFF1E293B),
    inversePrimary: primary,
    surfaceContainerHighest: darkSurfaceVariant,
  );
}
