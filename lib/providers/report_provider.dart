/// ==========================================================================
/// report_provider.dart — Report Generation State Management
/// ==========================================================================
/// Manages the state of PDF report generation and sharing.
///
/// ARCHITECTURE NOTE:
///   Weekly report data now comes from [weeklyReportProvider]
///   (InsightRepository → GET /weekly-report) instead of computing locally.
///   PDF generation still uses [PdfReportService] with the API-fetched data.
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_report_service.dart';
import '../models/weekly_report.dart';
import '../models/user_model.dart';
import '../models/health_log.dart';
import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../models/correlation.dart';
import 'auth_provider.dart';
import 'symptom_provider.dart';
import 'lifestyle_provider.dart';
import 'insight_provider.dart'; // weeklyReportProvider
import 'gamification_provider.dart';

/// Provides a singleton instance of [PdfReportService].
final pdfReportServiceProvider = Provider<PdfReportService>((ref) {
  return PdfReportService();
});

/// State notifier for managing the report generation lifecycle.
final reportProvider =
    StateNotifierProvider<ReportNotifier, AsyncValue<void>>((ref) {
  return ReportNotifier(ref.read(pdfReportServiceProvider), ref);
});

class ReportNotifier extends StateNotifier<AsyncValue<void>> {
  final PdfReportService _service;
  final Ref _ref;

  ReportNotifier(this._service, this._ref) : super(const AsyncData(null));

  /// Generates a PDF report and opens the platform share sheet.
  Future<void> generateAndShareReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const AsyncLoading();

    try {
      final user = _ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not authenticated');

      // 1. Gather data — comes from API-backed providers
      final symptoms = _ref.read(symptomLogsProvider).value ?? [];
      final lifestyle = _ref.read(lifestyleEntriesProvider).value ?? [];

      // Convert API insights to Correlation list for PDF compatibility
      final apiInsights = _ref.read(insightProvider).value ?? [];
      final correlations = apiInsights.map((insight) {
        return Correlation(
          id: insight.id,
          userId: user.id,
          symptom: SymptomType.other,
          trigger: insight.triggerFactor ?? '',
          frequency: 1,
          severityCorrelation: insight.confidence,
          summary: insight.description,
          detectedAt: insight.generatedAt,
          updatedAt: insight.generatedAt,
        );
      }).toList();

      // 2. Filter by date range
      final filteredSymptoms = symptoms.where((s) =>
          s.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          s.date.isBefore(endDate.add(const Duration(seconds: 1)))).toList();

      final filteredLifestyle = lifestyle.where((l) =>
          l.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          l.date.isBefore(endDate.add(const Duration(seconds: 1)))).toList();

      // 3. Generate the PDF bytes
      final pdfData = await _service.generateReport(
        user: user,
        symptoms: filteredSymptoms,
        lifestyle: filteredLifestyle,
        correlations: correlations,
        startDate: startDate,
        endDate: endDate,
      );

      // 4. Share
      final filename =
          'Health_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _service.shareReport(pdfData, filename);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Represents a summarized health report for the UI.
class HealthSummary {
  final int totalLogs;
  final double avgScore;
  final String improvement;
  final List<MonthlyOverview> monthlyOverview;
  final List<String> findings;

  HealthSummary({
    required this.totalLogs,
    required this.avgScore,
    required this.improvement,
    required this.monthlyOverview,
    required this.findings,
  });
}

class MonthlyOverview {
  final String month;
  final int goodDays;
  final int challengingDays;

  MonthlyOverview(this.month, this.goodDays, this.challengingDays);
}

/// Provides a summarized health report reactive to log changes.
final healthSummaryProvider = Provider.family<AsyncValue<HealthSummary>, String>((ref, userId) {
  final logsAsync = ref.watch(healthLogsProvider(userId));
  
  return logsAsync.whenData((logs) {
    if (logs.isEmpty) {
      return HealthSummary(
        totalLogs: 0,
        avgScore: 0,
        improvement: '0%',
        monthlyOverview: [],
        findings: ['Start logging your symptoms to see trends and insights.'],
      );
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    // 1. Basic Stats (Last 30 days)
    final recentLogs = logs.where((l) => l.createdAt.isAfter(thirtyDaysAgo)).toList();
    final previousLogs = logs.where((l) => 
      l.createdAt.isAfter(sixtyDaysAgo) && l.createdAt.isBefore(thirtyDaysAgo)
    ).toList();

    // 2. Improvement calculation
    double calculateAvgScore(List<HealthLog> l, int days) {
      if (l.isEmpty) return 0.0;
      final uniqueDays = l.map((log) => "${log.createdAt.year}-${log.createdAt.month}-${log.createdAt.day}").toSet().length;
      final density = (uniqueDays / days) * 40;
      final sleep = l.map((log) => log.sleepHours).reduce((a, b) => a + b) / l.length;
      return (density + (sleep / 8 * 30)).clamp(0, 100);
    }

    final currentScore = calculateAvgScore(recentLogs, 30);
    final prevScore = calculateAvgScore(previousLogs, 30);
    final diff = currentScore - prevScore;
    final improvementLabel = "${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(0)}%";

    // 3. 3-Month Overview
    final List<MonthlyOverview> overview = [];
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    for (int i = 0; i < 3; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthLogs = logs.where((l) => 
          l.createdAt.year == monthDate.year && l.createdAt.month == monthDate.month
        ).toList();
        
        final days = monthLogs.map((l) => l.createdAt.day).toSet();
        int good = 0;
        int bad = 0;
        for (var day in days) {
           final dayLogs = monthLogs.where((l) => l.createdAt.day == day).toList();
           final score = calculateAvgScore(dayLogs, 1);
           if (score > 70) good++;
           if (score < 40) bad++;
        }
        
        overview.add(MonthlyOverview(monthNames[monthDate.month - 1], good, bad));
    }

    // 4. Key Findings
    final findings = <String>[];
    if (recentLogs.length > previousLogs.length) {
      findings.add('You logged ${recentLogs.length - previousLogs.length} more entries this month, improving data accuracy.');
    }
    if (currentScore > prevScore + 1) {
      findings.add('Your overall wellness index improved by ${diff.toStringAsFixed(0)} points this month.');
    }
    
    final symptomCounts = <String, int>{};
    for (var l in recentLogs) {
      if (l.symptom != 'lifestyle_check_in') symptomCounts[l.symptom] = (symptomCounts[l.symptom] ?? 0) + 1;
    }
    if (symptomCounts.isNotEmpty) {
      final top = symptomCounts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
      findings.add('"${top.first.key}" was your most frequently logged symptom (${top.first.value} times).');
    }

    return HealthSummary(
      totalLogs: logs.length,
      avgScore: currentScore,
      improvement: improvementLabel,
      monthlyOverview: overview.reversed.toList(),
      findings: findings.isEmpty ? ['Continue logging to see more specific findings.'] : findings.take(3).toList(),
    );
  });
});
