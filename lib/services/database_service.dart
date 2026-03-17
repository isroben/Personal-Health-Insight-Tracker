/// ==========================================================================
/// database_service.dart — Firestore CRUD Operations
/// ==========================================================================
/// Centralized data layer for all Cloud Firestore read/write operations.
///
/// Collections:
///   - `users`             → User profiles
///   - `symptom_logs`      → Individual symptom entries
///   - `lifestyle_entries` → Daily lifestyle snapshots
///   - `correlations`      → Detected symptom-trigger correlations
///
/// Design decisions:
///   - All methods accept/return model objects (not raw maps)
///   - Queries are filtered by `userId` for data isolation
///   - Date-range queries use composite indexes on [userId, date]
///   - Lifestyle entries use upsert logic (one per user per day)
///
/// Consumed by Riverpod providers for reactive state updates.
/// ==========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../models/correlation.dart';

class DatabaseService {
  final FirebaseFirestore _db;

  /// Allow dependency injection for testing; uses real Firestore by default.
  DatabaseService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════════════
  // ── Collection References ──
  // ══════════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _symptomLogsCol =>
      _db.collection('symptom_logs');

  CollectionReference<Map<String, dynamic>> get _lifestyleCol =>
      _db.collection('lifestyle_entries');

  CollectionReference<Map<String, dynamic>> get _correlationsCol =>
      _db.collection('correlations');

  // ══════════════════════════════════════════════════════════════════════════
  // ── User Operations ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches the user profile document from Firestore.
  /// Returns `null` if the document does not exist.
  Future<UserModel?> getUser(String userId) async {
    final doc = await _usersCol.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Updates specific fields on a user's profile document.
  /// Uses Firestore merge to avoid overwriting unchanged fields.
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now().toIso8601String();
    await _usersCol.doc(userId).update(updates);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Symptom Logs — CRUD ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Saves a new symptom log entry to Firestore.
  /// Uses the log's [id] as the document ID for idempotent writes.
  Future<void> addSymptomLog(SymptomLog log) async {
    await _symptomLogsCol.doc(log.id).set(log.toMap());
  }

  /// Updates an existing symptom log entry.
  /// Useful when the user edits severity or notes after initial logging.
  Future<void> updateSymptomLog(SymptomLog log) async {
    await _symptomLogsCol.doc(log.id).update(log.toMap());
  }

  /// Returns all symptom logs for a user, ordered by date (newest first).
  /// Optionally limited to [limit] results for pagination.
  Future<List<SymptomLog>> getSymptomLogs(
    String userId, {
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _symptomLogsCol
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (limit != null) query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SymptomLog.fromMap(doc.data())).toList();
  }

  /// Returns symptom logs within a specific date range.
  /// Used by the Reports and Insights modules for time-bound analysis.
  Future<List<SymptomLog>> getSymptomLogsByDateRange(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _symptomLogsCol
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => SymptomLog.fromMap(doc.data())).toList();
  }

  /// Deletes a specific symptom log by its document ID.
  Future<void> deleteSymptomLog(String logId) async {
    await _symptomLogsCol.doc(logId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Lifestyle Entries — CRUD ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Saves or updates a lifestyle entry.
  ///
  /// Uses Firestore `set` with merge semantics. Because there should be
  /// only ONE lifestyle entry per user per day, we use the composite
  /// document ID: `{userId}_{dateKey}` to enforce this constraint.
  Future<void> addLifestyleEntry(LifestyleEntry entry) async {
    // Composite ID ensures one entry per user per day
    final docId = '${entry.userId}_${entry.dateKey}';
    await _lifestyleCol.doc(docId).set(entry.toMap(), SetOptions(merge: true));
  }

  /// Returns all lifestyle entries for a user, ordered by date (newest first).
  Future<List<LifestyleEntry>> getLifestyleEntries(
    String userId, {
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _lifestyleCol
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (limit != null) query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => LifestyleEntry.fromMap(doc.data()))
        .toList();
  }

  /// Returns lifestyle entries within a specific date range.
  Future<List<LifestyleEntry>> getLifestyleEntriesByDateRange(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _lifestyleCol
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LifestyleEntry.fromMap(doc.data()))
        .toList();
  }

  /// Returns today's lifestyle entry for a user, if it exists.
  /// Useful for pre-populating the logging screen.
  Future<LifestyleEntry?> getTodayLifestyleEntry(String userId) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
    final docId = '${userId}_$dateKey';

    final doc = await _lifestyleCol.doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    return LifestyleEntry.fromMap(doc.data()!);
  }

  /// Deletes a lifestyle entry by its document ID.
  Future<void> deleteLifestyleEntry(String docId) async {
    await _lifestyleCol.doc(docId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Correlations / Insights ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Saves a detected correlation (usually written by the AI insight engine).
  Future<void> saveCorrelation(Correlation correlation) async {
    await _correlationsCol.doc(correlation.id).set(correlation.toMap());
  }

  /// Saves a batch of correlations at once (after an AI analysis run).
  /// Uses a Firestore batch write for atomicity.
  Future<void> saveCorrelationsBatch(List<Correlation> correlations) async {
    final batch = _db.batch();
    for (final c in correlations) {
      batch.set(_correlationsCol.doc(c.id), c.toMap());
    }
    await batch.commit();
  }

  /// Returns all correlations for a user, ordered by strength (strongest first).
  Future<List<Correlation>> getCorrelations(String userId) async {
    final snapshot = await _correlationsCol
        .where('userId', isEqualTo: userId)
        .orderBy('severityCorrelation', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Correlation.fromMap(doc.data()))
        .toList();
  }

  /// Deletes all correlations for a user (e.g., when re-running analysis).
  Future<void> clearCorrelations(String userId) async {
    final snapshot =
        await _correlationsCol.where('userId', isEqualTo: userId).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Stream Variants (Real-time Listeners) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Real-time stream of symptom logs for a user.
  /// Used by the HomeScreen to display live updates.
  Stream<List<SymptomLog>> symptomLogsStream(String userId, {int? limit}) {
    Query<Map<String, dynamic>> query = _symptomLogsCol
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (limit != null) query = query.limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SymptomLog.fromMap(doc.data())).toList());
  }

  /// Real-time stream of correlations for a user.
  Stream<List<Correlation>> correlationsStream(String userId) {
    return _correlationsCol
        .where('userId', isEqualTo: userId)
        .orderBy('severityCorrelation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Correlation.fromMap(doc.data()))
            .toList());
  }
}
