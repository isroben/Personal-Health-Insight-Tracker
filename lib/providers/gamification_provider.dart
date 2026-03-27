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
final wellnessScoreProvider = FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(gamificationServiceProvider);
  // Watch the real-time stream to auto-refresh when any log is added
  ref.watch(healthLogsProvider(userId));
  return service.calculateWellnessScore(userId);
});

/// Provides the full health trend (score + label + change).
final healthTrendProvider = FutureProvider.family<HealthTrend, String>((ref, userId) async {
  final service = ref.watch(gamificationServiceProvider);
  // Watch the real-time stream to auto-refresh when any log is added
  ref.watch(healthLogsProvider(userId));
  return service.calculateHealthTrend(userId);
});

/// Provides the current logging streak for a user.
final streakProvider = FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(gamificationServiceProvider);
  // Watch the real-time stream to auto-refresh streak
  ref.watch(healthLogsProvider(userId));
  return service.calculateCurrentStreak(userId);
});

/// Provides today's health metrics summary.
final todaySummaryProvider = Provider.family<AsyncValue<Map<String, dynamic>>, String>((ref, userId) {
  final service = ref.watch(gamificationServiceProvider);
  final logsAsync = ref.watch(healthLogsProvider(userId));
  
  return logsAsync.whenData((logs) => service.calculateTodaySummary(logs));
});
