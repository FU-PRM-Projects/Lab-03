import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_admin/screens/dashboard_screen.dart';
import 'package:not_admin/services/admin_services.dart';
import 'package:not_admin/viewmodels/admin_view_models.dart';
import 'package:not_core/not_core.dart';

/// Máy chủ không trả lời (mất mạng): `count()` chờ mãi.
class _HangingDashboard implements DashboardRepository {
  int calls = 0;

  @override
  Future<DashboardStats> load() {
    calls++;
    return Completer<DashboardStats>().future;
  }
}

/// Máy chủ báo lỗi ngay.
class _FailingDashboard implements DashboardRepository {
  int calls = 0;

  @override
  Future<DashboardStats> load() async {
    calls++;
    throw const AppException(AppErrorKind.network);
  }
}

const _offline = 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';

/// Bản deploy 11/11/2026: tắt mạng thì Tổng quan quay vòng hơn 3 phút vì
/// Riverpod 3 tự thử lại provider lỗi 10 lần. `main.dart` dùng
/// `ProviderScope(retry: noRetry)`; các test này dựng y như vậy.
void main() {
  Future<void> pumpDashboard(
    WidgetTester tester,
    DashboardRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
  }

  testWidgets('máy chủ không trả lời: sau 15 giây hiện lỗi, không thử lại', (
    tester,
  ) async {
    final repository = _HangingDashboard();
    await pumpDashboard(tester, repository);
    expect(find.text('Đang đếm số liệu…'), findsOneWidget);

    await tester.pump(dashboardTimeout + const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text(_offline), findsOneWidget);
    expect(find.text('Đang đếm số liệu…'), findsNothing);

    // Không còn lần tải nào chạy ngầm sau khi đã báo lỗi.
    await tester.pump(const Duration(minutes: 1));
    expect(repository.calls, 1);
    expect(find.text(_offline), findsOneWidget);
  });

  testWidgets('lỗi mạng: hiện lỗi ngay, Thử lại thì tải lại một lần', (
    tester,
  ) async {
    final repository = _FailingDashboard();
    await pumpDashboard(tester, repository);
    await tester.pump();
    expect(find.text(_offline), findsOneWidget);
    expect(repository.calls, 1);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(repository.calls, 2);
    expect(find.text(_offline), findsOneWidget);
  });

  test('noRetry: không bao giờ hẹn lần thử lại', () {
    expect(noRetry(0, TimeoutException('x')), isNull);
    expect(noRetry(0, const AppException(AppErrorKind.network)), isNull);
  });
}
