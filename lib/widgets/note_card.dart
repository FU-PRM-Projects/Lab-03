import 'package:material_ui/material_ui.dart';

import '../models/image_ref.dart';
import '../models/note_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_network_image.dart';
import 'note_type_icon.dart';

/// Component `Card/Nốt`: 4 loại × Default, Pressed.
///
/// Cả thẻ là vùng chạm; khi nhấn nền đổi sang `surface-variant`.
class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.type,
    required this.title,
    required this.meta,
    this.image,
    this.onTap,
    super.key,
  });

  final NoteType type;
  final String title;

  /// Ảnh khoảnh khắc của nốt: có thì hiện thay cho biểu tượng loại nốt.
  final ImageRef? image;

  /// Dòng phụ, ví dụ "Chiến thắng · 24/10".
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: onTap != null,
      label: <String>[title, meta, if (image != null) 'có ảnh'].join(', '),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          highlightColor: scheme.surfaceContainerHighest,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSize.noteCardHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s16,
                vertical: AppSpace.s12,
              ),
              child: Row(
                children: <Widget>[
                  if (image case final ImageRef photo)
                    AppNetworkImage.square(
                      image: photo,
                      semanticLabel: 'Ảnh của nốt',
                      size: 44,
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.noteTint(type),
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                      child: SizedBox.square(
                        dimension: 44,
                        child: Icon(type.icon, color: colors.onSurfaceMuted),
                      ),
                    ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          meta,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
