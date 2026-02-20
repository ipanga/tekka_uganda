import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

/// Singleton connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for connectivity status (true = connected)
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Synchronous check for current connectivity
final isConnectedProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityProvider);
  return async.valueOrNull ?? true; // Default to connected
});
