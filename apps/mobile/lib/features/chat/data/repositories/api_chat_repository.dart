import 'dart:async';

import '../../../../core/services/api_client.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_api_repository.dart';

/// API-based implementation of ChatRepository
/// Wraps ChatApiRepository to implement the repository interface
/// Note: Stream methods use periodic polling since API doesn't support WebSockets
class ApiChatRepository implements ChatRepository {
  final ChatApiRepository _apiRepository;
  final Duration _pollInterval;

  ApiChatRepository(ApiClient apiClient, {Duration? pollInterval})
      : _apiRepository = ChatApiRepository(apiClient),
        _pollInterval = pollInterval ?? const Duration(seconds: 5);

  @override
  Stream<List<Chat>> getChatsStream(String userId) {
    return _createPollingStream(
      () => _apiRepository.getChats(),
      interval: _pollInterval,
    );
  }

  @override
  Future<Chat?> getChatById(String chatId) async {
    try {
      return await _apiRepository.getChat(chatId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Chat?> getChatByListingAndUser(String listingId, String buyerId) async {
    // Get all chats and find one matching the listing and buyer
    try {
      final chats = await _apiRepository.getChats();
      return chats.cast<Chat?>().firstWhere(
        (chat) => chat!.listingId == listingId && chat.buyerId == buyerId,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Chat> createChat(
    CreateChatRequest request,
    String buyerId,
    String buyerName,
    String? buyerPhotoUrl,
  ) async {
    return _apiRepository.createOrGetChat(
      sellerId: request.sellerId,
      listingId: request.listingId,
    );
  }

  @override
  Future<Chat> getOrCreateChat(
    CreateChatRequest request,
    String buyerId,
    String buyerName,
    String? buyerPhotoUrl,
  ) async {
    return _apiRepository.createOrGetChat(
      sellerId: request.sellerId,
      listingId: request.listingId,
    );
  }

  @override
  Stream<List<Message>> getMessagesStream(String chatId, {int limit = 50}) {
    return _createPollingStream(
      () async {
        final page = await _apiRepository.getMessages(chatId, limit: limit);
        return page.messages;
      },
      interval: const Duration(seconds: 2), // Poll more frequently for messages
    );
  }

  @override
  Future<List<Message>> getMessages(String chatId, {int limit = 50, String? lastMessageId}) async {
    final page = await _apiRepository.getMessages(
      chatId,
      cursor: lastMessageId,
      limit: limit,
    );
    return page.messages;
  }

  @override
  Future<Message> sendMessage(
    SendMessageRequest request,
    String senderId,
    String senderName,
  ) async {
    return _apiRepository.sendMessage(
      request.chatId,
      content: request.content,
      type: request.type,
      imageUrl: request.imageUrl,
      offerAmount: request.offerAmount,
      meetupData: request.meetupData,
    );
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    await _apiRepository.markAsRead(chatId);
  }

  @override
  Future<void> deleteChat(String chatId) async {
    await _apiRepository.deleteChat(chatId);
  }

  @override
  Stream<int> getUnreadCountStream(String userId) {
    return _createPollingStream(
      () => _apiRepository.getUnreadCount(),
      interval: _pollInterval,
    );
  }

  @override
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    // Typing status is not supported by REST API
    // Would require WebSocket implementation
    // For now, this is a no-op
  }

  @override
  Stream<Map<String, bool>> getTypingStatusStream(String chatId) {
    // Typing status is not supported by REST API
    // Return empty stream
    return Stream.value({});
  }

  @override
  Future<void> blockUser(String chatId, String userId, String blockedUserId) async {
    // Blocking is handled through the user API, not chat API
    // This will need to call the user blocking endpoint
    // For now, archive the chat
    await _apiRepository.archiveChat(chatId);
  }

  @override
  Future<void> reportChat(String chatId, String reporterId, String reason) async {
    // Reporting is handled through a separate reports API
    // For now, this is a no-op - should be implemented in reports feature
  }

  /// Helper to create a polling stream from an async function
  Stream<T> _createPollingStream<T>(
    Future<T> Function() fetcher, {
    required Duration interval,
  }) {
    late StreamController<T> controller;
    Timer? timer;
    bool isDisposed = false;

    Future<void> poll() async {
      if (isDisposed) return;
      try {
        final data = await fetcher();
        if (!isDisposed) {
          controller.add(data);
        }
      } catch (e) {
        if (!isDisposed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<T>(
      onListen: () {
        poll(); // Initial fetch
        timer = Timer.periodic(interval, (_) => poll());
      },
      onCancel: () {
        isDisposed = true;
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}
