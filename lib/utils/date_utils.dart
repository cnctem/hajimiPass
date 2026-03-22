abstract final class DateFormatUtils {
  static String format(int? time) {
    if (time == null || time == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return '${date.year}-${_two(date.month)}-${_two(date.day)} '
        '${_two(date.hour)}:${_two(date.minute)}:${_two(date.second)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
