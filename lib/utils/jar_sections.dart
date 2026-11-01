import '../models/note.dart';
import 'dates.dart';
import 'journey_stats.dart';

/// Một nhóm tờ nốt trên S05: "Hôm nay", "Hôm qua", "Tuần này", "Tuần trước"
/// rồi từng tháng.
class JarSection {
  const JarSection({
    required this.title,
    required this.notes,
    this.showsDay = true,
  });

  final String title;

  /// Mới nhất trước.
  final List<Note> notes;

  /// Nhóm gồm nhiều ngày: tờ nốt cần ghi ngày. "Hôm nay" / "Hôm qua" thì
  /// không, để bớt chữ lặp.
  final bool showsDay;
}

abstract final class JarSections {
  /// Gom [notes] (mới nhất trước) theo mốc thời gian so với [now]; bỏ nhóm
  /// rỗng.
  static List<JarSection> group(List<Note> notes, DateTime now) {
    final today = Dates.startOfDay(now);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final thisWeek = JourneyStats.weekStart(now);
    final lastWeek = DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7);

    final todayNotes = <Note>[];
    final yesterdayNotes = <Note>[];
    final weekNotes = <Note>[];
    final lastWeekNotes = <Note>[];
    final months = <DateTime, List<Note>>{};

    for (final note in notes) {
      final day = Dates.startOfDay(note.createdAt);
      if (!day.isBefore(today)) {
        todayNotes.add(note);
      } else if (day == yesterday) {
        yesterdayNotes.add(note);
      } else if (!day.isBefore(thisWeek)) {
        weekNotes.add(note);
      } else if (!day.isBefore(lastWeek)) {
        lastWeekNotes.add(note);
      } else {
        months.putIfAbsent(Dates.startOfMonth(day), () => <Note>[]).add(note);
      }
    }

    return <JarSection>[
      if (todayNotes.isNotEmpty)
        JarSection(title: 'Hôm nay', notes: todayNotes, showsDay: false),
      if (yesterdayNotes.isNotEmpty)
        JarSection(title: 'Hôm qua', notes: yesterdayNotes, showsDay: false),
      if (weekNotes.isNotEmpty) JarSection(title: 'Tuần này', notes: weekNotes),
      if (lastWeekNotes.isNotEmpty)
        JarSection(title: 'Tuần trước', notes: lastWeekNotes),
      for (final MapEntry(key: month, value: list) in months.entries)
        JarSection(
          title: month.year == now.year
              ? 'Tháng ${month.month}'
              : 'Tháng ${month.month}, ${month.year}',
          notes: list,
        ),
    ];
  }
}
