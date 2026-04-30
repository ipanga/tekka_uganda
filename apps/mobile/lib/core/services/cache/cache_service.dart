import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single cache entry.
@immutable
class CacheEntry {
  final String dataJson;
  final DateTime fetchedAt;
  final DateTime expiresAt;

  const CacheEntry({
    required this.dataJson,
    required this.fetchedAt,
    required this.expiresAt,
  });

  bool get isFresh => DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
    'd': dataJson,
    'f': fetchedAt.millisecondsSinceEpoch,
    'e': expiresAt.millisecondsSinceEpoch,
  };

  static CacheEntry? fromJson(Map<String, dynamic> json) {
    final data = json['d'];
    final fetched = json['f'];
    final expires = json['e'];
    if (data is! String || fetched is! int || expires is! int) return null;
    return CacheEntry(
      dataJson: data,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetched),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expires),
    );
  }
}

/// Two-tier TTL cache — L1 in-memory LRU + L2 shared_preferences.
///
/// Values are stored as already-serialized JSON strings so the cache stays
/// model-agnostic. Callers pass `toJson`/`fromJson` at the call site (see
/// `providers/swr.dart`).
class CacheService {
  CacheService({SharedPreferences? prefs, int memoryCapacity = 100})
    : _prefs = prefs,
      _memoryCapacity = memoryCapacity;

  static const String _prefsPrefix = 'tekka_cache:';

  /// L2 entries larger than this are kept memory-only (prefs would bloat).
  static const int _maxPrefsEntryBytes = 50 * 1024;

  SharedPreferences? _prefs;
  final int _memoryCapacity;

  /// L1 cache — insertion-ordered for LRU semantics.
  final LinkedHashMap<String, CacheEntry> _memory = LinkedHashMap();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Called once at app start so subsequent gets don't await prefs init.
  Future<void> init() async {
    await _getPrefs();
  }

  /// Returns the cached JSON string if still fresh, else null.
  /// On a miss in L1, probes L2 and hydrates L1 if found.
  Future<String?> getJson(String key) async {
    final memHit = _memory.remove(key);
    if (memHit != null) {
      if (memHit.isFresh) {
        _memory[key] = memHit; // re-insert at tail (most recent)
        return memHit.dataJson;
      }
      // expired — fall through, also purge L2
      unawaited(_deleteL2(key));
      return null;
    }

    final prefs = await _getPrefs();
    final raw = prefs.getString(_prefsPrefix + key);
    if (raw == null) return null;

    CacheEntry? entry;
    try {
      entry = CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_prefsPrefix + key);
      return null;
    }
    if (entry == null || !entry.isFresh) {
      await prefs.remove(_prefsPrefix + key);
      return null;
    }
    _putMemory(key, entry);
    return entry.dataJson;
  }

  /// Returns the entry (fresh or not) from L1/L2 without expiry check.
  /// Useful for stale-while-revalidate — callers can decide what to do with
  /// stale data (show it, refresh it, or both).
  Future<CacheEntry?> getEntry(String key) async {
    final memHit = _memory[key];
    if (memHit != null) return memHit;

    final prefs = await _getPrefs();
    final raw = prefs.getString(_prefsPrefix + key);
    if (raw == null) return null;
    try {
      final entry = CacheEntry.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (entry != null) _putMemory(key, entry);
      return entry;
    } catch (_) {
      await prefs.remove(_prefsPrefix + key);
      return null;
    }
  }

  /// Store a serialized JSON string under [key] with a [ttl].
  Future<void> setJson(String key, String dataJson, Duration ttl) async {
    final now = DateTime.now();
    final entry = CacheEntry(
      dataJson: dataJson,
      fetchedAt: now,
      expiresAt: now.add(ttl),
    );
    _putMemory(key, entry);

    // Skip L2 for oversized payloads to keep prefs tidy.
    if (dataJson.length <= _maxPrefsEntryBytes) {
      try {
        final prefs = await _getPrefs();
        await prefs.setString(_prefsPrefix + key, jsonEncode(entry.toJson()));
      } catch (e) {
        debugPrint('CacheService: L2 write failed for $key: $e');
      }
    }
  }

  /// Drop a single key from both tiers.
  Future<void> invalidate(String key) async {
    _memory.remove(key);
    await _deleteL2(key);
  }

  /// Drop every key whose name starts with [prefix] (both tiers).
  /// Used after mutations — e.g. invalidate('listings:') after create/update.
  Future<void> invalidatePrefix(String prefix) async {
    _memory.removeWhere((k, _) => k.startsWith(prefix));
    final prefs = await _getPrefs();
    final fullPrefix = _prefsPrefix + prefix;
    final toRemove = prefs
        .getKeys()
        .where((k) => k.startsWith(fullPrefix))
        .toList();
    for (final k in toRemove) {
      await prefs.remove(k);
    }
  }

  /// Wipe everything owned by this cache. Does not touch unrelated prefs keys.
  Future<void> clear() async {
    _memory.clear();
    final prefs = await _getPrefs();
    final ours = prefs.getKeys().where((k) => k.startsWith(_prefsPrefix));
    for (final k in ours) {
      await prefs.remove(k);
    }
  }

  @visibleForTesting
  int get memorySize => _memory.length;

  void _putMemory(String key, CacheEntry entry) {
    _memory.remove(key);
    _memory[key] = entry;
    while (_memory.length > _memoryCapacity) {
      _memory.remove(_memory.keys.first); // evict oldest
    }
  }

  Future<void> _deleteL2(String key) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_prefsPrefix + key);
    } catch (_) {
      // best-effort
    }
  }
}
