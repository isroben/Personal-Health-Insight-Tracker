/// ==========================================================================
/// logging_service.dart — Core Logging Business Logic
/// ==========================================================================
/// Orchestrates symptom and lifestyle logging operations:
///
///   1. Validates input using [AppValidators]
///   2. Builds the model object (SymptomLog / LifestyleEntry)
///   3. Saves to cloud (DatabaseService) with offline fallback (LocalCacheService)
///   4. Triggers notifications/nudges based on log content
///
/// This service is the single source of truth for all log write operations.
/// It is consumed by the Riverpod providers in the UI layer.
/// ==========================================================================

import 'package:uuid/uuid.dart';

import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../utils/validators.dart';
import 'database_service.dart';
import 'local_cache_service.dart';
import 'notification_service.dart';

/// Result of a logging operation — carries success flag and error messages.
class LogResult {
  final bool success;
  final String? message; // Success message or error summary
  final Map<String, String>? fieldErrors; // Form field → error message

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
  final DatabaseService _db;
  final LocalCacheService _cache;
  final NotificationService _notifications;
  final Uuid _uuid;

  LoggingService({
    DatabaseService? db,
    LocalCacheService? cache,
    NotificationService? notifications,
  })  : _db = db ?? DatabaseService(),
        _cache = cache ?? LocalCacheService(),
        _notifications = notifications ?? NotificationService(),
        _uuid = const Uuid();

