import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Kiểu của component `Button` Lab 2.
enum AppButtonVariant { filled, tonal, outlined, text, destructive }

/// Component `Button` Lab 2: 5 kiểu × Default, Pressed, Disabled, Loading.
///
/// Disabled khi [onPressed] là `null`. Loading giữ nguyên bề rộng nút và
/// chặn chạm. Mỗi màn chỉ nên có một nút [AppButtonVariant.filled].
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.iconAsset,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Icon SVG 20 dp của Figma, tô theo màu chữ của nút.
  final String? iconAsset;
  final bool loading;

  /// Kéo nút rộng hết chiều ngang (nút chính cuối màn).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onTap = loading ? null : onPressed;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (iconAsset != null) ...<Widget>[
          Builder(
            builder: (context) => SvgPicture.asset(
              iconAsset!,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                IconTheme.of(context).color ?? scheme.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    // Giữ chữ (vô hình) dưới vòng xoay để nút không đổi bề rộng.
    final child = loading
        ? Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(opacity: 0, child: content),
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          )
        : content;

    final Widget button = switch (variant) {
      AppButtonVariant.filled => FilledButton(onPressed: onTap, child: child),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: onTap,
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: onTap,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: onTap, child: child),
      AppButtonVariant.destructive => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
        ),
        child: child,
      ),
    };

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: loading ? '$label, đang xử lý' : null,
      excludeSemantics: loading,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
