/// ==========================================================================
/// insight_provider.dart — Insight State Management
/// ==========================================================================
/// Manages the state of health insights and correlation analysis.
/// 
/// Triggers:
///   - [refreshInsights]: Re-runs statistical analysis locally.
///   - [requestAiInsights]: Calls OpenAI for advanced patterns (premium).
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/correlation.dart';
import '../services/ai_insight_service.dart';
import 'symptom_provider.dart';
import 'lifestyle_provider.dart';
import 'auth_provider.dart';

final aiInsightServiceProvider = Provider<AIInsightService>((ref) {
  // TODO: Fetch API key from secure storage or environment
  return AIInsightService(apiKey: null); 
});

final insightProvider = StateNotifierProvider<InsightNotifier, AsyncValue<List<Correlation>>>((ref) {
  return InsightNotifier(
    ref.read(aiInsightServiceProvider),
    ref,
  );
});

class InsightNotifier extends StateNotifier<AsyncValue<List<Correlation>>> {
  final AIInsightService _service;
  final Ref _ref;

  InsightNotifier(this._service, this._ref) : super(const AsyncData([]));

  /// Runs local statistical analysis based on cached logs.
  Future<void> refreshInsights() async {
    state = const AsyncLoading();
    
    final symptoms = _ref.read(symptomLogsProvider).value ?? [];
    final lifestyle = _ref.read(lifestyleEntriesProvider).value ?? [];
    final userId = _ref.read(authStateProvider).value?.id ?? 'anon';

    try {
      final results = _service.detectStatisticalCorrelations(
        userId: userId,
        symptomLogs: symptoms,
        lifestyleLogs: lifestyle,
      );
      state = AsyncData(results);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Calls the AI engine for premium insights.
  Future<void> requestAiInsights() async {
    state = const AsyncLoading();

    final symptoms = _ref.read(symptomLogsProvider).value ?? [];
    final lifestyle = _ref.read(lifestyleEntriesProvider).value ?? [];
    final userId = _ref.read(authStateProvider).value?.id ?? 'anon';

    try {
      final results = await _service.generateAiInsights(
        userId: userId,
        symptomLogs: symptoms,
        lifestyleLogs: lifestyle,
      );
      state = AsyncData(results);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
