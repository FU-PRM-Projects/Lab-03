import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import '../router.dart';
import '../viewmodels/admin_view_models.dart';
import '../viewmodels/session_view_model.dart';
import '../widgets/admin_widgets.dart';

class _Destination {
  const _Destination(
    this.path,
    this.label,
    this.icon, {
    this.adminOnly = false,
  });

  final String path;
  final String label;
  final IconData icon;
  final bool adminOnly;
}

const List<_Destination> _destinations = <_Destination>[
  _Destination(AdminRoutes.dashboard, 'Tổng quan', Icons.insights_outlined),
  _Destination(AdminRoutes.catalog, 'Kho thẻ', Icons.style_outlined),
  _Destination(AdminRoutes.review, 'Hàng chờ duyệt', Icons.fact_check_outlined),
  _Destination(AdminRoutes.announcements, 'Thông báo', Icons.campaign_outlined),
  _Destination(
    AdminRoutes.users,
    'Người dùng',
    Icons.group_outlined,
    adminOnly: true,
  ),
];

/// Khung màn rộng: thanh điều hướng bên trái (NavigationRail), nội dung bên
/// phải. Dưới 900 px thanh điều hướng thu gọn chỉ còn icon.
class AdminShell extends ConsumerWidget {
  const AdminShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final staff = session is StaffSession ? session : null;
    final destinations = <_Destination>[
      for (final d in _destinations)
        if (!d.adminOnly || (staff?.isAdmin ?? false)) d,
    ];
    final selected = destinations.indexWhere(
      (d) => location.startsWith(d.path),
    );
    final pending = ref
        .watch(submissionsProvider(SubmissionStatus.pending))
        .value
        ?.length;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          body: Row(
            children: <Widget>[
              NavigationRail(
                extended: wide,
                minExtendedWidth: 232,
                backgroundColor: scheme.surfaceContainerLow,
                selectedIndex: selected < 0 ? null : selected,
                onDestinationSelected: (i) => context.go(destinations[i].path),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const AdminMascot('thong-tha', size: 40),
                      if (wide) ...<Widget>[
                        const SizedBox(width: AppSpace.s8),
                        Text('Nốt admin', style: text.titleMedium),
                      ],
                    ],
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.s16),
                      child: _Account(staff: staff, wide: wide),
                    ),
                  ),
                ),
                destinations: <NavigationRailDestination>[
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: d.path == AdminRoutes.review && (pending ?? 0) > 0
                          ? Badge.count(count: pending!, child: Icon(d.icon))
                          : Icon(d.icon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _Account extends ConsumerWidget {
  const _Account({required this.staff, required this.wide});

  final StaffSession? staff;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final signOut = ref.read(signInViewModelProvider.notifier).signOut;
    if (!wide) {
      return IconButton(
        tooltip: 'Đăng xuất',
        onPressed: signOut,
        icon: const Icon(Icons.logout),
      );
    }
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            staff?.user.displayName.isNotEmpty ?? false
                ? staff!.user.displayName
                : staff?.user.email ?? '',
            style: text.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.s4),
          AdminChip(staff?.role.label ?? ''),
          const SizedBox(height: AppSpace.s8),
          OutlinedButton.icon(
            onPressed: signOut,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
