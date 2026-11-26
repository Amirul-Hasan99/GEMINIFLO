
class DateFormatter {
  DateFormatter._();

  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String formatFull(DateTime date) {
    final dayName = _days[date.weekday - 1];
    final monthName = _months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  static String formatShort(DateTime date) {
    final monthName = _months[date.month - 1].substring(0, 3);
    return '${date.day} $monthName ${date.year}';
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} WIB';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatShort(dateTime)}, ${formatTime(dateTime)}';
  }

  static String formatDeadline(DateTime dateTime) {
    final monthName = _months[dateTime.month - 1].substring(0, 3);
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} $monthName ${dateTime.year}, $hours:$minutes';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
