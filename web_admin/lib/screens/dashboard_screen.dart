import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import '../viewmodels/admin_view_models.dart';
import '../viewmodels/messages.dart';
import '../widgets/admin_widgets.dart';

/// Màu hai chuỗi của biểu đồ hoạt động: primary của app và cam đậm. Đã chạy
/// bộ kiểm tra màu (lightness, chroma, mù màu, tương phản ≥ 3:1 trên nền
/// thẻ `#F6F7FB`); nhãn và chú thích luôn đi kèm nên không dựa vào màu.
const Color _seriesUsers = Color(0xFF3D4FD6);
const Color _seriesSubmissions = Color(0xFFD95926);

/// Màn 4 · Tổng quan: các con số từ truy vấn `count()`, biểu đồ hoạt động 14
/// ngày, tỉ lệ duyệt và kho thẻ theo chủ đề.
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
          icon: const Icon(Icons.refresh, size: 18),
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
    final last7Users = stats.daily
        .skip(DashboardStats.days - 7)
        .fold<int>(0, (sum, d) => sum + d.newUsers);
    final tiles = <_Kpi>[
      _Kpi(
        'Người dùng',
        stats.users,
        last7Users == 0
            ? '${stats.staff} staff / admin'
            : '+$last7Users trong 7 ngày',
        Icons.group_outlined,
      ),
      _Kpi(
        'Thẻ đang dùng',
        stats.activeCards,
        '${stats.archivedCards} đã lưu trữ',
        Icons.style_outlined,
      ),
      _Kpi(
        'Chờ duyệt',
        stats.pending,
        stats.pending == 0 ? 'Không còn thẻ nào chờ' : 'thẻ người dùng gửi',
        Icons.hourglass_empty,
      ),
      _Kpi(
        'Đã xử lý',
        stats.reviewed,
        '${stats.approved} duyệt · ${stats.rejected} từ chối',
        Icons.fact_check_outlined,
      ),
      _Kpi(
        'Thông báo',
        stats.announcements,
        'đã gửi tới app',
        Icons.campaign_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final tileWidth = wide
            ? (constraints.maxWidth - 4 * AppSpace.s16) / 5
            : (constraints.maxWidth - AppSpace.s16) / 2;
        final side = <Widget>[
          _StatusCard(stats: stats),
          const SizedBox(height: AppSpace.s16, width: AppSpace.s16),
          _TopicCard(stats: stats),
        ];
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpace.s24),
          children: <Widget>[
            Wrap(
              spacing: AppSpace.s16,
              runSpacing: AppSpace.s16,
              children: <Widget>[
                for (final kpi in tiles)
                  SizedBox(
                    width: tileWidth,
                    child: _KpiTile(kpi: kpi),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: _ActivityCard(stats: stats)),
                  const SizedBox(width: AppSpace.s16),
                  Expanded(flex: 2, child: Column(children: side)),
                ],
              )
            else ...<Widget>[
              _ActivityCard(stats: stats),
              const SizedBox(height: AppSpace.s16),
              ...side,
            ],
          ],
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.note, this.icon);

  final String label;
  final int value;
  final String note;
  final IconData icon;
}

/// Thẻ số liệu: nhãn + icon, số lớn, một dòng phụ.
class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.kpi});

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Semantics(
        label: '${kpi.label}: ${kpi.value}, ${kpi.note}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    kpi.label,
                    style: text.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(kpi.icon, size: 18, color: scheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: AppSpace.s12),
            Text(
              '${kpi.value}',
              style: text.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            Text(
              kpi.note,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung thẻ kiểu shadcn: nền trắng, viền mảnh, bo `card`.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpace.s20), child: child),
    );
  }
}

/// Thẻ biểu đồ: tiêu đề, mô tả, nội dung, dòng chân.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.description,
    required this.child,
    this.footer,
    this.trailing,
  });

  final String title;
  final String description;
  final Widget child;
  final String? footer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(title, style: text.titleMedium),
                    ),
                    const SizedBox(height: AppSpace.s2),
                    Text(
                      description,
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpace.s20),
          child,
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppSpace.s16),
            Text(footer!, style: text.bodySmall?.copyWith(color: muted)),
          ],
        ],
      ),
    );
  }
}

