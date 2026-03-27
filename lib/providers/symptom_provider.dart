/// ==========================================================================
/// symptom_provider.dart — Symptom Log State Provider (Online-Only)
/// ==========================================================================
/// Manages the list of symptom logs for the current user.
///
/// Strictly Online:
///   Data flows: UI → SymptomLogsNotifier → LoggingService
///                                             → HealthLogRepository
///                                             → ApiService → Backend.
/// ==========================================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom_log.dart';
import '../models/health_log.dart';
import '../services/logging_service.dart';
import 'logging_provider.dart';
import 'auth_provider.dart';

/// Provides the list of symptom logs for the current user.
/// Auto-refreshes when the authenticated user changes.
final symptomLogsProvider =
    StateNotifierProvider<SymptomLogsNotifier, AsyncValue<List<SymptomLog>>>(
        (ref) {
  final service = ref.watch(loggingServiceProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  
  final notifier = SymptomLogsNotifier(service);

  if (user != null) {
    notifier.startWatching(user.id);
  }

  return notifier;
});

class SymptomLogsNotifier
    extends StateNotifier<AsyncValue<List<SymptomLog>>> {
  final LoggingService _service;
  StreamSubscription? _subscription;

  SymptomLogsNotifier(this._service) : super(const AsyncLoading());

  /// Starts watching the real-time stream of logs for the user.
  void startWatching(String userId) {
    _subscription?.cancel();
    state = const AsyncLoading();

    _subscription = _service.getSymptomLogsStream(userId).listen(
      (logs) {
        // LoggingService already sorts, but we can be extra sure here
        final sortedLogs = List<SymptomLog>.from(logs)
          ..sort((a, b) => b.date.compareTo(a.date));
        state = AsyncData(sortedLogs);
      },
      onError: (e, st) => state = AsyncError(e, st),
    );
  }

  /// Fetches logs manually (legacy support, now triggers a stream restart).
  Future<void> fetchLogs(String userId) async {
    startWatching(userId);
  }

  /// Deletes a symptom log by ID via Firestore.
  /// The stream will automatically push the updated list after deletion.
  Future<void> deleteLog(String userId, String logId) async {
    try {
      await _service.deleteSymptomLog(userId, logId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provides a real-time stream of raw [HealthLog]s for a user.
final healthLogsProvider = StreamProvider.family<List<HealthLog>, String>((ref, userId) {
  final repo = ref.watch(healthLogRepositoryProvider);
  return repo.getHealthHistoryStream(userId: userId);
});
