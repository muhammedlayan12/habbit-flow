import 'package:intl/intl.dart';

/// Small collection of date helpers used across the app so date math
/// (streaks, weekly stats, calendar rendering...) is consistent everywhere.
class AppDateUtils {
  AppDateUtils._();

  /// Normalizes a [DateTime] to midnight (no time component), which is how
  /// we key every completion / date comparison in the app.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String storageKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static DateTime fromStorageKey(String key) => DateFormat('yyyy-MM-dd').parse(key);

  static String friendlyDate(DateTime date) =>
      DateFormat('EEEE, MMMM d').format(date);

  static String shortDate(DateTime date) => DateFormat('MMM d').format(date);

  static String weekdayShort(DateTime date) => DateFormat('EEE').format(date);

  static String formatTimeOfDay(int hour, int minute) {
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  /// Returns the Monday of the week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final d = dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static List<DateTime> lastNDays(int n, {DateTime? end}) {
    final endDate = dateOnly(end ?? DateTime.now());
    return List.generate(
      n,
      (i) => endDate.subtract(Duration(days: n - 1 - i)),
    );
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }
}
