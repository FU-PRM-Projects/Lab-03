import 'package:material_ui/material_ui.dart';

import '../models/streak.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Lời chúc mừng ngắn ở S04 khi nốt đầu tiên trong ngày nối dài chuỗi.
///
/// Chỉ hiện khi nốt vừa lưu là nốt đầu tiên của hôm nay — ghi thêm lần nữa
/// trong ngày không làm chuỗi dài thêm, nên không chúc lại.
class StreakCelebration extends StatelessWidget {
  const StreakCelebration({required this.streak, this.onShare, super.key});

  final StreakSummary streak;

  /// Có thì hiện nút "Chia sẻ chuỗi" ở cuối banner.
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final milestone = streak.isMilestone;
    final (title, subtitle) = milestone
        ? (
            'Mốc ${streak.current} ngày!',
            'Chuỗi ${streak.current} ngày liền có nốt. Tụi Nốt giữ chỗ cho ngày mai.',
          )
        : streak.current <= 1
        ? ('Chuỗi đã bắt đầu!', 'Ngày thứ 2 đang chờ bạn.')
        : ('Chuỗi ${streak.current} ngày!', 'Hôm nay đã nối thêm một ngày.');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.streakContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s12,
        ),
        child: Row(
          spacing: AppSpace.s12,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
              ),
              child: SizedBox.square(
                dimension: AppSpace.s24 + AppSpace.s16,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: colors.streak,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: '$title $subtitle',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s2,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: milestone
                            ? colors.primaryDark
                            : scheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onShare != null)
              IconButton(
                onPressed: onShare,
                tooltip: 'Chia sẻ chuỗi',
                icon: Icon(Icons.ios_share_rounded, color: colors.streak),
              ),
          ],
        ),
      ),
    );
  }
}
