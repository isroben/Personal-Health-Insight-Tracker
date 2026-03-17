/// ==========================================================================
/// report_provider.dart — Report Generation State
/// ==========================================================================
/// Manages the state and logic for generating health reports.
/// Connects the UI to the PdfReportService and fetches required data.
/// ==========================================================================

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_report_service.dart';
import 'auth_provider.dart';
import 'symptom_provider.dart';
import 'lifestyle_provider.dart';
import 'insight_provider.dart';

final pdfReportServiceProvider = Provider<PdfReportService>((ref) {
  return PdfReportService();
});

final reportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<Uint8List?>>((ref) {
  return ReportNotifier(ref.read(pdfReportServiceProvider), ref);
});

class ReportNotifier extends StateNotifier<AsyncValue<Uint8List?>> {
  final PdfReportService _service;
  final Ref _ref;

  ReportNotifier(this._service, this._ref) : super(const AsyncData(null));

  /// Generates the PDF report for the current user and specified date range.
  Future<void> generateAndShareReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const AsyncLoading();

    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return;
    }

    try {
      // Fetch required data from existing providers
      // Note: In a real app, these would be filtered by date range at the service layer
      final symptoms = _ref.read(symptomLogsProvider).value ?? [];
      final lifestyle = _ref.read(lifestyleEntriesProvider).value ?? [];
      final correlations = _ref.read(insightProvider).value ?? [];

      // Generate the PDF
      final pdfData = await _service.generateReport(
        user: user,
        symptoms: symptoms,
        lifestyle: lifestyle,
        correlations: correlations,
        startDate: startDate,
        endDate: endDate,
      );

      // Share the report
      await _service.shareReport(
        pdfData,
        'Health_Report_${user.name.replaceAll(' ', '_')}.pdf',
      );

      state = AsyncData(pdfData);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Resets the report state.
  void reset() => state = const AsyncData(null);
}
