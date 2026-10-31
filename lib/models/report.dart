import 'mood.dart';

/// Nội dung Thẻ tuần (S11b), cũng là nội dung file PDF tải lên Storage.
class WeeklySummary {
  const WeeklySummary({
    required this.weekStart,
    required this.noteCount,
    required this.daysWithNotes,
    required this.dayMoods,
    required this.wins,
    required this.balance,
    this.energy,
  });

  /// Thứ Hai đầu tuần.
  final DateTime weekStart;
  final int noteCount;

  /// "Mục tiêu tuần 5/7".
  final int daysWithNotes;

  /// Tâm trạng 7 ngày, chỉ số 0 = Thứ Hai; `null` là chưa ghi.
  final List<Mood?> dayMoods;

  /// Tối đa 3 chiến thắng mới nhất trong tuần.
  final List<String> wins;

  /// Số nốt theo nhãn "Cân bằng 5 điều tốt" (theo thứ tự hiển thị).
  final Map<String, int> balance;

  /// Năng lượng trung bình 1–5; `null` khi không có tâm trạng nào.
  final double? energy;

  DateTime get weekEnd =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

  /// Số tuần ISO 8601, dùng trong tên file (`weekly-2026-W43.pdf`).
  String get isoWeek {
    final thursday = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 3,
    );
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart = DateTime(
      firstThursday.year,
      1,
      4 - (firstThursday.weekday - 1),
    );
    final week = thursday.difference(firstWeekStart).inDays ~/ 7 + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  String get fileName => 'weekly-$isoWeek.pdf';
}

/// Một bước của lần tải file lên Storage.
class UploadProgress {
  const UploadProgress(this.fraction, {this.url});

  /// 0–1.
  final double fraction;

  /// Có khi đã tải xong: link tải về.
  final String? url;
}
