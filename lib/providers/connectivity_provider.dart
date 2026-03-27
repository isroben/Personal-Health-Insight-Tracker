/// ==========================================================================
/// connectivity_provider.dart — Network Connectivity State
/// ==========================================================================
/// Exposes the current connectivity status as a reactive [StreamProvider].
/// The app uses this to show the "No Internet" wall screen.
///
/// Usage:
///   final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connectivity_service.dart';

/// Singleton [ConnectivityService] provider.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Stream of connectivity status.
/// Emits [true] when online, [false] when offline.
/// Defaults to [true] while the first check is pending (optimistic).
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);

  // Emit the current status first so the UI has an immediate value
  yield await service.isConnected();

  // Then stream changes
  yield* service.onConnectivityChanged;
});
