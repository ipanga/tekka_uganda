/// Message status
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get apiValue => name.toUpperCase();

  static MessageStatus fromApi(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => MessageStatus.sent,
    );
  }
}

/// Message type
enum MessageType {
  text,
  image,
  offer,
  system,
  meetup;

  String get apiValue => name.toUpperCase();

  static MessageType fromApi(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => MessageType.text,
    );
  }
}

/// Represents a chat conversation between buyer and seller
class Chat {
  final String id;
  final String listingId;
  final String? listingTitle;
  final String? listingImageUrl;
  final int? listingPrice;
  final String buyerId;
  final String? buyerName;
  final String? buyerPhotoUrl;
  final String sellerId;
  final String? sellerName;
  final String? sellerPhotoUrl;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int buyerUnread;
  final int sellerUnread;
  final bool isArchivedBuyer;
  final bool isArchivedSeller;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.listingId,
    this.listingTitle,
    this.listingImageUrl,
    this.listingPrice,
    required this.buyerId,
    this.buyerName,
    this.buyerPhotoUrl,
    required this.sellerId,
    this.sellerName,
    this.sellerPhotoUrl,
    this.lastMessageText,
    this.lastMessageAt,
    this.buyerUnread = 0,
    this.sellerUnread = 0,
    this.isArchivedBuyer = false,
    this.isArchivedSeller = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the other participant's info based on current user
  String getOtherUserName(String currentUserId) {
    return currentUserId == buyerId
        ? (sellerName ?? 'Seller')
        : (buyerName ?? 'Buyer');
  }

  String? getOtherUserPhotoUrl(String currentUserId) {
    return currentUserId == buyerId ? sellerPhotoUrl : buyerPhotoUrl;
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == buyerId ? sellerId : buyerId;
  }

  int getUnreadCount(String currentUserId) {
    return currentUserId == buyerId ? buyerUnread : sellerUnread;
  }

  bool isArchived(String currentUserId) {
    return currentUserId == buyerId ? isArchivedBuyer : isArchivedSeller;
  }

  /// Check if current user is the buyer
  bool isBuyer(String currentUserId) => currentUserId == buyerId;

  Chat copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    int? listingPrice,
    String? buyerId,
    String? buyerName,
    String? buyerPhotoUrl,
    String? sellerId,
    String? sellerName,
    String? sellerPhotoUrl,
    String? lastMessageText,
    DateTime? lastMessageAt,
    int? buyerUnread,
    int? sellerUnread,
    bool? isArchivedBuyer,
    bool? isArchivedSeller,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      listingPrice: listingPrice ?? this.listingPrice,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhotoUrl: buyerPhotoUrl ?? this.buyerPhotoUrl,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhotoUrl: sellerPhotoUrl ?? this.sellerPhotoUrl,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      buyerUnread: buyerUnread ?? this.buyerUnread,
      sellerUnread: sellerUnread ?? this.sellerUnread,
      isArchivedBuyer: isArchivedBuyer ?? this.isArchivedBuyer,
      isArchivedSeller: isArchivedSeller ?? this.isArchivedSeller,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'lastMessage': lastMessageText,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'buyerUnread': buyerUnread,
      'sellerUnread': sellerUnread,
      'isArchivedBuyer': isArchivedBuyer,
      'isArchivedSeller': isArchivedSeller,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Handle embedded objects
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final seller = json['seller'] as Map<String, dynamic>?;
    final listing = json['listing'] as Map<String, dynamic>?;
    final otherUser = json['otherUser'] as Map<String, dynamic>?;
    final lastMessage = json['lastMessage'];

    // Handle lastMessage - backend returns it as object in list queries, string in other places
    String? lastMessageText;
    if (lastMessage is Map<String, dynamic>) {
      lastMessageText = lastMessage['content'] as String?;
    } else {
      lastMessageText = lastMessage as String?;
    }

    // Backend returns computed unreadCount for current user
    final unreadCount = json['unreadCount'] as int? ?? 0;

