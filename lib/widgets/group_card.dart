import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/first_group.dart';
import '../models/image_ref.dart';
import '../theme/app_tokens.dart';
import '../utils/vi_date_format.dart';
import 'app_network_image.dart';

/// Component `Card/Nhóm lần đầu` (S05): Có nốt / Gợi ý / Tạo mới.
///
/// Có nốt: nền surface-card, dòng "4 nốt · lần đầu 12/10" và thanh tới mốc kế
/// tiếp. Gợi ý và Tạo mới: nền surface, viền đứt. Vùng chạm ≥ 148 × 136.
class GroupCard extends StatelessWidget {
  const GroupCard({required this.group, required this.onTap, super.key})
    : create = false;

  /// Thẻ "Tạo nhóm mới" cuối kệ.
  const GroupCard.create({required this.onTap, super.key})
    : group = null,
      create = true;

  final FirstGroup? group;
  final bool create;
  final VoidCallback onTap;

  static const double width = 148;
  static const double minHeight = 136;

  String get _title => group?.name ?? 'Tạo nhóm mới';

  String get _meta {
    final g = group;
    if (g == null) return 'Lần đầu làm gì đó?';
    if (g.noteCount == 0) {
      return g.source == GroupSource.system ? 'Tụi Nốt gợi ý' : 'Chưa có nốt';
    }
    final first = g.firstAt;
    return first == null
        ? '${g.noteCount} nốt'
        : '${g.noteCount} nốt · lần đầu ${ViDateFormat.shortDate(first)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final g = group;
    final filled = g != null && g.noteCount > 0;
    final radius = BorderRadius.circular(AppRadius.card);
    final next = filled ? FirstGroups.nextMilestone(g.noteCount) : null;

    final content = Padding(
      padding: const EdgeInsets.all(AppSpace.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s8,
        children: <Widget>[
          if (g?.image case final ImageRef image)
            AppNetworkImage.square(
              image: image,
              semanticLabel: 'Ảnh nhóm',
              size: 40,
            )
          else
            Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              create ? 'assets/icons/plus.svg' : 'assets/icons/phase.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(scheme.onSurface, BlendMode.srcIn),
            ),
          ),
          Text(
            _title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _meta,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (filled)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: next == null ? 1 : g.noteCount / next,
                minHeight: AppSpace.s6,
                backgroundColor: scheme.outlineVariant,
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: '$_title, $_meta',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minHeight),
          child: CustomPaint(
            foregroundPainter: filled
                ? null
                : _DashedBorder(color: scheme.outline, radius: AppRadius.card),
            child: Material(
              color: filled ? scheme.surfaceContainerLow : scheme.surface,
              borderRadius: radius,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Viền đứt 1 dp quanh thẻ gợi ý (Figma `border-dashed`).
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}
