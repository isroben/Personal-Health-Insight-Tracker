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
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Health Reports'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor-friendly health summary', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
                _buildStatCard(context, 'Total Logs', '156', Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard(context, 'Avg Score', '78', Colors.green),
                const SizedBox(width: 12),
                _buildStatCard(context, 'Improvement', '+15%', Colors.orange),
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
                    SizedBox(height: 160, child: _buildOverviewChart()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Key Findings
            Text('Key Findings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildFindingItem('Symptom frequency decreased by 12% compared to last month.'),
            _buildFindingItem('Strong correlation found between sleep quality and migraine frequency.'),
            _buildFindingItem('Stress levels peak during mid-week, affecting overall wellness.'),
            const SizedBox(height: 32),
            
            // Export Options
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
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

  Widget _buildOverviewChart() {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar'];
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(months[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: 20, color: Colors.green, width: 24, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: 6, color: Colors.orange, width: 24, borderRadius: BorderRadius.circular(4)),
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: 18, color: Colors.green, width: 24, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: 8, color: Colors.orange, width: 24, borderRadius: BorderRadius.circular(4)),
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(toY: 24, color: Colors.green, width: 24, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: 4, color: Colors.orange, width: 24, borderRadius: BorderRadius.circular(4)),
          ]),
        ],
        maxY: 30,
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

