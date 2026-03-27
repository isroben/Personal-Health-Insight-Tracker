/// ==========================================================================
/// weekly_report.dart — Weekly Report Model (API Layer)
/// ==========================================================================
/// Represents the aggregated weekly health summary returned by
/// GET /weekly-report.
///
/// Used by the Reports screen to display charts and summaries
/// without performing any local analytics — the backend computes all
/// aggregations and sends the pre-processed result.
/// ==========================================================================

import 'dart:convert';
import 'insight.dart';

class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalLogs;               // Total health log entries this week
  final List<String> topSymptoms;    // Top 3 recorded symptoms (list of names)
  final Map<String, int> symptomFrequencies; // Detailed counts for bar charts
  final double avgSleepHours;        // Average sleep hours per day
  final double avgWaterIntakeLitres; // Average water intake in litres
  final double avgStressLevel;       // Average stress 1–10
  final int totalExerciseMinutes;    // Total exercise minutes this week
  final double wellnessScore;        // 0–100 composite score
  final List<double> dailyScores;    // Last 7 days of scores for trend charts
  final List<DateTime> dailyDates; // Added for accurate labeling
  final List<Insight> insights;      // Key insights for the week

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalLogs,
    required this.topSymptoms,
    required this.symptomFrequencies,
    required this.avgSleepHours,
    required this.avgWaterIntakeLitres,
    required this.avgStressLevel,
    required this.totalExerciseMinutes,
    required this.wellnessScore,
    required this.dailyScores,
    required this.dailyDates,
    required this.insights,
  });

  // ── JSON Serialization ──

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    final insightsList = (json['insights'] as List<dynamic>? ?? [])
        .map((i) => Insight.fromJson(i as Map<String, dynamic>))
        .toList();

    final scoresList = (json['daily_scores'] as List<dynamic>? ?? [])
        .map((s) => (s as num).toDouble())
        .toList();
    
    final freqMap = (json['symptom_frequencies'] as Map<String, dynamic>? ?? {})
        .map((key, value) => MapEntry(key, (value as num).toInt()));

    final datesList = (json['daily_dates'] as List<dynamic>? ?? [])
        .map((d) => DateTime.parse(d as String))
        .toList();

    return WeeklyReport(
      weekStart: json['week_start'] != null
          ? DateTime.parse(json['week_start'] as String)
          : DateTime.now().subtract(const Duration(days: 7)),
      weekEnd: json['week_end'] != null
          ? DateTime.parse(json['week_end'] as String)
          : DateTime.now(),
      totalLogs: (json['total_logs'] as num?)?.toInt() ?? 0,
      topSymptoms: (json['top_symptoms'] as List<dynamic>? ?? [])
          .map((s) => s as String)
          .toList(),
      symptomFrequencies: freqMap,
      avgSleepHours: (json['avg_sleep_hours'] as num?)?.toDouble() ?? 0.0,
      avgWaterIntakeLitres:
          (json['avg_water_intake_litres'] as num?)?.toDouble() ?? 0.0,
      avgStressLevel: (json['avg_stress_level'] as num?)?.toDouble() ?? 0.0,
      totalExerciseMinutes:
          (json['total_exercise_minutes'] as num?)?.toInt() ?? 0,
      wellnessScore: (json['wellness_score'] as num?)?.toDouble() ?? 0.0,
      dailyScores: scoresList,
      dailyDates: datesList,
      insights: insightsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_start': weekStart.toIso8601String(),
      'week_end': weekEnd.toIso8601String(),
      'total_logs': totalLogs,
      'top_symptoms': topSymptoms,
      'symptom_frequencies': symptomFrequencies,
      'avg_sleep_hours': avgSleepHours,
      'avg_water_intake_litres': avgWaterIntakeLitres,
      'avg_stress_level': avgStressLevel,
      'total_exercise_minutes': totalExerciseMinutes,
      'wellness_score': wellnessScore,
      'daily_scores': dailyScores,
      'daily_dates': dailyDates.map((d) => d.toIso8601String()).toList(),
      'insights': insights.map((i) => i.toJson()).toList(),
    };
  }

  String toJsonString() => json.encode(toJson());

  // ── Computed Properties ──

  /// Human-readable wellness level label.
  String get wellnessLabel {
    if (wellnessScore >= 80) return 'Excellent';
    if (wellnessScore >= 60) return 'Good';
    if (wellnessScore >= 40) return 'Fair';
    return 'Needs Attention';
  }

  @override
  String toString() =>
      'WeeklyReport(week: ${weekStart.toIso8601String().substring(0, 10)}, '
      'score: $wellnessScore)';
}