/// Chấm màu + nhãn của chú thích.
class _LegendItem extends StatelessWidget {
  const _LegendItem(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
        child: const SizedBox.square(dimension: 10),
      ),
      const SizedBox(width: AppSpace.s6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Biểu đồ vùng 14 ngày: người dùng mới và thẻ gửi duyệt, một trục, rê chuột
/// để xem số của từng ngày.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final days = stats.daily;
    final users = days.fold<int>(0, (s, d) => s + d.newUsers);
    final sent = days.fold<int>(0, (s, d) => s + d.submissions);
    final top = days.fold<int>(
      0,
      (m, d) => math.max(m, math.max(d.newUsers, d.submissions)),
    );
    final maxY = math.max(4, (top * 1.25).ceil()).toDouble();
    String dayLabel(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    LineChartBarData series(List<int> values, Color color) => LineChartBarData(
      spots: <FlSpot>[
        for (final (i, v) in values.indexed) FlSpot(i.toDouble(), v.toDouble()),
      ],
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.02),
          ],
        ),
      ),
    );

    return _ChartCard(
      title: 'Hoạt động 14 ngày',
      description: 'Người dùng mới và thẻ được gửi duyệt mỗi ngày.',
      trailing: const Wrap(
        spacing: AppSpace.s12,
        children: <Widget>[
          _LegendItem(_seriesUsers, 'Người dùng mới'),
          _LegendItem(_seriesSubmissions, 'Thẻ gửi duyệt'),
        ],
      ),
      footer: '14 ngày qua: $users người dùng mới, $sent thẻ được gửi duyệt.',
      child: SizedBox(
        height: 240,
        child: days.isEmpty
            ? Center(
                child: Text(
                  'Chưa có hoạt động trong 14 ngày qua.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              )
            : Semantics(
                label:
                    'Biểu đồ hoạt động 14 ngày: $users người dùng mới, $sent '
                    'thẻ gửi duyệt.',
                excludeSemantics: true,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (days.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: scheme.outlineVariant,
                        strokeWidth: 1,
                        dashArray: <int>[4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: maxY / 4,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.round().toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 3,
                          getTitlesWidget: (value, meta) {
                            final i = value.round();
                            if (i < 0 || i >= days.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                dayLabel(days[i].day),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      getTouchedSpotIndicator: (bar, indexes) =>
                          <TouchedSpotIndicatorData>[
                            for (final _ in indexes)
                              TouchedSpotIndicatorData(
                                FlLine(color: scheme.outline, strokeWidth: 1),
                                FlDotData(
                                  getDotPainter: (spot, percent, bar, index) =>
                                      FlDotCirclePainter(
                                        radius: 4,
                                        color: bar.color ?? scheme.primary,
                                        strokeWidth: 2,
                                        strokeColor: scheme.surface,
                                      ),
                                ),
                              ),
                          ],
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => scheme.inverseSurface,
                        tooltipBorderRadius: BorderRadius.circular(
                          AppRadius.r8,
                        ),
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (spots) => <LineTooltipItem?>[
                          for (final (i, spot) in spots.indexed)
                            LineTooltipItem(
                              i == 0
                                  ? '${dayLabel(days[spot.x.round()].day)}\n'
                                  : '',
                              theme.textTheme.labelSmall!.copyWith(
                                color: scheme.onInverseSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text:
                                      '${spot.barIndex == 0 ? 'Người dùng mới' : 'Thẻ gửi duyệt'}: '
                                      '${spot.y.round()}',
                                  style: theme.textTheme.labelMedium!.copyWith(
                                    color: scheme.onInverseSurface,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    lineBarsData: <LineChartBarData>[
                      series(<int>[
                        for (final d in days) d.newUsers,
                      ], _seriesUsers),
                      series(<int>[
                        for (final d in days) d.submissions,
                      ], _seriesSubmissions),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Thẻ người dùng gửi theo trạng thái: một thanh phân đoạn (một tổng chia
/// 3 phần) cùng bảng số và phần trăm. Màu trạng thái luôn đi kèm nhãn.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final parts = <(SubmissionStatus, int)>[
      (SubmissionStatus.pending, stats.pending),
      (SubmissionStatus.approved, stats.approved),
      (SubmissionStatus.rejected, stats.rejected),
    ];
    final total = parts.fold<int>(0, (s, p) => s + p.$2);
    String percent(int v) =>
        total == 0 ? '0%' : '${(v * 100 / total).round()}%';

    return _ChartCard(
      title: 'Thẻ người dùng gửi',
      description: 'Theo trạng thái duyệt.',
      footer: total == 0
          ? null
          : 'Tỉ lệ được duyệt: '
                '${stats.reviewed == 0 ? '—' : '${(stats.approved * 100 / stats.reviewed).round()}%'} '
                'trên ${stats.reviewed} thẻ đã xử lý.',
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
              child: Text(
                'Chưa có thẻ nào được gửi. Thẻ người dùng gửi từ app sẽ hiện '
                'ở đây.',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  label: parts.map((p) => '${p.$1.label} ${p.$2}').join(', '),
                  excludeSemantics: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.r6),
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          for (final (i, (status, value)) in parts.indexed)
                            if (value > 0) ...<Widget>[
                              if (i > 0 && parts.take(i).any((p) => p.$2 > 0))
                                const SizedBox(width: 2),
                              Expanded(
                                flex: value,
                                child: Tooltip(
                                  message:
                                      '${status.label}: $value (${percent(value)})',
                                  child: ColoredBox(
                                    color: statusColors(status).$2,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                for (final (status, value) in parts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s8),
                    child: Row(
                      children: <Widget>[
                        _LegendItem(statusColors(status).$2, status.label),
                        const Spacer(),
                        Text('$value', style: theme.textTheme.labelLarge),
                        SizedBox(
                          width: 48,
                          child: Text(
                            percent(value),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Kho thẻ theo chủ đề: thanh ngang một màu, số ở cuối thanh.
class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = <(String, int)>[
      for (final topic in ChallengeTopic.values)
        (topic.label, stats.cardsByTopic[topic] ?? 0),
    ];
    final top = rows.fold<int>(1, (m, r) => math.max(m, r.$2));

    return _ChartCard(
      title: 'Kho thẻ theo chủ đề',
      description: 'Gồm cả thẻ đã lưu trữ.',
      child: Column(
        children: <Widget>[
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s12),
              child: Semantics(
                label: '$label: $value thẻ',
                excludeSemantics: true,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 84,
                      child: Text(label, style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => Align(
                          alignment: Alignment.centerLeft,
                          child: Tooltip(
                            message: '$label: $value thẻ',
                            child: Container(
                              height: 22,
                              width: math.max(4, c.maxWidth * value / top),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$value',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
