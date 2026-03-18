/// ==========================================================================
/// symptom_provider.dart — Symptom Log State Provider (Riverpod)
/// ==========================================================================
/// Manages the list of symptom logs for the current user.
/// Provides:
/// - Fetching symptom logs (Cache-first via LoggingService)
/// - Adding a new symptom log
/// - Deleting a symptom log
///
/// Depends on: LoggingService, AuthProvider
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom_log.dart';
import '../services/logging_service.dart';
import 'logging_provider.dart';
import 'auth_provider.dart';

/// Provides the list of symptom logs for the current user.
/// Auto-refreshes when the user changes.
final symptomLogsProvider =
    StateNotifierProvider<SymptomLogsNotifier, AsyncValue<List<SymptomLog>>>(
        (ref) {
  final service = ref.watch(loggingServiceProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final notifier = SymptomLogsNotifier(service);
  
  if (user != null) {
    notifier.fetchLogs(user.id);
  }
  
  return notifier;
});

class SymptomLogsNotifier
    extends StateNotifier<AsyncValue<List<SymptomLog>>> {
  final LoggingService _service;

  SymptomLogsNotifier(this._service) : super(const AsyncLoading());

  /// Fetches all symptom logs for the given user.
  Future<void> fetchLogs(String userId) async {
    // Only show loading if we don't have data yet to avoid flicker
    if (!state.hasValue) {
      state = const AsyncLoading();
    }
    
    try {
      final logs = await _service.getSymptomLogs(userId);
      // Sort by date descending
      logs.sort((a, b) => b.date.compareTo(a.date));
      state = AsyncData(logs);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a symptom log by ID and refreshes the list.
  Future<void> deleteLog(String logId) async {
    try {
      await _service.deleteSymptomLog(logId);
      state.whenData((logs) {
        state = AsyncData(logs.where((l) => l.id != logId).toList());
      });
    } catch (e, st) {
      // If deletion fails, we might want to refresh from source
      final user = state.valueOrNull?.firstOrNull?.userId;
      if (user != null) fetchLogs(user);
    }
  }
}
