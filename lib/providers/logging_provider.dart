/// ==========================================================================
/// logging_provider.dart — Logging State Provider (Riverpod)
/// ==========================================================================
/// Exposes the [LoggingService] to the widget tree and tracks the state
/// of logging operations (idle / loading / success / error).
///
/// Widgets use [loggingProvider] to call logSymptom() and logLifestyle()
/// and observe the async state without managing it themselves.
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/logging_service.dart';
import '../services/database_service.dart';
import '../services/local_cache_service.dart';
import '../services/notification_service.dart';
import 'symptom_provider.dart'; // re-use databaseServiceProvider

// ── Service Providers ──

/// Provides a singleton [LocalCacheService] instance.
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

/// Provides a singleton [NotificationService] instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provides a singleton [LoggingService] with all dependencies injected.
final loggingServiceProvider = Provider<LoggingService>((ref) {
  return LoggingService(
    db: ref.read(databaseServiceProvider),
    cache: ref.read(localCacheServiceProvider),
    notifications: ref.read(notificationServiceProvider),
  );
});

// ── Logging Notifier ──

/// Tracks the state of the current logging operation.
///
/// State: [AsyncValue<LogResult?>]
///   - AsyncData(null): idle (nothing submitted yet)
///   - AsyncLoading(): submission in progress
///   - AsyncData(LogResult): submission complete (check result.success)
///   - AsyncError: unexpected error during submission
final loggingStateProvider =
    StateNotifierProvider<LoggingNotifier, AsyncValue<LogResult?>>((ref) {
  return LoggingNotifier(ref.read(loggingServiceProvider));
});

class LoggingNotifier extends StateNotifier<AsyncValue<LogResult?>> {
  final LoggingService _service;

  LoggingNotifier(this._service) : super(const AsyncData(null));

  /// Submits a new symptom log entry.
  ///
  /// Sets state to loading, then to the result of [LoggingService.logSymptom].
  /// Returns the [LogResult] so the widget can inspect field errors.
  Future<LogResult> submitSymptomLog({
    required String userId,
    required String symptomTypeName,
    required double severity,
    String? notes,
  }) async {
    state = const AsyncLoading();

    final result = await _service.logSymptom(
      userId: userId,
      symptomTypeName: symptomTypeName,
      severity: severity,
      notes: notes,
    );

    state = AsyncData(result);
    return result;
  }

  /// Submits a new lifestyle entry (or updates today's entry).
  Future<LogResult> submitLifestyleEntry({
    required String userId,
    required double sleepHours,
    required String dietQualityName,
    required int hydrationGlasses,
    required int exerciseMinutes,
    required double stressLevel,
    String? notes,
  }) async {
    state = const AsyncLoading();

    final result = await _service.logLifestyle(
      userId: userId,
      sleepHours: sleepHours,
      dietQualityName: dietQualityName,
      hydrationGlasses: hydrationGlasses,
      exerciseMinutes: exerciseMinutes,
      stressLevel: stressLevel,
      notes: notes,
    );

    state = AsyncData(result);
    return result;
  }

  /// Resets the logging state back to idle.
  /// Call this after the UI has consumed the last result.
  void reset() => state = const AsyncData(null);
}
