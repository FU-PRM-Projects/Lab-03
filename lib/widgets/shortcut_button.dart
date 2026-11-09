import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// `lối tắt` trên S02 ("Dừng lại", "Thở 90 giây", "Thử thách"): vòng 56 nền
/// `surface-variant` + icon 24 màu on-surface, nhãn Label/14 SemiBold bên dưới,
/// rộng 96. [caption] là dòng phụ nói mục đích ("khi bồn chồn"), vì icon một
/// mình chưa đủ rõ (deviation D-25).
class ShortcutButton extends StatelessWidget {
  const ShortcutButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.caption,
    super.key,
  });

  /// Icon 24 dp của Figma (`assets/icons/`).
  final String iconAsset;
  final String label;

  /// Dòng phụ Caption/12 dưới nhãn, ví dụ "ghi 1 lần tự chủ".
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: caption == null ? label : '$label, $caption',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ConstrainedBox(
          // Tối đa 96; hàng 4 nút trên màn hẹp thì co lại cho vừa.
          constraints: const BoxConstraints(maxWidth: 96, minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.surface, scheme.surfaceContainerHighest],
                    ),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.08),
                        offset: const Offset(0, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: SizedBox.square(
                    dimension: AppSize.shortcut,
                    child: Center(
                      child: SvgPicture.asset(
                        iconAsset,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          scheme.onSurface,
                          BlendMode.srcIn,
                        ),
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (caption case final caption?)
                  Text(
                    caption,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
