import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/correlation.dart';

/// ==========================================================================
/// correlation_bar_chart.dart — Bar Chart for Trigger Correlations
/// ==========================================================================
/// Visualizes the strength of correlation between symptoms and triggers.
/// ==========================================================================

class CorrelationBarChart extends StatelessWidget {
  final List<Correlation> correlations;

  const CorrelationBarChart({super.key, required this.correlations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (correlations.isEmpty) {
      return const Center(child: Text('Not enough data for correlation analysis.'));
    }

    // Take top 5 correlations
    final topCorrelations = correlations.take(5).toList();

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => theme.colorScheme.surfaceContainerHighest,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topCorrelations[groupIndex].trigger}\n',
                  theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: (rod.toY * 100).toStringAsFixed(0) + '% Strength',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= topCorrelations.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      topCorrelations[index].trigger,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  (value * 100).toInt().toString(),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: topCorrelations.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.severityCorrelation,
                  color: theme.colorScheme.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