  // ══════════════════════════════════════════════════════════════════════════
  // ── Symptom Logging ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Logs a new symptom entry for the given user.
  ///
  /// Steps:
  ///   1. Validate inputs (severity 1–10, symptom type required)
  ///   2. Build a [SymptomLog] with a new UUID and current timestamp
  ///   3. Write to LocalCacheService immediately (offline-first)
  ///   4. Attempt Firestore write; on failure, add to sync queue
  ///   5. Trigger high-severity nudge notification if severity >= 7
  ///   6. Return [LogResult] with success/failure state
  Future<LogResult> logSymptom({
    required String userId,
    required String symptomTypeName,
    required double severity,
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

    // ── Step 2: Build the model ──
    final now = DateTime.now();
    final log = SymptomLog(
      id: _uuid.v4(), // Generate a collision-resistant UUID
      userId: userId,
      date: now,
      symptomType: SymptomType.values.firstWhere(
        (e) => e.name == symptomTypeName,
        orElse: () => SymptomType.other,
      ),
      severity: severity.round(), // Normalize slider double to int
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    // ── Step 3: Write to local cache immediately ──
    // The user sees instant feedback regardless of connectivity.
    await _cache.cacheSymptomLog(log);

    // ── Step 4: Attempt Firestore write ──
    try {
      await _db.addSymptomLog(log);
    } catch (e) {
      // If Firestore fails (e.g. offline), queue for later sync.
      await _cache.addToSyncQueue(
        type: 'symptom_log',
        action: 'add',
        data: log.toMap(),
      );
      // Not a failure from the user's POV — data is safe in local cache.
    }

    // ── Step 5: Check notification triggers ──
    await _checkSymptomNotifications(log);

    return const LogResult.success('Symptom logged successfully!');
  }

  /// Updates an existing symptom log (e.g., user corrects severity).
  Future<LogResult> updateSymptomLog({
    required SymptomLog existingLog,
    required double newSeverity,
    String? newNotes,
  }) async {
    // Validate the updated severity
    final severityError = AppValidators.validateSeverity(newSeverity);
    if (severityError != null) {
      return LogResult.failure({'severity': severityError});
    }

    final updated = existingLog.copyWith(
      severity: newSeverity.round(),
      notes: newNotes?.trim(),
      updatedAt: DateTime.now(),
    );

    // Update local cache first
    await _cache.cacheSymptomLog(updated);

    try {
      await _db.updateSymptomLog(updated);
    } catch (e) {
      await _cache.addToSyncQueue(
        type: 'symptom_log',
        action: 'update',
        data: updated.toMap(),
      );
    }

    return const LogResult.success('Symptom updated.');
  }

  /// Deletes a symptom log by its ID.
  Future<LogResult> deleteSymptomLog(String logId) async {
    await _cache.removeSymptomLog(logId);

    try {
      await _db.deleteSymptomLog(logId);
    } catch (e) {
      await _cache.addToSyncQueue(
        type: 'symptom_log',
        action: 'delete',
        data: {'id': logId},
      );
    }

    return const LogResult.success('Entry deleted.');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Lifestyle Logging ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Logs or updates today's lifestyle entry for the given user.
  ///
  /// Steps:
  ///   1. Validate all lifestyle fields
  ///   2. Build [LifestyleEntry] with today's date and composite doc ID
  ///   3. Write to local cache immediately (offline-first)
  ///   4. Attempt Firestore upsert; queue offline if it fails
  ///   5. Trigger nudge notifications based on concerning patterns
  ///   6. Return [LogResult]
  Future<LogResult> logLifestyle({
    required String userId,
    required double sleepHours,
    required String dietQualityName,
    required int hydrationGlasses,
    required int exerciseMinutes,
    required double stressLevel,
    String? notes,
  }) async {
    // ── Step 1: Validate inputs ──
    final errors = AppValidators.validateLifestyleForm(
      sleepHours: sleepHours,
      hydration: hydrationGlasses,
      exerciseMinutes: exerciseMinutes,
      stressLevel: stressLevel,
    );

    if (errors.isNotEmpty) {
      return LogResult.failure(errors, 'Please fix the highlighted fields.');
    }

    // ── Step 2: Build the model ──
    final now = DateTime.now();
    final entry = LifestyleEntry(
      id: _uuid.v4(),
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

    // ── Step 3: Write to local cache ──
    await _cache.cacheLifestyleEntry(entry);

    // ── Step 4: Attempt Firestore upsert ──
    try {
      await _db.addLifestyleEntry(entry); // Uses upsert internally
    } catch (e) {
      await _cache.addToSyncQueue(
        type: 'lifestyle_entry',
        action: 'add',
        data: entry.toMap(),
      );
    }

    // ── Step 5: Check lifestyle-based notification triggers ──
    await _checkLifestyleNotifications(entry);

    return const LogResult.success('Lifestyle logged successfully!');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Cache-first Data Retrieval ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns a merged list of symptom logs: fetches from Firestore and
  /// updates the local cache, but returns the cache immediately for speed.
  ///
  /// Pattern: Cache-then-Network (optimistic UI)
  Future<List<SymptomLog>> getSymptomLogs(String userId) async {
    // Return cache immediately for instant UI
    final cached = _cache.getCachedSymptomLogs();

    // Fetch from Firestore in background and update cache
    try {
      final remote = await _db.getSymptomLogs(userId, limit: 100);
      await _cache.cacheSymptomLogsBatch(remote);
      return remote;
    } catch (_) {
      // Offline — return whatever is in the cache
      return cached;
    }
  }

  /// Returns today's lifestyle entry, checking local cache first.
  Future<LifestyleEntry?> getTodayLifestyleEntry(String userId) async {
    // Try Firestore first
    try {
      final remote = await _db.getTodayLifestyleEntry(userId);
      if (remote != null) {
        await _cache.cacheLifestyleEntry(remote);
        return remote;
      }
    } catch (_) {
      // Offline — try local cache
    }

    // Search cache for today's entry
    final cached = _cache.getCachedLifestyleEntries();
    final today = DateTime.now();
    return cached.where((e) =>
        e.date.year == today.year &&
        e.date.month == today.month &&
        e.date.day == today.day).firstOrNull;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Offline Sync ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Processes all pending sync queue items after connectivity is restored.
  ///
  /// Iterates through the sync queue and replays each pending operation
  /// against Firestore. Successfully synced items are removed from the queue.
  Future<void> syncPendingOperations() async {
    final pending = _cache.getPendingSyncOps();

    if (pending.isEmpty) return;

    for (final op in pending) {
      try {
        final type = op['type'] as String?;
        final action = op['action'] as String?;
        final data = op['data'] as Map<String, dynamic>?;

        if (type == null || action == null || data == null) continue;

        if (type == 'symptom_log') {
          final log = SymptomLog.fromMap(data);
          if (action == 'add' || action == 'update') {
            await _db.addSymptomLog(log);
          } else if (action == 'delete') {
            await _db.deleteSymptomLog(data['id'] as String);
          }
        } else if (type == 'lifestyle_entry') {
          final entry = LifestyleEntry.fromMap(data);
          if (action == 'add') {
            await _db.addLifestyleEntry(entry);
          }
        }

        // Remove successfully synced item from the queue
        final key = op['timestamp'] as String? ?? '';
        await _cache.removeSyncOp(key);
      } catch (e) {
        // Skip failed items — they'll be retried on next sync
        continue;
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Private: Notification Triggers ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Checks a newly logged symptom and triggers notifications when needed.
  ///
  /// Triggers:
  ///   - High severity (>= 7): "You logged a severe episode — stay hydrated
  ///     and rest." nudge notification
  ///   - Migraine: Specific migraine care tip notification
  Future<void> _checkSymptomNotifications(SymptomLog log) async {
    try {
      if (log.severity >= 8) {
        // Critical severity nudge — encourage immediate self-care action
        await _notifications.sendImmediateNudge(
          title: 'Severe ${log.symptomType.displayName} logged',
          body:
              'Severity ${log.severity}/10 detected. Remember to rest, '
              'stay hydrated, and avoid bright screens.',
          payload: 'symptom_log:${log.id}',
        );
      } else if (log.severity >= 6) {
        // Moderate severity — gentle tip
        await _notifications.sendImmediateNudge(
          title: 'Feeling rough?',
          body:
              'Your ${log.symptomType.displayName} is at ${log.severity}/10. '
              'Take a break and drink some water.',
          payload: 'symptom_log:${log.id}',
        );
      }

      // Migraine-specific advice
      if (log.symptomType == SymptomType.migraine && log.severity >= 5) {
        await _notifications.sendImmediateNudge(
          title: 'Migraine detected',
          body:
              'Find a quiet, dark space. Avoid screens. '
              'Track any triggers you notice today.',
          payload: 'symptom_log:${log.id}',
        );
      }
    } catch (_) {
      // Notification failures are non-critical — don't block the log save
    }
  }

  /// Checks a lifestyle entry and triggers nudges for concerning patterns.
  ///
  /// Triggers:
  ///   - Low sleep (< 5 hrs): sleep hygiene nudge
  ///   - High stress (>= 8): stress relief nudge
  ///   - Very low hydration (< 3 glasses): hydration nudge
  ///   - No exercise: gentle activity reminder
  Future<void> _checkLifestyleNotifications(LifestyleEntry entry) async {
    try {
      if (entry.sleepHours < 5) {
        await _notifications.sendImmediateNudge(
          title: 'Sleep alert',
          body:
              'Only ${entry.sleepHours.toStringAsFixed(1)} hrs of sleep logged. '
              'Poor sleep is a top trigger for headaches and fatigue.',
          payload: 'lifestyle:sleep',
        );
      }

      if (entry.stressLevel >= 8) {
        await _notifications.sendImmediateNudge(
          title: 'High stress detected',
          body:
              'Stress level ${entry.stressLevel}/10. '
              'Try 5 minutes of deep breathing or a short walk.',
          payload: 'lifestyle:stress',
        );
      }

      if (entry.hydrationGlasses < 3) {
        await _notifications.sendImmediateNudge(
          title: 'Stay hydrated 💧',
          body:
              'Only ${entry.hydrationGlasses} glasses logged today. '
              'Aim for 8 glasses — dehydration worsens most symptoms.',
          payload: 'lifestyle:hydration',
        );
      }

      if (entry.exerciseMinutes == 0) {
        // Schedule a gentle activity reminder for later today, not immediate
        await _notifications.scheduleDelayedNudge(
          title: 'Move a little today',
          body: 'Even a 10-minute walk can reduce stress and improve sleep quality.',
          delayMinutes: 60,
          payload: 'lifestyle:exercise',
        );
      }
    } catch (_) {
      // Non-critical — don't block lifestyle save
    }
  }
}
