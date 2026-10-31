import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import '../services/app_exception.dart';
import '../services/report_services.dart';

enum ReportPhase { idle, building, uploading, done, failed }

class ReportState {
  const ReportState({
    this.phase = ReportPhase.idle,
    this.progress = 0,
    this.url,
    this.message,
  });

  final ReportPhase phase;

  /// 0–1 khi đang tải lên.
  final double progress;

  /// Link tải về sau khi tải lên xong.
  final String? url;

  /// Lỗi (Error state) hoặc thông báo phụ (không mở được hộp chia sẻ).
  final String? message;

  bool get busy =>
      phase == ReportPhase.building || phase == ReportPhase.uploading;
}

final weeklyReportViewModelProvider =
    NotifierProvider.autoDispose<WeeklyReportViewModel, ReportState>(
      WeeklyReportViewModel.new,
    );

/// "Lưu thẻ tuần (PDF)" (S11b, deviation D-06): tạo PDF → tải lên
/// `reports/{uid}/` có tiến độ → hiện link → mở hộp chia sẻ.
class WeeklyReportViewModel extends Notifier<ReportState> {
  @override
  ReportState build() => const ReportState();

  Future<void> export(WeeklySummary summary) async {
    if (state.busy) return;
    state = const ReportState(phase: ReportPhase.building);
    try {
      final bytes = await ref.read(reportServiceProvider).weeklyCard(summary);
      if (!ref.mounted) return;
      state = const ReportState(phase: ReportPhase.uploading);
      String? url;
      await for (final step
          in ref
              .read(storageServiceProvider)
              .uploadReport(summary.fileName, bytes)) {
        if (!ref.mounted) return;
        url = step.url ?? url;
        state = ReportState(
          phase: ReportPhase.uploading,
          progress: step.fraction,
        );
      }
      if (!ref.mounted) return;
      state = ReportState(phase: ReportPhase.done, progress: 1, url: url);
      // Stage 5: logEvent(export_report).
      try {
        await ref.read(reportServiceProvider).share(bytes, summary.fileName);
      } on Object {
        if (ref.mounted) {
          state = ReportState(
            phase: ReportPhase.done,
            progress: 1,
            url: url,
            message: 'Đã lưu lên đám mây; chưa mở được hộp chia sẻ.',
          );
        }
      }
    } on Object catch (error) {
      // Stage 5: ghi non-fatal qua CrashReporter.
      if (!ref.mounted) return;
      state = ReportState(phase: ReportPhase.failed, message: _message(error));
    }
  }

  static String _message(Object error) => switch (error) {
    AppException(kind: AppErrorKind.network) =>
      'Chưa tải lên được: kiểm tra Wi-Fi rồi thử lại.',
    AppException(kind: AppErrorKind.permissionDenied) =>
      'Chưa tải lên được: phiên đăng nhập đã hết. Đăng nhập lại rồi thử lại.',
    _ => 'Chưa tạo được thẻ tuần. Thử lại nhé.',
  };
}
