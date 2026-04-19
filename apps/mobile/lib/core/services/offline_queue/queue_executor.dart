import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/chat/application/chat_provider.dart';
import '../../../features/chat/domain/entities/chat.dart';
import '../../providers/repository_providers.dart';
import 'offline_queue.dart';
import 'queued_action.dart';

/// Builds the [QueuedActionExecutor] used by the offline queue.
///
/// Takes a [ProviderContainer] so it can be invoked from either a Widget
/// (via `ProviderScope.containerOf(context)`) or a plain Dart entrypoint.
/// Kept separate from the queue itself so the queue stays trivially
/// testable (no repository imports) and so adding a new action kind is one
/// switch case in this file plus one case in [QueuedActionKind].
QueuedActionExecutor buildQueueExecutor(ProviderContainer container) {
  return (QueuedAction action) async {
    switch (action.kind) {
      case QueuedActionKind.sendMessage:
        return _replaySendMessage(container, action);
      case QueuedActionKind.saveListing:
        return _replaySaveListing(container, action);
      case QueuedActionKind.unsaveListing:
        return _replayUnsaveListing(container, action);
      case QueuedActionKind.markChatRead:
        return _replayMarkChatRead(container, action);
      case QueuedActionKind.unknown:
        debugPrint('OfflineQueue: unknown action ${action.id} — dropping');
        return false; // drop
    }
  };
}

Future<bool> _replaySendMessage(
  ProviderContainer container,
  QueuedAction action,
) async {
  final repo = container.read(chatRepositoryProvider);
  final p = action.payload;
  try {
    await repo.sendMessage(
      SendMessageRequest(
        chatId: p['chatId'] as String,
        content: p['content'] as String,
        type: MessageType.values.firstWhere(
          (t) => t.name == (p['type'] as String?),
          orElse: () => MessageType.text,
        ),
        imageUrl: p['imageUrl'] as String?,
        offerAmount: p['offerAmount'] as int?,
        meetupData: (p['meetupData'] as Map?)?.cast<String, dynamic>(),
      ),
      p['userId'] as String,
      p['userName'] as String,
    );
    return true;
  } on DioException catch (e) {
    // Permanent client error (bad input, gone, forbidden): drop so we don't
    // loop forever. Transient/server errors: rethrow so the queue keeps it.
    if (_isPermanentClientError(e)) return false;
    rethrow;
  }
}

Future<bool> _replaySaveListing(
  ProviderContainer container,
  QueuedAction action,
) async {
  final repo = container.read(listingApiRepositoryProvider);
  try {
    await repo.save(action.payload['listingId'] as String);
    return true;
  } on DioException catch (e) {
    if (_isPermanentClientError(e)) return false;
    rethrow;
  }
}

Future<bool> _replayUnsaveListing(
  ProviderContainer container,
  QueuedAction action,
) async {
  final repo = container.read(listingApiRepositoryProvider);
  try {
    await repo.unsave(action.payload['listingId'] as String);
    return true;
  } on DioException catch (e) {
    if (_isPermanentClientError(e)) return false;
    rethrow;
  }
}

Future<bool> _replayMarkChatRead(
  ProviderContainer container,
  QueuedAction action,
) async {
  final repo = container.read(chatRepositoryProvider);
  try {
    await repo.markAsRead(
      action.payload['chatId'] as String,
      action.payload['userId'] as String,
    );
    return true;
  } on DioException catch (e) {
    if (_isPermanentClientError(e)) return false;
    rethrow;
  }
}

bool _isPermanentClientError(DioException e) {
  final code = e.response?.statusCode ?? 0;
  // 4xx except 408/425/429 are "your fault, don't retry" per RFC semantics.
  return code >= 400 && code < 500 && code != 408 && code != 425 && code != 429;
}
