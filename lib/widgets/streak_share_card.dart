import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/streak.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/vi_date_format.dart';

/// Thẻ dọc 9:16 để chia sẻ chuỗi ngày. Không chứa nội dung nốt hay thông tin
/// cá nhân — chỉ con số chuỗi, kỷ lục, mốc và 7 ngày gần nhất.
class StreakShareCard extends StatelessWidget {
  const StreakShareCard({required this.streak, required this.date, super.key});

  final StreakSummary streak;

  /// Ngày tạo thẻ (lấy từ đồng hồ của app để test ổn định).
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final milestone = streak.isMilestone;
    final next = streak.nextMilestone;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colors.streakContainer,
              scheme.surface,
              colors.streakContainer,
            ],
            stops: const <double>[0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -36,
              top: -18,
              child: Opacity(
                opacity: 0.55,
                child: SvgPicture.asset(
                  'assets/illustrations/confetti.svg',
                  width: 190,
                  height: 112,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'NỐT',
                        style: theme.textTheme.labelLarge?.copyWith(
                          letterSpacing: 3,
                          color: scheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: colors.streak,
                        size: 22,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surface,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: colors.streak.withValues(alpha: 0.25),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: SizedBox.square(
                            dimension: 72,
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: colors.streak,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.s16),
                        Text(
                          '${streak.current}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 96,
                            height: 1,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          'ngày liền có nốt',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _DayDots(days: streak.days),
                  const SizedBox(height: AppSpace.s20),
                  Row(
                    spacing: AppSpace.s12,
                    children: <Widget>[
                      Expanded(
                        child: _Stat(
                          label: 'Kỷ lục',
                          value: '${streak.record} ngày',
                          color: AppPalette.tintBlue,
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: milestone ? 'Mốc' : 'Mốc kế',
                          value: milestone
                              ? '${streak.current} ngày'
                              : next == null
                              ? 'Đã đủ'
                              : '$next ngày',
                          color: AppPalette.tintOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s16),
                  Text(
                    'Mỗi ngày một nốt tích cực.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    ViDateFormat.dayHeader(date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _DayDots extends StatelessWidget {
  const _DayDots({required this.days});

  final List<StreakDay> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final label = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );

    return Row(
      children: <Widget>[
        for (final day in days)
          Expanded(
            child: Column(
              spacing: AppSpace.s4,
              children: <Widget>[
                Text(
                  ViDateFormat.weekdayShort[day.day.weekday - 1],
                  style: label,
                  maxLines: 1,
                  softWrap: false,
                ),
                SizedBox.square(
                  dimension: AppSpace.s24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: day.hasNote ? colors.streak : scheme.surface,
                      border: day.isToday
                          ? Border.all(color: scheme.onSurface, width: 1.5)
                          : null,
                    ),
                    child: day.hasNote
                        ? Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: scheme.onSurface,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
