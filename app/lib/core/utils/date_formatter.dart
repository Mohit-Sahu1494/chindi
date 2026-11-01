import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('d MMM');

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatShortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime.toLocal());
  }

  static String formatRelativeOrDate(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final difference = now.difference(local);

    if (difference.inDays == 0 && now.day == local.day) {
      return 'Aaj, ${_timeFormat.format(local)}';
    } else if (difference.inDays <= 1 && now.day - local.day == 1) {
      return 'Kal, ${_timeFormat.format(local)}';
    } else {
      return '${_shortDateFormat.format(local)}, ${_timeFormat.format(local)}';
    }
  }
}
