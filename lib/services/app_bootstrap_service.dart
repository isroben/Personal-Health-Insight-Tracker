/// ==========================================================================
/// app_bootstrap_service.dart — App-wide Logic Orchestration
/// ==========================================================================
/// Handles system events and background logic:
/// - Initializing services on launch
/// - Syncing offline data when connection restored
/// - Checking periodic nudge triggers
/// ==========================================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logging_service.dart';
import 'nudge_service.dart';
import 'notification_service.dart';
import '../providers/logging_provider.dart';

final appBootstrapServiceProvider = Provider<AppBootstrapService>((ref) {
  return AppBootstrapService(
    logging: ref.read(loggingServiceProvider),
    nudge: ref.read(nudgeServiceProvider),
    notifications: ref.read(notificationServiceProvider),
  );
});

class AppBootstrapService {
  final LoggingService _logging;
  final NudgeService _nudge;
  final NotificationService _notifications;

  AppBootstrapService({
    required LoggingService logging,
    required NudgeService nudge,
    required NotificationService notifications,
  })  : _logging = logging,
        _nudge = nudge,
        _notifications = notifications;

  /// Runs the initial boot sequence for the app.
  Future<void> onAppLaunch() async {
    // 1. Init notifications
    await _notifications.initialize();

    // 2. Schedule default reminder (if not already set)
    await _notifications.scheduleDailyReminder(hour: 20, minute: 30); // 8:30 PM

    // 3. Check for environmental triggers immediately on launch
    await _nudge.checkEnvironmentalNudges();
  }

  /// Called periodically or when app resumes from background.
  Future<void> refreshSystemContext(String userId) async {
    // Check environmental risk
    await _nudge.checkEnvironmentalNudges();

    // Note: Pattern nudges previously used local cache. 
    // For online-only, we skip or fetch from API if needed.
  }
}
