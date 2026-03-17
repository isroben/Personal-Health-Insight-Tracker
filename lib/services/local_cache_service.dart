/// ==========================================================================
/// local_cache_service.dart — Offline Local Cache (Hive)
/// ==========================================================================
/// Provides local caching for offline-first behavior using Hive.
///
/// Strategy:
///   - Each entity type has its own Hive box (key-value store)
///   - Data is stored as JSON strings keyed by document ID
///   - When online: write-through (save to Firestore + local cache)
///   - When offline: write to local cache, queue for sync later
///   - On app launch: load from cache first, then fetch remote updates
///
/// Boxes:
///   - 'symptom_logs'      → cached symptom log entries
///   - 'lifestyle_entries' → cached lifestyle entries
///   - 'correlations'      → cached correlation insights
///   - 'user_profile'      → cached current user data
///   - 'sync_queue'        → pending writes to sync when back online
///
/// This service does NOT depend on Firebase — it's pure local storage.
/// ==========================================================================

import 'package:hive_flutter/hive_flutter.dart';

import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../models/correlation.dart';
import '../models/user_model.dart';

class LocalCacheService {
  // ── Box Names ──
  static const String _symptomBox = 'symptom_logs';
  static const String _lifestyleBox = 'lifestyle_entries';
  static const String _correlationBox = 'correlations';
  static const String _userBox = 'user_profile';
  static const String _syncQueueBox = 'sync_queue';

  // ══════════════════════════════════════════════════════════════════════════
  // ── Initialisation ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Initialises Hive and opens all required boxes.
  /// Call this once at app startup (in main.dart).
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(_symptomBox),
      Hive.openBox<String>(_lifestyleBox),
      Hive.openBox<String>(_correlationBox),
      Hive.openBox<String>(_userBox),
      Hive.openBox<String>(_syncQueueBox),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── User Profile Cache ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Caches the current user profile locally.
  /// Called after sign-in or when profile data is fetched from Firestore.
  Future<void> cacheUser(UserModel user) async {
    final box = Hive.box<String>(_userBox);
    await box.put('current_user', user.toJson());
  }

  /// Returns the cached user profile, or null if not cached.
  /// Useful for instant app launch before Firestore responds.
  UserModel? getCachedUser() {
    final box = Hive.box<String>(_userBox);
    final json = box.get('current_user');
    if (json == null) return null;
    return UserModel.fromJson(json);
  }

