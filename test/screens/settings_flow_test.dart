import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/self_control.dart';
import 'package:lab03/screens/journey/journey_screen.dart';
import 'package:lab03/screens/settings/settings_screen.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/self_control_services.dart';
import 'package:lab03/viewmodels/settings_view_model.dart';
import 'package:lab03/viewmodels/view_state.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

/// Flow P8 Hồ sơ & cài đặt: S12.
void main() {
  group('SettingsViewModel', () {
    late FakeSelfControl store;
    late FakeLocalAuth localAuth;

    ProviderContainer makeContainer() {
      final c = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            FakeAuthService(signedIn: testUser),
          ),
          settingsRepositoryProvider.overrideWithValue(store.settingsView),
          localAuthServiceProvider.overrideWithValue(localAuth),
        ],
      );
      addTearDown(c.dispose);
      c.listen(settingsViewModelProvider, (_, _) {});
      return c;
    }

    setUp(() {
      store = FakeSelfControl();
      localAuth = FakeLocalAuth();
    });

    UserSettings value(ProviderContainer c) =>
        (c.read(settingsViewModelProvider).settings as Data<UserSettings>)
            .value;

    test('mặc định: nhắc 21:30, Giờ tỉnh 23:00 – 01:00, chưa khoá', () async {
      final c = makeContainer();
      await pumpEventQueue();
      expect(value(c).eveningReminder, 21 * 60 + 30);
      expect(value(c).awakeStart, 23 * 60);
      expect(value(c).lockSelfControl, isFalse);
    });

    test('đổi giờ nhắc và công tắc: lưu ngay', () async {
      final c = makeContainer();
      await pumpEventQueue();
      final vm = c.read(settingsViewModelProvider.notifier);
      await vm.setEveningReminder(20 * 60);
      await vm.setHideNotificationContent(true);
      await vm.setAiEnabled(true);
      expect(store.settings.eveningReminder, 20 * 60);
      expect(store.settings.hideNotificationContent, isTrue);
      expect(store.settings.aiEnabled, isTrue);
    });

    test('khoá Tự chủ: cần xác thực; thất bại thì không đổi', () async {
      final c = makeContainer();
      await pumpEventQueue();
      final vm = c.read(settingsViewModelProvider.notifier);

      localAuth.result = false;
      await vm.setLockSelfControl(true);
      expect(store.settings.lockSelfControl, isFalse);
      expect(
        c.read(settingsViewModelProvider).message,
        contains('Chưa xác thực'),
      );

      localAuth.result = true;
      await vm.setLockSelfControl(true);
      expect(store.settings.lockSelfControl, isTrue);
      expect(localAuth.calls, 2);
    });
  });

  for (final size in <Size>[phone360, phone412]) {
    testWidgets('S12 ở ${size.width.toInt()} dp: đủ 3 nhóm và khu demo', (
      tester,
    ) async {
      await pumpApp(tester, size: size);
      await tester.tap(find.byTooltip('Cài đặt'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('NHẮC NHỞ'), findsOneWidget);
      expect(find.text('21:30'), findsOneWidget);
      expect(find.text('23:00 – 01:00'), findsOneWidget);
      expect(find.text('QUYỀN RIÊNG TƯ'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('KHU DEMO FIREBASE'), 200);
      expect(find.text('Xuất & tải lên Thẻ tuần (PDF)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bật khoá ở S12 → S09 che thói quen', (tester) async {
    final services = await pumpApp(tester);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khoá phần Tự chủ'));
    await tester.pumpAndSettle();
    expect(services.selfControl.settings.lockSelfControl, isTrue);
    expect(services.localAuth.calls, 1);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Dừng lại'));
    await tester.pumpAndSettle();
    expect(find.text('Lướt mạng xã hội'), findsNothing);
    expect(find.text('Mở khoá'), findsOneWidget);
  });

  testWidgets('khu demo: Xuất & tải lên PDF mở Thống kê của S11', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Xuất & tải lên Thẻ tuần (PDF)'),
      200,
    );
    await tester.ensureVisible(find.text('Xuất & tải lên Thẻ tuần (PDF)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xuất & tải lên Thẻ tuần (PDF)'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyScreen), findsOneWidget);
    expect(find.text('Mục tiêu tuần'), findsOneWidget);
  });
}
