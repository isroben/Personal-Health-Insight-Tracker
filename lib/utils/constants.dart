/// ==========================================================================
/// constants.dart — App-wide Constants & Config
/// ==========================================================================

class AppConstants {
  // SharedPreferences keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyDailyReminderTime = 'daily_reminder_time';

  // UI Constants
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 16.0;

  // Limits
  static const int maxSymptomSeverity = 10;
  static const int maxStressLevel = 10;
  static const double maxSleepHours = 24.0;
}
