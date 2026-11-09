import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/app_exception.dart';
import '../services/crash_reporter.dart';
import '../services/report_services.dart';

enum ReportPhase { idle, building, saving, done, failed }

class ReportState {
  const ReportState({this.phase = ReportPhase.idle, this.saved, this.message});

  final ReportPhase phase;

  /// File vừa lưu, để chia sẻ lại.
  final SavedReport? saved;

  /// Lỗi (Error state) hoặc thông báo phụ (không mở được hộp chia sẻ).
  final String? message;

  bool get busy => phase == ReportPhase.building || phase == ReportPhase.saving;
}

final weeklyReportViewModelProvider =
    NotifierProvider.autoDispose<WeeklyReportViewModel, ReportState>(
      WeeklyReportViewModel.new,
    );

/// Lần lưu trước của tuần đang xem (metadata trên Firestore).
final weeklyReportRecordProvider = StreamProvider.autoDispose
    .family<ReportRecord?, String>(
      (ref, isoWeek) => ref.watch(reportRepositoryProvider).watchWeek(isoWeek),
    );

/// "Lưu thẻ tuần (PDF)" (S11b, deviation D-06): tạo PDF → lưu vào máy →
/// ghi metadata `users/{uid}/reports/{isoWeek}` → mở hộp chia sẻ.
class WeeklyReportViewModel extends Notifier<ReportState> {
  @override
  ReportState build() => const ReportState();

  Future<void> export(WeeklySummary summary) async {
    if (state.busy) return;
    state = const ReportState(phase: ReportPhase.building);
    final SavedReport saved;
    try {
      final bytes = await ref.read(reportServiceProvider).weeklyCard(summary);
      if (!ref.mounted) return;
      state = const ReportState(phase: ReportPhase.saving);
      saved = await ref
          .read(reportFileStoreProvider)
          .save(bytes, summary.fileName);
    } on Object catch (error, stack) {
      _record(error, stack, 'report_export');
      if (ref.mounted) {
        state = ReportState(
          phase: ReportPhase.failed,
          message: _message(error),
        );
      }
      return;
    }
    if (!ref.mounted) return;
    state = ReportState(phase: ReportPhase.done, saved: saved);

    // File đã nằm trên máy; metadata chỉ để biết tuần nào đã lưu. Không chờ
    // máy chủ xác nhận: offline thì Firestore tự gửi khi có mạng.
    unawaited(
      ref
          .read(reportRepositoryProvider)
          .record(
            ReportRecord(
              isoWeek: summary.isoWeek,
              fileName: saved.fileName,
              sizeBytes: saved.sizeBytes,
              noteCount: summary.noteCount,
            ),
          )
          .catchError((Object error, StackTrace stack) {
            _record(error, stack, 'report_metadata');
          }),
    );
    unawaited(
      ref.read(analyticsServiceProvider).track(
        AnalyticsEvents.reportExported,
        <String, Object>{AnalyticsParams.format: 'pdf'},
      ),
    );
    await share();
  }

  /// Mở hộp chia sẻ với file vừa lưu (tự mở sau khi lưu, bấm lại được).
  Future<void> share() async {
    final saved = state.saved;
    if (saved == null) return;
    try {
      await ref.read(reportFileStoreProvider).share(saved);
    } on Object catch (error, stack) {
      _record(error, stack, 'report_share');
      if (ref.mounted) {
        state = ReportState(
          phase: ReportPhase.done,
          saved: saved,
          message: 'Đã lưu vào máy; chưa mở được hộp chia sẻ.',
        );
      }
    }
  }

  void _record(Object error, StackTrace stack, String reason) => unawaited(
    ref.read(crashReporterProvider).recordError(error, stack, reason: reason),
  );

  static String _message(Object error) => switch (error) {
    AppException(kind: AppErrorKind.permissionDenied) =>
      'Chưa lưu được: app chưa có quyền ghi file. Thử lại nhé.',
    AppException(code: 'storage-full') =>
      'Chưa lưu được: máy đã đầy bộ nhớ. Dọn bớt rồi thử lại.',
    _ => 'Chưa tạo được thẻ tuần. Thử lại nhé.',
  };
}
