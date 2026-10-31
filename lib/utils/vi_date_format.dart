/// Định dạng ngày tiếng Việt theo Lab 2 ("Thứ Bảy, 24/10", giờ 24 giờ).
abstract final class ViDateFormat {
  static const List<String> _weekdays = <String>[
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// "Thứ Bảy, 24/10": tiêu đề S02.
  static String dayHeader(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${shortDate(date)}';

  /// "24/10".
  static String shortDate(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}';

  /// "Hôm nay", "Hôm qua" hoặc "24/10" so với [now]: nhãn ngày trên tờ nốt.
  static String relativeDay(DateTime date, DateTime now) {
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Hôm nay';
    if (day == DateTime(now.year, now.month, now.day - 1)) return 'Hôm qua';
    return shortDate(date);
  }

  /// "21:30".
  static String time(DateTime date) =>
      '${_two(date.hour)}:${_two(date.minute)}';

  /// "24 tháng 10": nhãn đọc cho trình đọc màn hình.
  static String spoken(DateTime date) => '${date.day} tháng ${date.month}';
}
