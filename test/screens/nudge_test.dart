import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/self_control.dart';
import 'package:lab03/router/app_routes.dart';
import 'package:lab03/screens/note_composer/note_composer_screen.dart';
import 'package:lab03/screens/self_control/self_control_screen.dart';
import 'package:lab03/screens/today/today_screen.dart';
import 'package:lab03/services/nudge_service.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

/// Lời nhắc trên máy: "Giờ tỉnh" (S09) và "Nhắc ghi nốt buổi tối" (S12).
void main() {
  testWidgets('đăng nhập: hẹn nhắc lúc bắt đầu khung giờ, xin quyền một lần', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    expect(services.nudges.scheduled[Nudge.awake], 23 * 60);
    expect(services.nudges.permissionRequests, 1);

    await services.selfControl.save(
      const UserSettings(awakeStart: 22 * 60 + 30, awakeEnd: 30),
    );
    await tester.pumpAndSettle();
    expect(services.nudges.scheduled[Nudge.awake], 22 * 60 + 30);
    expect(services.nudges.permissionRequests, 1);
  });

  testWidgets('tắt Giờ tỉnh ở S09: huỷ lời nhắc', (tester) async {
    final services = await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Dừng lại, ghi 1 lần tự chủ'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(Switch),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(services.selfControl.settings.awakeEnabled, isFalse);
    expect(services.nudges.scheduled[Nudge.awake], isNull);
  });

  testWidgets('nhắc buổi tối: hẹn lúc 21:30, đổi giờ thì hẹn lại', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    expect(services.nudges.scheduled[Nudge.evening], 21 * 60 + 30);

    await services.selfControl.save(
      const UserSettings(eveningReminder: 20 * 60),
    );
    await tester.pumpAndSettle();
    expect(services.nudges.scheduled[Nudge.evening], 20 * 60);
  });

  testWidgets('chạm nhắc buổi tối: mở S03a', (tester) async {
    final services = await pumpApp(tester);
    services.nudges.opened.add(Nudge.evening.route);
    await tester.pumpAndSettle();
    expect(find.byType(NoteComposerScreen), findsOneWidget);
  });

  testWidgets('chưa đăng nhập: không hẹn nhắc', (tester) async {
    final services = await pumpApp(
      tester,
      services: TestServices(signedIn: false),
    );
    expect(services.nudges.scheduled, isEmpty);
    expect(services.nudges.permissionRequests, 0);
  });

  testWidgets('chạm thông báo khi app đang mở: S09 chồng lên, Back về', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    services.nudges.opened.add(AppRoutes.selfControl);
    await tester.pumpAndSettle();
    expect(find.byType(SelfControlScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('thông báo mở app: vào thẳng S09, Back về Hôm nay', (
    tester,
  ) async {
    final services = TestServices();
    services.nudges.launch = AppRoutes.selfControl;
    await pumpApp(tester, services: services);
    expect(find.byType(SelfControlScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
