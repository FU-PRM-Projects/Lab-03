import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Lối tắt tròn trên S02 ("Dừng lại", "Thở 90 giây", "Thử thách"): vòng 56
/// + icon, nhãn bên dưới, vùng chạm ≥ 56 × 72.
class ShortcutButton extends StatelessWidget {
  const ShortcutButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
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
          constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerLow,
                  ),
                  child: SizedBox.square(
                    dimension: AppSize.shortcut,
                    child: Icon(icon, color: scheme.primary),
                  ),
                ),
                const SizedBox(height: AppSpace.s6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
