import 'package:intl/intl.dart';

/// Date and time formatting utility
class AppDateFormatter {
  static final DateFormat _timeFormat = DateFormat('h:mm:ss a');
  static final DateFormat _shortTimeFormat = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');

  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatShortTime(DateTime dt) => _shortTimeFormat.format(dt);
  static String formatDate(DateTime dt) => _dateFormat.format(dt);
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);

  static String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 5) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return formatDate(dt);
    }
  }
}
