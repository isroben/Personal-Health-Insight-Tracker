/// ==========================================================================
/// report_provider.dart — Report Generation State Management
/// ==========================================================================
/// Manages the state of PDF report generation and sharing.
/// Uses [PdfReportService] to create doctor-ready exports.
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_report_service.dart';
import 'auth_provider.dart';
import 'symptom_provider.dart';
import 'lifestyle_provider.dart';
import 'insight_provider.dart';

/// Provides a singleton instance of [PdfReportService].
final pdfReportServiceProvider = Provider<PdfReportService>((ref) {
  return PdfReportService();
});

/// State notifier for managing the report generation lifecycle.
final reportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<void>>((ref) {
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

      // 1. Gather data for the report
      final symptoms = _ref.read(symptomLogsProvider).value ?? [];
      final lifestyle = _ref.read(lifestyleEntriesProvider).value ?? [];
      final correlations = _ref.read(insightProvider).value ?? [];

      // 2. Filter data by date range
      final filteredSymptoms = symptoms.where((s) => 
        s.date.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
        s.date.isBefore(endDate.add(const Duration(seconds: 1)))
      ).toList();

      final filteredLifestyle = lifestyle.where((l) => 
        l.date.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
        l.date.isBefore(endDate.add(const Duration(seconds: 1)))
      ).toList();

      // 3. Generate the PDF bytes
      final pdfData = await _service.generateReport(
        user: user,
        symptoms: filteredSymptoms,
        lifestyle: filteredLifestyle,
        correlations: correlations,
        startDate: startDate,
        endDate: endDate,
      );

      // 4. Trigger share sheet
      final filename = 'Health_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _service.shareReport(pdfData, filename);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
