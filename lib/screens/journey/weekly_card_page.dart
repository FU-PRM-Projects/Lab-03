import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/report.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/weekly_report_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/mascot.dart';

/// Thẻ tuần dạng story toàn màn (S11b) với "Lưu thẻ tuần (PDF)" (D-06): file
/// lưu trên máy, chia sẻ qua hộp chia sẻ, metadata trên Firestore.
class WeeklyCardPage extends ConsumerWidget {
  const WeeklyCardPage({required this.summary, super.key});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final report = ref.watch(weeklyReportViewModelProvider);
    final viewModel = ref.read(weeklyReportViewModelProvider.notifier);
    final lastSaved = ref
        .watch(weeklyReportRecordProvider(summary.isoWeek))
        .value;
    final range =
        '${ViDateFormat.shortDate(summary.weekStart)} – '
        '${ViDateFormat.shortDate(summary.weekEnd)}';

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
        ),
        title: const Text('Thẻ tuần'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.narrowContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpace.screen),
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          range,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s8),
                      Text(
                        '${summary.noteCount} nốt · '
                        '${summary.daysWithNotes}/7 ngày có ghi'
                        '${summary.energy == null ? '' : ' · năng lượng ${ViDateFormat.decimal(summary.energy!)}/5'}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpace.s16),
                      Row(
                        children: <Widget>[
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: Semantics(
                                label:
                                    '${ViDateFormat.weekdayShort[i]}: '
                                    '${summary.dayMoods[i]?.label ?? 'chưa ghi'}',
                                excludeSemantics: true,
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      height: AppSize.minTouch,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: AppSpace.s2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: summary.dayMoods[i] == null
                                            ? theme.colorScheme.surface
                                            : colors.mood(summary.dayMoods[i]!),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.r8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.s4),
                                    Text(
                                      ViDateFormat.weekdayShort[i],
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.s24),
                      Text(
                        'Chiến thắng nhỏ',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpace.s8),
                      if (summary.wins.isEmpty)
                        Text(
                          'Tuần sau ghi thêm vài chiến thắng nhé.',
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        for (final win in summary.wins)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.s4),
                            child: Text(
                              '✓ $win',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                      const SizedBox(height: AppSpace.s24),
                      const Center(child: Mascot(state: MascotState.xong)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpace.screen),
                  child: _ExportArea(
                    report: report,
                    lastSaved: lastSaved,
                    onExport: () => viewModel.export(summary),
                    onShare: viewModel.share,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút lưu và phản hồi: đang tạo, đang lưu, đã lưu (kèm chia sẻ lại), lỗi,
/// và lần lưu trước của tuần này (từ Firestore).
class _ExportArea extends StatelessWidget {
  const _ExportArea({
    required this.report,
    required this.lastSaved,
    required this.onExport,
    required this.onShare,
  });

  final ReportState report;
  final ReportRecord? lastSaved;
  final VoidCallback onExport;
  final VoidCallback onShare;

  static String _size(int bytes) =>
      bytes < 1024 ? '$bytes B' : '${ViDateFormat.decimal(bytes / 1024)} KB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final saved = report.saved;
    final previous = lastSaved?.savedAt;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: switch (report.phase) {
            ReportPhase.idle =>
              previous == null
                  ? const SizedBox.shrink()
                  : Text(
                      'Đã lưu tuần này lúc ${ViDateFormat.time(previous)} '
                      '${ViDateFormat.shortDate(previous)}.',
                      style: theme.textTheme.bodySmall,
                    ),
            ReportPhase.building => Text(
              'Đang tạo PDF…',
              style: theme.textTheme.bodyMedium,
            ),
            ReportPhase.saving => Text(
              'Đang lưu vào máy…',
              style: theme.textTheme.bodyMedium,
            ),
            ReportPhase.done => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Đã lưu thẻ tuần vào máy.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.success,
                  ),
                ),
                if (saved != null)
                  Text(
                    '${saved.fileName} · ${_size(saved.sizeBytes)}',
                    style: theme.textTheme.bodySmall,
                  ),
                if (report.message case final message?)
                  Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
            ReportPhase.failed => Text(
              report.message ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          },
        ),
        const SizedBox(height: AppSpace.s8),
        if (report.phase == ReportPhase.done)
          AppButton(
            label: 'Chia sẻ PDF',
            icon: Icons.ios_share,
            variant: AppButtonVariant.tonal,
            expand: true,
            onPressed: onShare,
          )
        else
          AppButton(
            label: report.phase == ReportPhase.failed
                ? 'Thử lại'
                : 'Lưu thẻ tuần (PDF)',
            icon: Icons.picture_as_pdf_outlined,
            variant: AppButtonVariant.tonal,
            expand: true,
            loading: report.busy,
            onPressed: report.busy ? null : onExport,
          ),
      ],
    );
  }
}
