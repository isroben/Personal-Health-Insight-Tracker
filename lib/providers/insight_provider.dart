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
final insightProvider =
    StateNotifierProvider<InsightNotifier, AsyncValue<List<Insight>>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final notifier = InsightNotifier(ref);
  
  if (user != null) {
    // Watch health logs. Any change triggers a re-fetch of insights.
    ref.watch(healthLogsProvider(user.id));
    notifier.refreshInsights();
  }
  
  return notifier;
});

class InsightNotifier extends StateNotifier<AsyncValue<List<Insight>>> {
  final Ref _ref;

  InsightNotifier(this._ref) : super(const AsyncData([]));

  /// Fetches logs from Firestore and computes insights client-side.
  Future<void> refreshInsights() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = const AsyncData([]);
      return;
    }

    if (state.valueOrNull?.isEmpty ?? true) {
      state = const AsyncLoading();
    }
    
    try {
      final repo = _ref.read(insightRepositoryProvider);
      final results = await repo.getInsights(user.id);
      state = AsyncData(results);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provides the weekly health report computed client-side.
final weeklyReportProvider =
    StateNotifierProvider<WeeklyReportNotifier, AsyncValue<WeeklyReport?>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final notifier = WeeklyReportNotifier(ref);
  
  if (user != null) {
    // Watch health logs. Any change triggers a re-fetch of the report.
    ref.watch(healthLogsProvider(user.id));
    notifier.fetchReport();
  }
  
  return notifier;
});

class WeeklyReportNotifier extends StateNotifier<AsyncValue<WeeklyReport?>> {
  final Ref _ref;

  WeeklyReportNotifier(this._ref) : super(const AsyncData(null));

  /// Fetches logs from Firestore and computes the weekly report.
  Future<void> fetchReport({DateTime? weekStart}) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = const AsyncData(null);
      return;
    }

    if (state.valueOrNull == null) {
      state = const AsyncLoading();
    }

    try {
      final repo = _ref.read(insightRepositoryProvider);
      final report = await repo.getWeeklyReport(
        userId: user.id,
        weekStart: weekStart,
      );
      state = AsyncData(report);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
