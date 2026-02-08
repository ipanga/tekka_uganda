/// User role enum
enum UserRole {
  user,
  admin,
  moderator;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.user,
    );
  }
}

/// Represents a Tekka user
class AppUser {
  final String uid;
  final String? firebaseUid;
  final String phoneNumber;
  final String? email;
  final bool emailVerified;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActiveAt;
  final bool isOnboardingComplete;
  final bool isVerified;
  final bool isIdentityVerified;
  final bool isSuspended;
  final String? suspendedReason;
  final UserRole role;
  final bool showPhoneNumber;

  const AppUser({
    required this.uid,
    this.firebaseUid,
    required this.phoneNumber,
    this.email,
    this.emailVerified = false,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.location,
    required this.createdAt,
    this.updatedAt,
    this.lastActiveAt,
    this.isOnboardingComplete = false,
    this.isVerified = false,
    this.isIdentityVerified = false,
    this.isSuspended = false,
    this.suspendedReason,
    this.role = UserRole.user,
    this.showPhoneNumber = false,
  });

  AppUser copyWith({
    String? uid,
    String? firebaseUid,
    String? phoneNumber,
    String? email,
    bool? emailVerified,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
    bool? isOnboardingComplete,
    bool? isVerified,
    bool? isIdentityVerified,
    bool? isSuspended,
    String? suspendedReason,
    UserRole? role,
    bool? showPhoneNumber,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      isVerified: isVerified ?? this.isVerified,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedReason: suspendedReason ?? this.suspendedReason,
      role: role ?? this.role,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'firebaseUid': firebaseUid,
      'phoneNumber': phoneNumber,
      'email': email,
      'isEmailVerified': emailVerified,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'isOnboardingComplete': isOnboardingComplete,
      'isVerified': isVerified,
      'isIdentityVerified': isIdentityVerified,
      'isSuspended': isSuspended,
      'suspendedReason': suspendedReason,
      'role': role.name.toUpperCase(),
      'showPhoneNumber': showPhoneNumber,
    };
  }

  /// Create from API response JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String?,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      emailVerified: json['isEmailVerified'] as bool? ?? false,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      isOnboardingComplete: json['isOnboardingComplete'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      isIdentityVerified: json['isIdentityVerified'] as bool? ?? false,
      isSuspended: json['isSuspended'] as bool? ?? false,
      suspendedReason: json['suspendedReason'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'USER'),
      showPhoneNumber: json['showPhoneNumber'] as bool? ?? false,
    );
  }

  /// Legacy map factory (for Firebase compatibility)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    // Support both API format (id) and Firebase format (uid)
    final id = map['id'] ?? map['uid'];
    return AppUser(
      uid: id as String,
      firebaseUid: map['firebaseUid'] as String?,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String?,
      emailVerified:
          map['emailVerified'] ?? map['isEmailVerified'] as bool? ?? false,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      location: map['location'] as String?,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.parse(map['lastActiveAt'] as String)
          : null,
      isOnboardingComplete: map['isOnboardingComplete'] as bool? ?? false,
      isVerified: map['isVerified'] as bool? ?? false,
      isIdentityVerified: map['isIdentityVerified'] as bool? ?? false,
      isSuspended: map['isSuspended'] as bool? ?? false,
      suspendedReason: map['suspendedReason'] as String?,
      role: UserRole.fromString(map['role'] as String? ?? 'USER'),
      showPhoneNumber: map['showPhoneNumber'] as bool? ?? false,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => toMap();
}

/// User stats from API
class UserStats {
  final int totalListings;
  final int activeListings;
  final int soldListings;
  final int totalSales;
  final double averageRating;
  final int totalReviews;
  final int totalViews;
  final int totalFavorites;

  const UserStats({
    this.totalListings = 0,
    this.activeListings = 0,
    this.soldListings = 0,
    this.totalSales = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalViews = 0,
    this.totalFavorites = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalListings: json['totalListings'] as int? ?? 0,
      activeListings: json['activeListings'] as int? ?? 0,
      soldListings: json['soldListings'] as int? ?? 0,
      totalSales: json['totalSales'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
      totalFavorites: json['totalFavorites'] as int? ?? 0,
    );
  }
}
