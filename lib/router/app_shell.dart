import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/app_bottom_nav.dart';

/// Khung 4 tab với thanh tab nổi. Nội dung chạy dưới thanh tab
/// (`extendBody`), mỗi màn tab chừa khoảng trống cuối để không bị che.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final onToday = navigationShell.currentIndex == 0;

    // Back ở tab khác Hôm nay → về Hôm nay; ở Hôm nay → thoát app.
    return PopScope(
      canPop: onToday,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: AppBottomNav(
          currentIndex: navigationShell.currentIndex,
          onSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
