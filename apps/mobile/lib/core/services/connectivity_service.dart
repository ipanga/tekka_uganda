import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service that monitors network connectivity status.
///
/// Exposes two streams:
///   - [onConnectivityChanged] fires every time the state toggles.
///   - [onConnectivityRestored] fires only on offline → online transitions.
///     Handy for wiring "flush the offline queue when the network comes back".
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
    // Fire-and-forget initial probe so the first stream event is authoritative.
    unawaited(_runFirstCheck());
  }

  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  final _restoredController = StreamController<void>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool? _isConnected; // null = haven't checked yet
  bool _firstCheckDone = false;

  Future<void> _runFirstCheck() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _onChanged(results);
    } catch (_) {
      // On failure, treat as offline so we don't mask real issues.
      _emit(false);
    } finally {
      _firstCheckDone = true;
    }
  }

  void _onChanged(List<ConnectivityResult> results) {
    final connected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    _emit(connected);
  }

  void _emit(bool connected) {
    final previous = _isConnected;
    if (connected == previous) return;
    _isConnected = connected;
    _controller.add(connected);
    if (previous == false && connected == true) {
      _restoredController.add(null);
    }
  }

  /// Stream of connectivity changes (true = connected).
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Fires only when we go from offline back to online.
  Stream<void> get onConnectivityRestored => _restoredController.stream;

  /// Current connectivity status. Null until the first check completes.
  bool? get isConnected => _isConnected;

  /// Whether the initial connectivity probe has completed.
  bool get hasRunFirstCheck => _firstCheckDone;

  /// Re-check now. Returns the observed state.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final connected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    _emit(connected);
    return connected;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _restoredController.close();
  }
}
