/// ==========================================================================
/// symptom_provider.dart — Symptom Log State Provider (Riverpod)
/// ==========================================================================
/// Manages the list of symptom logs for the current user.
/// Provides:
/// - Fetching symptom logs from Firestore
/// - Adding a new symptom log
/// - Deleting a symptom log
///
/// Depends on: DatabaseService, AuthProvider
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom_log.dart';
import '../services/database_service.dart';

/// Provides a singleton instance of [DatabaseService].
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provides the list of symptom logs for the current user.
/// Auto-refreshes when a new log is added or deleted.
final symptomLogsProvider =
    StateNotifierProvider<SymptomLogsNotifier, AsyncValue<List<SymptomLog>>>(
        (ref) {
  return SymptomLogsNotifier(ref.read(databaseServiceProvider));
});

class SymptomLogsNotifier
    extends StateNotifier<AsyncValue<List<SymptomLog>>> {
  final DatabaseService _db;

  SymptomLogsNotifier(this._db) : super(const AsyncLoading());

  /// Fetches all symptom logs for the given user.
  Future<void> fetchLogs(String userId) async {
    state = const AsyncLoading();
    try {
      final logs = await _db.getSymptomLogs(userId);
      state = AsyncData(logs);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Adds a new symptom log and refreshes the list.
  Future<void> addLog(SymptomLog log) async {
    try {
      await _db.addSymptomLog(log);
      // Optimistically add to local state
      state.whenData((logs) {
        state = AsyncData([log, ...logs]);
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a symptom log by ID and refreshes the list.
  Future<void> deleteLog(String logId) async {
    try {
      await _db.deleteSymptomLog(logId);
      state.whenData((logs) {
        state = AsyncData(logs.where((l) => l.id != logId).toList());
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
