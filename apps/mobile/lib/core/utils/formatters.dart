import 'package:intl/intl.dart';

/// Utility class for formatting values
abstract class Formatters {
  Formatters._();

  /// Format price in UGX
  static String formatPrice(int amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return 'UGX ${formatter.format(amount)}';
  }

  /// Format price without currency
  static String formatNumber(int amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  /// Parse price string to int
  static int? parsePrice(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned);
  }

  /// Format relative time (e.g., "2 hours ago", "3 days ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes${minutes == 1 ? 'm' : 'm'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours${hours == 1 ? 'h' : 'h'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days${days == 1 ? 'd' : 'd'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks${weeks == 1 ? 'w' : 'w'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months${months == 1 ? 'mo' : 'mo'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years${years == 1 ? 'y' : 'y'} ago';
    }
  }

  /// Format date for display (e.g., "Jan 7, 2026")
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Format time for chat (e.g., "10:30 AM")
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format date for chat list (Today, Yesterday, or date)
  static String formatChatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return formatTime(dateTime);
    } else if (date == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // Day name
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  /// Format rating (e.g., "4.8")
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Format response time (e.g., "Responds in 1 hour")
  static String formatResponseTime(Duration duration) {
    if (duration.inMinutes < 60) {
      return 'Responds in ${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      return 'Responds in $hours${hours == 1 ? ' hour' : ' hours'}';
    } else {
      final days = duration.inDays;
      return 'Responds in $days${days == 1 ? ' day' : ' days'}';
    }
  }
}
