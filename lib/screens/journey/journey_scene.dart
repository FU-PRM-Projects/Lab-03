import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/challenge.dart';
import '../../theme/app_colors.dart';

/// Nền cảnh của S11a · Con đường, vẽ phẳng theo bảng màu app (góp ý của giảng
/// viên: con đường phải cho cảm giác leo lên một đỉnh cao, có khung cảnh phía
/// sau). Mỗi chủ đề một cảnh: Dũng cảm là leo núi (chân núi có cây, đỉnh tuyết
/// cắm cờ), Vận động là đi qua khu vườn (cổng vườn, đồi xanh, cây lớn trên
/// đồi). [points] là vị trí các nút từ dưới lên; con đường đi qua chúng tới
/// [summit]. Đoạn tới nút thứ [reached] (đã xong) tô primary.
class JourneyScenePainter extends CustomPainter {
  JourneyScenePainter({
    required this.topic,
    required this.points,
    required this.start,
    required this.summit,
    required this.reached,
    required this.primary,
  });

  final ChallengeTopic topic;
  final List<Offset> points;
  final Offset start;
  final Offset summit;

  /// Số nút đã đi qua (đoạn đường tô primary tới nút này).
  final int reached;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    switch (topic) {
      case ChallengeTopic.dungCam:
        _paintMountain(canvas, size);
      case ChallengeTopic.vanDong:
        _paintGarden(canvas, size);
    }
    _paintTrail(canvas);
  }

  // ---------------------------------------------------------------- núi

  void _paintMountain(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppPalette.tintBlue);
    _sun(canvas, Offset(w * 0.84, 56), const Color(0xFFFFE08A));
    _cloud(canvas, Offset(w * 0.2, 90), 1);
    _cloud(canvas, Offset(w * 0.78, h * 0.32), 0.8);
    _cloud(canvas, Offset(w * 0.18, h * 0.55), 0.7);

    // Núi xa: một đỉnh lớn ngay dưới điểm đích.
    final peak = Offset(summit.dx, summit.dy - 8);
    final far = Path()
      ..moveTo(-w * 0.1, h)
      ..lineTo(peak.dx, peak.dy)
      ..lineTo(w * 1.1, h)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFFC9D0F5));
    // Mũ tuyết.
    final capH = math.min(110.0, h * 0.14);
    final capW = capH * 0.62;
    final cap = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(peak.dx + capW, peak.dy + capH)
      ..lineTo(peak.dx + capW * 0.45, peak.dy + capH * 0.86)
      ..lineTo(peak.dx, peak.dy + capH)
      ..lineTo(peak.dx - capW * 0.45, peak.dy + capH * 0.86)
      ..lineTo(peak.dx - capW, peak.dy + capH)
      ..close();
    canvas.drawPath(cap, Paint()..color = Colors.white);

    // Hai sườn núi gần, thấp hơn.
    final mid = Paint()..color = const Color(0xFFADB7EE);
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.35, h)
        ..lineTo(w * 0.12, h * 0.48)
        ..lineTo(w * 0.62, h)
        ..close(),
      mid,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.4, h)
        ..lineTo(w * 0.92, h * 0.55)
        ..lineTo(w * 1.4, h)
        ..close(),
      mid,
    );

    // Chân núi: thảm cỏ và rừng thông.
    final ground = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 120)
      ..quadraticBezierTo(w * 0.25, h - 150, w * 0.5, h - 128)
      ..quadraticBezierTo(w * 0.75, h - 106, w, h - 136)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = AppPalette.heat2);
    for (final (x, s) in <(double, double)>[
      (0.06, 1),
      (0.14, 0.75),
      (0.86, 1),
      (0.94, 0.8),
      (0.24, 0.6),
    ]) {
      _pine(canvas, Offset(w * x, h - 112), 34 * s);
    }
  }

  // ---------------------------------------------------------------- vườn

  void _paintGarden(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFF6E5),
    );
    _sun(canvas, Offset(w * 0.16, 54), AppPalette.heat3);
    _cloud(canvas, Offset(w * 0.78, 84), 0.9);

    // Đồi xếp lớp, càng xuống càng đậm.
    void hill(double top, Color color, double wave) {
      final path = Path()
        ..moveTo(0, h)
        ..lineTo(0, top + wave)
        ..quadraticBezierTo(w * 0.3, top - wave, w * 0.55, top + wave * 0.3)
        ..quadraticBezierTo(w * 0.8, top + wave, w, top - wave * 0.6)
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    hill(summit.dy + 70, AppPalette.tintGreen, 26);
    hill(h * 0.45, const Color(0xFFC6EEDC), 24);
    hill(h * 0.7, const Color(0xFFA5E4C8), 20);
    hill(h - 130, AppPalette.heat2, 18);

    // Cây hai bên lối đi, thưa dần lên đồi.
    final rnd = math.Random(7);
    for (var y = summit.dy + 150; y < h - 150; y += 120) {
      _roundTree(canvas, Offset(w * (0.06 + rnd.nextDouble() * 0.06), y), 18);
      _roundTree(
        canvas,
        Offset(w * (0.88 + rnd.nextDouble() * 0.06), y + 40),
        20,
      );
    }
    // Hoa ở chân đồi.
    for (final x in <double>[0.08, 0.16, 0.24, 0.76, 0.84, 0.92]) {
      _flower(canvas, Offset(w * x, h - 70 + (x * 100 % 3) * 8));
    }
    // Cổng vườn ở điểm xuất phát.
    _gate(canvas, Offset(start.dx, h - 26));
    // Cây lớn trên đỉnh đồi (đích).
    _roundTree(canvas, Offset(summit.dx, summit.dy + 4), 40);
  }

  // --------------------------------------------------------- con đường

  void _paintTrail(Canvas canvas) {
    final all = <Offset>[start, ...points, summit];
    final trail = _smooth(all);
    // Lối mòn (vườn) hoặc vệt đường (núi) dưới nút.
    if (topic == ChallengeTopic.vanDong) {
      canvas.drawPath(
        trail,
        Paint()
          ..color = const Color(0xFFEADBB8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round,
      );
    }
    // Đoạn chưa đi: chấm trắng.
    final dashed = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final metric in trail.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 2), dashed);
      }
    }
    // Đoạn đã đi: liền, màu primary, tới nút đã xong cuối cùng.
    if (reached > 0) {
      final done = _smooth(all.sublist(0, reached + 1));
      canvas.drawPath(
        done,
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Đường cong mượt qua các điểm (Catmull-Rom sang Bézier bậc ba).
  static Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = i == 0 ? p[i] : p[i - 1];
      final p1 = p[i];
      final p2 = p[i + 1];
      final p3 = i + 2 < p.length ? p[i + 2] : p2;
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  // ------------------------------------------------------- chi tiết nhỏ

  static void _sun(Canvas canvas, Offset c, Color color) =>
      canvas.drawCircle(c, 22, Paint()..color = color);

  static void _cloud(Canvas canvas, Offset c, double s) {
    final paint = Paint()..color = Colors.white;
    canvas
      ..drawOval(
        Rect.fromCenter(center: c, width: 64 * s, height: 20 * s),
        paint,
      )
      ..drawOval(
        Rect.fromCenter(
          center: c + Offset(12 * s, -8 * s),
          width: 36 * s,
          height: 22 * s,
        ),
        paint,
      );
  }

  static void _pine(Canvas canvas, Offset base, double height) {
    canvas
      ..drawRect(
        Rect.fromCenter(
          center: base + Offset(0, -height * 0.12),
          width: height * 0.12,
          height: height * 0.3,
        ),
        Paint()..color = const Color(0xFF8A6A4A),
      )
      ..drawPath(
        Path()
          ..moveTo(base.dx, base.dy - height)
          ..lineTo(base.dx + height * 0.36, base.dy - height * 0.22)
          ..lineTo(base.dx - height * 0.36, base.dy - height * 0.22)
          ..close(),
        Paint()..color = const Color(0xFF3CA06C),
      );
  }

  static void _roundTree(Canvas canvas, Offset base, double r) {
    canvas
      ..drawRect(
        Rect.fromLTWH(base.dx - r * 0.13, base.dy - r * 0.9, r * 0.26, r * 0.9),
        Paint()..color = const Color(0xFF8A6A4A),
      )
      ..drawCircle(
        base + Offset(0, -r * 1.5),
        r,
        Paint()..color = const Color(0xFF5CC394),
      );
  }

  static void _flower(Canvas canvas, Offset c) {
    final petal = Paint()..color = AppPalette.heat5;
    for (final d in <Offset>[
      const Offset(0, -3),
      const Offset(0, 3),
      const Offset(-3, 0),
      const Offset(3, 0),
    ]) {
      canvas.drawCircle(c + d, 2.6, petal);
    }
    canvas.drawCircle(c, 2.2, Paint()..color = AppPalette.heat3);
  }

  static void _gate(Canvas canvas, Offset base) {
    final paint = Paint()
      ..color = const Color(0xFF8A6A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const half = 30.0;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - half, base.dy)
        ..lineTo(base.dx - half, base.dy - 34)
        ..arcToPoint(
          Offset(base.dx + half, base.dy - 34),
          radius: const Radius.circular(half),
        )
        ..lineTo(base.dx + half, base.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(JourneyScenePainter old) =>
      old.topic != topic ||
      old.reached != reached ||
      old.summit != summit ||
      old.start != start ||
      old.primary != primary ||
      !_samePoints(old.points, points);

  static bool _samePoints(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
