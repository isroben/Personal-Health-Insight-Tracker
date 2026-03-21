import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/insight_provider.dart';
import '../providers/symptom_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/symptom_log.dart';
import '../models/correlation.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insightState = ref.watch(insightProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Insights'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI-powered health pattern analysis', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            
            // Weekly Health Trend
            _buildChartCard(
              theme,
              title: 'Weekly Health Trend',
              subtitle: 'Your health score over the past week',
              currentValue: '80',
              chart: _buildLineChart(theme),
            ),
            const SizedBox(height: 16),
            
            // Monthly Symptom Frequency
            _buildChartCard(
              theme,
              title: 'Monthly Symptom Frequency',
              subtitle: 'Track symptom patterns over 4 weeks',
              chart: _buildBarChart(theme),
              legend: const [
                {'label': 'Headache', 'color': Colors.blue},
                {'label': 'Fatigue', 'color': Colors.green},
                {'label': 'Stress', 'color': Colors.orange},
              ],
            ),
            const SizedBox(height: 32),
            
            Text('Pattern Insights', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildInsightCard(
              theme,
              title: 'Sleep & Headaches',
              message: 'Headaches occur after low sleep 60% of the time.',
              icon: Icons.psychology_outlined,
              iconColor: Colors.blue,
              confidence: 'High confidence',
              confidenceColor: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              theme,
              title: 'Stress Pattern',
              message: 'Stress levels peak on weekdays between 2-4 PM.',
              icon: Icons.trending_up,
              iconColor: Colors.orange,
              confidence: 'Medium confidence',
              confidenceColor: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              theme,
              title: 'Hydration Impact',
              message: 'Drinking 8+ glasses reduces fatigue by 40%.',
              icon: Icons.lightbulb_outline,
              iconColor: Colors.green,
              confidence: 'High confidence',
              confidenceColor: Colors.green,
            ),
            const SizedBox(height: 24),
            
            // Premium Predictive Insights
            _buildPremiumCard(theme, ref),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, {required String title, required String subtitle, String? currentValue, required Widget chart, List<Map<String, dynamic>>? legend}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (currentValue != null) ...[
              const SizedBox(height: 8),
              const Text('Current', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
              Text(currentValue, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
            const SizedBox(height: 20),
            SizedBox(height: 160, child: chart),
            if (legend != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: legend.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: item['color'], shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(item['label'], style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(ThemeData theme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
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
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 50,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 65),
              FlSpot(1, 70),
              FlSpot(2, 68),
              FlSpot(3, 75),
              FlSpot(4, 72),
              FlSpot(5, 78),
              FlSpot(6, 80),
            ],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
                if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(weeks[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
              interval: 2,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 2, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 4, color: Colors.orange, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3, color: Colors.orange, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 5, color: Colors.orange, width: 12, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 2, color: Colors.orange, width: 12, borderRadius: BorderRadius.circular(4))]),
        ],
        maxY: 8,
      ),
    );
  }

  Widget _buildInsightCard(ThemeData theme, {required String title, required String message, required IconData icon, required Color iconColor, required String confidence, required Color confidenceColor}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(message, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: confidenceColor, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(confidence, style: TextStyle(color: confidenceColor, fontSize: 11, fontWeight: FontWeight.w500)),
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
          Text('Predictive Insights', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Text('Premium', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(
            'Get AI-powered predictions about potential health patterns before they happen.\n\n"High chance of migraine tomorrow based on current sleep and stress patterns."',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey[700]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ref.read(subscriptionActionsProvider.notifier).upgradeToPremium(),
              child: const Text('Upgrade to Premium'),
            ),
          ),
        ],
      ),
    );
  }
}
