import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'queued_action.dart';

/// Signature an executor must implement. Return `true` if the action was
/// applied and can be removed from the queue; `false` to drop (e.g. on
/// permanent 4xx). Throw to keep the action queued for a later retry.
typedef QueuedActionExecutor = Future<bool> Function(QueuedAction action);

/// Persistent FIFO queue of mutations that couldn't be made while offline.
///
/// Stored under a single shared_preferences key as a JSON array. Entries are
/// executed by whoever registered an executor — the queue itself knows
/// nothing about repositories or API shapes. This keeps the queue testable
/// and avoids circular imports.
class OfflineQueue {
  OfflineQueue({SharedPreferences? prefs, Uuid? uuid})
    : _prefs = prefs,
      _uuid = uuid ?? const Uuid();

  static const String _storageKey = 'tekka_offline_queue_v1';

  /// Max attempts before we give up and drop an action. Prevents a single
  /// broken action from jamming the queue forever.
  static const int _maxAttempts = 5;

  SharedPreferences? _prefs;
  final Uuid _uuid;
  final Completer<void> _ready = Completer<void>();
  final List<QueuedAction> _queue = [];
  bool _loaded = false;
  bool _flushing = false;

  QueuedActionExecutor? _executor;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load persisted queue from disk. Safe to call multiple times.
  Future<void> init() async {
    if (_loaded) return;
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          final action =
              QueuedAction.fromJson(item as Map<String, dynamic>);
          if (action != null) _queue.add(action);
        }
      }
    } catch (e) {
      debugPrint('OfflineQueue: failed to load persisted queue: $e');
    } finally {
      _loaded = true;
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  /// Register the callback that actually performs actions during a flush.
  /// Call once at app start.
  void registerExecutor(QueuedActionExecutor executor) {
    _executor = executor;
  }

  /// Enqueue a new action. Generates an idempotency key if none given so
  /// repeat flushes don't double-apply the same logical mutation.
  Future<QueuedAction> enqueue({
    required QueuedActionKind kind,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    await init();
    final action = QueuedAction(
      id: _uuid.v4(),
      kind: kind,
      payload: payload,
      createdAt: DateTime.now(),
      idempotencyKey: idempotencyKey ?? _uuid.v4(),
    );
    // Dedup: if an identical-idempotencyKey action is already queued, drop
    // the new one. This keeps e.g. rapid double-taps on "save" from stacking.
    final exists = _queue.any((a) => a.idempotencyKey == action.idempotencyKey);
    if (!exists) {
      _queue.add(action);
      await _persist();
    }
    return action;
  }

  /// Apply every queued action in FIFO order. Skips silently if already
  /// flushing or if no executor is registered.
  Future<void> flush() async {
    if (_flushing) return;
    if (_executor == null) {
      debugPrint('OfflineQueue: flush skipped — no executor registered');
      return;
    }
    await init();
    if (_queue.isEmpty) return;

    _flushing = true;
    try {
      // Snapshot so concurrent enqueues don't confuse iteration.
      final snapshot = List<QueuedAction>.from(_queue);
      for (final action in snapshot) {
        // Someone else may have drained it in the meantime.
        if (!_queue.any((a) => a.id == action.id)) continue;
        try {
          final done = await _executor!(action);
          if (done) {
            _queue.removeWhere((a) => a.id == action.id);
          } else {
            // Executor said "drop this" — non-retryable failure.
            debugPrint(
              'OfflineQueue: dropping ${action.kind.name} '
              '(id=${action.id}) on executor signal',
            );
            _queue.removeWhere((a) => a.id == action.id);
          }
        } catch (e) {
          // Keep it queued but bump attempts; drop after too many.
          final bumped = action.incrementAttempts();
          final idx = _queue.indexWhere((a) => a.id == action.id);
          if (idx >= 0) {
            if (bumped.attempts >= _maxAttempts) {
              debugPrint(
                'OfflineQueue: giving up on ${action.kind.name} '
                '(id=${action.id}) after ${bumped.attempts} attempts: $e',
              );
              _queue.removeAt(idx);
            } else {
              _queue[idx] = bumped;
            }
          }
          // Don't keep hammering — let the caller re-flush later.
          break;
        }
      }
    } finally {
      await _persist();
      _flushing = false;
    }
  }

  /// Current pending action count (useful for UI badges).
  int get length => _queue.length;

  List<QueuedAction> get pending => List.unmodifiable(_queue);

  Future<void> clear() async {
    _queue.clear();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await _getPrefs();
      final list = _queue.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('OfflineQueue: failed to persist: $e');
    }
  }
}
