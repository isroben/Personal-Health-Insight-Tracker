/// ==========================================================================
/// insight_repository.dart — Insights & Weekly Report Repository
/// ==========================================================================
/// Fetches AI-generated insights and weekly reports from the backend API.
///
///   GET /insights      → [getInsights]
///   GET /weekly-report → [getWeeklyReport]
///
/// The backend computes all correlations and aggregations server-side.
/// This replaces the client-side [AIInsightService] statistical analysis.
/// ==========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_log.dart';
import '../models/insight.dart';
import '../models/weekly_report.dart';

class InsightRepository {
  final FirebaseFirestore _db;

  InsightRepository({FirebaseFirestore? db}) 
      : _db = db ?? FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════════════
  // ── GET Insights ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches logs from Firestore and computes insights client-side.
  Future<List<Insight>> getInsights(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('logs')
        .orderBy('created_at', descending: true)
        .limit(30)
        .get();

    final logs = snapshot.docs.map((doc) => HealthLog.fromJson(doc.data())).toList();
    if (logs.isEmpty) return [];

    final insights = <Insight>[];
    
    // Summary aggregation for better insights
    final symptomLogs = logs.where((l) => l.symptom != 'lifestyle_check_in').toList();

    // 1. Stress Correlation
    if (logs.isNotEmpty) {
      final avgStress = logs.map((l) => l.stressLevel).reduce((a, b) => a + b) / logs.length;
      if (avgStress > 7) {
        insights.add(Insight(
          id: 'stress_alert',
          title: 'High Stress Levels Detected',
          description: 'Your average stress level is elevated. Consider relaxation techniques.',
          type: InsightType.trend,
          confidence: 0.85,
          generatedAt: DateTime.now(),
        ));
      }
    }

    // 2. Hydration Insight
    if (logs.isNotEmpty) {
      final avgWater = logs.map((l) => l.waterIntake).reduce((a, b) => a + b) / logs.length;
      if (avgWater < 1.5) {
        insights.add(Insight(
          id: 'hydration_tip',
          title: 'Increase Water Intake',
          description: 'You\'re averaging ${avgWater.toStringAsFixed(1)}L per day. Target 2.0L for better recovery.',
          type: InsightType.recommendation,
          confidence: 0.9,
          generatedAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── GET Weekly Report ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Computes a weekly health report directly from Firestore logs.
  Future<WeeklyReport> getWeeklyReport({
    required String userId,
    DateTime? weekStart,
  }) async {
    final start = weekStart ?? DateTime.now().subtract(const Duration(days: 7));
    
    // Fetch last 100 logs to ensure we capture records during schema transition.
    // Memory filtering is safer than field-specific Firestore 'where' during migration.
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('logs')
        .orderBy('created_at', descending: true)
        .limit(100)
        .get();

    final allLogs = snapshot.docs.map((doc) => HealthLog.fromJson(doc.data())).toList();
    
    // Filter for the specific week in memory
    final logs = allLogs.where((l) => l.createdAt.isAfter(start)).toList();
    
    if (logs.isEmpty) {
      return WeeklyReport(
        weekStart: start,
        weekEnd: start.add(const Duration(days: 7)),
        totalLogs: 0,
        topSymptoms: [],
        symptomFrequencies: {},
        avgSleepHours: 0.0,
        avgWaterIntakeLitres: 0.0,
        avgStressLevel: 0.0,
        totalExerciseMinutes: 0,
        wellnessScore: 0.0,
        dailyScores: [],
        dailyDates: [],
        insights: [],
      );
    }

    final total = logs.length;
    final symptomCounts = <String, int>{};
    for (var l in logs) {
      if (l.symptom.isNotEmpty && l.symptom != 'lifestyle_check_in') {
        symptomCounts[l.symptom] = (symptomCounts[l.symptom] ?? 0) + 1;
      }
    }

    final topSymptoms = symptomCounts.keys.toList()
      ..sort((a, b) => symptomCounts[b]!.compareTo(symptomCounts[a]!));

    // Compute Daily Scores for the chart (past 7 days)
    final dailyScores = <double>[];
    final dailyDates = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayLogs = logs.where((l) => 
        l.createdAt.year == day.year && 
        l.createdAt.month == day.month && 
        l.createdAt.day == day.day
      ).toList();
      
      dailyScores.add(_calculateScoreFromLogs(dayLogs, 1).toDouble());
      dailyDates.add(day);
    }

    // Overall Weekly Wellness Score
    final weeklyScore = _calculateScoreFromLogs(logs, 7).toDouble();

    return WeeklyReport(
      weekStart: start,
      weekEnd: start.add(const Duration(days: 7)),
      totalLogs: total,
      topSymptoms: topSymptoms.take(3).toList(),
      symptomFrequencies: symptomCounts,
      avgSleepHours: logs.map((l) => l.sleepHours).reduce((a, b) => a + b) / total,
      avgWaterIntakeLitres: logs.map((l) => l.waterIntake).reduce((a, b) => a + b) / total,
      avgStressLevel: logs.map((l) => l.stressLevel.toDouble()).reduce((a, b) => a + b) / total,
      totalExerciseMinutes: logs.map((l) => l.exerciseMinutes).reduce((a, b) => a + b),
      wellnessScore: weeklyScore,
      dailyScores: dailyScores,
      dailyDates: dailyDates,
      insights: [],
    );
  }

  /// Private helper: Compute wellness index from a subset of logs.
  int _calculateScoreFromLogs(List<HealthLog> periodLogs, int dayCount) {
    if (periodLogs.isEmpty) return 0;

    // 1. Data Density (max 40 pts)
    final uniqueDays = periodLogs.map((l) {
      final d = l.createdAt;
      return "${d.year}-${d.month}-${d.day}";
    }).toSet().length;
    double densityScore = (uniqueDays / dayCount.toDouble()) * 40;

    // 2. Symptom Stability (max 30 pts)
    final symptomLogs = periodLogs.where((l) => l.symptom != 'lifestyle_check_in').toList();
    double stabilityScore = 30.0;
    if (symptomLogs.isNotEmpty) {
      final avgSeverity = symptomLogs.map((l) => l.severity).reduce((a, b) => a + b) / symptomLogs.length;
      stabilityScore = 30.0 - (avgSeverity.toDouble() * 3.0);
    }

    // 3. Lifestyle Balance (max 30 pts)
    final lifestyleLogs = periodLogs.where((l) => l.sleepHours > 0 || l.waterIntake > 0).toList();
    double balanceScore = 0.0;
    if (lifestyleLogs.isNotEmpty) {
      final avgSleep = lifestyleLogs.map((l) => l.sleepHours).reduce((a, b) => a + b) / lifestyleLogs.length;
      final avgWater = lifestyleLogs.map((l) => l.waterIntake).reduce((a, b) => a + b) / lifestyleLogs.length;
      
      double sleepPts = (avgSleep / 8.0) * 15;
      double waterPts = (avgWater / 2.0) * 15;
      balanceScore = (sleepPts.clamp(0, 15) + waterPts.clamp(0, 15));
    }

    return (densityScore + stabilityScore + balanceScore).round().clamp(0, 100);
  }
}
