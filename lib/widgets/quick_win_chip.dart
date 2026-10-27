import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Component `Chip/Chiến thắng nhanh` ở S03b, S09, S10: Default / Selected,
/// cao 48 dp.
class QuickWinChip extends StatelessWidget {
  const QuickWinChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.minTouch),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
