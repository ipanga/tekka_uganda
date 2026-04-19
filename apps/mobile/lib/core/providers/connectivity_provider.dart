import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

/// Singleton connectivity service.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream provider for connectivity status (true = connected).
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Synchronous check for current connectivity.
///
/// Defaults to `true` **only after the first probe has run**. Before then we
/// optimistically assume connected so screens that load at app start don't
/// flash an "offline" banner while the platform is still answering the
/// initial query. After the first real signal, we trust the service.
final isConnectedProvider = Provider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  final async = ref.watch(connectivityProvider);
  final observed = async.valueOrNull;
  if (observed != null) return observed;
  // No event yet — fall back to the service's cached value (null before
  // first check, then a real bool).
  return service.isConnected ?? true;
});

/// Fires once per offline → online transition. Use with `ref.listen` to kick
/// off reconciliation work (e.g. flush the offline queue).
final connectivityRestoredProvider = StreamProvider<void>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityRestored;
});
