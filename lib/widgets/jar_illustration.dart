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
    super.key,
  });

  /// Loại của các tờ nốt trong hũ, mới nhất trước. Hũ chứa tối đa
  /// [capacity] tờ; phần dư bị bỏ qua.
  final List<NoteType> notes;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double height;

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
              children: <Widget>[
                Positioned.fill(
                  child: SvgPicture.asset(
                    _shellAsset,
                    excludeFromSemantics: true,
                  ),
                ),
                for (final (i, type) in shown.indexed)
                  _slipAt(_slots[i], scale, _slipColors[type]!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slipAt((double, double, double) slot, double scale, Color color) {
    final (x, y, degrees) = slot;
    final side = _slip * scale;
    return Positioned(
      left: x * scale,
      top: y * scale,
      width: side,
      height: side,
      child: Transform.rotate(
        angle: degrees * math.pi / 180,
        alignment: Alignment.topLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.r4 * scale),
          ),
        ),
      ),
    );
  }
}
