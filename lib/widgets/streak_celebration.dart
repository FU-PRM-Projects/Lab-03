import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
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
    final milestone = streak.isMilestone;
    final (title, subtitle) = milestone
        ? (
            'Mốc ${streak.current} ngày!',
            'Chuỗi ${streak.current} ngày liền có nốt. Tụi Nốt giữ chỗ cho ngày mai.',
          )
        : streak.current <= 1
        ? ('Chuỗi đã bắt đầu!', 'Ngày thứ 2 đang chờ bạn.')
        : ('Chuỗi ${streak.current} ngày!', 'Hôm nay đã nối thêm một ngày.');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1250),
      builder: (context, progress, _) {
        final bounce = math.sin(math.pi * (progress * 2).clamp(0, 1));
        final glow = math.sin(math.pi * progress);
        return Stack(
          children: [
            _banner(context, title, subtitle, bounce, glow),
            if (milestone && progress > 0 && progress < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: glow,
                    child: Transform.scale(
                      scale: 0.75 + progress * 0.45,
                      child: SvgPicture.asset(
                        'assets/illustrations/confetti.svg',
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _banner(
    BuildContext context,
    String title,
    String subtitle,
    double bounce,
    double glow,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
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
                borderRadius: BorderRadius.circular(AppRadius.card),
                color: scheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colors.streak.withValues(alpha: glow * 0.55),
                    blurRadius: 12 * glow,
                    spreadRadius: 3 * glow,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -6 * bounce),
                      child: Transform.scale(
                        scale: 1 + 0.22 * bounce,
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: colors.streak,
                          size: 24,
                        ),
                      ),
                    ),
                    Text('Hôm nay', style: theme.textTheme.labelSmall),
                  ],
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
                        color: streak.isMilestone
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
