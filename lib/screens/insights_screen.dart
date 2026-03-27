import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/insight_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/insight.dart';
import '../models/weekly_report.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    // No explicit initialization needed as FutureProviders are reactive
  }

  Future<void> _onRefresh() async {
    ref.invalidate(insightProvider);
    ref.invalidate(weeklyReportProvider);
    // FutureProviders will re-run automatically on invalidation
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightState = ref.watch(insightProvider);
    final reportState = ref.watch(weeklyReportProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Insights'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI-powered health pattern analysis',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // ── 1. Weekly Health Trend (REAL-TIME DATA) ──
              reportState.when(
                data: (report) => _buildChartCard(
                  theme,
                  title: 'Weekly Health Trend',
                  subtitle: 'Your wellness score over the past week',
                  currentValue:
                      report?.wellnessScore.round().toString() ?? '--',
                  chart: _buildLineChart(theme, report?.dailyScores ?? [], report?.dailyDates ?? []),
                ),
                loading: () => _buildLoadingCard(theme, 'Weekly Health Trend'),
                error: (err, _) =>
                    _buildErrorCard(theme, 'Weekly Health Trend', err.toString()),
              ),
              const SizedBox(height: 16),

              // ── 2. Monthly Symptom Frequency (REAL-TIME DATA) ──
              reportState.when(
                data: (report) {
                  final freqs = report?.symptomFrequencies ?? {};
                  final topSymptoms = freqs.keys.toList()
                    ..sort((a, b) => freqs[b]!.compareTo(freqs[a]!));
                  
                  // Display top 4 symptoms in the bar chart
                  final displaySymptoms = topSymptoms.take(4).toList();
                  final legend = displaySymptoms.asMap().entries.map((e) {
                    return {'label': e.value, 'color': _getBarColor(e.key)};
                  }).toList();

                  return _buildChartCard(
                    theme,
                    title: 'Monthly Symptom Frequency',
                    subtitle: 'Track symptom patterns over 30 days',
                    chart: _buildBarChart(theme, displaySymptoms, freqs),
                    legend: legend.isNotEmpty ? legend : null,
                  );
                },
                loading: () => _buildLoadingCard(theme, 'Monthly Symptom Frequency'),
                error: (err, _) => _buildErrorCard(
                    theme, 'Monthly Symptom Frequency', err.toString()),
              ),
              const SizedBox(height: 32),

              Text('Pattern Insights',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // ── 3. AI Pattern Insights (DYNAMIC LIST) ──
              insightState.when(
                data: (insights) {
                  if (insights.isEmpty) {
                    return _buildEmptyInsights(theme);
                  }
                  return Column(
                    children: insights.map((insight) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildInsightCard(
                          theme,
                          title: insight.title,
                          message: insight.description,
                          icon: _getInsightIcon(insight.type),
                          iconColor: _getInsightColor(insight.type),
                          confidence: insight.confidenceLabel,
                          confidenceColor: _getInsightColor(insight.type),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator())),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
              const SizedBox(height: 24),

              // ── 4. Premium Predictive Insights ──
              _buildPremiumCard(theme, ref),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Building Blocks ──

  Color _getBarColor(int index) {
    const defaultColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return defaultColors[index % defaultColors.length];
  }

  Widget _buildLoadingCard(ThemeData theme, String title) {
    return Card(
      child: Container(
        height: 250,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            const Center(child: CircularProgressIndicator()),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String title, String error) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Error: $error', style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInsights(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(Icons.auto_awesome,
                size: 48, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No insights generated yet.',
                style: TextStyle(color: Colors.grey)),
            const Text('Keep logging symptoms to detect patterns.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.correlation:
        return Icons.psychology_outlined;
      case InsightType.trend:
        return Icons.trending_up;
      case InsightType.prediction:
        return Icons.lightbulb_outline;
      case InsightType.recommendation:
        return Icons.star_outline;
    }
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.correlation:
        return Colors.blue;
      case InsightType.trend:
        return Colors.orange;
      case InsightType.prediction:
        return Colors.green;
      case InsightType.recommendation:
        return Colors.purple;
    }
  }

  Widget _buildChartCard(ThemeData theme,
      {required String title,
      required String subtitle,
      String? currentValue,
      required Widget chart,
      List<Map<String, dynamic>>? legend}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (currentValue != null) ...[
              const SizedBox(height: 8),
              const Text('Current Wellness Index',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
              Text(currentValue,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ],
            const SizedBox(height: 20),
            SizedBox(height: 160, child: chart),
            if (legend != null) ...[
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: legend.map((item) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: item['color'], shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(item['label'],
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(ThemeData theme, List<double> scores, List<DateTime> dates) {
    final spots = scores.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    // Use default mock spots if no data (e.g. no logs yet)
    final displaySpots = spots.isNotEmpty
        ? spots
        : [
            const FlSpot(0, 0),
            const FlSpot(1, 0),
            const FlSpot(2, 0),
            const FlSpot(3, 0),
            const FlSpot(4, 0),
            const FlSpot(5, 0),
            const FlSpot(6, 0)
          ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => 
              FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
          getDrawingVerticalLine: (value) => 
              FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dates.length) {
                  final date = dates[value.toInt()];
                  final label = DateFormat('E').format(date); // Mon, Tue, etc.
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(label,
                        style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                }
                // Fallback for mock data
                const mockDays = ['T-6', 'T-5', 'T-4', 'T-3', 'T-2', 'T-1', 'Now'];
                if (value.toInt() >= 0 && value.toInt() < mockDays.length) {
                   return SideTitleWidget(
                    meta: meta,
                    child: Text(mockDays[value.toInt()],
                        style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(value.toInt().toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: displaySpots,
            isCurved: true,
            preventCurveOverShooting: true, // Fixes the "bend" issue
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme, List<String> labels, Map<String, int> frequencies) {
    if (labels.isEmpty) {
      // Empty state bar chart
      return const Center(child: Text('No data recorded for this month', style: TextStyle(color: Colors.grey, fontSize: 12)));
    }

    final barGroups = labels.asMap().entries.map((e) {
      final freq = frequencies[e.value] ?? 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: freq.toDouble(),
            color: _getBarColor(e.key),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(labels[value.toInt()].substring(0, 3), // Short label
                        style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 1,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        maxY: (barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) + 1).toDouble().clamp(5, 50),
      ),
    );
  }

  Widget _buildInsightCard(ThemeData theme,
      {required String title,
      required String message,
      required IconData icon,
      required Color iconColor,
      required String confidence,
      required Color confidenceColor}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(message,
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: confidenceColor, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(confidence,
                          style: TextStyle(
                              color: confidenceColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(ThemeData theme, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text('Predictive Insights',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Premium',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(
            'Get AI-powered predictions about potential health patterns before they happen.\n\n"High chance of migraine tomorrow based on current sleep and stress patterns."',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.blueGrey[700]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ref
                  .read(subscriptionActionsProvider.notifier)
                  .upgradeToPremium(),
              child: const Text('Upgrade to Premium'),
            ),
          ),
        ],
      ),
    );
  }
}
