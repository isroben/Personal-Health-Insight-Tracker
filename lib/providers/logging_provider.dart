/// ==========================================================================
/// logging_provider.dart — Logging State Provider (Riverpod)
/// ==========================================================================
/// Exposes the [LoggingService] to the widget tree and tracks the state
/// of logging operations (idle / loading / success / error).
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';
import '../services/local_cache_service.dart';
import '../services/notification_service.dart';
import '../services/nudge_service.dart';
import '../services/environmental_service.dart';
import '../services/ai_insight_service.dart';

// ── Service Providers ──

/// Provides a singleton [DatabaseService] instance.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provides a singleton [LocalCacheService] instance.
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

/// Provides a singleton [NotificationService] instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref: ref);
});

/// Provides a singleton [EnvironmentalService] instance.
final environmentalServiceProvider = Provider<EnvironmentalService>((ref) {
  return EnvironmentalService();
});

/// Provides a singleton [AIInsightService] instance.
final aiInsightServiceProvider = Provider<AIInsightService>((ref) {
  return AIInsightService();
});

/// Provides a singleton [NudgeService] instance.
final nudgeServiceProvider = Provider<NudgeService>((ref) {
  return NudgeService(
    notifications: ref.read(notificationServiceProvider),
    environmental: ref.read(environmentalServiceProvider),
    ai: ref.read(aiInsightServiceProvider),
  );
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
final loggingStateProvider =
    StateNotifierProvider<LoggingNotifier, AsyncValue<LogResult?>>((ref) {
  return LoggingNotifier(ref.read(loggingServiceProvider));
});

class LoggingNotifier extends StateNotifier<AsyncValue<LogResult?>> {
  final LoggingService _service;

  LoggingNotifier(this._service) : super(const AsyncData(null));

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

  void reset() => state = const AsyncData(null);
}
