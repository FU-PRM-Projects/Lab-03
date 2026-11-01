import 'package:flutter_svg/flutter_svg.dart';
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
    this.tagSuffix,
    this.excerpt,
    this.onTap,
    super.key,
  });

  final NoteType type;
  final String title;

  /// Ví dụ "Hôm nay · Ổn", "24/10"; rỗng thì không có dòng này.
  final String dateLabel;

  /// Thêm sau nhãn loại, ví dụ "Chiến thắng · Lần đầu".
  final String? tagSuffix;

  /// Trích nhật ký, tối đa 2 dòng (thẻ "Nhớ lại lần này nhé" ở S02).
  final String? excerpt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.note);
    final tagColor = type.tagColor(theme.colorScheme, colors);
    final tag = tagSuffix == null ? type.label : '${type.label} · $tagSuffix';

    return Semantics(
      button: onTap != null,
      label: <String>[
        '$tag: $title',
        ?excerpt,
        if (dateLabel.isNotEmpty) dateLabel,
      ].join(', '),
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
              spacing: AppSpace.s6,
              children: <Widget>[
                // Nhãn loại: icon 14 + Caption/12 Bold màu theo loại.
                Row(
                  spacing: AppSpace.s4,
                  children: <Widget>[
                    SvgPicture.asset(
                      type.tagIconAsset,
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(tagColor, BlendMode.srcIn),
                      excludeFromSemantics: true,
                    ),
                    Flexible(
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tagColor,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Tối đa 3 dòng rồi "…" (Figma `Note/Tờ nốt`); Flexible thu
                // còn ít dòng hơn khi ô có chiều cao cố định hoặc chữ phóng to.
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (excerpt case final excerpt?)
                  Text(
                    excerpt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurfaceVariant,
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
