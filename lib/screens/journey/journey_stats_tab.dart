import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
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

  /// Figma S11b: các thẻ cách nhau 14.
  static const double _gap = AppSpace.s14;

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
            const SizedBox(height: _gap),
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
            const SizedBox(height: _gap),
            _Balance(data: value),
            const SizedBox(height: _gap),
            _Weekdays(counts: value.byWeekday),
          ];
          const padding = EdgeInsets.fromLTRB(
            AppSpace.screen,
            _gap,
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
              const SizedBox(height: _gap),
              ...right,
            ],
          );
        },
      ),
    };
  }
}

/// Khung thẻ dùng chung của Thống kê (Figma `Chart card`): nền surface-card,
/// viền outline-variant, bo 20, bóng mềm.
class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = AppSpace.s16,
    this.radius = 20,
  });

  final Widget child;
  final double padding;
  final double radius;

  static const Color _shadow = Color(0x1A1A1A33);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: _shadow, offset: Offset(0, 4), blurRadius: 12),
        ],
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

/// Figma `CardHeader`: tiêu đề Title/17 Bold và dòng phụ Label/13.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      spacing: AppSpace.s8,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s2,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppTextStyles.of(context).title17Bold
                      .copyWith(letterSpacing: -0.17),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Figma `CardFooter`: dòng kết luận Label/14 SemiBold và chú thích Caption/12.
