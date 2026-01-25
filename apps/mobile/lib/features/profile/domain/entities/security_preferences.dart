/// User security preferences and settings
class SecurityPreferences {
  /// Whether biometric authentication is enabled
  final bool biometricEnabled;

  /// Whether to show login alerts
  final bool loginAlerts;

  /// Whether to require confirmation for high-value transactions
  final bool requireTransactionConfirmation;

  /// High-value transaction threshold in UGX
  final int transactionThreshold;

  /// Last password change timestamp
  final DateTime? lastPasswordChange;

  /// Whether two-factor authentication is enabled
  final bool twoFactorEnabled;

  const SecurityPreferences({
    this.biometricEnabled = false,
    this.loginAlerts = true,
    this.requireTransactionConfirmation = true,
    this.transactionThreshold = 500000,
    this.lastPasswordChange,
    this.twoFactorEnabled = false,
  });

  SecurityPreferences copyWith({
    bool? biometricEnabled,
    bool? loginAlerts,
    bool? requireTransactionConfirmation,
    int? transactionThreshold,
    DateTime? lastPasswordChange,
    bool? twoFactorEnabled,
  }) {
    return SecurityPreferences(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      loginAlerts: loginAlerts ?? this.loginAlerts,
      requireTransactionConfirmation:
          requireTransactionConfirmation ?? this.requireTransactionConfirmation,
      transactionThreshold: transactionThreshold ?? this.transactionThreshold,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'biometricEnabled': biometricEnabled,
      'loginAlerts': loginAlerts,
      'requireTransactionConfirmation': requireTransactionConfirmation,
      'transactionThreshold': transactionThreshold,
      'lastPasswordChange': lastPasswordChange?.toIso8601String(),
      'twoFactorEnabled': twoFactorEnabled,
    };
  }

  factory SecurityPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SecurityPreferences();

    return SecurityPreferences(
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
      loginAlerts: map['loginAlerts'] as bool? ?? true,
      requireTransactionConfirmation:
          map['requireTransactionConfirmation'] as bool? ?? true,
      transactionThreshold: map['transactionThreshold'] as int? ?? 500000,
      lastPasswordChange: map['lastPasswordChange'] != null
          ? DateTime.parse(map['lastPasswordChange'] as String)
          : null,
      twoFactorEnabled: map['twoFactorEnabled'] as bool? ?? false,
    );
  }
}

/// Represents a login session
class LoginSession {
  final String id;
  final String deviceName;
  final String deviceType;
  final String location;
  final DateTime loginTime;
  final bool isCurrent;

  const LoginSession({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.location,
    required this.loginTime,
    this.isCurrent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'location': location,
      'loginTime': loginTime.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }

  factory LoginSession.fromMap(Map<String, dynamic> map) {
    return LoginSession(
      id: map['id'] as String,
      deviceName: map['deviceName'] as String? ?? 'Unknown Device',
      deviceType: map['deviceType'] as String? ?? 'mobile',
      location: map['location'] as String? ?? 'Unknown Location',
      loginTime: DateTime.parse(map['loginTime'] as String),
      isCurrent: map['isCurrent'] as bool? ?? false,
    );
  }
}

/// Verification status for the user
class VerificationStatus {
  final bool phoneVerified;
  final bool emailVerified;
  final bool identityVerified;
  final DateTime? phoneVerifiedAt;
  final DateTime? emailVerifiedAt;
  final DateTime? identityVerifiedAt;

  const VerificationStatus({
    this.phoneVerified = false,
    this.emailVerified = false,
    this.identityVerified = false,
    this.phoneVerifiedAt,
    this.emailVerifiedAt,
    this.identityVerifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
      'identityVerified': identityVerified,
      'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'identityVerifiedAt': identityVerifiedAt?.toIso8601String(),
    };
  }

  factory VerificationStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const VerificationStatus();

    return VerificationStatus(
      phoneVerified: map['phoneVerified'] as bool? ?? false,
      emailVerified: map['emailVerified'] as bool? ?? false,
      identityVerified: map['identityVerified'] as bool? ?? false,
      phoneVerifiedAt: map['phoneVerifiedAt'] != null
          ? DateTime.parse(map['phoneVerifiedAt'] as String)
          : null,
      emailVerifiedAt: map['emailVerifiedAt'] != null
          ? DateTime.parse(map['emailVerifiedAt'] as String)
          : null,
      identityVerifiedAt: map['identityVerifiedAt'] != null
          ? DateTime.parse(map['identityVerifiedAt'] as String)
          : null,
    );
  }

  int get verificationLevel {
    int level = 0;
    if (phoneVerified) level++;
    if (emailVerified) level++;
    if (identityVerified) level++;
    return level;
  }

  String get verificationBadge {
    switch (verificationLevel) {
      case 3:
        return 'Fully Verified';
      case 2:
        return 'Verified';
      case 1:
        return 'Basic';
      default:
        return 'Unverified';
    }
  }
}
