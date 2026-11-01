import 'dart:ui' show ImageFilter;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Một tab cấp cao của Nốt.
class AppTab {
  const AppTab(this.label, this.iconAsset);

  final String label;

  /// Icon 22 dp nét 1.83 của Figma (`icon/today`, `icon/jar`, …).
  final String iconAsset;
}

/// Bốn tab theo thứ tự Lab 2: Hôm nay, Hũ, Thử thách, Hành trình.
const List<AppTab> appTabs = <AppTab>[
  AppTab('Hôm nay', 'assets/icons/tab-today.svg'),
  AppTab('Hũ', 'assets/icons/tab-jar.svg'),
  AppTab('Thử thách', 'assets/icons/tab-flag.svg'),
  AppTab('Hành trình', 'assets/icons/tab-user.svg'),
];

/// Component `BottomNav/iPhone` (Final UI): thanh kính nổi bo 32, cao 64, cách
/// đáy 18. Tab đang chọn là viên thuốc có icon + nhãn; tab khác chỉ có icon
/// (nhãn vẫn đọc được qua tooltip và trình đọc màn hình).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const double _itemHeight = 52;
  static const Color _shadow = Color(0x1A1A1C29);

  @override
  Widget build(BuildContext context) {
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
          boxShadow: const <BoxShadow>[
            BoxShadow(color: _shadow, offset: Offset(0, 6), blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: AppSize.navBarHeight,
              padding: const EdgeInsets.all(AppSpace.s6),
              decoration: BoxDecoration(
                // Kính: nền trắng mờ trên nội dung đã làm nhoè, viền trắng
                // 70% và vệt sáng mép trên.
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: radius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              ),
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                child: Row(
                  spacing: 2,
                  children: <Widget>[
                    for (final (i, tab) in appTabs.indexed)
                      i == currentIndex
                          ? _ActiveTab(tab: tab, onTap: () => onSelected(i))
                          : Expanded(
                              child: _IdleTab(
                                tab: tab,
                                onTap: () => onSelected(i),
                              ),
                            ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.tab, required this.onTap});

  final AppTab tab;
  final VoidCallback onTap;

  static const Color _fill = Color(0x171B1D2A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    final radius = BorderRadius.circular(AppBottomNav._itemHeight / 2);

    return Semantics(
      button: true,
      selected: true,
      label: tab.label,
      excludeSemantics: true,
      child: Material(
        color: _fill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: AppBottomNav._itemHeight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.s8,
              children: <Widget>[
                _TabIcon(asset: tab.iconAsset, color: color),
                Text(
                  tab.label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdleTab extends StatelessWidget {
  const _IdleTab({required this.tab, required this.onTap});

  final AppTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppBottomNav._itemHeight / 2);

    return Tooltip(
      message: tab.label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: false,
        label: tab.label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: AppBottomNav._itemHeight,
            child: Center(
              child: _TabIcon(
                asset: tab.iconAsset,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.asset, required this.color});

  final String asset;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: 22,
    height: 22,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    excludeFromSemantics: true,
  );
}
