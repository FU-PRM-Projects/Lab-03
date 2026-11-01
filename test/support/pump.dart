import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lab03/app.dart';
import 'package:lab03/router/app_router.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/challenge_repository.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/draft_store.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/services/report_services.dart';
import 'package:lab03/services/self_control_services.dart';
import 'package:lab03/services/user_repository.dart';
import 'package:lab03/theme/app_theme.dart';
import 'package:lab03/widgets/app_text_field.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes.dart';

/// Khung thiết kế Lab 2 và khung kiểm tra thêm.
const Size phone360 = Size(360, 800);
const Size phone412 = Size(412, 915);

/// Đặt kích thước màn hình (dp) cho test và trả lại sau test.
void setScreenSize(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Service giả dùng chung cho một lần bơm app.
class TestServices {
  TestServices({bool signedIn = true})
    : auth = FakeAuthService(signedIn: signedIn ? testUser : null);

  final FakeAuthService auth;
  final FakeUserRepository users = FakeUserRepository();
  final FakeNoteRepository notes = FakeNoteRepository();
  final FakeDraftStore drafts = FakeDraftStore();
  final FixedClock clock = FixedClock();
  final FakeSelfControl selfControl = FakeSelfControl();
  final FakeLocalAuth localAuth = FakeLocalAuth();
  final FakeScreenGuard screenGuard = FakeScreenGuard();
  final FakeChallengeRepository challenges = FakeChallengeRepository();
  final FakeReportService reports = FakeReportService();
  final FakeStorageService storage = FakeStorageService();

  List<Override> get overrides => <Override>[
    authServiceProvider.overrideWithValue(auth),
    userRepositoryProvider.overrideWithValue(users),
    noteRepositoryProvider.overrideWithValue(notes),
    draftStoreProvider.overrideWithValue(drafts),
    clockProvider.overrideWithValue(clock),
    habitRepositoryProvider.overrideWithValue(selfControl),
    settingsRepositoryProvider.overrideWithValue(selfControl.settingsView),
    localAuthServiceProvider.overrideWithValue(localAuth),
    screenGuardProvider.overrideWithValue(screenGuard),
    challengeRepositoryProvider.overrideWithValue(challenges),
    reportServiceProvider.overrideWithValue(reports),
    storageServiceProvider.overrideWithValue(storage),
  ];
}

/// Bơm cả app (router, theme) với service giả. Mặc định đã đăng nhập.
Future<TestServices> pumpApp(
  WidgetTester tester, {
  Size size = phone360,
  TestServices? services,
}) async {
  final s = services ?? TestServices();
  setScreenSize(tester, size);
  await tester.pumpWidget(
    ProviderScope(overrides: s.overrides, child: const NotApp()),
  );
  await tester.pumpAndSettle();
  return s;
}

/// Router của app đang chạy trong test.
GoRouter routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(NotApp)))
        .read(appRouterProvider);

/// Bơm một widget trong theme Lab 2.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Size size = phone360,
}) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Ô nhập của `AppTextField` theo nhãn (nhãn nằm trên ô, ngoài TextField).
Finder findField(String label) => find.descendant(
  of: find.widgetWithText(AppTextField, label),
  matching: find.byType(TextField),
);

/// Tab chưa chọn trên thanh tab: chỉ có icon, nhãn nằm trong tooltip
/// (`Tooltip` của `material_ui`, nên `find.byTooltip` không thấy).
Finder findTab(String label) => find.byWidgetPredicate(
  (widget) => widget is Tooltip && widget.message == label,
);
