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
              AppSpace.s10,
              AppSpace.s12,
              AppSpace.s10,
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
                // Bảy ngày nối thành một dải: ngày có nốt tô primary, các
                // ngày liền nhau liền thành "chuỗi"; mốc kế tiếp ghi ngay dưới.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.s6,
                  children: <Widget>[
                    _WeekStrip(days: streak.days),
                    Text(
                      milestone,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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

/// Dải 7 ngày gần nhất chia đều theo chiều ngang, chữ thứ nằm trong từng
/// đoạn: ngày có nốt là đoạn primary chữ trắng, ngày trống là đoạn `mono1`,
/// hôm nay chưa ghi có viền primary. Các ngày có nốt liền nhau nối thành một
/// dải liền, nhìn ra "chuỗi".
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days});

  final List<StreakDay> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: _Segment(
              label: ViDateFormat.weekdayShort[days[i].day.weekday - 1],
              filled: days[i].hasNote,
              today: days[i].isToday,
              // Nối liền với ngày bên cạnh khi cả hai đều có nốt.
              joinLeft: i > 0 && days[i].hasNote && days[i - 1].hasNote,
              joinRight:
                  i < days.length - 1 && days[i].hasNote && days[i + 1].hasNote,
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.filled,
    required this.today,
    required this.joinLeft,
    required this.joinRight,
  });

  final String label;
  final bool filled;
  final bool today;
  final bool joinLeft;
  final bool joinRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const round = Radius.circular(AppRadius.full);
    return Padding(
      padding: EdgeInsets.only(
        left: joinLeft ? 0 : AppSpace.s2,
        right: joinRight ? 0 : AppSpace.s2,
      ),
      child: Container(
        height: AppSpace.s20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? scheme.primary : AppPalette.mono1,
          border: today && !filled
              ? Border.all(color: scheme.primary, width: 1.5)
              : null,
          borderRadius: BorderRadius.horizontal(
            left: joinLeft ? Radius.zero : round,
            right: joinRight ? Radius.zero : round,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            height: 1,
            fontWeight: today ? FontWeight.w700 : null,
            color: filled
                ? scheme.onPrimary
                : today
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
