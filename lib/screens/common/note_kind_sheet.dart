import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/note_type_icon.dart';

/// "Ghi nốt" (S02) và nút + (màn tab): hỏi ghi chiến thắng nhỏ, viết nhật
/// ký hay kể tự do rồi mở S03, màn Viết nhật ký (deviation D-29) hoặc S03b
/// Kể tự do (Nốt AI).
Future<void> openNoteKindSheet(BuildContext context) async {
  final route = await showModalBottomSheet<String>(
    context: context,
    // Nằm trên thanh tab nổi, không bị nó che phần dưới.
    useRootNavigator: true,
    showDragHandle: true,
    // 3 lựa chọn cao hơn nửa màn 800 dp: cho khay cao theo nội dung.
    isScrollControlled: true,
    builder: (_) => const _NoteKindSheet(),
  );
  if (route != null && context.mounted) await context.push(route);
}

class _NoteKindSheet extends StatelessWidget {
  const _NoteKindSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s12,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                'Hôm nay bạn muốn ghi gì?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            _KindCard(
              type: NoteType.chienThang,
              title: 'Chiến thắng nhỏ',
              subtitle: 'Một việc làm được hôm nay, chừng 30 giây.',
              onTap: () => Navigator.of(context).pop(AppRoutes.newNote()),
            ),
            _KindCard(
              type: NoteType.nhatKy,
              title: 'Viết nhật ký',
              subtitle: 'Viết ra suy nghĩ cho đầu nhẹ và rõ hơn.',
              onTap: () => Navigator.of(context).pop(AppRoutes.journal),
            ),
            _KindCard(
              type: NoteType.tuChu,
              title: 'Kể tự do · Nốt AI',
              subtitle: 'Kể cả ngày, Tụi Nốt tách thành vài nốt cho bạn chọn.',
              onTap: () => Navigator.of(context).pop(AppRoutes.freeTell),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một lựa chọn: nền tint của loại nốt sẽ lưu, icon nhãn loại trong vòng 40.
class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final NoteType type;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: colors.noteTint(type),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s12,
              AppSpace.s12,
              AppSpace.s8,
              AppSpace.s12,
            ),
            child: Row(
              spacing: AppSpace.s12,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    type.tagIconAsset,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      type.tagColor(scheme, colors),
                      BlendMode.srcIn,
                    ),
                    excludeFromSemantics: true,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpace.s2,
                    children: <Widget>[
                      Text(title, style: theme.textTheme.labelLarge),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
