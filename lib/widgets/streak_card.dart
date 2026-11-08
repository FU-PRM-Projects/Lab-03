import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/streak.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/vi_date_format.dart';

/// Thẻ chuỗi ngày ở S02: số ngày liền có nốt, kỷ lục, 7 ngày gần nhất và
/// tiến độ tới mốc kế tiếp. Chạm để mở Thống kê (S11b).
///
/// Theo phong cách của app (góp ý của giảng viên): nền lavender như hũ ở trên;
/// ngọn lửa vẽ phẳng trong ô trắng (xám khi chưa có chuỗi) thay cho icon lửa
/// của Material, không trùng mascot ở hũ ngay phía trên; 7 ô ngày chia đều;
/// màu primary cho phần "đã làm" để thẻ không lệch tông với nút Ghi nốt. Thẻ
/// vẫn gọn để các lối tắt còn với tới trên màn 360 × 800.
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
    // Ngọn lửa vẽ phẳng theo bảng màu app (heat4 / heat3); chưa có chuỗi thì
    // lửa xám, "đã tắt".
    final flame = streak.current == 0
        ? 'assets/icons/streak-flame-off.svg'
        : 'assets/icons/streak-flame.svg';

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
              spacing: AppSpace.s6,
              children: <Widget>[
                Row(
                  spacing: AppSpace.s12,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface,
                      ),
                      child: SizedBox.square(
                        dimension: 36,
                        child: Center(
                          child: SvgPicture.asset(
                            flame,
                            width: 20,
                            height: 24,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
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
                // Bảy ô tròn chia đều; mốc kế tiếp ghi ngay dưới.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.s2,
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

/// Dải 7 ngày gần nhất: 7 ô tròn chia đều hết chiều ngang để không bị sát
/// nhau. Ngày có nốt là ô primary có dấu tích trắng; ngày trống là ô trắng ghi
/// chữ thứ (T2…CN); hôm nay có thêm vòng primary bên ngoài.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days});

  final List<StreakDay> days;

  /// Đường kính ô.
  static const double _dot = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final day in days)
          Container(
            width: _dot,
            height: _dot,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: day.hasNote ? scheme.primary : scheme.surface,
              border: day.isToday
                  ? Border.all(
                      color: day.hasNote
                          ? scheme.primaryContainer
                          : scheme.primary,
                      width: 2,
                      strokeAlign: day.hasNote
                          ? BorderSide.strokeAlignOutside
                          : BorderSide.strokeAlignInside,
                    )
                  : null,
            ),
            child: day.hasNote
                ? SvgPicture.asset(
                    'assets/icons/check-bold.svg',
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      scheme.onPrimary,
                      BlendMode.srcIn,
                    ),
                    excludeFromSemantics: true,
                  )
                : Text(
                    ViDateFormat.weekdayShort[day.day.weekday - 1],
                    style: theme.textTheme.labelSmall?.copyWith(
                      height: 1,
                      fontWeight: day.isToday ? FontWeight.w700 : null,
                      color: day.isToday
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
          ),
      ],
    );
  }
}
