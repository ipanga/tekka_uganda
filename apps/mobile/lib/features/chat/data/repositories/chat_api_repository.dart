import '../../../../core/services/api_client.dart';
import '../../domain/entities/chat.dart';

/// Repository for chat-related API calls
class ChatApiRepository {
  final ApiClient _apiClient;

  ChatApiRepository(this._apiClient);

  /// Get all chats for current user
  Future<List<Chat>> getChats() async {
    final response = await _apiClient.get<List<dynamic>>('/chats');
    return response
        .map((e) => Chat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create or get existing chat
  Future<Chat> createOrGetChat({
    required String sellerId,
    required String listingId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/chats',
      data: {'sellerId': sellerId, 'listingId': listingId},
    );
    return Chat.fromJson(response);
  }

  /// Get total unread message count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/chats/unread-count',
    );
    // Backend returns { unreadCount: number }
    return response['unreadCount'] as int? ?? response['count'] as int? ?? 0;
  }

  /// Search messages across all chats
  Future<List<Message>> searchMessages(String query, {int? limit}) async {
    final queryParams = <String, dynamic>{'q': query};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get<List<dynamic>>(
      '/chats/search',
      queryParameters: queryParams,
    );
    return response
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific chat by ID
  Future<Chat> getChat(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/chats/$id');
    return Chat.fromJson(response);
  }

  /// Get messages for a chat with pagination
  Future<MessagePage> getMessages(
    String chatId, {
    String? cursor,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit.toString()};
    if (cursor != null) queryParams['cursor'] = cursor;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/chats/$chatId/messages',
      queryParameters: queryParams,
    );
    return MessagePage.fromJson(response);
  }

  /// Send a message in a chat
  Future<Message> sendMessage(
    String chatId, {
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    int? offerAmount,
    Map<String, dynamic>? meetupData,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/chats/$chatId/messages',
      data: {
        'content': content,
        'type': type.apiValue,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (offerAmount != null) 'offerAmount': offerAmount,
        if (meetupData != null) 'meetupData': meetupData,
      },
    );
    return Message.fromJson(response);
  }

  /// Mark all messages in chat as read
  Future<void> markAsRead(String chatId) async {
    await _apiClient.put('/chats/$chatId/read');
  }

  /// Archive a chat
  Future<void> archiveChat(String chatId) async {
    await _apiClient.put('/chats/$chatId/archive');
  }

  /// Unarchive a chat
  Future<void> unarchiveChat(String chatId) async {
    await _apiClient.put('/chats/$chatId/unarchive');
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    await _apiClient.delete('/chats/$chatId');
  }

  /// Edit a message
  Future<Message> updateMessage(String messageId, String content) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/chats/messages/$messageId',
      data: {'content': content},
    );
    return Message.fromJson(response);
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _apiClient.delete('/chats/messages/$messageId');
  }
}
