/// Notification types
enum NotificationType {
  message,
  offer,
  offerAccepted,
  offerDeclined,
  listingApproved,
  listingRejected,
  listingSold,
  newFollower,
  priceDropped,
  system,
}

/// App notification entity
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? targetId;
  final String? targetType;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.targetId,
    this.targetType,
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    String? targetId,
    String? targetType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'targetId': targetId,
      'targetType': targetType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      title: map['title'] as String,
      body: map['body'] as String,
      imageUrl: map['imageUrl'] as String?,
      targetId: map['targetId'] as String?,
      targetType: map['targetType'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Factory for parsing API JSON response
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Parse data field which contains targetId and targetType
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return AppNotification(
      id: json['id'] as String,
      type: _parseNotificationType(json['type'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: data['imageUrl'] as String?,
      targetId:
          data['targetId'] as String? ??
          data['offerId'] as String? ??
          data['chatId'] as String? ??
          data['listingId'] as String? ??
          data['reviewId'] as String?,
      targetType: data['type'] as String? ?? data['targetType'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.system;

    // API uses SCREAMING_SNAKE_CASE, Flutter uses camelCase
    switch (type.toUpperCase()) {
      case 'MESSAGE':
        return NotificationType.message;
      case 'OFFER':
        return NotificationType.offer;
      case 'OFFER_ACCEPTED':
        return NotificationType.offerAccepted;
      case 'OFFER_DECLINED':
        return NotificationType.offerDeclined;
      case 'LISTING_APPROVED':
        return NotificationType.listingApproved;
      case 'LISTING_REJECTED':
        return NotificationType.listingRejected;
      case 'LISTING_SOLD':
        return NotificationType.listingSold;
      case 'NEW_FOLLOWER':
        return NotificationType.newFollower;
      case 'PRICE_DROP':
        return NotificationType.priceDropped;
      case 'SYSTEM':
      default:
        return NotificationType.system;
    }
  }
}
