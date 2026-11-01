import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/challenge.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/screens/challenge_detail/challenge_detail_screen.dart';
import 'package:lab03/screens/journey/journey_screen.dart';
import 'package:lab03/screens/journey/weekly_card_page.dart';
import 'package:lab03/screens/note_detail/note_detail_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

/// S11 Hành trình trên cả app (flow P6, T3; chặng hiện tại của F3).
void main() {
  /// 10 ngày có tâm trạng xen kẽ, đủ để vẽ biểu đồ.
  List<Note> monthOfNotes() => <Note>[
    for (var day = 15; day <= 24; day++)
      sampleNote(
        'n$day',
        DateTime(2026, 10, day, 20),
        title: 'Chiến thắng ngày $day',
        mood: day.isEven ? Mood.vui : Mood.binhThuong,
      ),
  ];

  Future<TestServices> openJourney(
    WidgetTester tester, {
    List<Note> notes = const <Note>[],
    Size size = phone360,
  }) async {
    final services = TestServices()..notes.notes.addAll(notes);
    await pumpApp(tester, services: services, size: size);
    await tester.tap(findTab('Hành trình'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyScreen), findsOneWidget);
    return services;
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  for (final size in <Size>[phone360, phone412]) {
    testWidgets('3 tab con ở ${size.width.toInt()} dp không tràn', (
      tester,
    ) async {
      await openJourney(tester, notes: monthOfNotes(), size: size);
      expect(find.text('CHẶNG 1 · DŨNG CẢM'), findsOneWidget);

      await openTab(tester, 'Thống kê');
      expect(find.text('Nốt tuần này'), findsOneWidget);
      expect(find.text('Năng lượng mỗi ngày'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Năng lượng 30 ngày')),
        findsOneWidget,
      );

      await openTab(tester, 'Lịch');
      expect(find.text('Lịch năng lượng'), findsOneWidget);
      expect(find.text('Tháng 10, 2026'), findsOneWidget);
      await tester.tap(find.text('Năm'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Năm 2026 bạn ghi tâm trạng 10 ngày'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('con đường: chạm thẻ hiện tại mở S08', (tester) async {
    final services = TestServices();
    services.challenges.progress[ChallengeTopic.dungCam] =
        const ChallengeProgress(completed: <String>{'dc-1-1'});
    await pumpApp(tester, services: services);
    await tester.tap(findTab('Hành trình'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dũng cảm cấp 1 thẻ 2 · 4 phút'));
    await tester.pumpAndSettle();
    expect(find.byType(ChallengeDetailScreen), findsOneWidget);
  });

  testWidgets('ít dữ liệu: biểu đồ thay bằng lời nhắc', (tester) async {
    await openJourney(
      tester,
      notes: <Note>[sampleNote('a', DateTime(2026, 10, 24))],
    );
    await openTab(tester, 'Thống kê');
    expect(find.text('Ghi thêm vài ngày để thấy xu hướng'), findsOneWidget);
  });

  testWidgets('lịch: chạm một ngày → sheet các nốt → S06', (tester) async {
    await openJourney(tester, notes: monthOfNotes());
    await openTab(tester, 'Lịch');
    await tester.tap(find.bySemanticsLabel('20 tháng 10, Vui'));
    await tester.pumpAndSettle();
    expect(find.text('Thứ Ba, 20/10'), findsOneWidget);
    await tester.tap(find.text('Chiến thắng ngày 20'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteDetailScreen), findsOneWidget);
  });

  testWidgets('Thẻ tuần: Lưu PDF → tiến độ → link đã lưu', (tester) async {
    final services = await openJourney(tester, notes: monthOfNotes());
    await openTab(tester, 'Thống kê');
    await tester.scrollUntilVisible(find.text('Mục tiêu tuần'), 200);
    await tester.tap(find.text('Mục tiêu tuần'));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyCardPage), findsOneWidget);
    expect(find.text('19/10 – 25/10'), findsOneWidget);

    await tester.tap(find.text('Lưu thẻ tuần (PDF)'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu thẻ tuần lên đám mây.'), findsOneWidget);
    expect(find.textContaining('weekly-2026-W43.pdf'), findsOneWidget);
    expect(services.storage.uploaded, hasLength(1));
  });

  testWidgets('P6: 5 ngày Rối liền → dialog gợi ý hỗ trợ, "Để sau" đóng', (
    tester,
  ) async {
    await openJourney(
      tester,
      notes: <Note>[
        for (var day = 20; day <= 24; day++)
          sampleNote('d$day', DateTime(2026, 10, day), mood: Mood.roi),
      ],
    );
    expect(find.text('Mấy hôm nay hơi nặng nề'), findsOneWidget);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(find.text('Mấy hôm nay hơi nặng nề'), findsNothing);
  });
}
