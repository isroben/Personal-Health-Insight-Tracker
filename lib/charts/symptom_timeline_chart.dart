import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/symptom_log.dart';

/// ==========================================================================
/// symptom_timeline_chart.dart — Line Chart for Symptom Severity
/// ==========================================================================
/// Visualizes symptom severity (1-10) over time (last 7 or 30 days).
/// Features:
/// - Multiple lines for different symptoms (if selected)
/// - Interactive tooltips
/// - Clean, calm color palette
/// ==========================================================================

class SymptomTimelineChart extends StatelessWidget {
  final List<SymptomLog> logs;
  final int days;

  const SymptomTimelineChart({
    super.key,
    required this.logs,
    this.days = 7,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (logs.isEmpty) {
      return const Center(child: Text('No data for this period'));
    }

    // 1. Group logs by symptom type for multi-line support
    final groupedLogs = <SymptomType, List<SymptomLog>>{};
    for (var log in logs) {
      groupedLogs.putIfAbsent(log.symptomType, () => []).add(log);
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.now().subtract(Duration(days: days - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E').format(date),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 2 != 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 28,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: days.toDouble() - 1,
          minY: 0,
          maxY: 10,
          lineBarsData: groupedLogs.entries.map((entry) {
            return _buildLineSeries(entry.key, entry.value, theme);
          }).toList(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => theme.colorScheme.surfaceContainerHighest,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${SymptomType.values[spot.barIndex].displayName}: ${spot.y.toInt()}/10',
                    theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildLineSeries(SymptomType type, List<SymptomLog> logs, ThemeData theme) {
    // Convert logs to chart spots, normalized to the 'days' range
    final spots = <FlSpot>[];
    final now = DateTime.now();
    
    for (var i = 0; i < days; i++) {
       final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1 - i));
       final dayLogs = logs.where((l) => 
          l.date.year == day.year && l.date.month == day.month && l.date.day == day.day
       ).toList();
       
       if (dayLogs.isNotEmpty) {
         // Use average severity for the day if multiple logs exist
         final avg = dayLogs.map((l) => l.severity).reduce((a, b) => a + b) / dayLogs.length;
         spots.add(FlSpot(i.toDouble(), avg));
       }
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: _getSymptomColor(type, theme),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: _getSymptomColor(type, theme).withValues(alpha: 0.1),
      ),
    );
  }

  Color _getSymptomColor(SymptomType type, ThemeData theme) {
    switch (type) {
      case SymptomType.migraine: return Colors.purple;
      case SymptomType.headache: return Colors.blue;
      case SymptomType.fatigue: return Colors.orange;
      case SymptomType.nausea: return Colors.green;
      default: return theme.colorScheme.primary;
    }
  }
}
