/// Mốc ngày và tháng theo giờ trên máy.
abstract final class Dates {
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  /// Ngày đầu tháng sau ([DateTime] tự chuyển tháng 13 sang tháng 1 năm sau).
  static DateTime startOfNextMonth(DateTime date) =>
      DateTime(date.year, date.month + 1);

  /// Đầu ngày trước [date]; dùng phép cộng ngày thay vì trừ 24 giờ để đúng cả
  /// khi đổi giờ mùa hè.
  static DateTime startOfYesterday(DateTime date) =>
      DateTime(date.year, date.month, date.day - 1);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
