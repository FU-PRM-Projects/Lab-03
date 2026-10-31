import '../models/challenge.dart';
import '../models/mood.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import 'dates.dart';

/// Năng lượng của một ngày trên biểu đồ S11b.
class EnergyPoint {
  const EnergyPoint({required this.day, required this.count, this.energy});

  final DateTime day;

  /// Trung bình thang 1–5 của các nốt có tâm trạng; `null` khi không có.
  final double? energy;

  /// Số nốt trong ngày (tooltip).
  final int count;
}

/// "Cân bằng 5 điều tốt" (S11b).
enum GoodThing {
  chienThang('Chiến thắng'),
  nhatKy('Nhật ký'),
  tuChu('Tự chủ'),
  vanDong('Vận động'),
  nguoiLa('Người lạ');

  const GoodThing(this.label);

  final String label;

  static GoodThing? of(Note note) => switch (note.type) {
    NoteType.chienThang => GoodThing.chienThang,
    NoteType.nhatKy => GoodThing.nhatKy,
    NoteType.tuChu => GoodThing.tuChu,
    NoteType.thuThach =>
      note.challenge?.subtype == ChallengeTopic.vanDong.subtype
          ? GoodThing.vanDong
          : GoodThing.nguoiLa,
  };
}

/// Các phép tính thuần cho S11 (Thống kê, Lịch, Thẻ tuần), để test không cần
/// Firestore. Mọi ngày tính theo giờ trên máy; tuần bắt đầu từ Thứ Hai.
abstract final class JourneyStats {
  static DateTime weekStart(DateTime date) {
    final day = Dates.startOfDay(date);
    return DateTime(day.year, day.month, day.day - (day.weekday - 1));
  }

  static List<Note> between(List<Note> notes, DateTime start, DateTime end) =>
      notes
          .where(
            (n) => !n.createdAt.isBefore(start) && n.createdAt.isBefore(end),
          )
          .toList();

  /// Tâm trạng của mỗi ngày: tâm trạng của nốt có tâm trạng ghi muộn nhất.
  static Map<DateTime, Mood> dayMoods(List<Note> notes) {
    final latest = <DateTime, Note>{};
    for (final note in notes) {
      if (note.mood == null) continue;
      final day = Dates.startOfDay(note.createdAt);
      final current = latest[day];
      if (current == null || note.createdAt.isAfter(current.createdAt)) {
        latest[day] = note;
      }
    }
    return latest.map((day, note) => MapEntry(day, note.mood!));
  }

  /// [days] ngày gần nhất, cũ trước, kết thúc ở hôm nay.
  static List<EnergyPoint> energy(List<Note> notes, DateTime now, int days) {
    final today = Dates.startOfDay(now);
    return <EnergyPoint>[
      for (var i = days - 1; i >= 0; i--)
        () {
          final day = DateTime(today.year, today.month, today.day - i);
          final inDay = notes
              .where((n) => Dates.sameDay(n.createdAt, day))
              .toList();
          final scores = inDay.map((n) => n.mood?.score).nonNulls.toList();
          return EnergyPoint(
            day: day,
            count: inDay.length,
            energy: scores.isEmpty
                ? null
                : scores.reduce((a, b) => a + b) / scores.length,
          );
        }(),
    ];
  }

  static double? average(List<EnergyPoint> points) {
    final values = points.map((p) => p.energy).nonNulls.toList();
    return values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
  }

  /// Chuỗi ngày có ghi nốt tính tới hôm nay. Hôm nay chưa ghi thì tính tới
  /// hôm qua: chưa hết ngày thì chưa đứt chuỗi (DESIGN.md: không phạt).
  static int streak(List<Note> notes, DateTime now) {
    final days = notes.map((n) => Dates.startOfDay(n.createdAt)).toSet();
    var day = Dates.startOfDay(now);
    if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (days.contains(day)) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// Chuỗi dài nhất trong dữ liệu đã tải.
  static int longestStreak(List<Note> notes) {
    final days =
        notes.map((n) => Dates.startOfDay(n.createdAt)).toSet().toList()
          ..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      final next = previous == null
          ? null
          : DateTime(previous.year, previous.month, previous.day + 1);
      run = next == day ? run + 1 : 1;
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }

  /// Số ngày có ghi nốt trong tuần chứa [now] ("Mục tiêu tuần 5/7").
  static int daysWithNotesThisWeek(List<Note> notes, DateTime now) {
    final start = weekStart(now);
    final end = DateTime(start.year, start.month, start.day + 7);
    return between(
      notes,
      start,
      end,
    ).map((n) => Dates.startOfDay(n.createdAt)).toSet().length;
  }

  static Map<GoodThing, int> balance(List<Note> notes) => <GoodThing, int>{
    for (final thing in GoodThing.values)
      thing: notes.where((n) => GoodThing.of(n) == thing).length,
  };

  /// Số nốt theo thứ trong tuần, chỉ số 0 = Thứ Hai.
  static List<int> byWeekday(List<Note> notes) {
    final counts = List<int>.filled(7, 0);
    for (final note in notes) {
      counts[note.createdAt.weekday - 1]++;
    }
    return counts;
  }

  /// Số ngày Mệt / Rối liền nhau tính lùi từ ngày gần nhất có tâm trạng
  /// (hôm nay hoặc hôm qua). Ngày không có tâm trạng làm đứt chuỗi.
  static int lowMoodRun(List<Note> notes, DateTime now) {
    final moods = dayMoods(notes);
    var day = Dates.startOfDay(now);
    if (!moods.containsKey(day)) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (moods[day]?.isLow ?? false) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// Các ngày của lưới lịch tháng [month]: từ Thứ Hai của tuần chứa ngày 1
  /// tới Chủ Nhật của tuần chứa ngày cuối tháng.
  static List<DateTime> monthGrid(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final start = weekStart(first);
    final end = DateTime(last.year, last.month, last.day + (7 - last.weekday));
    return <DateTime>[
      for (
        var d = start;
        !d.isAfter(end);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        d,
    ];
  }
}
