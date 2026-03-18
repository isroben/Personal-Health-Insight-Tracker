/// ==========================================================================
/// notification_service.dart — Local & Remote Notification Service
/// ==========================================================================
/// Handles:
/// - Daily scheduled reminders (configurable time)
/// - Immediate nudge notifications (triggered by high-severity logs)
/// - Delayed nudge notifications (scheduled for later in the day)
/// - Predictive alert notifications (premium — high-risk day warnings)
/// - Remote Firebase Messaging (FCM) integration
///
/// Uses flutter_local_notifications for local and firebase_messaging for remote.
/// ==========================================================================

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final FirebaseMessaging _fcm;
  final Ref? _ref;

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    FirebaseMessaging? fcm,
    Ref? ref,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _fcm = fcm ?? FirebaseMessaging.instance,
        _ref = ref;

  // ── Notification IDs ──
  static const int _dailyReminderId = 1;
  static const int _nudgeBaseId = 100;
  static const int _alertBaseId = 200;

  // ══════════════════════════════════════════════════════════════════════════
  // ── Initialisation ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // 1. Setup Local Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // 2. Setup Firebase Messaging
    await _setupFCM();
  }

  Future<void> _setupFCM() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleRemoteMessage(message);
      });

      // Terminated state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessage(initialMessage);
      }

      // Background but opened via notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleRemoteMessage(message);
      });
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      // Save to history using STATIC helper for thread-safe access
      NotificationListNotifier.saveNotificationStatic(
        title: notification.title ?? 'System Alert',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );

      // Trigger state refresh if UI is active
      if (_ref != null) {
        _ref!.read(notificationListProvider.notifier).loadNotifications();
      }

      if (Platform.isAndroid) {
        _plugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          _notificationDetails(channel: _Channel.alert),
          payload: message.data.toString(),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Daily Reminders ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> scheduleDailyReminder({
    int hour = 21,
    int minute = 0,
  }) async {
    await _plugin.cancel(_dailyReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const title = '🌙 Time to log your health today';
    const body = 'Tap to record your symptoms and lifestyle — it takes under 30 seconds.';

    await _plugin.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      scheduledDate,
      _notificationDetails(channel: _Channel.reminder),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Immediate Nudges ──
  // ══════════════════════════════════════════════════════════════════════════

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

    _addToHistory(title: title, body: body, payload: payload);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Delayed Nudges ──
  // ══════════════════════════════════════════════════════════════════════════

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
    
    _addToHistory(title: title, body: body, payload: payload);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Predictive Alerts (Premium) ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> sendPredictiveAlert({
    required String symptomName,
    required double riskScore,
  }) async {
    final riskPercent = (riskScore * 100).round();
    final id = _alertBaseId + (DateTime.now().millisecondsSinceEpoch % 100);
    final title = '⚠️ $symptomName alert for today';
    final body = 'AI predicts a $riskPercent% chance of $symptomName today. '
          'Consider staying hydrated and managing stress.';

    await _plugin.show(
      id,
      title,
      body,
      _notificationDetails(channel: _Channel.alert),
      payload: 'predictive_alert:$symptomName',
    );

    _addToHistory(title: title, body: body, payload: 'predictive_alert:$symptomName');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Housekeeping ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  void _addToHistory({required String title, required String body, String? payload}) {
    NotificationListNotifier.saveNotificationStatic(
      title: title,
      body: body,
      payload: payload,
    );
    
    if (_ref != null) {
      _ref!.read(notificationListProvider.notifier).loadNotifications();
    }
  }

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

  void _onNotificationTapped(NotificationResponse response) {
    // History is already updated.
  }
}

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
