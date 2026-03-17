/// ==========================================================================
/// date_helpers.dart — Date formatting utilities
/// ==========================================================================
import 'package:intl/intl.dart';

class DateHelpers {
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d').format(date); // e.g. "Oct 12"
  }

  static String formatLongDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date); // e.g. "October 12, 2023"
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date); // e.g. "4:30 PM"
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
