import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Component `SettingRow` ở S09, S12: trailing là giá trị hoặc công tắc.
///
/// Final UI: nền surface-card, cao 64 (tối thiểu 56), lề trái 16 phải 12;
/// tiêu đề Body/16 SemiBold, phụ đề Label/13. Cả dòng là vùng chạm.
class SettingRow extends StatelessWidget {
  /// Dòng có giá trị bên phải (ví dụ "21:30"); chạm để đổi.
  const SettingRow.value({
    required this.title,
    required String this.value,
    this.subtitle,
    this.onTap,
    super.key,
  }) : switchValue = null,
       onChanged = null;

  /// Dòng có công tắc bên phải.
  const SettingRow.toggle({
    required this.title,
    required bool value,
    required this.onChanged,
    this.subtitle,
    super.key,
  }) : switchValue = value,
       value = null,
       onTap = null;

  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isToggle = switchValue != null;
    final onRowTap = isToggle
        ? (onChanged == null ? null : () => onChanged!(!switchValue!))
        : onTap;

    return MergeSemantics(
      child: Material(
        color: scheme.surfaceContainerLow,
        child: InkWell(
          onTap: onRowTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s16,
                AppSpace.s12,
                AppSpace.s12,
                AppSpace.s12,
              ),
              child: Row(
                spacing: AppSpace.s12,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.s2,
                      children: <Widget>[
                        Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isToggle)
                    Switch(value: switchValue!, onChanged: onChanged)
                  else ...<Widget>[
                    // Giá trị chỉ rộng bằng chữ của nó (tối đa ~nửa dòng, dài
                    // hơn thì "…"); `Flexible` sẽ giữ chỗ nửa dòng kể cả khi
                    // giá trị ngắn như "Mở" và làm tiêu đề xuống dòng.
                    if (value!.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                        ),
                        child: Text(
                          value!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (onTap != null)
                      SvgPicture.asset(
                        'assets/icons/chevron-right.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          scheme.onSurface,
                          BlendMode.srcIn,
                        ),
                        excludeFromSemantics: true,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nhóm `SettingRow` của S12: nhãn Overline phía trên, các dòng cách nhau 2
/// trong khối bo 16.
class SettingGroup extends StatelessWidget {
  const SettingGroup({required this.children, this.label, super.key});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s8,
      children: <Widget>[
        if (label != null)
          Semantics(
            header: true,
            child: Text(
              label!,
              style: AppTextStyles.of(context).overline.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.72,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s2,
            children: children,
          ),
        ),
      ],
    );
  }
}
