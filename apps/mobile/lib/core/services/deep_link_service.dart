import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'deep_link_mapper.dart';

/// Listens for incoming https://tekka.ug/* universal links (iOS) and
/// verified app links (Android) and navigates via the shared GoRouter.
///
/// Handles all three lifecycle states:
///   - Cold start (`getInitialLink`)
///   - Foreground resume (`uriLinkStream`)
///   - Background return (same stream on both platforms)
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;
  Uri? _lastHandledUri;

  Future<void> initialize(GoRouter router) async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handle(router, initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService initial link failed: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _handle(router, uri),
      onError: (Object err) => debugPrint('DeepLinkService stream error: $err'),
    );
  }

  void _handle(GoRouter router, Uri uri) {
    final route = mapDeepLinkUri(uri);
    if (route == null) {
      debugPrint('DeepLinkService: no mapping for $uri');
      return;
    }
    // Skip if we've already handled this exact URI in this app session.
    // The OS delivers the cold-start link via getInitialLink and the foreground
    // stream, so we'd otherwise push twice.
    if (_lastHandledUri == uri) return;
    _lastHandledUri = uri;
    debugPrint('DeepLinkService: navigating to $route (from $uri)');
    router.go(route);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
