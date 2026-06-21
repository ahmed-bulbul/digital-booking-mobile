import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt.toLocal());
  static String formatDate(DateTime dt) => DateFormat('EEE, dd MMM yyyy').format(dt.toLocal());
  static String formatShortDate(DateTime dt) => DateFormat('dd MMM').format(dt.toLocal());
  static String formatInputDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static DateTime tomorrowBst() {
    final bstNow = DateTime.now().toUtc().add(const Duration(hours: 6));
    return DateTime(bstNow.year, bstNow.month, bstNow.day + 1);
  }
}
