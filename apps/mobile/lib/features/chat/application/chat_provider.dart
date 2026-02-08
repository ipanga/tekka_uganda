import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';
import '../../report/application/report_provider.dart';
import '../data/repositories/api_chat_repository.dart';
import '../domain/entities/chat.dart';
import '../domain/repositories/chat_repository.dart';

/// Chat repository provider - uses API backend
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiChatRepository(apiClient);
});

/// Stream of all chats for current user
final chatsStreamProvider = StreamProvider<List<Chat>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatsStream(user.uid);
});

/// Stream of unread message count
final unreadCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final repository = ref.watch(chatRepositoryProvider);
  return repository.getUnreadCountStream(user.uid);
});

/// Single chat provider
final chatProvider = FutureProvider.family<Chat?, String>((ref, chatId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatById(chatId);
});

/// Messages stream for a chat
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessagesStream(chatId);
});

/// Typing status stream for a chat
final typingStatusProvider = StreamProvider.family<Map<String, bool>, String>((
  ref,
  chatId,
) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getTypingStatusStream(chatId);
});

/// Chat actions notifier for a specific chat
class ChatActionsNotifier extends StateNotifier<ChatActionsState> {
  final ChatRepository _repository;
  final String chatId;
  final String userId;
  final String userName;
  Timer? _typingTimer;

  ChatActionsNotifier(this._repository, this.chatId, this.userId, this.userName)
    : super(const ChatActionsState());

  Future<void> sendMessage(
    String content, {
    MessageType type = MessageType.text,
    String? imageUrl,
    int? offerAmount,
    Map<String, dynamic>? meetupData,
  }) async {
    if (content.trim().isEmpty && imageUrl == null) return;

    state = state.copyWith(isSending: true);

    try {
      await _repository.sendMessage(
        SendMessageRequest(
          chatId: chatId,
          content: content.trim(),
          type: type,
          imageUrl: imageUrl,
          offerAmount: offerAmount,
          meetupData: meetupData,
        ),
        userId,
        userName,
      );
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  void setUploadingImage(bool isUploading) {
    state = state.copyWith(isUploadingImage: isUploading);
  }

  Future<void> markAsRead() async {
    try {
      await _repository.markAsRead(chatId, userId);
    } catch (_) {
      // Silently fail
    }
  }

  void setTyping(bool isTyping) {
    _typingTimer?.cancel();

    if (isTyping) {
      _repository.setTypingStatus(chatId, userId, true);

      // Auto-clear typing after 3 seconds
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _repository.setTypingStatus(chatId, userId, false);
      });
    } else {
      _repository.setTypingStatus(chatId, userId, false);
    }
  }

  Future<void> deleteChat() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteChat(chatId);
      state = state.copyWith(isLoading: false, isDeleted: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> blockUser(String blockedUserId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.blockUser(chatId, userId, blockedUserId);
      state = state.copyWith(isLoading: false, isDeleted: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> reportChat(String reason) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.reportChat(chatId, userId, reason);
      state = state.copyWith(isLoading: false, isReported: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _repository.setTypingStatus(chatId, userId, false);
    super.dispose();
  }
}

/// Chat actions state
class ChatActionsState {
  final bool isSending;
  final bool isLoading;
  final bool isUploadingImage;
  final bool isDeleted;
  final bool isReported;
  final String? error;

  const ChatActionsState({
    this.isSending = false,
    this.isLoading = false,
    this.isUploadingImage = false,
    this.isDeleted = false,
    this.isReported = false,
    this.error,
  });

  ChatActionsState copyWith({
    bool? isSending,
    bool? isLoading,
    bool? isUploadingImage,
    bool? isDeleted,
    bool? isReported,
    String? error,
  }) {
    return ChatActionsState(
      isSending: isSending ?? this.isSending,
      isLoading: isLoading ?? this.isLoading,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      isDeleted: isDeleted ?? this.isDeleted,
      isReported: isReported ?? this.isReported,
      error: error,
    );
  }
}

/// Chat actions provider - not autoDispose to prevent disposal during async operations
final chatActionsProvider =
    StateNotifierProvider.family<ChatActionsNotifier, ChatActionsState, String>(
      (ref, chatId) {
        final user = ref.watch(currentUserProvider);
        final repository = ref.watch(chatRepositoryProvider);

        return ChatActionsNotifier(
          repository,
          chatId,
          user?.uid ?? '',
          user?.displayName ?? 'User',
        );
      },
    );

/// Create chat notifier
class CreateChatNotifier extends StateNotifier<CreateChatState> {
  final ChatRepository _repository;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  CreateChatNotifier(
    this._repository,
    this.userId,
    this.userName,
    this.userPhotoUrl,
  ) : super(const CreateChatState());

  Future<Chat?> createChat(CreateChatRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final chat = await _repository.getOrCreateChat(
        request,
        userId,
        userName,
        userPhotoUrl,
      );

      state = state.copyWith(isLoading: false, createdChat: chat);
      return chat;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const CreateChatState();
  }
}

/// Create chat state
class CreateChatState {
  final bool isLoading;
  final String? error;
  final Chat? createdChat;

  const CreateChatState({this.isLoading = false, this.error, this.createdChat});

  CreateChatState copyWith({
    bool? isLoading,
    String? error,
    Chat? createdChat,
  }) {
    return CreateChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdChat: createdChat ?? this.createdChat,
    );
  }
}

/// Create chat provider - not autoDispose to prevent disposal during async operations
final createChatProvider =
    StateNotifierProvider<CreateChatNotifier, CreateChatState>((ref) {
      final user = ref.watch(currentUserProvider);
      final repository = ref.watch(chatRepositoryProvider);

      return CreateChatNotifier(
        repository,
        user?.uid ?? '',
        user?.displayName ?? 'User',
        user?.photoUrl,
      );
    });

/// Check if chat exists between user and listing
final existingChatProvider = FutureProvider.family<Chat?, String>((
  ref,
  listingId,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatByListingAndUser(listingId, user.uid);
});

/// Check if the other user in a chat is blocked (either direction)
final isChatBlockedProvider = FutureProvider.family<bool, String>((
  ref,
  otherUserId,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  // Check if current user blocked the other user
  final isBlockedByMe = await ref.watch(isBlockedProvider(otherUserId).future);
  if (isBlockedByMe) return true;

  // Check if other user blocked the current user
  final reportRepository = ref.watch(reportRepositoryProvider);
  final isBlockedByThem = await reportRepository.isBlocked(
    otherUserId,
    user.uid,
  );
  return isBlockedByThem;
});
