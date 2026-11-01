import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Component `Text field`: Default, Focused, Filled, Error, Disabled.
///
/// Final UI: nhãn Label/14 SemiBold nằm trên ô, cách 6. Lỗi hiện dưới ô, màu
/// `error`, kèm chữ nguyên nhân ([errorText]). Khi có [maxLength], bộ đếm hiện
/// dạng "n/max".
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s6,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            enabled: enabled,
            autofocus: autofocus,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            minLines: minLines,
            maxLines: obscureText ? 1 : maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              helperMaxLines: 2,
              errorText: errorText,
              errorMaxLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}
