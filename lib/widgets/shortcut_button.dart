import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// `lối tắt` trên S02 ("Dừng lại", "Thở 90 giây", "Thử thách"): vòng 56 nền
/// `surface-variant` + icon 24 màu on-surface, nhãn Label/14 SemiBold bên dưới,
/// rộng 96.
class ShortcutButton extends StatelessWidget {
  const ShortcutButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    super.key,
  });

  /// Icon 24 dp của Figma (`assets/icons/`).
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 96).copyWith(
            minHeight: 72,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerHighest,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
