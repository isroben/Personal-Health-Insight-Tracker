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
import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../models/correlation.dart';
import 'auth_provider.dart';
import 'symptom_provider.dart';
import 'lifestyle_provider.dart';
import 'insight_provider.dart'; // weeklyReportProvider

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
  ///
  /// Fetches data from providers — symptom logs and lifestyle entries
  /// come from cached/API state; insights can come from the weekly report.
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
