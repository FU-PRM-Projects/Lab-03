import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/note_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// `Illustration/Hũ chiến thắng`: thân hũ là SVG export từ Figma, các tờ nốt
/// đặt vào đúng 8 ô của Figma nhưng tô màu theo loại các nốt thật của người
/// dùng (deviation D-14). Chỉ vẽ hũ; mỗi màn tự đặt mascot, nền tròn quanh
/// hũ theo Figma (S02 cảnh có nền tròn, S04 mascot bên trái, S05 hũ nhỏ).
class JarIllustration extends StatelessWidget {
  const JarIllustration({
    required this.notes,
    required this.semanticLabel,
    this.onTap,
    this.height = 203,
    this.paperPoses,
    this.ejection,
    this.insertion,
    super.key,
  });

  /// Loại của các tờ nốt trong hũ, mới nhất trước. Hũ chứa tối đa
  /// [capacity] tờ; phần dư bị bỏ qua.
  final List<NoteType> notes;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double height;

  /// Paper centers and rotations in the SVG's coordinate space.
  final List<(Offset, double)>? paperPoses;
  final (NoteType, double)? ejection;
  final double? insertion;

  static const String _shellAsset = 'assets/illustrations/jar-empty.svg';

  /// Khung SVG của Figma (120 × 140).
  static const Size _frame = Size(120, 140);
  static const double _slip = 24;

  /// Ô tờ nốt trong Figma: góc trên trái và góc nghiêng (độ), xoay quanh
  /// góc trên trái như `rotate(a x y)` của SVG. Xếp từ đáy hũ lên.
  static const List<(double, double, double)> _slots = [
    (18, 96, -8),
    (44, 102, 10),
    (70, 96, -12),
    (28, 74, 6),
    (56, 76, -9),
    (80, 72, 12),
    (40, 52, -4),
    (66, 52, 8),
  ];

  static int get capacity => _slots.length;

  static (Offset, double) restPose(int index) {
    final (x, y, degrees) = _slots[index];
    return (Offset(x + _slip / 2, y + _slip / 2), degrees * math.pi / 180);
  }

  /// Tờ nốt trong Figma tô bằng `heat/*` (đậm hơn `tint/*` để nổi trên nền
  /// kính); mỗi loại lấy màu cùng họ với tint của nó.
  static const Map<NoteType, Color> _slipColors = <NoteType, Color>{
    NoteType.chienThang: AppPalette.heat4,
    NoteType.tuChu: AppPalette.mono3,
    NoteType.thuThach: AppPalette.heat2,
    NoteType.nhatKy: AppPalette.heat1,
  };

  @override
  Widget build(BuildContext context) {
    final scale = height / _frame.height;
    // Tờ mới nhất nằm trên cùng: ô thấp nhận nốt cũ hơn.
    final shown = notes.take(capacity).toList().reversed.toList();
    final shell = SvgPicture.asset(_shellAsset, excludeFromSemantics: true);
    final dropping = insertion != null && insertion! < 1 && shown.isNotEmpty;
    final opening = ejection?.$2 ?? (dropping ? insertion : null);

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.nav),
          child: SizedBox(
            width: _frame.width * scale,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: opening == null
                      ? shell
                      : ClipRect(clipper: const _GlassClip(), child: shell),
                ),
                for (final (i, type) in shown.indexed)
                  if (dropping && i == shown.length - 1)
                    _dropSlip(i, insertion!, scale, _slipColors[type]!)
                  else if (paperPoses case final poses? when i < poses.length)
                    _movingSlip(poses[i], scale, _slipColors[type]!)
                  else
                    _movingSlip(restPose(i), scale, _slipColors[type]!),
                if (opening case final time?)
                  Positioned(
                    top: (4 - 13 * math.sin(math.pi * time)) * scale,
                    left: (20 + 21 * math.sin(math.pi * time)) * scale,
                    width: 80 * scale,
                    height: 16 * scale,
                    child: Transform.rotate(
                      angle: 0.42 * math.sin(math.pi * time),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF677BF1), Color(0xFF3244B8)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                if (ejection case (final type, final time) when time > 0.13)
                  _movingSlip(
                    (
                      Offset(
                        60 - 34 * time,
                        30 - 235 * time + 160 * time * time,
                      ),
                      -1.2 * time,
                    ),
                    scale,
                    _slipColors[type]!,
                    flying: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropSlip(int slot, double time, double scale, Color color) {
    final (target, angle) = restPose(slot);
    final fall = ((time - 0.15) / 0.85).clamp(0.0, 1.0);
    final landing = Curves.bounceOut.transform(fall);
    return _movingSlip(
      (
        Offset(60 + (target.dx - 60) * fall, -22 + (target.dy + 22) * landing),
        angle + (1 - fall) * 0.58,
      ),
      scale,
      color,
    );
  }

  Widget _movingSlip(
    (Offset, double) pose,
    double scale,
    Color color, {
    bool flying = false,
  }) {
    final (center, angle) = pose;
    final side = _slip * scale * (flying ? 1.38 : 1);
    return Positioned(
      left: center.dx * scale - side / 2,
      top: center.dy * scale - side / 2,
      width: side,
      height: side,
      child: Transform.rotate(
        angle: angle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.r4 * scale),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF232750)
                    .withValues(alpha: flying ? 0.24 : 0.12),
                offset: const Offset(1, 2) * scale,
                blurRadius: (flying ? 6 : 2) * scale,
              ),
            ],
          ),
          child: flying
              ? Icon(
                  Icons.short_text_rounded,
                  color: const Color(0xFF232750),
                  size: side * 0.6,
                )
              : null,
        ),
      ),
    );
  }
}

class _GlassClip extends CustomClipper<Rect> {
  const _GlassClip();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * (20 / 140), size.width, size.height);

  @override
  bool shouldReclip(_GlassClip oldClipper) => false;
}
