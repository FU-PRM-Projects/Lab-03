import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/screens/jar/jar_screen.dart';
import 'package:lab03/screens/settings/settings_screen.dart';
import 'package:lab03/screens/today/today_screen.dart';
import 'package:lab03/screens/welcome/welcome_screen.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/widgets/app_bottom_nav.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

/// Lab 3 mục 6, Authentication: chưa đăng nhập → S01, đã đăng nhập → S02,
/// huỷ đăng nhập có thông báo, đăng xuất xoá dữ liệu trên máy (flow P1, P8).
void main() {
  testWidgets('chưa đăng nhập: mở app ở S01, không thấy thanh tab', (
    tester,
  ) async {
    await pumpApp(tester, services: TestServices(signedIn: false));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
  });

  testWidgets('đã đăng nhập: mở thẳng S02', (tester) async {
    await pumpApp(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('Google: nút Loading rồi vào S02 (P1)', (tester) async {
    final services = TestServices(signedIn: false);
    final gate = Completer<void>();
    services.auth.googleGate = gate;
    await pumpApp(tester, services: services);

    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pump();
    expect(
      find.bySemanticsLabel('Tiếp tục với Google, đang xử lý'),
      findsOneWidget,
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(services.users.profiles.single, testUser);
  });

  testWidgets('huỷ chọn tài khoản: SnackBar, vẫn ở S01', (tester) async {
    final services = TestServices(signedIn: false);
    services.auth.nextError = const AppException(AppErrorKind.cancelled);
    await pumpApp(tester, services: services);

    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã huỷ đăng nhập.'), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets(
    'mở route khi chưa đăng nhập: đăng nhập xong tới đúng đích (P7)',
    (tester) async {
      await pumpApp(tester, services: TestServices(signedIn: false));
      routerOf(tester).go('/jar');
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);

      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pumpAndSettle();
      expect(find.byType(JarScreen), findsOneWidget);
    },
  );

  testWidgets('form email: lỗi dưới ô, đăng nhập được (P2)', (tester) async {
    await pumpApp(tester, services: TestServices(signedIn: false));
    await tester.tap(find.text('Đăng nhập bằng email'));
    await tester.pumpAndSettle();

    await tester.enterText(findField('Email'), 'minh@');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(
      find.text('Email chưa đúng dạng, ví dụ ten@gmail.com.'),
      findsOneWidget,
    );

    await tester.enterText(findField('Email'), 'minh@example.com');
    await tester.enterText(findField('Mật khẩu'), 'matkhau123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('đăng xuất ở S12: hỏi lại, về S01, xoá dữ liệu trên máy (P8)', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    final signOut = find.widgetWithText(OutlinedButton, 'Đăng xuất');
    await tester.scrollUntilVisible(signOut, 200);
    expect(find.text(testUser.email!), findsOneWidget);

    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(find.text('Đăng xuất khỏi Nốt?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(services.users.clearCount, 1);
  });
}
