/// ==========================================================================
/// logging_service.dart — Core Logging Business Logic (Online-Only)
/// ==========================================================================
/// Orchestrates symptom and lifestyle logging operations:
///
///   1. Validates input using [AppValidators]
///   2. Builds the [HealthLog] model for the API
///   3. Posts to the backend via [HealthLogRepository]
///   4. Triggers notifications/nudges based on log content
///
/// Strictly Online:
///   - All operations require an active connection to the [ApiService].
///   - No local caching or offline fallbacks.
/// ==========================================================================

import 'package:uuid/uuid.dart';
import '../models/health_log.dart';
import '../models/lifestyle_entry.dart';
import '../models/symptom_log.dart';
import '../repositories/health_log_repository.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';

/// Result of a logging operation.
class LogResult {
  final bool success;
  final String? message;
  final Map<String, String>? fieldErrors;

  const LogResult.success([this.message = 'Entry saved successfully!'])
      : success = true,
        fieldErrors = null;

  const LogResult.failure(this.fieldErrors, [this.message])
      : success = false;

  const LogResult.error(String errorMessage)
      : success = false,
        message = errorMessage,
        fieldErrors = null;
}

class LoggingService {
  final HealthLogRepository _healthLogRepo;
  final NotificationService _notifications;
  final Uuid _uuid;

  LoggingService({
    required HealthLogRepository healthLogRepo,
    NotificationService? notifications,
  })  : _healthLogRepo = healthLogRepo,
        _notifications = notifications ?? NotificationService(),
        _uuid = const Uuid();

