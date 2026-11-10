import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/report.dart';
import 'package:lab03/services/analytics_events.dart';
import 'package:lab03/services/analytics_service.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/crash_reporter.dart';
import 'package:lab03/services/report_services.dart';
import 'package:lab03/viewmodels/weekly_report_view_model.dart';

import '../support/fakes.dart';

/// Thẻ tuần PDF (S11b, D-06): file lưu trên máy, chia sẻ qua hộp chia sẻ,
/// metadata ở `users/{uid}/reports/{isoWeek}` (Final Assignment, mục 4).
void main() {
  final summary = WeeklySummary(
    weekStart: DateTime(2026, 10, 19),
    noteCount: 4,
    daysWithNotes: 3,
    dayMoods: List<Mood?>.filled(7, null),
    wins: const <String>['Đi bộ 20 phút'],
    balance: const <String, int>{},
  );

  late FakeReportService reports;
  late FakeReportFileStore files;
  late FakeReportRepository records;
  late FakeAnalyticsService analytics;
  late FakeCrashReporter crash;

  setUp(() {
    reports = FakeReportService();
    files = FakeReportFileStore();
    records = FakeReportRepository();
    analytics = FakeAnalyticsService();
    crash = FakeCrashReporter();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        reportServiceProvider.overrideWithValue(reports),
        reportFileStoreProvider.overrideWithValue(files),
        reportRepositoryProvider.overrideWithValue(records),
        analyticsServiceProvider.overrideWithValue(analytics),
        crashReporterProvider.overrideWithValue(crash),
      ],
    );
    addTearDown(c.dispose);
    c.listen(weeklyReportViewModelProvider, (_, _) {});
    return c;
  }

  ReportState state(ProviderContainer c) =>
      c.read(weeklyReportViewModelProvider);

  test('tên file và id metadata theo tuần ISO', () {
    expect(summary.isoWeek, '2026-W43');
    expect(summary.fileName, 'weekly-2026-W43.pdf');
    final newYear = WeeklySummary(
      weekStart: DateTime(2026, 12, 28),
      noteCount: 0,
      daysWithNotes: 0,
      dayMoods: List<Mood?>.filled(7, null),
      wins: const <String>[],
      balance: const <String, int>{},
    );
    expect(newYear.isoWeek, '2026-W53');
  });

  test('lưu vào máy, mở chia sẻ, ghi metadata và sự kiện', () async {
    final c = makeContainer();
    await c.read(weeklyReportViewModelProvider.notifier).export(summary);
    await pumpEventQueue();

    expect(state(c).phase, ReportPhase.done);
    expect(state(c).saved?.path, '/app/documents/reports/weekly-2026-W43.pdf');
    expect(files.saved, <String>['weekly-2026-W43.pdf']);
    expect(files.shared, <String>['weekly-2026-W43.pdf']);
    final record = records.records['2026-W43']!;
    expect(record.fileName, 'weekly-2026-W43.pdf');
    expect(record.sizeBytes, 5);
    expect(record.noteCount, 4);
    expect(analytics.events.map((e) => e.name), <String>[
      AnalyticsEvents.reportExported,
    ]);
  });

  test('không ghi được file → báo lỗi, thử lại được, không chia sẻ', () async {
    files.saveError = const AppException(
      AppErrorKind.unknown,
      code: 'storage-full',
    );
    final c = makeContainer();
    await c.read(weeklyReportViewModelProvider.notifier).export(summary);

    expect(state(c).phase, ReportPhase.failed);
    expect(state(c).message, contains('đầy bộ nhớ'));
    expect(files.shared, isEmpty);
    expect(records.records, isEmpty);
    expect(crash.errors.single.reason, 'report_export');
    expect(crash.errors.single.fatal, isFalse);

    files.saveError = null;
    await c.read(weeklyReportViewModelProvider.notifier).export(summary);
    expect(state(c).phase, ReportPhase.done);
  });

  test('metadata lỗi (mất quyền) không làm hỏng file đã lưu', () async {
    records.recordError = const AppException(AppErrorKind.permissionDenied);
    final c = makeContainer();
    await c.read(weeklyReportViewModelProvider.notifier).export(summary);
    await pumpEventQueue();

    expect(state(c).phase, ReportPhase.done);
    expect(files.saved, hasLength(1));
    expect(crash.errors.single.reason, 'report_metadata');
  });

  test('không mở được hộp chia sẻ → vẫn đã lưu, có thông báo', () async {
    files.shareError = const AppException(AppErrorKind.unknown, code: 'share');
    final c = makeContainer();
    await c.read(weeklyReportViewModelProvider.notifier).export(summary);

    expect(state(c).phase, ReportPhase.done);
    expect(state(c).message, 'Đã lưu vào máy; chưa mở được hộp chia sẻ.');
    expect(crash.errors.single.reason, 'report_share');
  });
}
