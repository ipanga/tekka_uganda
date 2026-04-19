import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekka/core/services/offline_queue/offline_queue.dart';
import 'package:tekka/core/services/offline_queue/queued_action.dart';

void main() {
  late OfflineQueue queue;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    queue = OfflineQueue();
    await queue.init();
  });

  group('enqueue', () {
    test('adds an action and persists it', () async {
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'abc'},
      );
      expect(queue.length, 1);

      // Simulate app relaunch — a fresh instance should read the same queue.
      final next = OfflineQueue();
      await next.init();
      expect(next.length, 1);
      expect(next.pending.first.kind, QueuedActionKind.saveListing);
      expect(next.pending.first.payload['listingId'], 'abc');
    });

    test('dedupes by idempotency key', () async {
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'abc'},
        idempotencyKey: 'save:abc',
      );
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'abc'},
        idempotencyKey: 'save:abc',
      );
      expect(queue.length, 1);
    });
  });

  group('flush', () {
    test('runs actions FIFO and removes successful ones', () async {
      final order = <String>[];
      queue.registerExecutor((action) async {
        order.add(action.payload['listingId'] as String);
        return true;
      });

      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'one'},
      );
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'two'},
      );
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'three'},
      );

      await queue.flush();

      expect(order, ['one', 'two', 'three']);
      expect(queue.length, 0);
    });

    test('stops at the first thrown error and keeps the rest queued',
        () async {
      var attempts = 0;
      queue.registerExecutor((action) async {
        attempts++;
        if (action.payload['listingId'] == 'two') throw Exception('boom');
        return true;
      });

      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'one'},
      );
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'two'},
      );
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'three'},
      );

      await queue.flush();

      // Executor was called for "one" (success) and "two" (throw); stops.
      expect(attempts, 2);
      expect(queue.length, 2); // "two" and "three" remain
      expect(queue.pending.first.payload['listingId'], 'two');
      expect(queue.pending.first.attempts, 1);
    });

    test('drops actions when executor signals non-retryable failure',
        () async {
      queue.registerExecutor((action) async => false);

      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'bad'},
      );
      await queue.flush();
      expect(queue.length, 0);
    });

    test('flush is skipped if no executor is registered', () async {
      // No executor on `queue` (the SUT). Enqueue and try to flush.
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'abc'},
      );
      await queue.flush();
      expect(queue.length, 1); // still there
    });
  });

  group('persistence', () {
    test('attempts counter survives app restart', () async {
      queue.registerExecutor((_) async => throw Exception('never succeeds'));
      await queue.enqueue(
        kind: QueuedActionKind.saveListing,
        payload: {'listingId': 'x'},
      );
      await queue.flush();
      expect(queue.pending.first.attempts, 1);

      final next = OfflineQueue();
      await next.init();
      expect(next.pending.first.attempts, 1);
    });
  });
}
