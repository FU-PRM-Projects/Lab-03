import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Component `App bar` cho màn lồng: Default (nút Back + tiêu đề) và With
/// actions (ví dụ Sửa, Xoá ở S06).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({required this.title, this.actions, super.key});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(AppSize.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), actions: actions);
  }
}

/// Hàng đầu của 4 màn tab: tiêu đề bên trái, nút chuông và avatar bên phải.
class TabHeader extends StatelessWidget {
  const TabHeader({
    required this.title,
    required this.onNotifications,
    required this.onProfile,
    super.key,
  });

  final String title;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Figma `header`: cao 56, lề 16, tiêu đề Headline/28 Bold; chuông trong
    // vòng 48 nền `surface-variant`, avatar 48, cách nhau 8.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.s16,
        AppSpace.screen,
        0,
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          spacing: AppSpace.s8,
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: -0.56,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              onPressed: onNotifications,
              tooltip: 'Nhắc nhở',
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest,
                fixedSize: const Size.square(AppSize.minTouch),
              ),
              icon: SvgPicture.asset(
                'assets/icons/bell.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(scheme.onSurface, BlendMode.srcIn),
              ),
            ),
            Tooltip(
              message: 'Cài đặt',
              child: Semantics(
                button: true,
                label: 'Cài đặt',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onProfile,
                  customBorder: const CircleBorder(),
                  child: SvgPicture.asset(
                    'assets/icons/avatar.svg',
                    width: AppSize.minTouch,
                    height: AppSize.minTouch,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
