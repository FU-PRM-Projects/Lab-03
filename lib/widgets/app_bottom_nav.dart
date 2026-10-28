import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Một tab cấp cao của Nốt.
class AppTab {
  const AppTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bốn tab theo thứ tự Lab 2: Hôm nay, Hũ, Thử thách, Hành trình.
const List<AppTab> appTabs = <AppTab>[
  AppTab('Hôm nay', Icons.wb_sunny_outlined, Icons.wb_sunny),
  AppTab('Hũ', Icons.inventory_2_outlined, Icons.inventory_2),
  AppTab('Thử thách', Icons.flag_outlined, Icons.flag),
  AppTab('Hành trình', Icons.route_outlined, Icons.route),
];

/// Component `BottomNav · Nốt`: thanh tab nổi bo 32, cách đáy 12, chỉ hiện ở
/// 4 màn gốc.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.nav);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        0,
        AppSpace.screen,
        AppSize.navBarBottomGap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppElevation.fab(scheme.shadow),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelected,
            destinations: <NavigationDestination>[
              for (final tab in appTabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
