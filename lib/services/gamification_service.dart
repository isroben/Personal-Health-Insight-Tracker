import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../models/user_model.dart';
import 'database_service.dart';

/// ==========================================================================
/// gamification_service.dart — Engagement & Health Scoring
/// ==========================================================================
/// Handles the "Gamification" layer of the app, including:
/// 1. Logging Streaks: Consecutive days of symptom or lifestyle logging.
/// 2. Wellness Score: A 0-100 composite index based on data density/balance.
/// ==========================================================================

class GamificationService {
  final DatabaseService _db;

  GamificationService({DatabaseService? db}) : _db = db ?? DatabaseService();

  // ══════════════════════════════════════════════════════════════════════════
  // ── 1. Streak Calculation ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates the current logging streak for a user.
  /// A streak counts consecutive days (starting from yesterday back) where 
  /// at least one symptom or lifestyle entry was recorded.
  Future<int> calculateCurrentStreak(String userId) async {
    final now = DateTime.now();
    final logs = await _db.getSymptomLogs(userId, limit: 30);
    final entries = await _db.getLifestyleEntries(userId, limit: 30);

    // Combine and sort unique dates (normalized to YYYY-MM-DD)
    final activityDates = <String>{};
    for (var l in logs) activityDates.add(_normalizeDate(l.date));
    for (var e in entries) activityDates.add(_normalizeDate(e.date));

    final sortedDates = activityDates.toList()..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return 0;

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

  /// Calculates a "Wellness Score" (0-100) based on the last 7 days.
  /// Components:
  /// - Data Density (40%): How many days did you log?
  /// - Symptom Stability (30%): Are symptoms trending down/low?
  /// - Lifestyle Balance (30%): Water/Sleep/Exercise adherence.
  Future<int> calculateWellnessScore(String userId) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final logs = await _db.getSymptomLogsByDateRange(
      userId, 
      startDate: sevenDaysAgo, 
      endDate: now
    );
    final entries = await _db.getLifestyleEntriesByDateRange(
      userId, 
      startDate: sevenDaysAgo, 
      endDate: now
    );

    // 1. Data Density (max 40 pts)
    final uniqueDays = <String>{
      ...logs.map((l) => _normalizeDate(l.date)),
      ...entries.map((e) => _normalizeDate(e.date))
    }.length;
    double densityScore = (uniqueDays / 7.0) * 40;

    // 2. Symptom Stability (max 30 pts)
    // Formula: 30 - average severity (0-10) scaled to 30.
    double stabilityScore = 30.0;
    if (logs.isNotEmpty) {
      final avgSeverity = logs.map((l) => l.severity).reduce((a, b) => a + b) / logs.length;
      stabilityScore = 30 - (avgSeverity * 3);
    }

    // 3. Lifestyle Balance (max 30 pts)
    double balanceScore = 0.0;
    if (entries.isNotEmpty) {
      final avgSleep = entries.map((e) => e.sleepHours).reduce((a, b) => a + b) / entries.length;
      final avgWater = entries.map((e) => e.hydrationGlasses).reduce((a, b) => a + b) / entries.length;
      
      // Target: 8hrs sleep (15 pts), 8 glasses water (15 pts)
      double sleepPts = (avgSleep / 8.0) * 15;
      double waterPts = (avgWater / 8.0) * 15;
      balanceScore = (sleepPts.clamp(0, 15) + waterPts.clamp(0, 15));
    }

    return (densityScore + stabilityScore + balanceScore).round().clamp(0, 100);
  }

  String _normalizeDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
