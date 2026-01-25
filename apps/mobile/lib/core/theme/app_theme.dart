import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Tekka App Theme
///
/// Complete Material 3 theme configuration with Tekka branding.
/// Use `AppTheme.light` for the app's ThemeData.
abstract class AppTheme {
  AppTheme._();

  /// Light theme (primary theme for Tekka)
  static ThemeData get light {
    final colorScheme = AppColors.lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme,

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.onSurface,
          size: AppSpacing.iconMedium,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: AppSpacing.iconMedium,
            );
          }
          return const IconThemeData(
            color: AppColors.onSurfaceVariant,
            size: AppSpacing.iconMedium,
          );
        }),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMedium),
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMedium),
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Outlined Button (Secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMedium),
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          side: const BorderSide(color: AppColors.outline),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(AppSpacing.touchTargetMin, AppSpacing.buttonHeightSmall),
          padding: AppSpacing.buttonPadding,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: CircleBorder(),
        sizeConstraints: BoxConstraints.tightFor(
          width: AppSpacing.fabSize,
          height: AppSpacing.fabSize,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: AppSpacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.buttonRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.buttonRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.buttonRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.buttonRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.buttonRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTypography.hint,
        labelStyle: AppTypography.bodyLarge,
        errorStyle: AppTypography.errorText,
        helperStyle: AppTypography.bodySmall,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.gray100,
        labelStyle: AppTypography.labelMedium,
        padding: AppSpacing.chipPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.chipRadius,
          side: const BorderSide(color: AppColors.outline),
        ),
        side: const BorderSide(color: AppColors.outline),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        titleTextStyle: AppTypography.titleLarge,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.bottomSheetRadius,
        ),
        dragHandleColor: AppColors.outline,
        dragHandleSize: Size(32, 4),
        showDragHandle: true,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.primaryContainer,
        linearTrackColor: AppColors.primaryContainer,
      ),

      // List Tile
      listTileTheme: const ListTileThemeData(
        contentPadding: AppSpacing.screenHorizontal,
        minVerticalPadding: AppSpacing.space3,
        horizontalTitleGap: AppSpacing.space3,
        iconColor: AppColors.onSurfaceVariant,
      ),

      // Badge
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.primary,
        textColor: AppColors.onPrimary,
        textStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.onPrimary,
        ),
      ),

      // Tabs
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }

  /// Box shadow for cards
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Box shadow for elevated elements (FAB, modals)
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// Box shadow for sticky elements
  static List<BoxShadow> get stickyShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, -4),
    ),
  ];

  /// Primary gradient decoration
  static BoxDecoration get primaryGradientDecoration => const BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: AppSpacing.buttonRadius,
  );
}
