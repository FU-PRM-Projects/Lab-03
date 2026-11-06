import 'package:material_ui/material_ui.dart';

import '../models/streak.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Thẻ chuỗi ngày ở S02: số ngày liền có nốt, kỷ lục, 7 ngày gần nhất và
/// tiến độ tới mốc kế tiếp. Chạm để mở Thống kê (S11b).
///
/// Thẻ giữ một khối gọn để các lối tắt bên dưới vẫn với tới được trên màn
/// 360 × 800; chi tiết từng ngày nằm ở S11b.
class StreakCard extends StatelessWidget {
  const StreakCard({required this.streak, this.onTap, super.key});

  final StreakSummary streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.card);
    final title = streak.current == 0
        ? 'Bắt đầu chuỗi ngày'
        : 'Chuỗi ${streak.current} ngày';
    final status = switch ((streak.current, streak.activeToday)) {
      (0, _) => 'Ghi nốt để mở chuỗi',
      (_, true) => 'Mai ghi tiếp để nối chuỗi',
      _ => 'Ghi nốt để giữ chuỗi',
    };
    final next = streak.nextMilestone;
    final daysToNext = streak.daysToNext;
    final milestone = next == null
        ? 'Đã qua mốc ${StreakMilestones.days.last} ngày'
        : 'Còn $daysToNext ngày tới mốc $next ngày';

    return Semantics(
      button: onTap != null,
      label: <String>[
        title,
        if (streak.record > 0) 'Kỷ lục ${streak.record} ngày',
        status,
        milestone,
      ].join('. '),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: colors.streakContainer,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s8,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s12,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface,
                      ),
                      child: SizedBox.square(
                        dimension: AppSpace.s24 + AppSpace.s12,
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: colors.streak,
                          size: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.s2,
                        children: <Widget>[
                          Row(
                            spacing: AppSpace.s8,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (streak.record > 0)
                                Text(
                                  'Kỷ lục ${streak.record}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                  ],
                ),
                Row(
                  spacing: AppSpace.s8,
                  children: <Widget>[
                    _WeekDots(days: streak.days),
                    Expanded(
                      child: Text(
                        milestone,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r4),
                  child: LinearProgressIndicator(
                    value: streak.progressToNext,
                    minHeight: AppSpace.s4,
                    backgroundColor: scheme.surface,
                    semanticsLabel: milestone,
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

/// Dải 7 ngày gần nhất: chấm đầy khi ngày đó có nốt, vòng đậm cho hôm nay.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.days});

  final List<StreakDay> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    return Row(
      spacing: AppSpace.s4,
      children: <Widget>[
        for (final day in days)
          SizedBox.square(
            dimension: AppSpace.s20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: day.hasNote ? colors.streak : scheme.surface,
                border: day.isToday
                    ? Border.all(color: scheme.onSurface, width: 1.5)
                    : null,
              ),
              child: day.hasNote
                  ? Icon(Icons.check_rounded, size: 13, color: scheme.onSurface)
                  : null,
            ),
          ),
      ],
    );
  }
}
