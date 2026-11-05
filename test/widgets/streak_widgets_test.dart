import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/streak.dart';
import 'package:lab03/theme/app_theme.dart';
import 'package:lab03/widgets/streak_card.dart';
import 'package:lab03/widgets/streak_celebration.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

/// Thẻ chuỗi ở S02 và lời chúc ở S04: nội dung theo số ngày và mốc.
void main() {
  final now = DateTime(2026, 10, 24);

  StreakSummary summary({
    required int current,
    int record = 0,
    int todayCount = 0,
    int? nextMilestone,
    int? daysToNext,
    double progress = 0,
  }) {
    return StreakSummary(
      current: current,
      record: record,
      todayCount: todayCount,
      days: <StreakDay>[
        for (var i = 6; i >= 0; i--)
          StreakDay(
            day: now.subtract(Duration(days: i)),
            hasNote: i < current,
            isToday: i == 0,
          ),
      ],
      nextMilestone: nextMilestone,
      daysToNext: daysToNext,
      progressToNext: progress,
    );
  }

  Future<void> pumpWidget(WidgetTester tester, Widget child) async {
    setScreenSize(tester, phone360);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('thẻ S02: chuỗi, kỷ lục, câu nhắc và mốc kế tiếp', (
    tester,
  ) async {
    var taps = 0;
    await pumpWidget(
      tester,
      StreakCard(
        streak: summary(
          current: 5,
          record: 7,
          todayCount: 1,
          nextMilestone: 7,
          daysToNext: 2,
          progress: 0.5,
        ),
        onTap: () => taps++,
      ),
    );

    expect(find.text('Chuỗi 5 ngày'), findsOneWidget);
    expect(find.text('Kỷ lục 7'), findsOneWidget);
    expect(find.text('Mai ghi tiếp để nối chuỗi'), findsOneWidget);
    expect(find.text('Còn 2 ngày tới mốc 7 ngày'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('Chuỗi 5 ngày.*Kỷ lục 7 ngày.*Còn 2 ngày tới mốc 7 ngày'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(StreakCard));
    expect(taps, 1);
  });

  testWidgets('thẻ S02: chưa có nốt thì mời mở chuỗi', (tester) async {
    await pumpWidget(
      tester,
      StreakCard(streak: summary(current: 0, nextMilestone: 3, daysToNext: 3)),
    );

    expect(find.text('Bắt đầu chuỗi ngày'), findsOneWidget);
    expect(find.text('Ghi nốt để mở chuỗi'), findsOneWidget);
    expect(find.text('Còn 3 ngày tới mốc 3 ngày'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('S04 chúc mừng chuỗi mới và biến thể chạm mốc', (tester) async {
    await pumpWidget(
      tester,
      StreakCelebration(streak: summary(current: 1, todayCount: 1)),
    );
    expect(find.text('Chuỗi đã bắt đầu!'), findsOneWidget);
    expect(find.text('Ngày thứ 2 đang chờ bạn.'), findsOneWidget);

    await pumpWidget(
      tester,
      StreakCelebration(streak: summary(current: 5, todayCount: 1)),
    );
    expect(find.text('Chuỗi 5 ngày!'), findsOneWidget);
    expect(find.text('Hôm nay đã nối thêm một ngày.'), findsOneWidget);

    await pumpWidget(
      tester,
      StreakCelebration(streak: summary(current: 3, todayCount: 1)),
    );
    expect(find.text('Mốc 3 ngày!'), findsOneWidget);
    expect(
      find.text('Chuỗi 3 ngày liền có nốt. Tụi Nốt giữ chỗ cho ngày mai.'),
      findsOneWidget,
    );
  });
}
