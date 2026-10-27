import 'package:material_ui/material_ui.dart';

import '../models/mood.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'mascot.dart';

/// Component `Cell/Ngày năng lượng`: ô 48 × 56 của lịch tháng S11c.
///
/// [mood] `null` là "Chưa ghi"; [inMonth] `false` là ngày khác tháng (không
/// nền, chữ mờ).
class MoodDayCell extends StatelessWidget {
  const MoodDayCell({
    required this.day,
    required this.semanticDate,
    this.mood,
    this.inMonth = true,
    this.onTap,
    super.key,
  });

  final int day;

  /// Ngày đọc cho trình đọc màn hình, ví dụ "24 tháng 10".
  final String semanticDate;
  final Mood? mood;
  final bool inMonth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    final Color? background = !inMonth
        ? null
        : mood == null
        ? scheme.surfaceContainerHighest
        : colors.mood(mood!);

    return Semantics(
      button: onTap != null,
      label: '$semanticDate, ${mood?.label ?? 'chưa ghi'}',
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox.fromSize(
        size: AppSize.moodDayCell,
        child: Material(
          color: background ?? const Color(0x00000000),
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$day',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: inMonth ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
                if (inMonth && mood != null) ...<Widget>[
                  const SizedBox(height: AppSpace.s2),
                  Mascot(state: mood!.mascot, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Component `Cell/Pixel năm`: ô nhỏ chế độ Năm, chỉ trang trí (có chú giải
/// chữ đi kèm).
class MoodPixel extends StatelessWidget {
  const MoodPixel({this.mood, this.hasDay = true, super.key});

  final Mood? mood;

  /// `false` cho ô không có ngày (ví dụ 30/2).
  final bool hasDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSize.moodPixel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: !hasDay
                ? const Color(0x00000000)
                : mood == null
                ? scheme.surfaceContainerHighest
                : AppColors.of(context).mood(mood!),
            borderRadius: BorderRadius.circular(AppRadius.r4 / 2),
          ),
        ),
      ),
    );
  }
}