    return Chat(
      id: json['id'] as String,
      listingId: listing?['id'] ?? json['listingId'] as String,
      listingTitle: listing?['title'] ?? json['listingTitle'] as String?,
      listingImageUrl:
          listing?['imageUrls']?[0] ?? json['listingImageUrl'] as String?,
      listingPrice: listing?['price'] ?? json['listingPrice'] as int?,
      buyerId: buyer?['id'] ?? json['buyerId'] as String,
      buyerName: buyer?['displayName'] ?? json['buyerName'] as String?,
      buyerPhotoUrl: buyer?['photoUrl'] ?? json['buyerPhotoUrl'] as String?,
      sellerId: seller?['id'] ?? json['sellerId'] as String,
      sellerName:
          seller?['displayName'] ??
          otherUser?['displayName'] ??
          json['sellerName'] as String?,
      sellerPhotoUrl:
          seller?['photoUrl'] ??
          otherUser?['photoUrl'] ??
          json['sellerPhotoUrl'] as String?,
      lastMessageText: lastMessageText,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      // Use unreadCount if provided (from list queries), otherwise use individual fields
      buyerUnread: json['buyerUnread'] as int? ?? unreadCount,
      sellerUnread: json['sellerUnread'] as int? ?? unreadCount,
      isArchivedBuyer: json['isArchivedBuyer'] as bool? ?? false,
      isArchivedSeller: json['isArchivedSeller'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  factory Chat.fromMap(Map<String, dynamic> map) => Chat.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  /// Get time ago string for last message
  String get timeAgo {
    if (lastMessageAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    if (difference.inDays > 7) {
      return '${lastMessageAt!.day}/${lastMessageAt!.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}

/// Represents a single message in a chat
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final MessageType type;
  final String content;
  final String? imageUrl;
  final int? offerAmount;
  final Map<String, dynamic>? meetupData;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.type = MessageType.text,
    required this.content,
    this.imageUrl,
    this.offerAmount,
    this.meetupData,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.readAt,
  });

  bool isFromMe(String currentUserId) => senderId == currentUserId;

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    MessageType? type,
    String? content,
    String? imageUrl,
    int? offerAmount,
    Map<String, dynamic>? meetupData,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      type: type ?? this.type,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      offerAmount: offerAmount ?? this.offerAmount,
      meetupData: meetupData ?? this.meetupData,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'type': type.apiValue,
      'content': content,
      'imageUrl': imageUrl,
      'offerAmount': offerAmount,
      'meetupData': meetupData,
      'status': status.apiValue,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;

    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: sender?['id'] ?? json['senderId'] as String,
      senderName: sender?['displayName'] ?? json['senderName'] as String?,
      senderPhotoUrl: sender?['photoUrl'] ?? json['senderPhotoUrl'] as String?,
      type: MessageType.fromApi(json['type'] as String? ?? 'TEXT'),
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      offerAmount: json['offerAmount'] as int?,
      meetupData: json['meetupData'] as Map<String, dynamic>?,
      status: MessageStatus.fromApi(json['status'] as String? ?? 'SENT'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  factory Message.fromMap(Map<String, dynamic> map) => Message.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  /// Get formatted time
  String get formattedTime {
    final hour = createdAt.hour;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get formatted date for grouping
  String get dateGroup {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[messageDate.weekday - 1];
    } else {
      return '${messageDate.day}/${messageDate.month}/${messageDate.year}';
    }
  }
}

/// Paginated messages response
class MessagePage {
  final List<Message> messages;
  final String? nextCursor;
  final bool hasMore;

  const MessagePage({
    required this.messages,
    this.nextCursor,
    this.hasMore = false,
  });

  factory MessagePage.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] as List<dynamic>? ??
        json['messages'] as List<dynamic>? ??
        [];
    return MessagePage(
      messages: data
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

/// Request to create a new chat
class CreateChatRequest {
  final String listingId;
  final String sellerId;
  final String? initialMessage;
  // Additional fields for Firebase backward compatibility
  final String? listingTitle;
  final String? listingImageUrl;
  final int? listingPrice;
  final String? sellerName;
  final String? sellerPhotoUrl;

  const CreateChatRequest({
    required this.listingId,
    required this.sellerId,
    this.initialMessage,
    this.listingTitle,
    this.listingImageUrl,
    this.listingPrice,
    this.sellerName,
    this.sellerPhotoUrl,
  });

  Map<String, dynamic> toJson() => {
    'listingId': listingId,
    'sellerId': sellerId,
    if (initialMessage != null) 'initialMessage': initialMessage,
  };
}

/// Request to send a message
class SendMessageRequest {
  final String chatId;
  final MessageType type;
  final String content;
  final String? imageUrl;
  final int? offerAmount;
  final Map<String, dynamic>? meetupData;

  const SendMessageRequest({
    required this.chatId,
    this.type = MessageType.text,
    required this.content,
    this.imageUrl,
    this.offerAmount,
    this.meetupData,
  });

  Map<String, dynamic> toJson() => {
    'type': type.apiValue,
    'content': content,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (offerAmount != null) 'offerAmount': offerAmount,
    if (meetupData != null) 'meetupData': meetupData,
  };
}
