import '../models/note.dart';
import '../models/streak.dart';
import 'dates.dart';
import 'journey_stats.dart';

/// Các phép tính thuần cho chuỗi ngày, để test không cần Firestore và để
/// ViewModel không tự đếm ngày.
abstract final class StreakStats {
  /// Tổng hợp chuỗi ngày từ [notes] tính tới [now].
  ///
  /// Dùng lại [JourneyStats.streak] và [JourneyStats.longestStreak] để S02,
  /// S04 và S11 luôn ra cùng một con số.
  static StreakSummary summary(List<Note> notes, DateTime now) {
    final today = Dates.startOfDay(now);
    final activeDays = notes
        .map((note) => Dates.startOfDay(note.createdAt))
        .toSet();
    final todayCount = notes
        .where((note) => Dates.sameDay(note.createdAt, now))
        .length;

    final current = JourneyStats.streak(notes, now);
    final record = JourneyStats.longestStreak(notes);
    final next = StreakMilestones.next(current);
    final previous = StreakMilestones.previous(current);
    final span = next == null ? 0 : next - (previous ?? 0);

    return StreakSummary(
      current: current,
      record: record < current ? current : record,
      todayCount: todayCount,
      days: <StreakDay>[
        for (var i = 6; i >= 0; i--)
          () {
            final day = DateTime(today.year, today.month, today.day - i);
            return StreakDay(
              day: day,
              hasNote: activeDays.contains(day),
              isToday: i == 0,
            );
          }(),
      ],
      nextMilestone: next,
      previousMilestone: previous,
      daysToNext: next == null ? null : next - current,
      progressToNext: span == 0
          ? 1
          : ((current - (previous ?? 0)) / span).clamp(0.0, 1.0).toDouble(),
    );
  }
}