  // ══════════════════════════════════════════════════════════════════════════
  // ── Symptom Logging ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Logs a new symptom entry.
  Future<LogResult> logSymptom({
    required String userId,
    required String symptomTypeName,
    required double severity,
    required double sleepHours,
    required double waterIntakeLitres,
    required int exerciseMinutes,
    required String mood,
    required double stressLevel,
    String? notes,
  }) async {
    // ── Step 1: Validate inputs ──
    final errors = AppValidators.validateSymptomLogForm(
      symptomType: symptomTypeName,
      severity: severity,
      notes: notes,
    );

    if (errors.isNotEmpty) {
      return LogResult.failure(errors, 'Please fix the highlighted fields.');
    }

    // ── Step 2: Build the HealthLog model ──
    final now = DateTime.now();
    final log = HealthLog(
      id: _uuid.v4(), 
      userId: userId,
      symptom: symptomTypeName,
      severity: severity.round(),
      sleepHours: sleepHours,
      waterIntake: waterIntakeLitres,
      exerciseMinutes: exerciseMinutes,
      mood: mood,
      stressLevel: stressLevel.round(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: now,
    );

    // ── Step 3: POST to backend via repository ──
    try {
      final persisted = await _healthLogRepo.logSymptom(log);
      
      // ── Step 4: Notification triggers (using the persisted or local data) ──
      final symptomLog = SymptomLog(
        id: persisted.id,
        userId: userId,
        date: now,
        symptomType: SymptomType.values.firstWhere(
          (e) => e.name == symptomTypeName,
          orElse: () => SymptomType.other,
        ),
        severity: severity.round(),
        notes: log.notes,
        createdAt: now,
        updatedAt: now,
      );
      await _checkSymptomNotifications(symptomLog);

      return const LogResult.success('Symptom logged successfully!');
    } catch (e) {
      return LogResult.error('Failed to save log: ${e.toString()}');
    }
  }

  /// Updates an existing symptom log (edit flow).
  Future<LogResult> updateSymptomLog({
    required SymptomLog existingLog,
    required double newSeverity,
    String? newNotes,
  }) async {
    final severityError = AppValidators.validateSeverity(newSeverity);
    if (severityError != null) {
      return LogResult.failure({'severity': severityError});
    }

    final updatedHealthLog = HealthLog(
      id: existingLog.id,
      userId: existingLog.userId,
      symptom: existingLog.symptomType.name,
      severity: newSeverity.round(),
      sleepHours: 0,
      waterIntake: 0,
      exerciseMinutes: 0,
      mood: '',
      stressLevel: 5,
      notes: newNotes?.trim(),
      createdAt: existingLog.createdAt,
    );

    try {
      await _healthLogRepo.logSymptom(updatedHealthLog);
      return const LogResult.success('Symptom updated successfully.');
    } catch (e) {
      return LogResult.error('Update failed: ${e.toString()}');
    }
  }

  /// Deletes a symptom log via Firestore.
  Future<LogResult> deleteSymptomLog(String userId, String logId) async {
    try {
      await _healthLogRepo.deleteLog(userId, logId);
      return const LogResult.success('Entry deleted successfully.');
    } catch (e) {
      return LogResult.error('Deletion failed: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Lifestyle Logging ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Logs today's lifestyle entry via the API.
  Future<LogResult> logLifestyle({
    required String userId,
    required double sleepHours,
    required String dietQualityName,
    required int hydrationGlasses,
    required int exerciseMinutes,
    required double stressLevel,
    String? notes,
  }) async {
    final errors = AppValidators.validateLifestyleForm(
      sleepHours: sleepHours,
      hydration: hydrationGlasses,
      exerciseMinutes: exerciseMinutes,
      stressLevel: stressLevel,
    );

    if (errors.isNotEmpty) {
      return LogResult.failure(errors, 'Please fix the highlighted fields.');
    }

    // Build a combined HealthLog for the API
    final now = DateTime.now();
    final mood = _moodFromStress(stressLevel);
    final healthLog = HealthLog(
      id: _uuid.v4(),
      userId: userId,
      symptom: 'lifestyle_check_in',
      severity: 0,
      sleepHours: sleepHours,
      waterIntake: hydrationGlasses * 0.25, // approx 250ml per glass
      exerciseMinutes: exerciseMinutes,
      mood: mood,
      stressLevel: stressLevel.round(),
      notes: notes?.trim(),
      createdAt: now,
    );

    try {
      await _healthLogRepo.logSymptom(healthLog);
      
      // Track for notifications
      final entry = LifestyleEntry(
        id: healthLog.id,
        userId: userId,
        date: now,
        sleepHours: sleepHours,
        diet: DietQuality.values.firstWhere(
          (e) => e.name == dietQualityName,
          orElse: () => DietQuality.fair,
        ),
        hydrationGlasses: hydrationGlasses,
        exerciseMinutes: exerciseMinutes,
        stressLevel: stressLevel.round(),
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await _checkLifestyleNotifications(entry);
      
      return const LogResult.success('Lifestyle logged successfully!');
    } catch (e) {
      return LogResult.error('Failed to log lifestyle: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Data Retrieval (Direct Firestore) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns health history from Firestore as a real-time stream.
  Stream<List<HealthLog>> getHealthHistoryStream(String userId) {
    return _healthLogRepo.getHealthHistoryStream(userId: userId, limit: 100);
  }

  /// Returns symptom logs from Firestore as a real-time stream.
  Stream<List<SymptomLog>> getSymptomLogsStream(String userId) {
    return _healthLogRepo.getHealthHistoryStream(userId: userId, limit: 100).map((healthLogs) {
      return healthLogs.map((hl) {
        final symptomType = SymptomType.values.firstWhere(
          (e) => e.name == hl.symptom || 
                 e.displayName.toLowerCase() == hl.symptom.toLowerCase(),
          orElse: () => SymptomType.other,
        );
        return SymptomLog(
          id: hl.id,
          userId: hl.userId,
          date: hl.createdAt,
          symptomType: symptomType,
          severity: hl.severity,
          notes: hl.notes,
          createdAt: hl.createdAt,
          updatedAt: hl.createdAt,
        );
      }).toList();
    });
  }

  /// Returns health history from Firestore.
  Future<List<HealthLog>> getHealthHistory(String userId) async {
    return await _healthLogRepo.getHealthHistory(userId: userId, limit: 100);
  }

  /// Returns health history converted back to SymptomLog for UI compatibility.
  Future<List<SymptomLog>> getSymptomLogs(String userId) async {
    final healthLogs = await _healthLogRepo.getHealthHistory(userId: userId, limit: 100);
    return healthLogs.map((hl) {
      final symptomType = SymptomType.values.firstWhere(
        (e) => e.name == hl.symptom || 
               e.displayName.toLowerCase() == hl.symptom.toLowerCase(),
        orElse: () => SymptomType.other,
      );
      return SymptomLog(
        id: hl.id,
        userId: hl.userId,
        date: hl.createdAt,
        symptomType: symptomType,
        severity: hl.severity,
        notes: hl.notes,
        createdAt: hl.createdAt,
        updatedAt: hl.createdAt,
      );
    }).toList();
  }

  // ── Private Helpers ──

  String _moodFromStress(double stressLevel) {
    if (stressLevel <= 3) return 'calm';
    if (stressLevel <= 5) return 'neutral';
    if (stressLevel <= 7) return 'stressed';
    return 'overwhelmed';
  }

  Future<void> _checkSymptomNotifications(SymptomLog log) async {
    try {
      if (log.severity >= 8) {
        await _notifications.sendImmediateNudge(
          title: 'Severe ${log.symptomType.displayName} logged',
          body: 'Severity ${log.severity}/10. Remember to rest and stay hydrated.',
          payload: 'symptom_log:${log.id}',
        );
      } else if (log.severity >= 6) {
        await _notifications.sendImmediateNudge(
          title: 'Feeling rough?',
          body: 'Your ${log.symptomType.displayName} is at ${log.severity}/10. Take a break.',
          payload: 'symptom_log:${log.id}',
        );
      }
    } catch (_) {}
  }

  Future<void> _checkLifestyleNotifications(LifestyleEntry entry) async {
    try {
      if (entry.sleepHours < 5) {
        await _notifications.sendImmediateNudge(
          title: 'Sleep alert',
          body: 'Only ${entry.sleepHours.toStringAsFixed(1)} hrs logged. Poor sleep worsens symptoms.',
          payload: 'lifestyle:sleep',
        );
      }
      if (entry.stressLevel >= 8) {
        await _notifications.sendImmediateNudge(
          title: 'High stress detected',
          body: 'Stress ${entry.stressLevel}/10. Try 5 minutes of deep breathing.',
          payload: 'lifestyle:stress',
        );
      }
      if (entry.hydrationGlasses < 3) {
        await _notifications.sendImmediateNudge(
          title: 'Stay hydrated 💧',
          body: 'Only ${entry.hydrationGlasses} glasses today. Aim for 8.',
          payload: 'lifestyle:hydration',
        );
      }
    } catch (_) {}
  }
}
