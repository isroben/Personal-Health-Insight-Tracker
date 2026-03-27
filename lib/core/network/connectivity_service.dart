/// ==========================================================================
/// connectivity_service.dart — Network Connectivity Monitor
/// ==========================================================================
/// Wraps [connectivity_plus] to provide a simple interface for:
///   - Checking current connectivity status synchronously
///   - Streaming connectivity changes reactively
///
/// Consumed by [connectivityProvider] for app-wide offline detection.
/// ==========================================================================

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Returns true if the device currently has internet connectivity.
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  /// Stream of connectivity status changes.
  /// Emits [true] when online, [false] when offline.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => _isOnline(results),
    );
  }

  /// Determines if the connectivity result represents an online state.
  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}
