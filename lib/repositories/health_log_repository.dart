import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_log.dart';

class HealthLogRepository {
  final FirebaseFirestore _db;

  HealthLogRepository({
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════════════
  // ── Create Log ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Submits a new health log entry directly to Firestore.
  /// Path: users/{uid}/logs/{logId}
  Future<HealthLog> logSymptom(HealthLog log) async {
    final uid = log.userId;
    if (uid.isEmpty) throw Exception('User ID is required for logging');

    final docRef = _db.collection('users').doc(uid).collection('logs').doc();
    
    final persistedLog = log.copyWith(id: docRef.id);
    await docRef.set(persistedLog.toJson());

    return persistedLog;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Read History ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches the user's health log history directly from Firestore.
  Future<List<HealthLog>> getHealthHistory({
    required String userId,
    int limit = 50,
  }) async {
    final query = _db
        .collection('users')
        .doc(userId)
        .collection('logs')
        .orderBy('created_at', descending: true)
        .limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => HealthLog.fromJson(doc.data()))
        .toList();
  }

  /// Provides a real-time stream of the user's health log history.
  Stream<List<HealthLog>> getHealthHistoryStream({
    required String userId,
    int limit = 100,
  }) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('logs')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthLog.fromJson(doc.data()))
            .toList());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Delete Log ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Deletes a health log directly from Firestore.
  Future<void> deleteLog(String userId, String logId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('logs')
        .doc(logId)
        .delete();
  }
}