class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s2,
      children: <Widget>[
        Text(title, style: theme.textTheme.labelLarge),
        Text(
          caption,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s12,
        children: <Widget>[
          Expanded(
            child: _Number(
              label: 'Nốt tuần này',
              value: '${data.thisWeek}',
              badge: changeLabel,
              badgeColor: AppPalette.tintGreen,
              caption: 'so với tuần trước',
              semantic:
                  'Nốt tuần này ${data.thisWeek}'
                  '${change == null ? '' : ', ${change >= 0 ? 'tăng' : 'giảm'} ${change.abs()} phần trăm so với tuần trước'}',
            ),
          ),
          Expanded(
            child: _Number(
              label: 'Chuỗi ngày',
              value: '${data.streak}',
              badge: 'Kỷ lục ${data.record}',
              badgeColor: AppPalette.tintOrange,
              caption: 'ngày liền có nốt',
              semantic: 'Chuỗi ngày ${data.streak}, kỷ lục ${data.record}',
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `Stat`: nhãn, số Headline/28 kèm badge, chú thích.
class _Number extends StatelessWidget {
  const _Number({
    required this.label,
    required this.value,
    required this.caption,
    required this.semantic,
    required this.badgeColor,
    this.badge,
  });

  final String label;
  final String value;
  final String? badge;
  final Color badgeColor;
  final String caption;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: _Card(
        padding: AppSpace.s14,
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s4,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: muted,
              ),
            ),
            Wrap(
              spacing: AppSpace.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: -0.56,
                  ),
                ),
                if (badge != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s8,
                        vertical: 3,
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `Chart card · Năng lượng mỗi ngày`: vùng tô dưới đường cong, lưới
/// đứt, tooltip luôn hiện ở một ngày (mặc định ngày gần nhất có tâm trạng,
/// chạm để đổi) và dòng so sánh với khoảng trước.
class _EnergyCard extends StatefulWidget {
  const _EnergyCard({
    required this.data,
    required this.days,
    required this.onDays,
  });

  final JourneyData data;
  final int days;
  final ValueChanged<int> onDays;

  @override
  State<_EnergyCard> createState() => _EnergyCardState();
}

class _EnergyCardState extends State<_EnergyCard> {
  static const double _chartHeight = 124;

  /// Ngày đang mở tooltip (chỉ số trong danh sách ngày); `null` là mặc định.
  int? _selected;

  @override
  void didUpdateWidget(_EnergyCard old) {
    super.didUpdateWidget(old);
    if (old.days != widget.days) _selected = null;
  }

  List<EnergyPoint> get _points =>
      widget.days == 7 ? widget.data.energy7 : widget.data.energy30;

  /// "↑ Tăng 0,4 điểm so với 30 ngày trước", hoặc trung bình khi khoảng trước
  /// chưa có tâm trạng nào.
  String _summary(double? average) {
    final days = widget.days;
    if (average == null) return 'Chưa có tâm trạng nào trong $days ngày qua.';
    final previous = days == 7
        ? widget.data.previousEnergy7
        : widget.data.previousEnergy30;
    if (previous == null) {
      return 'Trung bình ${ViDateFormat.decimal(average)} / 5 '
          'trong $days ngày qua.';
    }
    // Làm tròn 1 chữ số trước khi so để "0,0" không thành tăng / giảm.
    final diff = ((average - previous) * 10).round() / 10;
    if (diff == 0) return 'Giữ nguyên so với $days ngày trước';
    return diff > 0
        ? '↑ Tăng ${ViDateFormat.decimal(diff)} điểm so với $days ngày trước'
        : '↓ Giảm ${ViDateFormat.decimal(-diff)} điểm so với $days ngày '
              'trước';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = widget.days;
    final points = _points;
    final withEnergy = <int>[
      for (final (i, p) in points.indexed)
        if (p.energy != null) i,
    ];
    final average = JourneyStats.average(points);
    final summary = _summary(average);
    final axisStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    // Trục X: 4 mốc trải đều (Figma `trục X`).
    final ticks = <int>{
      for (var k = 0; k < 4; k++) ((points.length - 1) * k / 3).round(),
    };

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s12,
        children: <Widget>[
          _CardHeader(
            title: 'Năng lượng mỗi ngày',
            subtitle: '$days ngày qua · thang 1–5',
            trailing: _RangeSelect(days: days, onDays: widget.onDays),
          ),
          if (withEnergy.length < JourneyData.minEnergyDays)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s24),
              child: Text(
                'Ghi thêm vài ngày để thấy xu hướng',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else ...<Widget>[
            Semantics(
              container: true,
              label:
                  'Năng lượng $days ngày. Trung bình '
                  '${ViDateFormat.decimal(average!)} / 5. $summary',
              child: SizedBox(
                height: _chartHeight,
                child: LineChart(
                  _chart(
                    context,
                    points,
                    withEnergy,
                    _selected ?? withEnergy.last,
                  ),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (final i in ticks)
                    Text(
                      ViDateFormat.shortDate(points[i].day),
                      style: axisStyle,
                    ),
                ],
              ),
            ),
          ],
          _CardFooter(
            title: summary,
            caption: 'Tính từ tâm trạng bạn chọn mỗi lần ghi nốt',
          ),
        ],
      ),
    );
  }

  /// [withEnergy] là các ngày có tâm trạng; ngày không ghi bị bỏ qua để
  /// đường nối liền như Figma. [selected] là ngày đang mở tooltip.
  LineChartData _chart(
    BuildContext context,
    List<EnergyPoint> points,
    List<int> withEnergy,
    int selected,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tooltipStyle = theme.textTheme.labelSmall!;
    final spotIndex = withEnergy.indexOf(selected);

    final bar = LineChartBarData(
      spots: <FlSpot>[
        for (final i in withEnergy) FlSpot(i.toDouble(), points[i].energy!),
      ],
      // Đường mềm như sóng (Figma); khung đã chừa 0,4 nên vượt nhẹ không bị
      // cắt.
      isCurved: true,
      curveSmoothness: 0.3,
      color: scheme.primary,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      showingIndicators: <int>[if (spotIndex >= 0) spotIndex],
      // Figma `area`: vùng dưới đường tô primary nhạt dần.
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            scheme.primary.withValues(alpha: 0.28),
            scheme.primary.withValues(alpha: 0.02),
          ],
        ),
      ),
    );

    // Tooltip nằm phía còn chỗ của ngày đang chọn để không che chấm tròn.
    final tooltipOnLeft = selected > (points.length - 1) / 2;

    return LineChartData(
      // Chừa 0,4 trên dưới để đường ở mức 1 hoặc 5 không dính mép khung.
      minY: 0.6,
      maxY: 5.4,
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      // Figma `grid`: 3 vạch đứt ở mức 1, 3, 5.
      gridData: const FlGridData(show: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: <HorizontalLine>[
          for (final y in <double>[1, 3, 5])
            HorizontalLine(
              y: y,
              color: scheme.outlineVariant,
              strokeWidth: 1,
              dashArray: const <int>[4, 4],
            ),
        ],
      ),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(show: false),
      showingTooltipIndicators: <ShowingTooltipIndicators>[
        if (spotIndex >= 0)
          ShowingTooltipIndicators(<LineBarSpot>[
            LineBarSpot(bar, 0, bar.spots[spotIndex]),
          ]),
      ],
      lineTouchData: LineTouchData(
        // Tooltip luôn hiện; chạm hoặc kéo trên biểu đồ để đổi ngày.
        handleBuiltInTouches: false,
        touchCallback: (event, response) {
          final spot = response?.lineBarSpots?.firstOrNull;
          if (spot == null || !event.isInterestedForInteractions) return;
          final day = spot.x.toInt();
          if (day != _selected) setState(() => _selected = day);
        },
        getTouchedSpotIndicator: (bar, indexes) => <TouchedSpotIndicatorData>[
          for (final _ in indexes)
            TouchedSpotIndicatorData(
              FlLine(
                color: scheme.onSurfaceVariant,
                strokeWidth: 1,
                dashArray: const <int>[3, 3],
              ),
              FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 5,
                      color: scheme.surface,
                      strokeWidth: 2.5,
                      strokeColor: scheme.primary,
                    ),
              ),
            ),
        ],
        touchTooltipData: LineTouchTooltipData(
          tooltipHorizontalAlignment: tooltipOnLeft
              ? FLHorizontalAlignment.left
              : FLHorizontalAlignment.right,
          tooltipHorizontalOffset: tooltipOnLeft ? -12 : 12,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) => scheme.surfaceContainerLow,
          tooltipBorder: BorderSide(color: scheme.outlineVariant),
          tooltipBorderRadius: BorderRadius.circular(10),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: AppSpace.s8,
          ),
          getTooltipItems: (spots) => <LineTooltipItem>[
            for (final spot in spots)
              LineTooltipItem(
                '${ViDateFormat.dayHeader(points[spot.x.toInt()].day)}\n',
                tooltipStyle.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.start,
                children: <TextSpan>[
                  TextSpan(
                    text: '■ ',
                    style: tooltipStyle.copyWith(color: scheme.primary),
                  ),
                  TextSpan(
                    text: 'Năng lượng ',
                    style: tooltipStyle.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '${ViDateFormat.decimal(spot.y)}/5\n',
                    style: tooltipStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: '■ ',
                    style: tooltipStyle.copyWith(color: AppPalette.heat2),
                  ),
                  TextSpan(
                    text: 'Số nốt ',
                    style: tooltipStyle.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '${points[spot.x.toInt()].count}',
                    style: tooltipStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ),
      lineBarsData: <LineChartBarData>[bar],
    );
  }
}

/// Figma `Select · khoảng`: ô viền bo 10 "30 ngày ▾", mở menu 7 / 30 ngày.
class _RangeSelect extends StatelessWidget {
  const _RangeSelect({required this.days, required this.onDays});

  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopupMenuButton<int>(
      tooltip: 'Đổi khoảng thời gian',
      initialValue: days,
      onSelected: onDays,
      itemBuilder: (context) => const <PopupMenuEntry<int>>[
        PopupMenuItem<int>(value: 7, child: Text('7 ngày')),
        PopupMenuItem<int>(value: 30, child: Text('30 ngày')),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.minTouch),
        child: Center(
          widthFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text.rich(
                TextSpan(
                  text: '$days ngày ',
                  style: theme.textTheme.labelMedium,
                  children: <TextSpan>[
                    TextSpan(
                      text: '▾',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma `Radial chart · mục tiêu tuần`: vòng 76 và lời nhắc giữ chuỗi.
class _WeekGoal extends StatelessWidget {
  const _WeekGoal({required this.data, required this.onOpen});

  final JourneyData data;
  final VoidCallback onOpen;

  static const double _ring = 76;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = AppTextStyles.of(context).title17Bold
        .copyWith(letterSpacing: -0.17);
    final days = data.weekGoalDays;
    final left = 7 - days;

    return Semantics(
      button: true,
      label: 'Mục tiêu tuần $days trên 7 ngày. Mở Thẻ tuần',
      excludeSemantics: true,
      child: _Card(
        padding: 0,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s16),
              child: Row(
                spacing: AppSpace.s16,
                children: <Widget>[
                  SizedBox.square(
                    dimension: _ring,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        CircularProgressIndicator(
                          value: days / 7,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                        Center(child: Text('$days/7', style: title)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.s2,
                      children: <Widget>[
                        Text('Mục tiêu tuần', style: title),
                        Text(
                          left > 0
                              ? '$days trên 7 ngày có nốt. Thêm $left ngày '
                                    'nữa là giữ chuỗi!'
                              : 'Đủ 7 ngày có nốt. Tuần này tuyệt lắm!',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma `Radar chart`: "Cân bằng 5 điều tốt", mỗi đỉnh là một loại kèm số.
class _Balance extends StatelessWidget {
  const _Balance({required this.data});

  final JourneyData data;

  static const double _chartHeight = 170;

  /// Chỗ cho nhãn 2 dòng (Caption/12) quanh biểu đồ radar.
  static const double _labelRoom = 36;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final least = data.leastBalanced;
    final entries = data.balance.entries.toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s12,
        children: <Widget>[
          const _CardHeader(
            title: 'Cân bằng 5 điều tốt',
            subtitle: 'Tháng này · số nốt mỗi loại',
          ),
          Semantics(
            container: true,
            label: entries
                .map((e) => '${e.key.label}: ${e.value} nốt')
                .join(', '),
            excludeSemantics: true,
            // fl_chart vẽ nhãn đỉnh ra ngoài khung biểu đồ: chừa lề để nhãn
            // trên cùng ("Chiến thắng" + số, 2 dòng) không đè lên tiêu đề thẻ
            // và nhãn hai đỉnh dưới không đè lên dòng kết luận.
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _labelRoom,
                _labelRoom,
                _labelRoom,
                AppSpace.s24,
              ),
              child: SizedBox(
                height: _chartHeight,
                child: RadarChart(
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    tickCount: 3,
                    ticksTextStyle: const TextStyle(
                      color: Color(0x00000000),
                      fontSize: 1,
                    ),
                    radarBorderData: BorderSide(color: scheme.outlineVariant),
                    gridBorderData: BorderSide(color: scheme.outlineVariant),
                    tickBorderData: BorderSide(color: scheme.outlineVariant),
                    titlePositionPercentageOffset: 0.18,
                    titleTextStyle: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    getTitle: (index, angle) => RadarChartTitle(
                      text:
                          '${entries[index].key.label}\n${entries[index].value}',
                    ),
                    dataSets: <RadarDataSet>[
                      RadarDataSet(
                        dataEntries: <RadarEntry>[
                          for (final e in entries)
                            RadarEntry(value: e.value.toDouble()),
                        ],
                        fillColor: scheme.primary.withValues(alpha: 0.22),
                        borderColor: scheme.primary,
                        borderWidth: 2,
                        entryRadius: 3.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _CardFooter(
            title: '${least.label} đang ít nhất (${data.balance[least]} nốt)',
            caption: 'Thử thêm một nốt ${least.label} tuần này nhé.',
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

/// "Bạn ghi nốt ngày nào?" trong 30 ngày gần nhất (Figma `Bar chart`).
class _Weekdays extends StatelessWidget {
  const _Weekdays({required this.counts});

  final List<int> counts;

  static const double _barMax = 110;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = counts.fold<int>(1, (a, b) => b > a ? b : a);
    final caption = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s12,
        children: <Widget>[
          const _CardHeader(
            title: 'Bạn ghi nốt ngày nào?',
            subtitle: '30 ngày gần đây',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Semantics(
                    label: '${ViDateFormat.weekdayShort[i]}: ${counts[i]} nốt',
                    excludeSemantics: true,
                    child: Column(
                      spacing: AppSpace.s4,
                      children: <Widget>[
                        Text('${counts[i]}', style: caption),
                        Container(
                          width: 24,
                          height: AppSpace.s4 + _barMax * counts[i] / max,
                          // Tím nhạt mono/3: khác hẳn nút "+" primary nổi
                          // phía trên.
                          decoration: const BoxDecoration(
                            color: AppPalette.mono3,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        Text(ViDateFormat.weekdayShort[i], style: caption),
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
