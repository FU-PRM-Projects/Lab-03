import 'package:material_ui/material_ui.dart';

import '../models/mood.dart';
import '../theme/app_tokens.dart';
import 'mascot.dart';

/// Component `MoodOption`: ô tâm trạng 96 × 116 ở S03a, Default / Selected.
///
/// Mỗi ô có mặt mascot + chữ, nên tâm trạng không chỉ báo bằng màu.
class MoodOption extends StatelessWidget {
  const MoodOption({
    required this.mood,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Tâm trạng ${mood.label}',
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox.fromSize(
        size: AppSize.moodOption,
        child: Material(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? scheme.primary : scheme.surfaceContainerLow,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Figma: mascot 53.76 × 60.48, cách nhãn 8.
                Mascot(state: mood.mascot, size: 60.48),
                const SizedBox(height: AppSpace.s8),
                Text(
                  mood.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
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
