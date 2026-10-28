import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Component `Sticker/Mốc`: nhãn dán tháng, Đã mở / Chưa mở.
class MilestoneSticker extends StatelessWidget {
  const MilestoneSticker({
    required this.label,
    required this.unlocked,
    super.key,
  });

  /// Ví dụ "Th10".
  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: 'Nhãn dán $label, ${unlocked ? 'đã mở' : 'chưa mở'}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked ? scheme.primary : scheme.surfaceContainerHighest,
            ),
            child: SizedBox.square(
              dimension: AppSize.shortcut,
              child: Icon(
                unlocked ? Icons.star : Icons.lock_outline,
                color: unlocked ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
