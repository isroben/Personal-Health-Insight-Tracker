import '../models/health_log.dart';
import '../repositories/health_log_repository.dart';

/// ==========================================================================
/// gamification_service.dart — Engagement & Health Scoring
/// ==========================================================================
/// Handles the "Gamification" layer of the app, including:
/// 1. Logging Streaks: Consecutive days of logging.
/// 2. Wellness Score: A 0-100 composite index based on data density/stability.
/// 3. Health Trends: Comparing current performance to previous periods.
///
/// ARCHITECTURE NOTE:
///   Now uses [HealthLogRepository] to fetch data from the API/cache.
///   No longer depends on [DatabaseService] directly.
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

  /// Calculates the current logging streak for a user.
  /// Fetches the last 50 logs from the repository.
  Future<int> calculateCurrentStreak(String userId) async {
    final now = DateTime.now();
    final logs = await _repo.getHealthHistory(userId: userId, limit: 50);

    if (logs.isEmpty) return 0;

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

  /// Calculates a "Wellness Score" (0-100) for a given date range.
  Future<int> calculateWellnessScore(String userId, {DateTime? start, DateTime? end}) async {
    final now = end ?? DateTime.now();
    final startDate = start ?? now.subtract(const Duration(days: 7));

    final logs = await _repo.getHealthHistory(userId: userId, limit: 100);
    final periodLogs = logs.where((l) => 
      l.createdAt.isAfter(startDate) && l.createdAt.isBefore(now.add(const Duration(seconds: 1)))
    ).toList();

    if (periodLogs.isEmpty) return 0;

    // 1. Data Density (max 40 pts)
    final uniqueDays = periodLogs.map((l) => _normalizeDate(l.createdAt)).toSet().length;
    double densityScore = (uniqueDays / 7.0) * 40;

    // 2. Symptom Stability (max 30 pts)
    // Filter for logs with actual symptoms (not just lifestyle check-ins)
    final symptomLogs = periodLogs.where((l) => l.symptom != 'lifestyle_check_in').toList();
    double stabilityScore = 30.0;
    if (symptomLogs.isNotEmpty) {
      final avgSeverity = symptomLogs.map((l) => l.severity).reduce((a, b) => a + b) / symptomLogs.length;
      stabilityScore = 30.0 - (avgSeverity.toDouble() * 3.0);
    }

    // 3. Lifestyle Balance (max 30 pts)
    // Filter for logs with lifestyle data
    final lifestyleLogs = periodLogs.where((l) => l.sleepHours > 0 || l.waterIntake > 0).toList();
    double balanceScore = 0.0;
    if (lifestyleLogs.isNotEmpty) {
      final avgSleep = lifestyleLogs.map((l) => l.sleepHours).reduce((a, b) => a + b) / lifestyleLogs.length;
      final avgWater = lifestyleLogs.map((l) => l.waterIntake).reduce((a, b) => a + b) / lifestyleLogs.length;
      
      // Target: 8hrs sleep (15 pts), 2L water (15 pts)
      double sleepPts = (avgSleep / 8.0) * 15;
      double waterPts = (avgWater / 2.0) * 15;
      balanceScore = (sleepPts.clamp(0, 15) + waterPts.clamp(0, 15));
    }

    return (densityScore + stabilityScore + balanceScore).round().clamp(0, 100);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 3. Health Trend ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates the score trend (Current week vs Previous week).
  Future<HealthTrend> calculateHealthTrend(String userId) async {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(const Duration(days: 7));
    final lastWeekStart = now.subtract(const Duration(days: 14));

    final currentScore = await calculateWellnessScore(userId, start: thisWeekStart, end: now);
    final previousScore = await calculateWellnessScore(userId, start: lastWeekStart, end: thisWeekStart);

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
  // ── 4. Detailed Analytics for Charts ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates daily wellness scores for the past 7 days.
  Future<List<double>> calculateDailyScores(String userId) async {
    final List<double> dailyScores = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd =
          dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));

      final score =
          await calculateWellnessScore(userId, start: dayStart, end: dayEnd);
      dailyScores.add(score.toDouble());
    }
    return dailyScores;
  }

  /// Calculates symptom frequency for the past 30 days.
  Future<Map<String, int>> calculateMonthlySymptomFrequency(
      String userId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    // Fetch a large enough history to cover 30 days
    final logs = await _repo.getHealthHistory(userId: userId, limit: 500);

    final periodLogs =
        logs.where((l) => l.createdAt.isAfter(thirtyDaysAgo)).toList();

    final Map<String, int> frequencies = {};
    for (final log in periodLogs) {
      if (log.symptom.isNotEmpty && log.symptom != 'lifestyle_check_in') {
        frequencies[log.symptom] = (frequencies[log.symptom] ?? 0) + 1;
      }
    }
    return frequencies;
  }

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
      };
    }

    // Aggregation logic
    double totalSleep = 0;
    double totalWater = 0;
    int totalExercise = 0;
    int totalStress = 0;
    int stressCount = 0;

    for (var l in todayLogs) {
      // For sleep, we take the latest non-zero entry from today
      if (l.sleepHours > 0) totalSleep = l.sleepHours; 
      
      totalWater += l.waterIntake;
      totalExercise += l.exerciseMinutes;
      
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
    };
  }

  String _normalizeDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
