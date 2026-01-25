import '../entities/chat.dart';

/// Chat repository interface
abstract class ChatRepository {
  /// Get all chats for a user (as buyer or seller)
  Stream<List<Chat>> getChatsStream(String userId);

  /// Get a single chat by ID
  Future<Chat?> getChatById(String chatId);

  /// Get chat between user and listing (to check if exists)
  Future<Chat?> getChatByListingAndUser(String listingId, String buyerId);

  /// Create a new chat conversation
  Future<Chat> createChat(CreateChatRequest request, String buyerId, String buyerName, String? buyerPhotoUrl);

  /// Get or create chat (returns existing if already exists)
  Future<Chat> getOrCreateChat(CreateChatRequest request, String buyerId, String buyerName, String? buyerPhotoUrl);

  /// Get messages stream for a chat
  Stream<List<Message>> getMessagesStream(String chatId, {int limit = 50});

  /// Get messages with pagination
  Future<List<Message>> getMessages(String chatId, {int limit = 50, String? lastMessageId});

  /// Send a message
  Future<Message> sendMessage(SendMessageRequest request, String senderId, String senderName);

  /// Mark messages as read
  Future<void> markAsRead(String chatId, String userId);

  /// Delete a chat (soft delete - marks as inactive)
  Future<void> deleteChat(String chatId);

  /// Get total unread count for a user
  Stream<int> getUnreadCountStream(String userId);

  /// Update typing status
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping);

  /// Get typing status stream
  Stream<Map<String, bool>> getTypingStatusStream(String chatId);

  /// Block a user in chat
  Future<void> blockUser(String chatId, String userId, String blockedUserId);

  /// Report a chat/user
  Future<void> reportChat(String chatId, String reporterId, String reason);
}
