import 'package:material_ui/material_ui.dart';

/// Component `SettingRow` ở S09, S12: trailing là giá trị hoặc công tắc.
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
    final subtitleWidget = subtitle == null ? null : Text(subtitle!);

    if (switchValue != null) {
      return SwitchListTile(
        title: Text(title),
        subtitle: subtitleWidget,
        value: switchValue!,
        onChanged: onChanged,
      );
    }

    return ListTile(
      title: Text(title),
      subtitle: subtitleWidget,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
