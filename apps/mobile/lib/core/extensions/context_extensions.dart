import 'package:flutter/material.dart';

/// Extension methods on BuildContext for easy access to theme and media
extension ContextExtensions on BuildContext {
  /// Access the current ThemeData
  ThemeData get theme => Theme.of(this);

  /// Access the current ColorScheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Access the current TextTheme
  TextTheme get textTheme => theme.textTheme;

  /// Access MediaQueryData
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width
  double get screenWidth => mediaQuery.size.width;

  /// Screen height
  double get screenHeight => mediaQuery.size.height;

  /// Safe area padding
  EdgeInsets get padding => mediaQuery.padding;

  /// Bottom padding (for bottom nav, keyboard, etc.)
  double get bottomPadding => padding.bottom;

  /// Top padding (status bar)
  double get topPadding => padding.top;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => mediaQuery.viewInsets.bottom > 0;

  /// Show a snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a success snackbar
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.onPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF28A745),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show an error snackbar
  void showError(String message) {
    showSnackBar(message, isError: true);
  }

  /// Pop current route
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Check if current locale is RTL
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
