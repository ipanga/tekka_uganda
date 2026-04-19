import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekka/core/services/cache/cache_service.dart';

void main() {
  late CacheService cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = CacheService(memoryCapacity: 3);
    await cache.init();
  });

  group('get/set', () {
    test('returns null on miss', () async {
      expect(await cache.getJson('missing'), isNull);
    });

    test('round-trips through memory', () async {
      await cache.setJson('k', '"hello"', const Duration(minutes: 1));
      expect(await cache.getJson('k'), '"hello"');
    });

    test('round-trips through prefs when memory is cleared', () async {
      await cache.setJson('k', '"hello"', const Duration(minutes: 1));
      // New instance — memory is empty, so any hit must come from L2.
      final prefs = await SharedPreferences.getInstance();
      final other = CacheService(prefs: prefs);
      expect(await other.getJson('k'), '"hello"');
    });
  });

  group('TTL', () {
    test('expired entries are reported as miss', () async {
      await cache.setJson(
        'k',
        '"stale"',
        const Duration(milliseconds: -1), // already expired
      );
      expect(await cache.getJson('k'), isNull);
    });

    test('getEntry returns a stale entry for SWR fallback', () async {
      await cache.setJson(
        'k',
        '"stale"',
        const Duration(milliseconds: -1),
      );
      final entry = await cache.getEntry('k');
      expect(entry, isNotNull);
      expect(entry!.isFresh, isFalse);
      expect(entry.dataJson, '"stale"');
    });
  });

  group('invalidation', () {
    test('invalidate drops a single key from both tiers', () async {
      await cache.setJson('k', '"v"', const Duration(minutes: 1));
      await cache.invalidate('k');
      expect(await cache.getJson('k'), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tekka_cache:k'), isNull);
    });

    test('invalidatePrefix nukes everything with a given prefix', () async {
      final ttl = const Duration(minutes: 1);
      await cache.setJson('listings:a', '"1"', ttl);
      await cache.setJson('listings:b', '"2"', ttl);
      await cache.setJson('user:1', '"3"', ttl);
      await cache.invalidatePrefix('listings:');
      expect(await cache.getJson('listings:a'), isNull);
      expect(await cache.getJson('listings:b'), isNull);
      expect(await cache.getJson('user:1'), '"3"');
    });
  });

  group('memory capacity', () {
    test('evicts oldest entry once over capacity', () async {
      final ttl = const Duration(minutes: 1);
      await cache.setJson('a', '"1"', ttl);
      await cache.setJson('b', '"2"', ttl);
      await cache.setJson('c', '"3"', ttl);
      await cache.setJson('d', '"4"', ttl); // evicts "a"
      expect(cache.memorySize, 3);
    });
  });

  group('L2 size guard', () {
    test('oversized payloads skip shared_preferences but stay in memory',
        () async {
      final big = jsonEncode({'blob': 'x' * (60 * 1024)});
      await cache.setJson('huge', big, const Duration(minutes: 1));
      // Memory hit works.
      expect(await cache.getJson('huge'), big);
      // But L2 does not persist it.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tekka_cache:huge'), isNull);
    });
  });
}
