import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/screens/breathing/breathing_screen.dart';
import 'package:lab03/screens/jar/jar_screen.dart';
import 'package:lab03/screens/journey/journey_screen.dart';
import 'package:lab03/screens/note_composer/note_composer_screen.dart';
import 'package:lab03/screens/note_detail/note_detail_screen.dart';
import 'package:lab03/screens/note_saved/note_saved_screen.dart';
import 'package:lab03/screens/self_control/self_control_screen.dart';
import 'package:lab03/screens/settings/settings_screen.dart';
import 'package:lab03/screens/today/today_screen.dart';
import 'package:lab03/widgets/app_bottom_nav.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

/// Cấu trúc điều hướng Lab 2 (`user-flow.md` mục 1.1, handout mục 3).
void main() {
  // Đã đăng nhập sẵn (fake); luồng đăng nhập ở auth_flow_test.dart.
  Future<void> enterApp(WidgetTester tester) => pumpApp(tester);

  testWidgets('đã đăng nhập: mở ở S02 có thanh tab 4 mục', (tester) async {
    await enterApp(tester);

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    // Tab đang chọn hiện nhãn; tab khác chỉ có icon, nhãn qua tooltip.
    expect(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Hôm nay'),
      ),
      findsOneWidget,
    );
    for (final label in <String>['Hũ', 'Thử thách', 'Hành trình']) {
      expect(findTab(label), findsOneWidget);
    }
  });

  testWidgets('màn lồng che thanh tab; Back quay lại tab', (tester) async {
    final services = TestServices();
    services.notes.notes.add(sampleNote('n1', DateTime(2026, 10, 24)));
    await pumpApp(tester, services: services);
    await tester.tap(findTab('Hũ'));
    await tester.pumpAndSettle();
    expect(find.byType(JarScreen), findsOneWidget);

    await tester.tap(find.text('Dọn bàn học, gửi email hỏi thầy'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteDetailScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(JarScreen), findsOneWidget);
  });

  testWidgets('Back hệ thống ở tab khác về Hôm nay', (tester) async {
    await enterApp(tester);
    await tester.tap(findTab('Hành trình'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('F1: Ghi nốt → S03 → S04 → Về Hôm nay', (tester) async {
    await enterApp(tester);
    await tester.tap(find.text('Ghi nốt'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Chiến thắng nhỏ')));
    await tester.pumpAndSettle();
    expect(find.byType(NoteComposerScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Tâm trạng Ổn'));
    await tester.pump();
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đi bộ'));
    await tester.pump();
    await tester.tap(find.text('Bỏ qua phần kể thêm'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteSavedScreen), findsOneWidget);

    await tester.tap(find.text('Về Hôm nay'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('S09 không còn nút thở; S02 Stress? → S10', (tester) async {
    await enterApp(tester);
    await tester.tap(find.bySemanticsLabel('Dừng lại, ghi 1 lần tự chủ'));
    await tester.pumpAndSettle();
    expect(find.byType(SelfControlScreen), findsOneWidget);
    expect(find.text('Khó dừng? Thở 90 giây'), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Stress?, Thở 90 giây để thả lỏng'));
    // S10 thở ngay khi mở nên không bao giờ "settle"; chỉ chờ chuyển màn.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BreathingScreen), findsOneWidget);
  });

  testWidgets('avatar ở màn tab mở S12; nút + mở S03', (tester) async {
    await enterApp(tester);
    await tester.tap(findTab('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(findTab('Thử thách'));
    await tester.pumpAndSettle();
    await tester.tap(findTab('Ghi nốt'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Chiến thắng nhỏ')));
    await tester.pumpAndSettle();
    expect(find.byType(NoteComposerScreen), findsOneWidget);
  });

  testWidgets('tab con của S11 đổi theo ?tab=', (tester) async {
    await enterApp(tester);
    await tester.tap(findTab('Hành trình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();

    final screen = tester.widget<JourneyScreen>(find.byType(JourneyScreen));
    expect(screen.tab, JourneyTab.calendar);
  });
}
