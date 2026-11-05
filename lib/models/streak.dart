/// Một ngày trong 7 ngày gần nhất của [StreakSummary], để vẽ dải ngày.
class StreakDay {
  const StreakDay({
    required this.day,
    required this.hasNote,
    required this.isToday,
  });

  /// Ngày (đã đưa về 0h theo giờ máy).
  final DateTime day;

  /// Ngày này có ít nhất một nốt.
  final bool hasNote;

  /// Ngày hôm nay, để vẽ vòng nhấn.
  final bool isToday;
}

/// Chuỗi ngày ghi nốt của người dùng.
///
/// Chuỗi tính theo ngày có ít nhất một nốt — mọi loại nốt đều tính (chiến
/// thắng, nhật ký, tự chủ, thử thách). Hôm nay chưa ghi thì chuỗi vẫn còn
/// tính tới hôm qua; chưa hết ngày thì chưa đứt (không phạt người dùng).
class StreakSummary {
  const StreakSummary({
    required this.current,
    required this.record,
    required this.todayCount,
    required this.days,
    required this.progressToNext,
    this.nextMilestone,
    this.previousMilestone,
    this.daysToNext,
  });

  /// Số ngày liền nhau có nốt, tính tới hôm nay hoặc hôm qua.
  final int current;

  /// Chuỗi dài nhất trong dữ liệu đã tải.
  final int record;

  /// Số nốt đã ghi trong hôm nay.
  final int todayCount;

  /// 7 ngày gần nhất, cũ nhất trước, kết thúc ở hôm nay.
  final List<StreakDay> days;

  /// Mốc kế tiếp cần chạm; `null` khi đã qua mốc cuối.
  final int? nextMilestone;

  /// Mốc gần nhất đã qua, dùng để tính tiến độ.
  final int? previousMilestone;

  /// Còn bao nhiêu ngày nữa tới [nextMilestone].
  final int? daysToNext;

  /// Tiến độ 0–1 từ [previousMilestone] tới [nextMilestone].
  final double progressToNext;

  /// Hôm nay đã có nốt: chuỗi đã được nối thêm.
  bool get activeToday => todayCount > 0;

  /// Chuỗi vừa chạm một mốc trong hôm nay.
  bool get isMilestone => activeToday && StreakMilestones.reached(current);

  /// Đã từng có chuỗi (dù hôm nay chưa ghi).
  bool get started => current > 0;
}

/// Các mốc của chuỗi ngày. Mốc nhỏ để người mới thấy tiến bộ sớm, sau đó
/// giãn ra để không phải chúc mừng quá thường xuyên.
abstract final class StreakMilestones {
  static const List<int> days = <int>[3, 7, 14, 30, 60, 100, 365];

  /// Mốc đầu tiên lớn hơn [current]; `null` khi đã qua mốc cuối.
  static int? next(int current) {
    for (final milestone in days) {
      if (milestone > current) return milestone;
    }
    return null;
  }

  /// Mốc lớn nhất đã qua (nhỏ hơn [current]); `null` khi chưa tới mốc đầu.
  static int? previous(int current) {
    int? result;
    for (final milestone in days) {
      if (milestone >= current) break;
      result = milestone;
    }
    return result;
  }

  /// [current] đúng bằng một mốc.
  static bool reached(int current) => days.contains(current);
}
