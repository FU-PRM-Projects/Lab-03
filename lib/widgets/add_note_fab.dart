import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Nút nổi + ở S05, S07, S11, nằm trên thanh tab nổi; mở S03.
class AddNoteFab extends StatelessWidget {
  const AddNoteFab({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Thanh tab cách đáy max(vùng cử chỉ, 18) (SafeArea `minimum`); nút nằm
    // trên thanh tab 12 như Figma. Scaffold đã đặt nút cách đáy 16. Đọc vùng
    // cử chỉ từ View vì màn tab nhận MediaQuery đã bỏ phần đệm đáy.
    final view = View.of(context);
    final navBottom = math.max(
      view.viewPadding.bottom / view.devicePixelRatio,
      AppSize.navBarBottomGap,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom:
            navBottom +
            AppSize.navBarHeight +
            AppSpace.s12 -
            kFloatingActionButtonMargin,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 10,
            ),
          ],
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
