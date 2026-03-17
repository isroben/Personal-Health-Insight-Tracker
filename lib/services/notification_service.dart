/// ==========================================================================
/// notification_service.dart — Local Notification Service
/// ==========================================================================
/// Handles:
/// - Daily scheduled reminders (configurable time)
/// - Immediate nudge notifications (triggered by high-severity logs)
/// - Delayed nudge notifications (scheduled for later in the day)
/// - Predictive alert notifications (premium — high-risk day warnings)
///
/// Uses flutter_local_notifications for all local scheduling.
/// Firebase Messaging handles server-pushed notifications (separate setup).
///
/// Notification channels (Android):
///   - 'reminders'    → Daily logging reminders (low priority)
///   - 'nudges'       → Health tips and nudges (default priority)
///   - 'alerts'       → High-severity alerts (high priority, vibrates)
/// ==========================================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  // ── Notification IDs ──
  // Fixed IDs allow us to cancel/replace specific notifications reliably.
  static const int _dailyReminderId = 1;
  static const int _nudgeBaseId = 100; // nudges use 100+
  static const int _alertBaseId = 200; // alerts use 200+

  // ══════════════════════════════════════════════════════════════════════════
  // ── Initialisation ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Initialises the notification plugin and timezone data.
  ///
  /// Call once from main.dart before runApp().
  /// Requests notification permissions on iOS/Android 13+.
  Future<void> initialize() async {
    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();

    // ── Android setup ──
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // ── iOS setup ──
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Daily Reminders ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Schedules a repeating daily reminder at the specified local time.
  ///
  /// Cancels any existing daily reminder before scheduling the new one,
  /// so calling this multiple times is safe (idempotent).
  ///
  /// [hour] and [minute] are in local time (0–23, 0–59).
  Future<void> scheduleDailyReminder({
    int hour = 21, // Default: 9 PM
    int minute = 0,
  }) async {
    // Cancel any existing scheduled reminder first
    await _plugin.cancel(_dailyReminderId);

    // Build the next occurrence of the specified time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '🌙 Time to log your health today',
      'Tap to record your symptoms and lifestyle — it takes under 30 seconds.',
      scheduledDate,
      _notificationDetails(channel: _Channel.reminder),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'daily_reminder',
    );
  }

  /// Cancels the scheduled daily reminder.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Immediate Nudges ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Shows an immediate nudge notification (appears right away).
  ///
  /// Used by [LoggingService] when a high-severity entry is logged.
  /// Each nudge gets a unique ID derived from the current timestamp
  /// so multiple nudges don't overwrite each other.
  Future<void> sendImmediateNudge({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = _nudgeBaseId + (DateTime.now().millisecondsSinceEpoch % 100);

    await _plugin.show(
      id,
      title,
      body,
      _notificationDetails(channel: _Channel.nudge),
      payload: payload,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Delayed Nudges ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Schedules a one-time nudge notification after a delay.
  ///
  /// Used for gentle lifestyle reminders (e.g., "move a little today"
  /// scheduled 1 hour after a zero-exercise log).
  Future<void> scheduleDelayedNudge({
    required String title,
    required String body,
    required int delayMinutes,
    String? payload,
  }) async {
    final id = _nudgeBaseId + (DateTime.now().millisecondsSinceEpoch % 99);
    final scheduledTime = tz.TZDateTime.now(tz.local)
        .add(Duration(minutes: delayMinutes));

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      _notificationDetails(channel: _Channel.nudge),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Predictive Alerts (Premium) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Shows a high-priority alert notification when AI predicts a risky day.
  ///
  /// Premium feature — only sent if subscription is active.
  /// Uses the high-priority notification channel (vibrates + sound).
  Future<void> sendPredictiveAlert({
    required String symptomName,
    required double riskScore, // 0.0 – 1.0
  }) async {
    final riskPercent = (riskScore * 100).round();
    final id = _alertBaseId + (DateTime.now().millisecondsSinceEpoch % 100);

    await _plugin.show(
      id,
      '⚠️ $symptomName alert for today',
      'AI predicts a $riskPercent% chance of $symptomName today. '
          'Consider staying hydrated and managing stress.',
      _notificationDetails(channel: _Channel.alert),
      payload: 'predictive_alert:$symptomName',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Housekeeping ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Cancels all pending and shown notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Returns the number of pending scheduled notifications.
  Future<int> pendingNotificationCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Private Helpers ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Builds platform-specific notification details for a given channel.
  NotificationDetails _notificationDetails({required _Channel channel}) {
    final android = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: channel.priority,
      icon: '@mipmap/ic_launcher',
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: android, iOS: ios);
  }

  /// Called when the user taps a notification.
  /// Deep-links into the relevant screen based on the payload.
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // TODO: Use a global navigator key to push to the relevant screen
    // Example routing:
    // if (payload == 'daily_reminder')  → navigate to LoggingScreen
    // if (payload.startsWith('symptom_log:')) → navigate to HomeScreen
    // if (payload.startsWith('predictive_alert:')) → navigate to InsightsScreen
  }
}

/// Internal enum defining notification channels and their properties.
enum _Channel {
  reminder(
    id: 'reminders',
    name: 'Daily Reminders',
    description: 'Daily logging nudges',
    importance: Importance.low,
    priority: Priority.low,
  ),
  nudge(
    id: 'nudges',
    name: 'Health Nudges',
    description: 'Tips and nudges triggered by logged entries',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  alert(
    id: 'alerts',
    name: 'Health Alerts',
    description: 'AI-powered predictive alerts and high-severity warnings',
    importance: Importance.high,
    priority: Priority.high,
  );

  const _Channel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.priority,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;
  final Priority priority;
}
