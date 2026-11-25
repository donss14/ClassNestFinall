/// Day names and time formatting. Times are minutes since midnight.
class TimeUtils {
  TimeUtils._();

  static const List<String> dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> dayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// [day] is 1 (Monday) to 7 (Sunday).
  static String dayName(int day) => dayNames[day - 1];

  static String formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  static String formatRange(int start, int end) =>
      '${formatMinutes(start)} - ${formatMinutes(end)}';
}
