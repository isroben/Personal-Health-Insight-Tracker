/// ==========================================================================
/// pdf_report_service.dart — PDF Generation & Export
/// ==========================================================================
/// Generates "doctor-ready" PDF reports containing:
/// - User profile summary
/// - Statistical and AI-generated insights
/// - Symptom frequency and severity tables
/// - Correlated lifestyle factors
///
/// Uses the 'pdf' package for layout and 'printing' for sharing/saving.
/// ==========================================================================

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/user_model.dart';
import '../models/symptom_log.dart';
import '../models/correlation.dart';
import '../models/lifestyle_entry.dart';

class PdfReportService {
  /// Generates a comprehensive health report as a PDF.
  /// 
  /// Returns the generated [Uint8List] of the PDF file.
  Future<Uint8List> generateReport({
    required UserModel user,
    required List<SymptomLog> symptoms,
    required List<LifestyleEntry> lifestyle,
    required List<Correlation> correlations,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    // ── PDF Layout ──
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(user, startDate, endDate),
            pw.SizedBox(height: 24),
            _buildSummarySection(symptoms, lifestyle),
            pw.SizedBox(height: 24),
            _buildCorrelationsSection(correlations),
            pw.SizedBox(height: 24),
            _buildSymptomTable(symptoms),
            pw.SizedBox(height: 24),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Saves the PDF to a temporary file and triggers the platform share sheet.
  Future<void> shareReport(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(
      bytes: pdfData,
      filename: filename,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Private Layout Components ──
  // ══════════════════════════════════════════════════════════════════════════

  pw.Widget _buildHeader(UserModel user, DateTime start, DateTime end) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Personal Health Insight Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal),
            ),
            pw.SizedBox(height: 4),
            pw.Text('User: ${user.name} (${user.email})'),
            pw.Text('Report Period: ${DateFormat('MMM dd, yyyy').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Generated on:', style: const pw.TextStyle(color: PdfColors.grey)),
            pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummarySection(List<SymptomLog> symptoms, List<LifestyleEntry> lifestyle) {
    final avgSleep = lifestyle.isEmpty ? 0.0 : lifestyle.map((e) => e.sleepHours).reduce((a, b) => a + b) / lifestyle.length;
    final totalSymptoms = symptoms.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Executive Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Logged Episodes', '$totalSymptoms'),
              _buildMetric('Avg. Sleep', '${avgSleep.toStringAsFixed(1)}h'),
              _buildMetric('Active Logs', '${lifestyle.length} days'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetric(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  pw.Widget _buildCorrelationsSection(List<Correlation> correlations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Detected Patterns & Insights', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.Divider(color: PdfColors.teal),
        pw.SizedBox(height: 8),
        if (correlations.isEmpty)
          pw.Text('No significant patterns detected in this period.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))
        else
          pw.ListView.builder(
            itemCount: correlations.length,
            itemBuilder: (context, index) {
              final c = correlations[index];
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Bullet(),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${c.symptom.name.toUpperCase()} correlated with ${c.trigger}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(c.summary ?? 'A strong correlation was observed between this symptom and lifestyle factor.'),
                          pw.SizedBox(height: 2),
                          pw.Text('Confidence: ${c.strengthLabel} (${(c.severityCorrelation * 100).toInt()}%)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  pw.Widget _buildSymptomTable(List<SymptomLog> symptoms) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Detailed Symptom Logs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Symptom', 'Severity', 'Notes'],
          data: symptoms.map((s) => [
            DateFormat('yyyy-MM-dd').format(s.date),
            s.symptomType.name,
            '${s.severity}/10',
            s.notes ?? '-',
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
          cellHeight: 25,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerLeft,
          },
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 32),
      child: pw.Text(
        'Generated by Personal Health Insight Tracker. This report is for informational purposes and should be discussed with a medical professional.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        textAlign: pw.TextAlign.right,
      ),
    );
  }
}
