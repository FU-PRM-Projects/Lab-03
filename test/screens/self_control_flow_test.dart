import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/models/self_control.dart';
import 'package:lab03/screens/breathing/breathing_screen.dart';
import 'package:lab03/screens/note_saved/note_saved_screen.dart';
import 'package:lab03/screens/self_control/self_control_screen.dart';
import 'package:lab03/screens/today/today_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

/// Flow F2 Tự chủ trên cả app: S02 → S09 → S04, nhánh S10, nhánh phục hồi.
void main() {
  Future<void> openSelfControl(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Dừng lại'));
    await tester.pumpAndSettle();
    expect(find.byType(SelfControlScreen), findsOneWidget);
  }

  for (final size in <Size>[phone360, phone412]) {
    testWidgets('dừng được ngay ở ${size.width.toInt()} dp: 2 chạm tới S04', (
      tester,
    ) async {
      final services = await pumpApp(tester, size: size);
      await openSelfControl(tester);
      expect(find.text('lần tự chủ tháng này'), findsOneWidget);
      expect(find.text('Lướt mạng xã hội'), findsOneWidget);
      expect(services.screenGuard.secure, isTrue);

      await tester.tap(find.text('Mình vừa dừng lại'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteSavedScreen), findsOneWidget);
      expect(services.notes.notes.single.type, NoteType.tuChu);
      expect(services.screenGuard.secure, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('theo dõi 1 thói quen: ghi luôn kèm tên thói quen', (
    tester,
  ) async {
    final services = TestServices();
    services.selfControl.habits = const HabitList(
      selected: <String>{'Video ngắn'},
    );
    await pumpApp(tester, services: services);
    await openSelfControl(tester);
    await tester.tap(find.text('Mình vừa dừng lại'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteSavedScreen), findsOneWidget);
    expect(services.notes.notes.single.title, 'Dừng Video ngắn lúc 21:30');
  });

  testWidgets('theo dõi nhiều thói quen: "Bạn vừa dừng gì?" rồi ghi', (
    tester,
  ) async {
    final services = TestServices();
    services.selfControl.habits = const HabitList(
      selected: <String>{'Lướt mạng xã hội', 'Video ngắn'},
    );
    await pumpApp(tester, services: services);
    await openSelfControl(tester);
    await tester.tap(find.text('Mình vừa dừng lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn vừa dừng gì?'), findsOneWidget);
    expect(services.notes.notes, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Video ngắn'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NoteSavedScreen), findsOneWidget);
    expect(services.notes.notes.single.title, 'Dừng Video ngắn lúc 21:30');
  });

  testWidgets('khó dừng: S10 thở → Cơn sóng đã hạ → Ghi vào hũ → S04', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await openSelfControl(tester);
    await tester.tap(find.text('Khó dừng? Thở 90 giây'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BreathingScreen), findsOneWidget);
    expect(find.text('Hít vào…'), findsOneWidget);
    expect(find.text('Còn 1:30'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Thở ra…'), findsOneWidget);
    expect(services.screenGuard.keepScreenOn, isTrue);

    await tester.tap(find.text('Cơn sóng đã hạ'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã vượt qua!'), findsOneWidget);
    await tester.tap(find.text('Đi bộ 5 phút'));
    await tester.pump();
    await tester.tap(find.text('Ghi vào hũ'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteSavedScreen), findsOneWidget);
    expect(services.notes.notes.single.title, 'Thở 90 giây rồi đi bộ 5 phút');
    expect(services.screenGuard.keepScreenOn, isFalse);
  });

  testWidgets('đang khoá: thói quen bị che, Mở khoá rồi mới thấy', (
    tester,
  ) async {
    final services = TestServices();
    services.selfControl.settings = const UserSettings(lockSelfControl: true);
    services.localAuth.result = false;
    await pumpApp(tester, services: services);
    await openSelfControl(tester);

    expect(find.text('Lướt mạng xã hội'), findsNothing);
    await tester.ensureVisible(find.text('Mở khoá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở khoá'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa mở được phần này.'), findsOneWidget);
    expect(find.text('Lướt mạng xã hội'), findsNothing);

    services.localAuth.result = true;
    await tester.ensureVisible(find.text('Mở khoá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở khoá'));
    await tester.pumpAndSettle();
    expect(find.text('Lướt mạng xã hội'), findsOneWidget);
  });

  testWidgets('đã lỡ lướt: sheet → "Nhận ra cũng là bắt đầu tự chủ"', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await openSelfControl(tester);
    await tester.tap(find.text('Lỡ lướt quá đà?'));
    await tester.pumpAndSettle();
    expect(find.text('Lúc đó mình đang thấy gì?'), findsOneWidget);

    await tester.tap(find.text('Căng thẳng'));
    await tester.pump();
    await tester.tap(find.text('Ghi lại'));
    await tester.pumpAndSettle();
    expect(find.text('Nhận ra cũng là bắt đầu tự chủ.'), findsOneWidget);
    expect(find.text('Đã lưu vào Nhật ký trong hũ của bạn.'), findsOneWidget);
    expect(find.text('Xem trong hũ'), findsOneWidget);
    expect(services.notes.notes.single.type, NoteType.nhatKy);

    await tester.tap(find.text('Về Hôm nay'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('+ Thêm thói quen mới', (tester) async {
    final services = await pumpApp(tester);
    await openSelfControl(tester);
    await tester.scrollUntilVisible(find.text('+ Thêm'), 100);
    await tester.ensureVisible(find.text('+ Thêm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Thêm'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Đọc truyện tới 2h');
    await tester.pump();
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    expect(find.text('Đọc truyện tới 2h'), findsOneWidget);
    expect(services.selfControl.habits.custom, <String>['Đọc truyện tới 2h']);
  });
}
