import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import '../viewmodels/admin_view_models.dart';
import '../viewmodels/messages.dart';
import '../widgets/admin_widgets.dart';

/// Màn 4 · Tổng quan: các con số từ truy vấn `count()` và một biểu đồ.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    return AdminPage(
      title: 'Tổng quan',
      subtitle: 'Số liệu đếm trực tiếp trên Firestore (truy vấn tổng hợp).',
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: stats.isLoading
              ? null
              : () => ref.invalidate(dashboardProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Làm mới'),
        ),
      ],
      child: switch (stats) {
        AsyncData(:final value) => _Body(stats: value),
        AsyncError(:final error) => MessageView.error(
          message: errorMessage(error),
          onAction: () => ref.invalidate(dashboardProvider),
        ),
        _ => const LoadingView(message: 'Đang đếm số liệu…'),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.users == 0 && stats.cards == 0) {
      return const MessageView(
        title: 'Chưa có dữ liệu',
        message:
            'Chưa có người dùng hay thẻ nào. Nạp kho thẻ bằng '
            '`npm run seed` rồi quay lại.',
      );
    }
    final figures = <(String, int, String)>[
      ('Người dùng', stats.users, '${stats.staff} staff / admin'),
      ('Thẻ đang dùng', stats.activeCards, '${stats.archivedCards} đã lưu trữ'),
      ('Chờ duyệt', stats.pending, 'thẻ người dùng gửi'),
      (
        'Đã duyệt / từ chối',
        stats.reviewed,
        '${stats.approved} duyệt · '
            '${stats.rejected} từ chối',
      ),
      ('Thông báo', stats.announcements, 'đã gửi tới app'),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpace.s24),
      children: <Widget>[
        Wrap(
          spacing: AppSpace.s16,
          runSpacing: AppSpace.s16,
          children: <Widget>[
            for (final (label, value, note) in figures)
              SizedBox(
                width: 216,
                child: _Figure(label: label, value: value, note: note),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s24),
        Wrap(
          spacing: AppSpace.s16,
          runSpacing: AppSpace.s16,
          children: <Widget>[
            SizedBox(
              width: 520,
              child: _ChartCard(
                title: 'Thẻ người dùng gửi theo trạng thái',
                bars: <(String, int, Color)>[
                  for (final status in SubmissionStatus.values)
                    (
                      status.label,
                      switch (status) {
                        SubmissionStatus.pending => stats.pending,
                        SubmissionStatus.approved => stats.approved,
                        SubmissionStatus.rejected => stats.rejected,
                      },
                      statusColors(status).$2,
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 520,
              child: _ChartCard(
                title: 'Kho thẻ theo chủ đề',
                bars: <(String, int, Color)>[
                  for (final topic in ChallengeTopic.values)
                    (
                      topic.label,
                      stats.cardsByTopic[topic] ?? 0,
                      topicColors(topic).$2,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.note});

  final String label;
  final int value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AdminCard(
      child: Semantics(
        label: '$label: $value, $note',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: text.labelLarge?.copyWith(color: muted)),
            const SizedBox(height: AppSpace.s8),
            Text('$value', style: text.displaySmall),
            const SizedBox(height: AppSpace.s4),
            Text(note, style: text.bodySmall?.copyWith(color: muted)),
          ],
        ),
      ),
    );
  }
}

/// Biểu đồ cột (fl_chart). Mỗi cột có nhãn số ở trên để không chỉ dựa vào
/// màu.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.bars});

  final String title;
  final List<(String, int, Color)> bars;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final maxValue = bars.fold<int>(0, (m, b) => b.$2 > m ? b.$2 : m);
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: text.titleSmall),
          const SizedBox(height: AppSpace.s16),
          SizedBox(
            height: 220,
            child: Semantics(
              label: '$title: ${bars.map((b) => '${b.$1} ${b.$2}').join(', ')}',
              excludeSemantics: true,
              child: BarChart(
                BarChartData(
                  maxY: (maxValue == 0 ? 1 : maxValue) * 1.25,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 4,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            '${rod.toY.round()}',
                            text.labelLarge ?? const TextStyle(),
                          ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            bars[value.toInt()].$1,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  barGroups: <BarChartGroupData>[
                    for (final (i, bar) in bars.indexed)
                      BarChartGroupData(
                        x: i,
                        showingTooltipIndicators: const <int>[0],
                        barRods: <BarChartRodData>[
                          BarChartRodData(
                            toY: bar.$2.toDouble(),
                            color: bar.$3,
                            width: 36,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.r6),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
