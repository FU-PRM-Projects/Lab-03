import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/journey_stats.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/journey_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/state_views.dart';
import 'weekly_card_page.dart';

/// S11b · Thống kê.
class JourneyStatsTab extends StatelessWidget {
  const JourneyStatsTab({
    required this.state,
    required this.viewModel,
    super.key,
  });

  final JourneyState state;
  final JourneyViewModel viewModel;

  /// Màn rộng: Thống kê 2 cột (handout S11).
  static const double _twoColumnWidth = 840;

  @override
  Widget build(BuildContext context) {
    return switch (state.data) {
      Loading<JourneyData>() || Empty<JourneyData>() => const Padding(
        padding: EdgeInsets.all(AppSpace.screen),
        child: LoadingState.skeleton(message: 'Đang tính hành trình của bạn…'),
      ),
      Failure<JourneyData>(:final message, :final offline) => Padding(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: ErrorState(
          title: 'Chưa tải được thống kê',
          cause: message,
          kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
          onRetry: viewModel.retry,
        ),
      ),
      Data<JourneyData>(:final value) => LayoutBuilder(
        builder: (context, constraints) {
          final left = <Widget>[
            _Numbers(data: value),
            const SizedBox(height: AppSpace.s16),
            _EnergyCard(
              data: value,
              days: state.energyDays,
              onDays: viewModel.setEnergyDays,
            ),
          ];
          final right = <Widget>[
            _WeekGoal(
              data: value,
              onOpen: () {
                final summary = viewModel.weeklySummary();
                if (summary == null) return;
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => WeeklyCardPage(summary: summary),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpace.s16),
            _Balance(data: value),
            const SizedBox(height: AppSpace.s16),
            _Weekdays(counts: value.byWeekday),
          ];
          const padding = EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s8,
            AppSpace.screen,
            AppSpace.tabContentBottom,
          );
          if (constraints.maxWidth >= _twoColumnWidth) {
            return SingleChildScrollView(
              padding: padding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: Column(children: left)),
                  const SizedBox(width: AppSpace.s16),
                  Expanded(child: Column(children: right)),
                ],
              ),
            );
          }
          return ListView(
            padding: padding,
            children: <Widget>[
              ...left,
              const SizedBox(height: AppSpace.s16),
              ...right,
            ],
          );
        },
      ),
    };
  }
}

/// Khung thẻ dùng chung của các mục Thống kê.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpace.s16), child: child),
    );
  }
}

class _Numbers extends StatelessWidget {
  const _Numbers({required this.data});

  final JourneyData data;

  @override
  Widget build(BuildContext context) {
    final change = data.weekChangePercent;
    final changeLabel = change == null
        ? null
        : change >= 0
        ? '↑ $change%'
        : '↓ ${-change}%';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _Number(
            label: 'Nốt tuần này',
            value: '${data.thisWeek}',
            detail: changeLabel,
            semantic:
                'Nốt tuần này ${data.thisWeek}'
                '${change == null ? '' : ', ${change >= 0 ? 'tăng' : 'giảm'} ${change.abs()} phần trăm so với tuần trước'}',
          ),
        ),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: _Number(
            label: 'Chuỗi ngày',
            value: '${data.streak}',
            detail: 'Kỷ lục ${data.record}',
            semantic: 'Chuỗi ngày ${data.streak}, kỷ lục ${data.record}',
          ),
        ),
      ],
    );
  }
}

