/// ==========================================================================
/// local_cache_service.dart — Simple Local Persistence (SharedPreferences)
/// ==========================================================================
/// Provides a lightweight caching layer for:
///   1. Storing small, JSON-encodable health data backups.
///   2. Persisting app configuration (onboarding status, theme preference).
///   3. Offline-first UI support (caching the last 50 logs).
/// ==========================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  // ── Keys ──
  static const String _onboardingKey = 'onboarding_completed';
  static const String _healthHistoryKey = 'cached_health_history';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // ══════════════════════════════════════════════════════════════════════════
  // ── 1. App Configuration (Onboarding) ──
  // ══════════════════════════════════════════════════════════════════════════

  bool isOnboardingCompleted() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingKey, completed);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 2. Data Caching (Generic JSON) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Saves a list of maps (JSON) to local storage.
  Future<void> saveCache(String key, List<Map<String, dynamic>> data) async {
    final String jsonString = jsonEncode(data);
    await _prefs.setString(key, jsonString);
  }

  /// Reads a list of maps (JSON) from local storage.
  List<Map<String, dynamic>> getCache(String key) {
    final String? jsonString = _prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => item as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Deletes a specific cache entry.
  Future<void> deleteCache(String key) async {
    await _prefs.remove(key);
  }

  /// Clears all local application data.
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
