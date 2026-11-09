import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/image_ref.dart';
import '../theme/app_tokens.dart';
import 'app_network_image.dart';

/// Nút đầu của [AppTopBar]: Back (mặc định) hoặc Close (form).
enum AppBarLeading { back, close }

/// Component `App bar` cho màn lồng (Final UI): cao 56, cách mép trên 16, lề
/// 20. Leading 48 (Back hoặc Close), tiêu đề Title/20 Bold, 1–2 nút action.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    this.actions,
    this.leading = AppBarLeading.back,
    this.onLeading,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final AppBarLeading leading;

  /// Mặc định là `Navigator.maybePop`.
  final VoidCallback? onLeading;

  static const double _inset = AppSpace.screen + AppSpace.s4;

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppSpace.s16 + AppSize.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showLeading =
        onLeading != null ||
        leading == AppBarLeading.close ||
        (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              showLeading ? _inset : AppSpace.screen,
              AppSpace.s16,
              _inset,
              0,
            ),
            child: SizedBox(
              height: AppSize.appBarHeight,
              child: Row(
                spacing: AppSpace.s4,
                children: <Widget>[
                  if (showLeading)
                    switch (leading) {
                      AppBarLeading.back => BackButton(onPressed: onLeading),
                      AppBarLeading.close => CloseButton(onPressed: onLeading),
                    },
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.appBarTheme.titleTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ...?actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hàng đầu của 4 màn tab: tiêu đề bên trái, nút chuông và avatar bên phải.
class TabHeader extends StatelessWidget {
  const TabHeader({
    required this.title,
    required this.onNotifications,
    required this.onProfile,
    this.photo,
    this.unread = 0,
    this.raised = false,
    super.key,
  });

  final String title;
  final VoidCallback onNotifications;

  /// Số tin riêng chưa đọc trong hộp thư (chấm đỏ trên chuông).
  final int unread;
  final bool raised;
  final VoidCallback onProfile;

  /// Ảnh đại diện; `null` thì dùng avatar mặc định.
  final ImageRef? photo;

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
            _actionSurface(
              context,
              IconButton(
                onPressed: onNotifications,
                tooltip: unread > 0 ? 'Hộp thư, $unread tin mới' : 'Hộp thư',
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHighest,
                  fixedSize: const Size.square(AppSize.minTouch),
                ),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: SvgPicture.asset(
                    'assets/icons/bell.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      scheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            _actionSurface(
              context,
              Tooltip(
                message: 'Cài đặt',
                child: Semantics(
                  button: true,
                  label: 'Cài đặt',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onProfile,
                    customBorder: const CircleBorder(),
                    child: AppNetworkImage.square(
                      image: photo,
                      semanticLabel: 'Ảnh đại diện',
                      size: AppSize.minTouch,
                      circle: true,
                      fallback: SvgPicture.asset(
                        'assets/icons/avatar.svg',
                        width: AppSize.minTouch,
                        height: AppSize.minTouch,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionSurface(BuildContext context, Widget child) => raised
      ? Material(
          type: MaterialType.circle,
          color: Theme.of(context).colorScheme.surface,
          elevation: 1,
          shadowColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: 0.15),
          child: child,
        )
      : child;
}
