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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.s12,
        AppSpace.s8,
        AppSpace.s12,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.headlineMedium),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Nhắc nhở',
          ),
          IconButton(
            onPressed: onProfile,
            tooltip: 'Cài đặt',
            icon: CircleAvatar(
              radius: AppSize.avatar / 2,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: const Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
    );
  }
}
