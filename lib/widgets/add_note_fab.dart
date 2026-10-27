import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Nút nổi + ở S05, S07, S11, nằm trên thanh tab nổi; mở S03.
class AddNoteFab extends StatelessWidget {
  const AddNoteFab({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSize.navBarHeight + AppSize.navBarBottomGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppElevation.fab(scheme.shadow),
        ),
        child: FloatingActionButton(
          onPressed: onPressed,
          tooltip: 'Ghi nốt',
          elevation: AppElevation.flat,
          highlightElevation: AppElevation.flat,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
