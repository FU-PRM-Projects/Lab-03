import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/self_control.dart';
import 'package:lab03/router/app_routes.dart';
import 'package:lab03/screens/self_control/self_control_screen.dart';
import 'package:lab03/screens/today/today_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

/// Lời nhắc "Giờ tỉnh" (S09): hẹn theo cài đặt, chạm vào thì mở S09.
void main() {
  testWidgets('đăng nhập: hẹn nhắc lúc bắt đầu khung giờ, xin quyền một lần', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    expect(services.nudges.awakeAt, 23 * 60);
    expect(services.nudges.permissionRequests, 1);

    await services.selfControl.save(
      const UserSettings(awakeStart: 22 * 60 + 30, awakeEnd: 30),
    );
    await tester.pumpAndSettle();
    expect(services.nudges.awakeAt, 22 * 60 + 30);
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
    expect(services.nudges.awakeAt, isNull);
  });

  testWidgets('chưa đăng nhập: không hẹn nhắc', (tester) async {
    final services = await pumpApp(
      tester,
      services: TestServices(signedIn: false),
    );
    expect(services.nudges.awakeAt, isNull);
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
