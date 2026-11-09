import 'mood.dart';

/// Nội dung Thẻ tuần (S11b).
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
}
