import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/insight.dart';
import '../models/weekly_report.dart';
import '../repositories/insight_repository.dart';
import 'auth_provider.dart';
import 'symptom_provider.dart'; // for healthLogsProvider

/// Provides a singleton [InsightRepository].
final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  return InsightRepository(db: null); // Defaults to FirebaseFirestore.instance
});

/// Provides the list of health insights computed client-side.
/// Reactive to changes in health logs.
final insightProvider = FutureProvider<List<Insight>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  // Watch health logs. Any change triggers this FutureProvider to re-run.
  ref.watch(healthLogsProvider(user.id));
  
  final repo = ref.read(insightRepositoryProvider);
  return await repo.getInsights(user.id);
});

/// Provides the weekly health report computed client-side.
/// Reactive to changes in health logs.
final weeklyReportProvider = FutureProvider<WeeklyReport?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;

  // Watch health logs. Any change triggers this FutureProvider to re-run.
  ref.watch(healthLogsProvider(user.id));
  
  final repo = ref.read(insightRepositoryProvider);
  return await repo.getWeeklyReport(userId: user.id);
});
