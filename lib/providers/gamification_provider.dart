import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gamification_service.dart';
import '../repositories/health_log_repository.dart';
import 'logging_provider.dart'; // healthLogRepositoryProvider
import 'symptom_provider.dart';

/// Provides a singleton [GamificationService] instance.
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService(
    repo: ref.watch(healthLogRepositoryProvider),
  );
});

/// Provides the current wellness score for a user.
/// Reactive to changes in health logs.
final wellnessScoreProvider = Provider.family<AsyncValue<int>, String>((ref, userId) {
  final service = ref.watch(gamificationServiceProvider);
  final logsAsync = ref.watch(healthLogsProvider(userId));
  
  return logsAsync.whenData((logs) => service.calculateWellnessScoreFromLogs(logs));
});

/// Provides the full health trend (score + label + change).
/// Reactive to changes in health logs.
final healthTrendProvider = Provider.family<AsyncValue<HealthTrend>, String>((ref, userId) {
  final service = ref.watch(gamificationServiceProvider);
  final logsAsync = ref.watch(healthLogsProvider(userId));
  
  return logsAsync.whenData((logs) => service.calculateHealthTrendFromLogs(logs));
});

/// Provides the current logging streak for a user.
/// Reactive to changes in health logs.
final streakProvider = Provider.family<AsyncValue<int>, String>((ref, userId) {
  final service = ref.watch(gamificationServiceProvider);
  final logsAsync = ref.watch(healthLogsProvider(userId));
  
  return logsAsync.whenData((logs) => service.calculateCurrentStreak(logs));
});

/// Provides today's health metrics summary.
/// Reactive to changes in health logs.
final todaySummaryProvider = Provider.family<AsyncValue<Map<String, dynamic>>, String>((ref, userId) {
  final service = ref.watch(gamificationServiceProvider);
  final logsAsync = ref.watch(healthLogsProvider(userId));
  
  return logsAsync.whenData((logs) => service.calculateTodaySummary(logs));
});
