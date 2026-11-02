import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'mascot.dart';

/// Component `Sticker/Mốc`: nhãn dán tháng, Đã mở / Chưa mở.
///
/// Final UI cỡ 64: vòng 64 trong cột rộng 72, nhãn Caption/12 SemiBold cách 6.
/// Đã mở: nền và mascot đổi theo tháng (Th8 heat/2 + Thong Thả, Th9 heat/3 +
/// Xong, Th10 heat/1 + Xong). Chưa mở: viền đứt 1.5 và dấu "?". [size] phóng
/// cả khối theo tỉ lệ (S04 dùng 108.8).
class MilestoneSticker extends StatelessWidget {
  const MilestoneSticker({
    required this.month,
    required this.unlocked,
    this.size = 64,
    super.key,
  });

  /// Tháng 1–12.
  final int month;
  final bool unlocked;

  /// Đường kính vòng.
  final double size;

  static const List<Color> _colors = <Color>[
    AppPalette.heat3,
    AppPalette.heat1,
    AppPalette.heat2,
  ];

  static Color colorOf(int month) => _colors[month % _colors.length];

  static MascotState mascotOf(int month) =>
      month % 3 == 2 ? MascotState.thongTha : MascotState.xong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scale = size / 64;
    final label = 'Tháng $month';

    return Semantics(
      label: 'Nhãn dán $label, ${unlocked ? 'đã mở' : 'chưa mở'}',
      excludeSemantics: true,
      child: SizedBox(
        width: 72 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6 * scale,
          children: <Widget>[
            SizedBox.square(
              dimension: size,
              child: unlocked
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorOf(month),
                      ),
                      child: Center(
                        child: Mascot(
                          state: mascotOf(month),
                          size: 51.84 * scale,
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _DashedCircle(
                        fill: scheme.surfaceContainerHighest,
                        stroke: scheme.outline,
                      ),
                      child: Center(
                        child: Text(
                          '?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 22 * scale,
                            letterSpacing: -0.44 * scale,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12 * scale,
                color: unlocked ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vòng chưa mở: nền surface-variant, viền đứt 1.5 (Figma `border-dashed`).
class _DashedCircle extends CustomPainter {
  const _DashedCircle({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  static const double _width = 1.5;
  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_width / 2);
    canvas.drawOval(rect, Paint()..color = fill);
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    for (final metric in (Path()..addOval(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) =>
      old.fill != fill || old.stroke != stroke;
}
