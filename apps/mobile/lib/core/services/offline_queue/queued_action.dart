import 'package:flutter/foundation.dart' show immutable;

/// A pending mutation that ran while offline and needs to be replayed.
///
/// Kept deliberately small: the set of action types is closed (see
/// [QueuedActionKind]) and the payload is free-form JSON so we don't have to
/// ship a heavyweight serialization library. Each action carries a client-
/// generated [idempotencyKey] so a flush that fails halfway won't double-
/// submit on the next attempt.
@immutable
class QueuedAction {
  final String id;
  final QueuedActionKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String idempotencyKey;

  const QueuedAction({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    required this.idempotencyKey,
    this.attempts = 0,
  });

  QueuedAction incrementAttempts() => QueuedAction(
    id: id,
    kind: kind,
    payload: payload,
    createdAt: createdAt,
    idempotencyKey: idempotencyKey,
    attempts: attempts + 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'payload': payload,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'attempts': attempts,
    'idempotencyKey': idempotencyKey,
  };

  static QueuedAction? fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'];
    final kind = QueuedActionKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => QueuedActionKind.unknown,
    );
    if (kind == QueuedActionKind.unknown) return null;
    return QueuedAction(
      id: json['id'] as String,
      kind: kind,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      attempts: (json['attempts'] as int?) ?? 0,
      idempotencyKey: json['idempotencyKey'] as String,
    );
  }
}

/// Closed set of queueable actions. If you add one, teach
/// [OfflineQueue._dispatch] how to execute it.
enum QueuedActionKind {
  sendMessage,
  saveListing,
  unsaveListing,
  markChatRead,
  unknown,
}
