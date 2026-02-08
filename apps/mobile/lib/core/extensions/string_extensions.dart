/// Extension methods on String
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if string is a valid Ugandan phone number
  /// Handles:
  /// - Full E.164: +256712345678 (13 chars)
  /// - Without +: 256712345678 (12 chars)
  /// - Local with 0: 0712345678 (10 chars)
  /// - Local without 0: 712345678 (9 chars)
  bool get isValidUgandaPhone {
    // Remove spaces, dashes, and other non-digit characters except +
    final cleaned = replaceAll(RegExp(r'[^\d+]'), '');

    // Check formats: +256XXXXXXXXX, 256XXXXXXXXX, 0XXXXXXXXX, XXXXXXXXX
    if (cleaned.startsWith('+256')) {
      return cleaned.length == 13 &&
          RegExp(r'^\+256[7][0-9]{8}$').hasMatch(cleaned);
    } else if (cleaned.startsWith('256')) {
      return cleaned.length == 12 &&
          RegExp(r'^256[7][0-9]{8}$').hasMatch(cleaned);
    } else if (cleaned.startsWith('0')) {
      return cleaned.length == 10 &&
          RegExp(r'^0[7][0-9]{8}$').hasMatch(cleaned);
    } else if (cleaned.startsWith('7')) {
      // Handle case where user enters 9 digits starting with 7
      return cleaned.length == 9 && RegExp(r'^[7][0-9]{8}$').hasMatch(cleaned);
    }
    return false;
  }

  /// Format phone number to E.164 format (+256XXXXXXXXX)
  /// Handles:
  /// - +256712345678 → +256712345678 (no change)
  /// - 256712345678 → +256712345678 (add +)
  /// - 0712345678 → +256712345678 (replace 0 with +256)
  /// - 712345678 → +256712345678 (add +256)
  String get toE164Phone {
    // Remove spaces, dashes, and other non-digit characters except +
    final cleaned = replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+256')) {
      return cleaned;
    } else if (cleaned.startsWith('256') && cleaned.length >= 12) {
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      return '+256${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') && cleaned.length == 9) {
      // Handle 9-digit number starting with 7 (without leading 0)
      return '+256$cleaned';
    }
    // Default: assume it's a local number, add +256
    return '+256$cleaned';
  }

  /// Format phone for display (e.g., +256 7XX XXX XXX)
  String get formatPhoneDisplay {
    final e164 = toE164Phone;
    if (e164.length != 13) return this;

    return '${e164.substring(0, 4)} ${e164.substring(4, 7)} ${e164.substring(7, 10)} ${e164.substring(10)}';
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Convert string to slug
  String get toSlug {
    return toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Return null if string is empty
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// Extension on nullable String
extension NullableStringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Return empty string if null
  String get orEmpty => this ?? '';
}
