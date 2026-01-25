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
  bool get isValidUgandaPhone {
    // Remove spaces and dashes
    final cleaned = replaceAll(RegExp(r'[\s\-]'), '');

    // Check formats: +256XXXXXXXXX, 256XXXXXXXXX, 0XXXXXXXXX
    if (cleaned.startsWith('+256')) {
      return cleaned.length == 13 && RegExp(r'^\+256[7][0-9]{8}$').hasMatch(cleaned);
    } else if (cleaned.startsWith('256')) {
      return cleaned.length == 12 && RegExp(r'^256[7][0-9]{8}$').hasMatch(cleaned);
    } else if (cleaned.startsWith('0')) {
      return cleaned.length == 10 && RegExp(r'^0[7][0-9]{8}$').hasMatch(cleaned);
    }
    return false;
  }

  /// Format phone number to +256 format
  String get toE164Phone {
    final cleaned = replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.startsWith('+256')) {
      return cleaned;
    } else if (cleaned.startsWith('256')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      return '+256${cleaned.substring(1)}';
    }
    return cleaned;
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
