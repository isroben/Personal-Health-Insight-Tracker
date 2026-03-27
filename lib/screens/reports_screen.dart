import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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
  final List<String> _ranges = ['Last 7 Days', 'Last 30 Days', 'This Month', 'Last 3 Months'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final summaryAsync = ref.watch(healthSummaryProvider(user.id));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Health Reports'),
        centerTitle: false,
      ),
      body: summaryAsync.when(
        data: (summary) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 800 ? (MediaQuery.of(context).size.width - 800)/2 : 24.0, 
            vertical: 24.0
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doctor-friendly health summary', 
                   style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              
              // Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRange,
                    isExpanded: true,
                    items: _ranges.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => _selectedRange = newValue!);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Summary Stats
              Row(
                children: [
                  _buildStatCard(context, 'Total Logs', summary.totalLogs.toString(), Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard(context, 'Avg Score', summary.avgScore.round().toString(), Colors.green),
                  const SizedBox(width: 12),
                  _buildStatCard(context, 'Improvement', summary.improvement, Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              
              // 3-Month Overview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('3-Month Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLegendItem(context, 'Good Days', Colors.green),
                          const SizedBox(width: 16),
                          _buildLegendItem(context, 'Challenging Days', Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(height: 160, child: _buildOverviewChart(summary.monthlyOverview)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Key Findings
              Text('Key Findings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...summary.findings.map((f) => _buildFindingItem(f)).toList(),
              const SizedBox(height: 32),
              
              // Export Options
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing not available in preview')));
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final now = DateTime.now();
                        ref.read(reportProvider.notifier).generateAndShareReport(
                          startDate: now.subtract(const Duration(days: 30)),
                          endDate: now,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Export PDF'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading report: $err')),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildOverviewChart(List<MonthlyOverview> overview) {
    if (overview.isEmpty) {
        return const Center(child: Text('No data for overview', style: TextStyle(color: Colors.grey)));
    }

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < overview.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(overview[value.toInt()].month, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: overview.asMap().entries.map((e) {
            return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(toY: e.value.goodDays.toDouble(), color: Colors.green, width: 24, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: e.value.challengingDays.toDouble(), color: Colors.orange, width: 24, borderRadius: BorderRadius.circular(4)),
            ]);
        }).toList(),
        maxY: 31,
      ),
    );
  }

  Widget _buildFindingItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 6, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

