import 'package:material_ui/material_ui.dart';

import '../models/note_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'note_type_icon.dart';

/// Component `Note/Tờ nốt`: tờ nốt trong lưới 2 cột ở S04, S05.
///
/// Nền theo loại nốt, luôn kèm nhãn loại bằng chữ (không chỉ báo bằng màu).
class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.type,
    required this.title,
    required this.dateLabel,
    this.onTap,
    super.key,
  });

  final NoteType type;
  final String title;

  /// Ví dụ "Hôm nay · Ổn", "24/10".
  final String dateLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.note);

    return Semantics(
      button: onTap != null,
      label: '${type.label}: $title, $dateLabel',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: colors.noteTint(type),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(type.icon, size: 18, color: colors.onSurfaceMuted),
                    const SizedBox(width: AppSpace.s6),
                    Flexible(
                      child: Text(
                        type.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s8),
                // Tối đa 2 dòng rồi "…" (DESIGN.md mục 10, deviation D-11);
                // Flexible giữ tờ nốt không tràn khi người dùng phóng to chữ.
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  dateLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
