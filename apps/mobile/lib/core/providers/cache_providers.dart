import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cache/cache_service.dart';
import '../services/offline_queue/offline_queue.dart';

/// Process-wide cache. `keepAlive` because cache state must survive
/// provider rebuilds — that's the whole point.
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// Process-wide offline action queue. Executor is registered from
/// `main.dart` once repositories are available.
final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  return OfflineQueue();
});
