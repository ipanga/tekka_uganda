/// User privacy preferences
class PrivacyPreferences {
  /// Profile visibility setting
  final ProfileVisibility profileVisibility;

  /// Whether to show location on profile
  final bool showLocation;

  /// Whether to show phone number to other users
  final bool showPhoneNumber;

  /// Who can send messages to this user
  final MessagePermission messagePermission;

  /// Whether to show online status
  final bool showOnlineStatus;

  /// Whether to show purchase history on profile
  final bool showPurchaseHistory;

  /// Whether to show listings count on profile
  final bool showListingsCount;

  /// Whether to appear in search results
  final bool appearInSearch;

  /// Whether to allow profile to be shared via link
  final bool allowProfileSharing;

  const PrivacyPreferences({
    this.profileVisibility = ProfileVisibility.public,
    this.showLocation = true,
    this.showPhoneNumber = false,
    this.messagePermission = MessagePermission.everyone,
    this.showOnlineStatus = true,
    this.showPurchaseHistory = false,
    this.showListingsCount = true,
    this.appearInSearch = true,
    this.allowProfileSharing = true,
  });

  PrivacyPreferences copyWith({
    ProfileVisibility? profileVisibility,
    bool? showLocation,
    bool? showPhoneNumber,
    MessagePermission? messagePermission,
    bool? showOnlineStatus,
    bool? showPurchaseHistory,
    bool? showListingsCount,
    bool? appearInSearch,
    bool? allowProfileSharing,
  }) {
    return PrivacyPreferences(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showLocation: showLocation ?? this.showLocation,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      messagePermission: messagePermission ?? this.messagePermission,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showPurchaseHistory: showPurchaseHistory ?? this.showPurchaseHistory,
      showListingsCount: showListingsCount ?? this.showListingsCount,
      appearInSearch: appearInSearch ?? this.appearInSearch,
      allowProfileSharing: allowProfileSharing ?? this.allowProfileSharing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileVisibility': profileVisibility.name,
      'showLocation': showLocation,
      'showPhoneNumber': showPhoneNumber,
      'messagePermission': messagePermission.name,
      'showOnlineStatus': showOnlineStatus,
      'showPurchaseHistory': showPurchaseHistory,
      'showListingsCount': showListingsCount,
      'appearInSearch': appearInSearch,
      'allowProfileSharing': allowProfileSharing,
    };
  }

  factory PrivacyPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PrivacyPreferences();

    return PrivacyPreferences(
      profileVisibility: ProfileVisibility.values.firstWhere(
        (e) => e.name == map['profileVisibility'],
        orElse: () => ProfileVisibility.public,
      ),
      showLocation: map['showLocation'] as bool? ?? true,
      showPhoneNumber: map['showPhoneNumber'] as bool? ?? false,
      messagePermission: MessagePermission.values.firstWhere(
        (e) => e.name == map['messagePermission'],
        orElse: () => MessagePermission.everyone,
      ),
      showOnlineStatus: map['showOnlineStatus'] as bool? ?? true,
      showPurchaseHistory: map['showPurchaseHistory'] as bool? ?? false,
      showListingsCount: map['showListingsCount'] as bool? ?? true,
      appearInSearch: map['appearInSearch'] as bool? ?? true,
      allowProfileSharing: map['allowProfileSharing'] as bool? ?? true,
    );
  }
}

/// Profile visibility options
enum ProfileVisibility {
  public('Public', 'Anyone can view your profile'),
  buyersOnly('Buyers Only', 'Only users who bought from you can view'),
  private('Private', 'Only you can view your profile');

  final String displayName;
  final String description;

  const ProfileVisibility(this.displayName, this.description);
}

/// Message permission options
enum MessagePermission {
  everyone('Everyone', 'Anyone can message you'),
  verifiedOnly('Verified Users', 'Only verified users can message you'),
  noOne('No One', 'Block all incoming messages');

  final String displayName;
  final String description;

  const MessagePermission(this.displayName, this.description);
}
