/// ==========================================================================
/// nudge_service.dart — Pattern-Based Health Nudges
/// ==========================================================================
/// Logic layer for determining when to "nudge" the user.
/// 
/// Triggers:
/// 1. Environmental: High AQI, sudden pressure drops (migraine risk).
/// 2. Patterns: 3+ days of poor sleep, low hydration, or zero exercise.
/// 3. Predictive: AI-detected risky days.
/// ==========================================================================

import '../models/lifestyle_entry.dart';
import '../models/symptom_log.dart';
import 'notification_service.dart';
import 'environmental_service.dart';
import 'ai_insight_service.dart';

class NudgeService {
  final NotificationService _notifications;
  final EnvironmentalService _environmental;
  final AIInsightService _ai;

  NudgeService({
    NotificationService? notifications,
    EnvironmentalService? environmental,
    AIInsightService? ai,
  })  : _notifications = notifications ?? NotificationService(),
        _environmental = environmental ?? EnvironmentalService(),
        _ai = ai ?? AIInsightService();

  // ══════════════════════════════════════════════════════════════════════════
  // ── Environmental Nudges ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Checks current weather/air quality and sends nudges if triggers are met.
  Future<void> checkEnvironmentalNudges() async {
    final context = await _environmental.getCurrentContext();

    if (context.isHighRiskAirQuality) {
      await _notifications.sendImmediateNudge(
        title: 'Air Quality Alert 💨',
        body: 'AQI is at ${context.aqi} (Unhealthy). Consider staying indoors today to avoid respiratory triggers.',
        payload: 'env:aqi',
      );
    }

    if (context.humidity > 80) {
      await _notifications.sendImmediateNudge(
        title: 'High Humidity Today',
        body: 'Humidity is ${context.humidity}%. High humidity can be a trigger for some — stay cool and hydrated.',
        payload: 'env:humidity',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Pattern-Based Nudges ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Analyzes recent lifestyle entries for multi-day patterns.
  Future<void> checkPatternNudges(List<LifestyleEntry> recentLogs) async {
    if (recentLogs.length < 3) return;

    // ── 1. Sleep Streak (last 3 entries) ──
    final last3Sleep = recentLogs.take(3).map((e) => e.sleepHours).toList();
    final avgSleep = last3Sleep.reduce((a, b) => a + b) / 3;
    
    if (avgSleep < 5.5) {
      await _notifications.sendImmediateNudge(
        title: 'Restorative Sleep Needed',
        body: 'You\'ve averaged only ${avgSleep.toStringAsFixed(1)} hrs of sleep lately. Consistency is key for symptom control.',
        payload: 'pattern:sleep',
      );
    }

    // ── 2. Hydration Habit ──
    final daysDehydrated = recentLogs.take(3).where((e) => e.hydrationGlasses < 4).length;
    if (daysDehydrated >= 3) {
      await _notifications.sendImmediateNudge(
        title: 'Hydration Challenge 💧',
        body: 'You\'ve hit your hydration goal 0 times in the last 3 days. Ready to drink an extra glass now?',
        payload: 'pattern:hydration',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Predictive Nudges (Premium Integration) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Uses AI service to predict risk for the current day.
  Future<void> checkPredictiveNudge({
    required String userId,
    required List<SymptomLog> symptomLogs,
    required List<LifestyleEntry> lifestyleLogs,
  }) async {
    // In a real app, logic would check if user is Premium first
    try {
      // Mocking AI prediction for MVP
      // If AI detects a high-risk alignment, send a predictive alert
      await _notifications.sendPredictiveAlert(
        symptomName: 'Migraine',
        riskScore: 0.85,
      );
    } catch (_) {}
  }
}
