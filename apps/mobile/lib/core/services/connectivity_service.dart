import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service that monitors network connectivity status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  ConnectivityService() {
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
    // Check initial status
    _connectivity.checkConnectivity().then(_onChanged);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final connected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (connected != _isConnected) {
      _isConnected = connected;
      _controller.add(_isConnected);
    }
  }

  /// Stream of connectivity changes (true = connected)
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Check connectivity now
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    return _isConnected;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
