import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/streak.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/vi_date_format.dart';
import 'mascot.dart';

/// Thẻ chuỗi ngày ở S02: số ngày liền có nốt, kỷ lục, 7 ngày gần nhất và
/// tiến độ tới mốc kế tiếp. Chạm để mở Thống kê (S11b).
///
/// Theo phong cách của app (góp ý của giảng viên): nền lavender như hũ ở trên,
/// Tụi Nốt (đổi nét mặt theo chuỗi) thay cho icon lửa của Material, dải 7 ngày có nhãn thứ như lịch
/// S11c, và chỉ dùng màu primary cho phần "đã làm" để thẻ không lệch tông cam
/// với nút Ghi nốt bên dưới. Thẻ vẫn gọn để các lối tắt còn với tới trên màn
/// 360 × 800.
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
    // Nét mặt theo chuỗi: chưa có thì Nốt ngủ chờ, hôm nay đã ghi thì Nốt vui,
    // chưa ghi thì Nốt đợi. Không dùng Nốt Cháy (mặt nhăn, dễ hiểu là kiệt sức).
    final face = switch ((streak.current, streak.activeToday)) {
      (0, _) => MascotState.ngu,
      (_, true) => MascotState.xong,
      _ => MascotState.doi,
    };

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
        color: colors.tintLavender,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s16,
              AppSpace.s12,
              AppSpace.s12,
              AppSpace.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s8,
              children: <Widget>[
                Row(
                  spacing: AppSpace.s12,
                  children: <Widget>[
                    Mascot(state: face, size: 36),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.s2,
                        children: <Widget>[
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    if (streak.record > 0)
                      _RecordPill(label: 'Kỷ lục ${streak.record}'),
                    if (onTap != null)
                      SvgPicture.asset(
                        'assets/icons/chevron-right.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          scheme.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                        excludeFromSemantics: true,
                      ),
                  ],
                ),
                Row(
                  spacing: AppSpace.s8,
                  children: <Widget>[
                    _WeekStrip(days: streak.days),
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
                    color: scheme.primary,
                    backgroundColor: AppPalette.mono1,
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

/// Nhãn "Kỷ lục N" dạng viên thuốc trắng, như các nhãn phụ khác của app.
class _RecordPill extends StatelessWidget {
  const _RecordPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s8,
          vertical: AppSpace.s4,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Dải 7 ngày gần nhất, chữ thứ nằm trong chấm: chấm primary có dấu tích khi
/// ngày đó có nốt, viền primary cho hôm nay chưa ghi, chấm trắng cho ngày trống.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days});

  final List<StreakDay> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      spacing: AppSpace.s4,
      children: <Widget>[
        for (final day in days)
          SizedBox.square(
            dimension: AppSpace.s20 + AppSpace.s2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: day.hasNote ? scheme.primary : scheme.surface,
                border: day.isToday && !day.hasNote
                    ? Border.all(color: scheme.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: day.hasNote
                    ? SvgPicture.asset(
                        'assets/icons/check-bold.svg',
                        width: 12,
                        height: 12,
                        colorFilter: ColorFilter.mode(
                          scheme.onPrimary,
                          BlendMode.srcIn,
                        ),
                        excludeFromSemantics: true,
                      )
                    : Text(
                        ViDateFormat.weekdayShort[day.day.weekday - 1],
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          height: 1,
                          fontWeight: day.isToday ? FontWeight.w700 : null,
                          color: day.isToday
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
