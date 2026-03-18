import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_entry.dart';

final notificationListProvider = StateNotifierProvider<NotificationListNotifier, List<NotificationEntry>>((ref) {
  return NotificationListNotifier();
});

class NotificationListNotifier extends StateNotifier<List<NotificationEntry>> {
  NotificationListNotifier() : super([]) {
    _init();
  }

  static const String storageKey = 'notifications_history';

  Future<void> _init() async {
    await loadNotifications();
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(storageKey);
    if (data != null) {
      state = data.map((item) => NotificationEntry.fromJson(item)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  /// Static helper to add a notification to history from anywhere (including background).
  static Future<void> saveNotificationStatic({
    required String title,
    required String body,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(storageKey) ?? [];
    
    final newEntry = NotificationEntry(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      payload: payload,
    );

    data.insert(0, newEntry.toJson());
    
    // Limit to last 50
    final limitedData = data.length > 50 ? data.sublist(0, 50) : data;
    await prefs.setStringList(storageKey, limitedData);
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await saveNotificationStatic(title: title, body: body, payload: payload);
    await loadNotifications();
  }

  Future<void> markAsRead(String id) async {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
    _saveToPrefs();
  }

  Future<void> markAllAsRead() async {
    state = [
      for (final n in state) n.copyWith(isRead: true)
    ];
    _saveToPrefs();
  }

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.map((n) => n.toJson()).toList();
    await prefs.setStringList(storageKey, data);
  }
}