class _Number extends StatelessWidget {
  const _Number({
    required this.label,
    required this.value,
    required this.semantic,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.bodyMedium),
            Text(value, style: theme.textTheme.headlineMedium),
            if (detail != null)
              Text(
                detail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard({
    required this.data,
    required this.days,
    required this.onDays,
  });

  final JourneyData data;
  final int days;
  final ValueChanged<int> onDays;

  static const double _chartHeight = 180;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = days == 7 ? data.energy7 : data.energy30;
    final withEnergy = points.where((p) => p.energy != null).length;
    final average = JourneyStats.average(points);
    final summary = average == null
        ? 'Chưa có tâm trạng nào trong $days ngày qua.'
        : 'Trung bình ${ViDateFormat.decimal(average)} / 5 trong $days ngày qua.';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Năng lượng mỗi ngày',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              DropdownButton<int>(
                value: days,
                underline: const SizedBox.shrink(),
                items: const <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(value: 7, child: Text('7 ngày')),
                  DropdownMenuItem<int>(value: 30, child: Text('30 ngày')),
                ],
                onChanged: (value) => onDays(value ?? days),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          if (withEnergy < JourneyData.minEnergyDays)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s24),
              child: Text(
                'Ghi thêm vài ngày để thấy xu hướng',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            Semantics(
              container: true,
              label: 'Năng lượng $days ngày. $summary',
              child: SizedBox(
                height: _chartHeight,
                child: LineChart(_chart(context, points)),
              ),
            ),
          const SizedBox(height: AppSpace.s8),
          Text(summary, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  LineChartData _chart(BuildContext context, List<EnergyPoint> points) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final axisStyle = theme.textTheme.labelSmall;
    final step = points.length > 7 ? 7 : 1;

    return LineChartData(
      minY: 1,
      maxY: 5,
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: scheme.outlineVariant, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 24,
            getTitlesWidget: (value, meta) =>
                Text('${value.toInt()}', style: axisStyle),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: step.toDouble(),
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= points.length) return const SizedBox.shrink();
              return Text(
                ViDateFormat.shortDate(points[i].day),
                style: axisStyle,
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => scheme.inverseSurface,
          getTooltipItems: (spots) => <LineTooltipItem>[
            for (final spot in spots)
              LineTooltipItem(
                '${ViDateFormat.shortDate(points[spot.x.toInt()].day)}\n'
                'Năng lượng ${ViDateFormat.decimal(spot.y)} · '
                '${points[spot.x.toInt()].count} nốt',
                theme.textTheme.labelMedium!.copyWith(
                  color: scheme.onInverseSurface,
                ),
              ),
          ],
        ),
      ),
      lineBarsData: <LineChartBarData>[
        LineChartBarData(
          spots: <FlSpot>[
            for (final (i, p) in points.indexed)
              p.energy == null
                  ? FlSpot.nullSpot
                  : FlSpot(i.toDouble(), p.energy!),
          ],
          isCurved: true,
          preventCurveOverShooting: true,
          color: scheme.primary,
          barWidth: 3,
        ),
      ],
    );
  }
}

class _WeekGoal extends StatelessWidget {
  const _WeekGoal({required this.data, required this.onOpen});

  final JourneyData data;
  final VoidCallback onOpen;

  static const double _ring = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Mục tiêu tuần ${data.weekGoalDays} trên 7 ngày. Mở Thẻ tuần',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Row(
              children: <Widget>[
                SizedBox.square(
                  dimension: _ring,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      CircularProgressIndicator(
                        value: data.weekGoalDays / 7,
                        strokeWidth: AppSpace.s8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      Center(
                        child: Text(
                          '${data.weekGoalDays}/7',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Mục tiêu tuần', style: theme.textTheme.titleMedium),
                      Text(
                        'Chạm để xem Thẻ tuần',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Cân bằng 5 điều tốt": thanh ngang theo loại + gợi ý loại đang ít.
class _Balance extends StatelessWidget {
  const _Balance({required this.data});

  final JourneyData data;

  static const double _labelWidth = 96;
  static const double _countWidth = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final max = data.balance.values.fold<int>(1, (a, b) => b > a ? b : a);
    final least = data.leastBalanced;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Cân bằng 5 điều tốt', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.s12),
          for (final (i, entry) in data.balance.entries.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s8),
              child: Semantics(
                label: '${entry.key.label}: ${entry.value} nốt',
                excludeSemantics: true,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: _labelWidth,
                      child: Text(
                        entry.key.label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: entry.value / max,
                          minHeight: AppSpace.s12,
                          color: colors.chart[i % colors.chart.length],
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s8),
                    SizedBox(
                      width: _countWidth,
                      child: Text(
                        '${entry.value}',
                        style: theme.textTheme.labelLarge,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            'Tháng này ít ${least.label} nhất. Thử thêm một nốt ${least.label} nhé.',
            style: theme.textTheme.bodySmall,
          ),
          if (least == GoodThing.vanDong || least == GoodThing.nguoiLa)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.challenges),
                child: const Text('Mở Thử thách'),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Bạn ghi nốt ngày nào?" trong 30 ngày gần nhất.
class _Weekdays extends StatelessWidget {
  const _Weekdays({required this.counts});

  final List<int> counts;

  static const double _barMax = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = counts.fold<int>(1, (a, b) => b > a ? b : a);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Bạn ghi nốt ngày nào?', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Semantics(
                    label: '${ViDateFormat.weekdayShort[i]}: ${counts[i]} nốt',
                    excludeSemantics: true,
                    child: Column(
                      children: <Widget>[
                        Text('${counts[i]}', style: theme.textTheme.labelSmall),
                        const SizedBox(height: AppSpace.s2),
                        Container(
                          height: AppSpace.s4 + _barMax * counts[i] / max,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.r4),
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
        ],
      ),
    );
  }
}
