import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/streak.dart';
import 'package:lab03/utils/streak_stats.dart';

import '../support/fakes.dart';

void main() {
  // Thứ Bảy 24/10/2026.
  final now = DateTime(2026, 10, 24, 21, 30);

  test('chuỗi, kỷ lục, 7 ngày gần nhất và mốc kế tiếp', () {
    final notes = <DateTime>[
      DateTime(2026, 10, 24, 8),
      DateTime(2026, 10, 23, 20),
      DateTime(2026, 10, 22, 7),
      DateTime(2026, 10, 20, 19),
    ].indexed.map((e) => sampleNote('n${e.$1}', e.$2)).toList();

    final streak = StreakStats.summary(notes, now);

    expect(streak.current, 3);
    expect(streak.record, 3);
    expect(streak.todayCount, 1);
    expect(streak.activeToday, isTrue);
    expect(streak.nextMilestone, 7);
    expect(streak.previousMilestone, isNull);
    expect(streak.daysToNext, 4);
    expect(streak.days, hasLength(7));
    expect(streak.days.last.isToday, isTrue);
    expect(streak.days.last.hasNote, isTrue);
    // 23, 22 có nốt; 21 trống; 20 có nốt.
    expect(streak.days.map((day) => day.hasNote), <bool>[
      false, // 18
      false, // 19
      true, // 20
      false, // 21
      true, // 22
      true, // 23
      true, // 24
    ]);
  });

  test('hôm nay chưa ghi vẫn giữ chuỗi nhưng chuỗi chưa nối hôm nay', () {
    final notes = <DateTime>[
      DateTime(2026, 10, 23, 20),
      DateTime(2026, 10, 22, 7),
    ].indexed.map((e) => sampleNote('n${e.$1}', e.$2)).toList();

    final streak = StreakStats.summary(notes, now);

    expect(streak.current, 2);
    expect(streak.todayCount, 0);
    expect(streak.activeToday, isFalse);
    expect(streak.days.last.hasNote, isFalse);
  });

  test('tiến độ tới mốc tính từ mốc đã qua gần nhất', () {
    final notes = <DateTime>[
      for (var day = 20; day <= 24; day++) DateTime(2026, 10, day, 8),
    ].indexed.map((e) => sampleNote('n${e.$1}', e.$2)).toList();

    final streak = StreakStats.summary(notes, now);

    expect(streak.current, 5);
    expect(streak.nextMilestone, 7);
    expect(streak.previousMilestone, 3);
    expect(streak.progressToNext, closeTo(0.5, 1e-9));
  });

  test('chưa có nốt: chuỗi 0, mốc đầu là 3 ngày', () {
    final streak = StreakStats.summary(const <Never>[], now);

    expect(streak.current, 0);
    expect(streak.record, 0);
    expect(streak.started, isFalse);
    expect(streak.nextMilestone, 3);
    expect(streak.daysToNext, 3);
    expect(streak.progressToNext, 0);
    expect(streak.isMilestone, isFalse);
  });

  test('chạm mốc 3 ngày: isMilestone bật', () {
    final notes = <DateTime>[
      for (var day = 22; day <= 24; day++) DateTime(2026, 10, day, 8),
    ].indexed.map((e) => sampleNote('n${e.$1}', e.$2)).toList();

    final streak = StreakStats.summary(notes, now);

    expect(streak.current, 3);
    expect(streak.isMilestone, isTrue);
    expect(StreakMilestones.reached(3), isTrue);
    expect(StreakMilestones.next(3), 7);
    expect(StreakMilestones.previous(7), 3);
  });
}
