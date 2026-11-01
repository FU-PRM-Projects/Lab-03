import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Component `Tabs` của Final UI (S11): khay surface-variant bo tròn, lề 4;
/// mục đang chọn nổi lên nền surface-card có bóng nhẹ. Mỗi mục cao 48.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    required this.items,
    required this.selected,
    required this.onSelected,
    this.radius = AppRadius.full,
    this.padding = AppSpace.s4,
    this.selectedColor,
    super.key,
  });

  /// Giá trị và nhãn của từng mục, theo thứ tự hiển thị.
  final List<(T, String)> items;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Bo góc khay; mục bên trong bo nhỏ hơn đúng bằng [padding].
  final double radius;
  final double padding;

  /// Mặc định surface-card.
  final Color? selectedColor;

  static const _shadow = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final outer = BorderRadius.circular(radius);
    final inner = BorderRadius.circular(
      radius >= AppRadius.full ? radius : radius - padding,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: outer,
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          spacing: AppSpace.s4,
          children: <Widget>[
            for (final (value, label) in items)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: value == selected,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: value == selected
                          ? selectedColor ?? scheme.surfaceContainerLow
                          : const Color(0x00000000),
                      borderRadius: inner,
                      boxShadow: value == selected
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: _shadow,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => onSelected(value),
                        borderRadius: inner,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSize.minTouch,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpace.s8),
                              child: Text(
                                label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: value == selected
                                      ? scheme.onSurface
                                      : scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
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
}
