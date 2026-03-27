import '../models/health_log.dart';
import '../repositories/health_log_repository.dart';

/// ==========================================================================
/// gamification_service.dart — Engagement & Health Scoring
/// ==========================================================================
/// Handles the "Gamification" layer of the app.
/// Calculations are now "pure" functions taking List<HealthLog> as input
/// to ensure instant reactive updates without redundant I/O.
/// ==========================================================================

class HealthTrend {
  final double score;
  final double previousScore;
  final String label; // "Improving", "Declining", "Stable"
  final double change;

  const HealthTrend({
    required this.score,
    required this.previousScore,
    required this.label,
    required this.change,
  });
}

class GamificationService {
  final HealthLogRepository _repo;

  GamificationService({
    required HealthLogRepository repo,
  }) : _repo = repo;

  // ══════════════════════════════════════════════════════════════════════════
  // ── 1. Streak Calculation ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates the current logging streak from a list of logs.
  int calculateCurrentStreak(List<HealthLog> logs) {
    if (logs.isEmpty) return 0;

    final now = DateTime.now();
    final activityDates = logs.map((l) => _normalizeDate(l.createdAt)).toSet();
    
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    
    // Check if user logged today
    if (activityDates.contains(_normalizeDate(checkDate))) {
      streak++;
    } else {
      // If not today, check yesterday. If no yesterday, streak is 0.
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!activityDates.contains(_normalizeDate(checkDate))) return 0;
      streak++;
    }

    // Iterate backwards
    while (true) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (activityDates.contains(_normalizeDate(checkDate))) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 2. Wellness Score ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates a "Wellness Score" (0-100) from a list of logs in a range.
  int calculateWellnessScoreFromLogs(List<HealthLog> logs, {DateTime? start, DateTime? end}) {
    final now = end ?? DateTime.now();
    final startDate = start ?? now.subtract(const Duration(days: 7));

    final periodLogs = logs.where((l) => 
      l.createdAt.isAfter(startDate) && l.createdAt.isBefore(now.add(const Duration(seconds: 1)))
    ).toList();

    if (periodLogs.isEmpty) return 0;

    // 1. Data Density (max 40 pts)
    final uniqueDays = periodLogs.map((l) => _normalizeDate(l.createdAt)).toSet().length;
    double densityScore = (uniqueDays / 7.0) * 40;

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

  // ══════════════════════════════════════════════════════════════════════════
  // ── 3. Health Trend ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates the score trend (Current week vs Previous week) from logs.
  HealthTrend calculateHealthTrendFromLogs(List<HealthLog> logs) {
    if (logs.isEmpty) {
      return const HealthTrend(score: 0, previousScore: 0, label: 'Stable', change: 0);
    }

    final now = DateTime.now();
    final thisWeekStart = now.subtract(const Duration(days: 7));
    final lastWeekStart = now.subtract(const Duration(days: 14));

    final currentScore = calculateWellnessScoreFromLogs(logs, start: thisWeekStart, end: now);
    final previousScore = calculateWellnessScoreFromLogs(logs, start: lastWeekStart, end: thisWeekStart);

    final change = currentScore.toDouble() - previousScore.toDouble();
    String label = 'Stable';
    if (change > 3) label = 'Improving';
    if (change < -3) label = 'Declining';

    return HealthTrend(
      score: currentScore.toDouble(),
      previousScore: previousScore.toDouble(),
      label: label,
      change: change,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 4. Today's Summary ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates metrics specifically for today's summary.
  Map<String, dynamic> calculateTodaySummary(List<HealthLog> logs) {
    final now = DateTime.now();
    final todayLogs = logs.where((l) => 
      l.createdAt.year == now.year && 
      l.createdAt.month == now.month && 
      l.createdAt.day == now.day
    ).toList();

    if (todayLogs.isEmpty) {
      return {
        'sleep': 0.0,
        'hydration': 0.0,
        'stress': 'N/A',
        'exercise': 0,
        'screen_time': 0,
      };
    }

    double totalSleep = 0;
    double totalWater = 0;
    int totalExercise = 0;
    int totalScreenTime = 0;
    int totalStress = 0;
    int stressCount = 0;

    for (var l in todayLogs) {
      if (l.sleepHours > 0) totalSleep = l.sleepHours; 
      totalWater += l.waterIntake;
      totalExercise += l.exerciseMinutes;
      totalScreenTime += l.screenTimeMinutes;
      if (l.stressLevel > 0) {
        totalStress += l.stressLevel;
        stressCount++;
      }
    }

    String stressLabel = 'N/A';
    if (stressCount > 0) {
      final avgStress = totalStress / stressCount;
      if (avgStress <= 3) stressLabel = 'Low';
      else if (avgStress <= 6) stressLabel = 'Moderate';
      else stressLabel = 'High';
    }

    return {
      'sleep': totalSleep,
      'hydration': totalWater,
      'stress': stressLabel,
      'exercise': totalExercise,
      'screen_time': totalScreenTime,
    };
  }

  String _normalizeDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
