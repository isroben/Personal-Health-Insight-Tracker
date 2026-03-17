/// ==========================================================================
/// reports_screen.dart — PDF Reports Screen
/// ==========================================================================
/// Allows generation of doctor-ready reports.
/// Features:
/// - Date range picker (Last 7 days, 30 days, Custom)
/// - Preview generic report mockup
/// - Big Share Action button
/// ==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedRange = 'Last 30 Days';
  final List<String> _ranges = ['Last 7 Days', 'Last 30 Days', 'This Month', 'Custom...'];

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedRange) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 30 Days':
        return now.subtract(const Duration(days: 30));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Doctor Reports'),
        centerTitle: false,
        actions: [
          if (ref.watch(authStateProvider).value?.subscription == SubscriptionTier.premium)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'PREMIUM',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate a comprehensive PDF report of your symptoms, lifestyle factors, and detected correlations to share with your healthcare provider.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // ── Configurations ──
              Text(
                'Report Configuration',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                      title: const Text('Date Range'),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRange,
                          items: _ranges.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedRange = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(Icons.tune, color: theme.colorScheme.primary),
                      title: const Text('Include Charts & Graphs'),
                      trailing: Switch(
                        value: true,
                        onChanged: (val) {
                          // TODO: Implement toggle
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Preview Area ──
              Text(
                'Report Preview',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          reportState.isLoading ? 'Generating PDF...' : 'Ready to export',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        if (reportState.hasError) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${reportState.error}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Generate Button ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: reportState.isLoading
                      ? null
                      : () {
                          ref.read(reportProvider.notifier).generateAndShareReport(
                                startDate: _startDate,
                                endDate: DateTime.now(),
                              );
                        },
                  icon: reportState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(
                    reportState.isLoading ? 'Generating...' : 'Generate & Share PDF',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

