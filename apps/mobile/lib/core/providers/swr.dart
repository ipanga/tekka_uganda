import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_providers.dart';

/// Read-through cache helper for use inside a `FutureProvider`.
///
/// Behavior:
///   1. If a **fresh** cache entry exists, return it immediately (no network).
///   2. Otherwise call [fetch]. On success, write to cache and return.
///   3. If [fetch] throws AND a **stale** cache entry exists, return the
///      stale value instead of erroring — this is the offline/fallback path.
///      Screens that care can check `ref.read(staleDataProvider(key))` to
///      show a "showing cached data" hint.
///
/// Example usage:
/// ```dart
/// final listingProvider = FutureProvider.family<Listing, String>((ref, id) {
///   final repo = ref.watch(listingApiRepositoryProvider);
///   return fetchWithCache(
///     ref: ref,
///     key: CacheKeys.listingDetail(id),
///     ttl: CacheKeys.listingDetailTtl,
///     fetch: () => repo.getById(id),
///     toJson: (l) => l.toJson(),
///     fromJson: Listing.fromJson,
///   );
/// });
/// ```
Future<T> fetchWithCache<T>({
  required Ref ref,
  required String key,
  required Duration ttl,
  required Future<T> Function() fetch,
  required Map<String, dynamic> Function(T) toJson,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  final cache = ref.read(cacheServiceProvider);
  final stale = await cache.getEntry(key);

  if (stale != null && stale.isFresh) {
    try {
      return fromJson(jsonDecode(stale.dataJson) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('SWR: stale-but-fresh decode failed for $key: $e');
      await cache.invalidate(key);
    }
  }

  try {
    final value = await fetch();
    try {
      final encoded = jsonEncode(toJson(value));
      await cache.setJson(key, encoded, ttl);
      ref.read(_staleMarker(key).notifier).state = false;
    } catch (e) {
      debugPrint('SWR: cache write failed for $key: $e');
    }
    return value;
  } catch (e) {
    // Offline / server fallback: return stale data if we have any.
    if (stale != null) {
      try {
        final value = fromJson(jsonDecode(stale.dataJson) as Map<String, dynamic>);
        debugPrint('SWR: serving stale cache for $key after fetch failed: $e');
        ref.read(_staleMarker(key).notifier).state = true;
        return value;
      } catch (_) {
        // fall through to rethrow
      }
    }
    rethrow;
  }
}

/// Same as [fetchWithCache] but for lists. Identical semantics; we just
/// encode/decode through a JSON array wrapper.
Future<List<T>> fetchListWithCache<T>({
  required Ref ref,
  required String key,
  required Duration ttl,
  required Future<List<T>> Function() fetch,
  required Map<String, dynamic> Function(T) toJson,
  required T Function(Map<String, dynamic>) fromJson,
  int? maxCacheItems,
}) async {
  return fetchWithCache<List<T>>(
    ref: ref,
    key: key,
    ttl: ttl,
    fetch: fetch,
    toJson: (list) {
      final cappedSource = maxCacheItems != null && list.length > maxCacheItems
          ? list.sublist(0, maxCacheItems)
          : list;
      return {'items': cappedSource.map(toJson).toList()};
    },
    fromJson: (json) {
      final items = (json['items'] as List<dynamic>?) ?? const [];
      return items
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    },
  );
}

/// Per-key staleness flag. Screens can watch
/// `ref.watch(staleDataProvider(key))` to render a "showing cached data" hint.
final staleDataProvider = Provider.family<bool, String>((ref, key) {
  return ref.watch(_staleMarker(key));
});

final _staleMarker = StateProvider.family<bool, String>((ref, key) => false);