  /// Clears cached user data (called on sign-out).
  Future<void> clearUserCache() async {
    final box = Hive.box<String>(_userBox);
    await box.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Symptom Logs Cache ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Caches a single symptom log locally, keyed by its ID.
  Future<void> cacheSymptomLog(SymptomLog log) async {
    final box = Hive.box<String>(_symptomBox);
    await box.put(log.id, log.toJson());
  }

  /// Caches a batch of symptom logs (e.g., after fetching from Firestore).
  /// Replaces any existing entries with the same IDs.
  Future<void> cacheSymptomLogsBatch(List<SymptomLog> logs) async {
    final box = Hive.box<String>(_symptomBox);
    final entries = {for (final log in logs) log.id: log.toJson()};
    await box.putAll(entries);
  }

  /// Returns all cached symptom logs, sorted by date (newest first).
  List<SymptomLog> getCachedSymptomLogs() {
    final box = Hive.box<String>(_symptomBox);
    final logs = box.values.map((json) => SymptomLog.fromJson(json)).toList();
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  /// Removes a symptom log from the local cache.
  Future<void> removeSymptomLog(String logId) async {
    final box = Hive.box<String>(_symptomBox);
    await box.delete(logId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Lifestyle Entries Cache ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Caches a single lifestyle entry locally.
  Future<void> cacheLifestyleEntry(LifestyleEntry entry) async {
    final box = Hive.box<String>(_lifestyleBox);
    await box.put(entry.id, entry.toJson());
  }

  /// Caches a batch of lifestyle entries.
  Future<void> cacheLifestyleEntriesBatch(List<LifestyleEntry> entries) async {
    final box = Hive.box<String>(_lifestyleBox);
    final map = {for (final e in entries) e.id: e.toJson()};
    await box.putAll(map);
  }

  /// Returns all cached lifestyle entries, sorted by date (newest first).
  List<LifestyleEntry> getCachedLifestyleEntries() {
    final box = Hive.box<String>(_lifestyleBox);
    final entries =
        box.values.map((json) => LifestyleEntry.fromJson(json)).toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Removes a lifestyle entry from cache.
  Future<void> removeLifestyleEntry(String entryId) async {
    final box = Hive.box<String>(_lifestyleBox);
    await box.delete(entryId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Correlations Cache ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Caches a batch of correlations (replaces all previous).
  /// Called after an AI analysis run returns new insights.
  Future<void> cacheCorrelationsBatch(List<Correlation> correlations) async {
    final box = Hive.box<String>(_correlationBox);
    await box.clear(); // Replace all previous correlations
    final map = {for (final c in correlations) c.id: c.toJson()};
    await box.putAll(map);
  }

  /// Returns all cached correlations, sorted by strength (strongest first).
  List<Correlation> getCachedCorrelations() {
    final box = Hive.box<String>(_correlationBox);
    final correlations =
        box.values.map((json) => Correlation.fromJson(json)).toList();
    correlations
        .sort((a, b) => b.severityCorrelation.compareTo(a.severityCorrelation));
    return correlations;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Sync Queue (Offline Write Queue) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Adds a pending write operation to the sync queue.
  ///
  /// Each entry is a JSON-encoded map with:
  ///   - 'type': 'symptom_log' | 'lifestyle_entry' | 'correlation'
  ///   - 'action': 'add' | 'update' | 'delete'
  ///   - 'data': the serialized model data (or just the ID for deletes)
  ///   - 'timestamp': when the operation was queued
  ///
  /// The sync queue is processed when connectivity is restored.
  Future<void> addToSyncQueue({
    required String type,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final box = Hive.box<String>(_syncQueueBox);
    final key = '${DateTime.now().millisecondsSinceEpoch}_$type';
    final entry = {
      'type': type,
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.put(key, _mapToJson(entry));
  }

  /// Returns all pending sync operations in chronological order.
  List<Map<String, dynamic>> getPendingSyncOps() {
    final box = Hive.box<String>(_syncQueueBox);
    return box.values.map((json) => _jsonToMap(json)).toList();
  }

  /// Removes a specific sync operation after it has been successfully synced.
  Future<void> removeSyncOp(String key) async {
    final box = Hive.box<String>(_syncQueueBox);
    await box.delete(key);
  }

  /// Clears the entire sync queue after a successful full sync.
  Future<void> clearSyncQueue() async {
    final box = Hive.box<String>(_syncQueueBox);
    await box.clear();
  }

  /// Returns the number of pending sync operations.
  int get pendingSyncCount {
    final box = Hive.box<String>(_syncQueueBox);
    return box.length;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Housekeeping ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Clears ALL local caches. Called on sign-out or data reset.
  Future<void> clearAll() async {
    await Future.wait([
      Hive.box<String>(_symptomBox).clear(),
      Hive.box<String>(_lifestyleBox).clear(),
      Hive.box<String>(_correlationBox).clear(),
      Hive.box<String>(_userBox).clear(),
      Hive.box<String>(_syncQueueBox).clear(),
    ]);
  }

  // ── Private JSON helpers ──

  String _mapToJson(Map<String, dynamic> map) {
    // Simple serialization — models already handle their own toJson
    return map.entries
        .map((e) => '"${e.key}":${_encodeValue(e.value)}')
        .join(',');
  }

  String _encodeValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value is Map) return '{${_mapToJson(value as Map<String, dynamic>)}}';
    return '$value';
  }

  Map<String, dynamic> _jsonToMap(String json) {
    // For production, use dart:convert — this is a simplified placeholder.
    // The actual models use their own fromJson which uses dart:convert.
    return {'raw': json};
  }
}
