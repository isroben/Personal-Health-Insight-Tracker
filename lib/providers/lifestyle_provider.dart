/// ==========================================================================
/// lifestyle_provider.dart — Lifestyle Entry State Provider (Online-Only)
/// ==========================================================================
/// Manages the list of lifestyle entries for the current user.
///
/// Strictly Online:
///   Data flows: UI → LifestyleEntriesNotifier → LoggingService 
///                                             → HealthLogRepository 
///                                             → ApiService → Backend.
/// ==========================================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lifestyle_entry.dart';
import '../models/health_log.dart';
import '../services/logging_service.dart';
import 'logging_provider.dart';
import 'auth_provider.dart';

/// Provides the list of lifestyle entries for the current user.
/// Fetches directly from the API via [LoggingService].
final lifestyleEntriesProvider = StateNotifierProvider<
    LifestyleEntriesNotifier, AsyncValue<List<LifestyleEntry>>>((ref) {
  final service = ref.watch(loggingServiceProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final notifier = LifestyleEntriesNotifier(service);
  
  if (user != null) {
    notifier.startWatching(user.id);
  }
  
  return notifier;
});

class LifestyleEntriesNotifier
    extends StateNotifier<AsyncValue<List<LifestyleEntry>>> {
  final LoggingService _service;
  StreamSubscription? _subscription;

  LifestyleEntriesNotifier(this._service) : super(const AsyncLoading());

  /// Starts watching the real-time stream of lifestyle entries.
  void startWatching(String userId) {
    _subscription?.cancel();
    state = const AsyncLoading();

    _subscription = _service.getHealthHistoryStream(userId).listen(
      (logs) {
        // Filter for lifestyle entries (marked by special symptom name)
        final entries = logs
            .where((hl) => hl.symptom == 'lifestyle_check_in')
            .map((hl) => _healthLogToLifestyleEntry(hl))
            .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
              
        state = AsyncData(entries);
      },
      onError: (e, st) => state = AsyncError(e, st),
    );
  }

  /// Refreshes entries manually (now restarts the stream).
  Future<void> fetchEntries(String userId) async {
    startWatching(userId);
  }

  /// Helper: Convert API [HealthLog] back to legacy [LifestyleEntry] model.
  LifestyleEntry _healthLogToLifestyleEntry(HealthLog hl) {
    return LifestyleEntry(
      id: hl.id,
      userId: hl.userId,
      date: hl.createdAt,
      sleepHours: hl.sleepHours,
      diet: DietQuality.fair, // Diet quality not currently split in HealthLog
      hydrationGlasses: (hl.waterIntake / 0.25).round(),
      exerciseMinutes: hl.exerciseMinutes,
      screenTimeMinutes: hl.screenTimeMinutes,
      stressLevel: hl.stressLevel,
      notes: hl.notes,
      createdAt: hl.createdAt,
      updatedAt: hl.createdAt,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
