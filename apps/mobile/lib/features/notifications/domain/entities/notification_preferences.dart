/// User notification preferences
class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool marketingEnabled;

  // Granular push notification settings
  final bool messageNotifications;
  final bool offerNotifications;
  final bool reviewNotifications;
  final bool listingNotifications;
  final bool systemNotifications;

  // Do not disturb
  final bool doNotDisturb;
  final int? dndStartHour; // 0-23
  final int? dndEndHour; // 0-23

  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.marketingEnabled = false,
    this.messageNotifications = true,
    this.offerNotifications = true,
    this.reviewNotifications = true,
    this.listingNotifications = true,
    this.systemNotifications = true,
    this.doNotDisturb = false,
    this.dndStartHour,
    this.dndEndHour,
  });

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? marketingEnabled,
    bool? messageNotifications,
    bool? offerNotifications,
    bool? reviewNotifications,
    bool? listingNotifications,
    bool? systemNotifications,
    bool? doNotDisturb,
    int? dndStartHour,
    int? dndEndHour,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      offerNotifications: offerNotifications ?? this.offerNotifications,
      reviewNotifications: reviewNotifications ?? this.reviewNotifications,
      listingNotifications: listingNotifications ?? this.listingNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
      dndStartHour: dndStartHour ?? this.dndStartHour,
      dndEndHour: dndEndHour ?? this.dndEndHour,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'marketingEnabled': marketingEnabled,
      'messageNotifications': messageNotifications,
      'offerNotifications': offerNotifications,
      'reviewNotifications': reviewNotifications,
      'listingNotifications': listingNotifications,
      'systemNotifications': systemNotifications,
      'doNotDisturb': doNotDisturb,
      'dndStartHour': dndStartHour,
      'dndEndHour': dndEndHour,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();

    return NotificationPreferences(
      pushEnabled: map['pushEnabled'] as bool? ?? true,
      emailEnabled: map['emailEnabled'] as bool? ?? true,
      marketingEnabled: map['marketingEnabled'] as bool? ?? false,
      messageNotifications: map['messageNotifications'] as bool? ?? true,
      offerNotifications: map['offerNotifications'] as bool? ?? true,
      reviewNotifications: map['reviewNotifications'] as bool? ?? true,
      listingNotifications: map['listingNotifications'] as bool? ?? true,
      systemNotifications: map['systemNotifications'] as bool? ?? true,
      doNotDisturb: map['doNotDisturb'] as bool? ?? false,
      dndStartHour: map['dndStartHour'] as int?,
      dndEndHour: map['dndEndHour'] as int?,
    );
  }

  /// Check if notifications should be shown based on DND settings
  bool shouldShowNotification() {
    if (!pushEnabled) return false;
    if (!doNotDisturb) return true;

    if (dndStartHour == null || dndEndHour == null) return true;

    final now = DateTime.now();
    final currentHour = now.hour;

    // Handle overnight DND (e.g., 22:00 to 07:00)
    if (dndStartHour! > dndEndHour!) {
      return currentHour >= dndEndHour! && currentHour < dndStartHour!;
    }

    // Handle same-day DND (e.g., 09:00 to 17:00)
    return currentHour < dndStartHour! || currentHour >= dndEndHour!;
  }
}
