/// ==========================================================================
/// logging_provider.dart — Logging State Provider (Riverpod) — Online-Only
/// ==========================================================================
/// Exposes [LoggingService] to the widget tree with full dependency injection
/// through the repository layer.
///
/// Dependency graph:
///   loggingServiceProvider
///     └── HealthLogRepository
///           └── ApiService        ← attaches Firebase token
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_cache_service.dart';
import '../services/logging_service.dart';
import '../services/notification_service.dart';
import '../services/nudge_service.dart';
import '../services/environmental_service.dart';
import '../services/ai_insight_service.dart';
import '../repositories/health_log_repository.dart';
import 'auth_provider.dart'; // re-exports apiServiceProvider
import 'symptom_provider.dart';
import 'lifestyle_provider.dart';

// ── Service Providers ──

/// Provides a singleton [LocalCacheService].
/// This is used for persisting lightweight configuration and offline data.
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  throw UnimplementedError('Initialize this provider in main.dart with a real instance');
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
  return AIInsightService(apiKey: null);
});

/// Provides a singleton [NudgeService] instance.
final nudgeServiceProvider = Provider<NudgeService>((ref) {
  return NudgeService(
    notifications: ref.read(notificationServiceProvider),
    environmental: ref.read(environmentalServiceProvider),
    ai: ref.read(aiInsightServiceProvider),
  );
});

/// Provides a singleton [HealthLogRepository] using [FirebaseFirestore].
final healthLogRepositoryProvider = Provider<HealthLogRepository>((ref) {
  return HealthLogRepository();
});

/// Provides a singleton [LoggingService] with all dependencies injected.
final loggingServiceProvider = Provider<LoggingService>((ref) {
  return LoggingService(
    healthLogRepo: ref.read(healthLogRepositoryProvider),
    notifications: ref.read(notificationServiceProvider),
  );
});


// ── Logging Notifier ──

/// Tracks the state of the current logging operation.
final loggingStateProvider =
    StateNotifierProvider<LoggingNotifier, AsyncValue<LogResult?>>((ref) {
  return LoggingNotifier(ref.read(loggingServiceProvider), ref);
});

class LoggingNotifier extends StateNotifier<AsyncValue<LogResult?>> {
  final LoggingService _service;
  final Ref _ref;

  LoggingNotifier(this._service, this._ref) : super(const AsyncData(null));

  /// Submits a symptom + lifestyle log entry to the API.
  Future<LogResult> submitSymptomLog({
    required String userId,
    required String symptomTypeName,
    required double severity,
    double sleepHours = 0,
    double waterIntakeLitres = 0,
    int exerciseMinutes = 0,
    String mood = '',
    double stressLevel = 5,
    String? notes,
  }) async {
    state = const AsyncLoading();

    try {
      final result = await _service.logSymptom(
        userId: userId,
        symptomTypeName: symptomTypeName,
        severity: severity,
        sleepHours: sleepHours,
        waterIntakeLitres: waterIntakeLitres,
        exerciseMinutes: exerciseMinutes,
        mood: mood,
        stressLevel: stressLevel,
        notes: notes,
      );

      // No manual refresh needed! Firestore streams push updates automatically.
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Submits a lifestyle-only log entry to the API.
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

    try {
      final result = await _service.logLifestyle(
        userId: userId,
        sleepHours: sleepHours,
        dietQualityName: dietQualityName,
        hydrationGlasses: hydrationGlasses,
        exerciseMinutes: exerciseMinutes,
        stressLevel: stressLevel,
        notes: notes,
      );

      // No manual refresh needed! Firestore streams push updates automatically.
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void reset() => state = const AsyncData(null);
}
