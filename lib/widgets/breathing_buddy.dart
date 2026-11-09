import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../viewmodels/breathing_view_model.dart';
import 'mascot.dart';

/// Vòng thở ở S10 với Nốt chuyển động theo hơi thở, để người dùng nhìn theo
/// mascot thay vì nhìn chằm chằm vào đồng hồ đếm ngược.
///
/// - Nốt nhún nhẹ liên tục, phồng lên khi hít vào, giữ và lắc nhẹ khi giữ hơi,
///   xẹp xuống khi thở ra; nét mặt đổi theo từng nhịp.
/// - Vòng ngoài là tiến độ của nhịp hiện tại (đầy dần trong 4, 7 hoặc 8 giây).
/// - Mỗi lần đổi nhịp có một gợn sóng lan ra; các hạt nhỏ bay vào khi hít,
///   bay ra khi thở.
/// - Khi bật "Giảm chuyển động" trong máy: không nhún, không hạt, không gợn;
///   vòng trong đổi kích thước theo bước như trước.
class BreathingBuddy extends StatefulWidget {
  const BreathingBuddy({
    required this.phase,
    required this.phaseSeconds,
    required this.done,
    this.size = 240,
    super.key,
  });

  final BreathPhase phase;

  /// Độ dài nhịp hiện tại, dùng cho vòng tiến độ và nhịp phồng / xẹp.
  final int phaseSeconds;

  /// Hết vòng 90 giây: Nốt nhảy mừng.
  final bool done;
  final double size;

  @override
  State<BreathingBuddy> createState() => _BreathingBuddyState();
}

class _BreathingBuddyState extends State<BreathingBuddy>
    with TickerProviderStateMixin {
  /// Nhịp nền 2,4 giây cho nhún và hạt bay.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// Gợn sóng mỗi lần đổi nhịp.
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// Đếm số lần đổi nhịp, làm khoá cho vòng tiến độ của từng nhịp.
  int _phaseIndex = 0;
  bool _motion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = !MediaQuery.disableAnimationsOf(context);
    _syncIdle();
  }

  @override
  void didUpdateWidget(covariant BreathingBuddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase || oldWidget.done != widget.done) {
      _phaseIndex++;
      if (_motion) _ripple.forward(from: 0);
    }
    _syncIdle();
  }

  void _syncIdle() {
    final run = _motion && !widget.done;
    if (run && !_idle.isAnimating) {
      _idle.repeat();
    } else if (!run && _idle.isAnimating) {
      _idle.stop();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _ripple.dispose();
    super.dispose();
  }

  MascotState get _face => widget.done
      ? MascotState.xong
      : switch (widget.phase) {
          BreathPhase.inhale => MascotState.tapTrung,
          BreathPhase.hold => MascotState.doi,
          BreathPhase.exhale => MascotState.thongTha,
        };

  /// Kích thước vòng trong (theo Figma `vòng thở`: 220 khi hít / giữ, 140 khi thở ra).
  double get _innerTarget =>
      widget.done || widget.phase != BreathPhase.exhale ? 220 : 140;

  /// Nốt phồng khi hít, xẹp khi thở.
  double get _mascotTarget => widget.done
      ? 1.08
      : switch (widget.phase) {
          BreathPhase.inhale || BreathPhase.hold => 1.14,
          BreathPhase.exhale => 0.9,
        };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phaseDuration = Duration(seconds: widget.phaseSeconds);
    final grow = _motion && !widget.done ? phaseDuration : Duration.zero;
    final scale = widget.size / 240;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          // Quầng sáng phía sau quả cầu.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.8),
                  scheme.primaryContainer.withValues(alpha: 0.35),
                  scheme.primaryContainer.withValues(alpha: 0),
                ],
                stops: const [0.35, 0.76, 1],
              ),
            ),
          ),
          // Vòng tiến độ của nhịp hiện tại.
          if (!widget.done)
            TweenAnimationBuilder<double>(
              key: ValueKey<int>(_phaseIndex),
              tween: Tween<double>(begin: 0, end: 1),
              duration: _motion ? phaseDuration : Duration.zero,
              builder: (context, value, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: _PhaseArcPainter(
                  progress: value,
                  color: scheme.primary,
                  track: scheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          // Gợn sóng khi đổi nhịp.
          if (_motion)
            AnimatedBuilder(
              animation: _ripple,
              builder: (context, _) => _ripple.isAnimating
                  ? CustomPaint(
                      size: Size.square(widget.size),
                      painter: _RipplePainter(
                        t: _ripple.value,
                        color: scheme.primary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          // Vòng trong phồng / xẹp theo nhịp.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _innerTarget * scale),
            duration: grow,
            curve: Curves.easeInOut,
            builder: (context, d, child) => SizedBox(
              width: d,
              height: d,
              child: CustomPaint(
                painter: _BreathOrbPainter(
                  light: scheme.primaryContainer,
                  depth: scheme.primary,
                ),
              ),
            ),
          ),
          // Hạt bay vào khi hít, bay ra khi thở.
          if (_motion && !widget.done)
            AnimatedBuilder(
              animation: _idle,
              builder: (context, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: _ParticlePainter(
                  t: _idle.value,
                  inward: widget.phase != BreathPhase.exhale,
                  orbitColor: scheme.primary,
                  colors: const <Color>[
                    AppPalette.heat1,
                    AppPalette.heat2,
                    AppPalette.heat3,
                    AppPalette.heat4,
                  ],
                ),
              ),
            ),
          // Luồng gió ngang miệng, phía sau Nốt.
          if (_motion && !widget.done && widget.phase != BreathPhase.hold)
            CustomPaint(
              size: Size.square(widget.size),
              painter: _BreathWindPainter(
                animation: _idle,
                inward: widget.phase == BreathPhase.inhale,
                color: scheme.primary,
              ),
            ),
          // Nốt: phồng / xẹp theo nhịp, nhún và lắc nhẹ liên tục.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _mascotTarget),
            duration: widget.done ? const Duration(milliseconds: 500) : grow,
            curve: widget.done ? Curves.elasticOut : Curves.easeInOut,
            builder: (context, s, child) => AnimatedBuilder(
              animation: _idle,
              child: child,
              builder: (context, child) {
                final wave = math.sin(_idle.value * 2 * math.pi);
                final bob = _motion && !widget.done ? wave * 6 : 0.0;
                final tilt = !_motion || widget.done
                    ? 0.0
                    : widget.phase == BreathPhase.hold
                    ? wave * 0.08
                    : wave * 0.04;
                final yaw = _motion && !widget.done
                    ? math.cos(_idle.value * 2 * math.pi) * 0.16
                    : 0.0;
                // Nén ngang một chút khi phồng, để Nốt trông "hít căng".
                final squash = 1 + (s - 1) * 0.35;
                return Transform.translate(
                  offset: Offset(0, bob),
                  child: Transform.rotate(
                    angle: tilt,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform:
                          Matrix4.diagonal3Values(s / squash, s * squash, 1)
                            ..setEntry(3, 2, 0.002)
                            ..rotateY(yaw),
                      child: child,
                    ),
                  ),
                );
              },
            ),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: _motion ? 280 : 0),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Mascot(
                key: ValueKey<MascotState>(_face),
                state: _face,
                size: 102.6 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathWindPainter extends CustomPainter {
  _BreathWindPainter({
    required this.animation,
    required this.inward,
    required this.color,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final bool inward;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final scale = size.width / 240;
    final center = size.center(Offset.zero);
    final mouthY = center.dy + 15 * scale + math.sin(t * 2 * math.pi) * 6;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Khi hít, gió từ hai bên hội tụ. Khi thở, luồng gió mở rộng sang phải.
    for (final side in inward ? const [-1, 1] : const [1]) {
      for (var i = 0; i < 3; i++) {
        final progress = (t * 2 + i * 0.24) % 1;
        final distance = inward ? 1 - progress : progress;
        final x = center.dx + side * (38 + 42 * distance) * scale;
        final y = mouthY + (i - 1) * (5 + 9 * distance) * scale;
        final length = side * (14 + 10 * distance) * scale;
        final bend = (i.isEven ? -5 : 5) * scale;
        final trail = Path()
          ..moveTo(x, y)
          ..cubicTo(
            x + length * 0.3,
            y + bend,
            x + length * 0.7,
            y - bend,
            x + length,
            y,
          );
        stroke
          ..strokeWidth = (i == 1 ? 2.6 : 1.8) * scale
          ..color = color.withValues(
            alpha: math.sin(progress * math.pi) * (i == 1 ? 0.72 : 0.45),
          );
        canvas.drawPath(trail, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_BreathWindPainter old) =>
      old.animation != animation || old.inward != inward || old.color != color;
}

class _BreathOrbPainter extends CustomPainter {
  const _BreathOrbPainter({required this.light, required this.depth});

  final Color light;
  final Color depth;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final center = bounds.center;
    final radius = size.width / 2;

    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.44, -0.52),
        radius: 1.12,
        colors: [
          Color.lerp(light, Colors.white, 0.88)!,
          Color.lerp(light, Colors.white, 0.35)!,
          light,
          Color.lerp(light, depth, 0.58)!,
        ],
        stops: const [0, 0.28, 0.64, 1],
      ).createShader(bounds);
    canvas.drawCircle(center, radius, body);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.025
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.08),
          light.withValues(alpha: 0.72),
        ],
      ).createShader(bounds);
    canvas.drawCircle(center, radius - rim.strokeWidth / 2, rim);

    // Phản chiếu mềm ở phía trên trái, cùng hướng với nguồn sáng.
    canvas.save();
    canvas.translate(center.dx - radius * 0.31, center.dy - radius * 0.46);
    canvas.rotate(-0.45);
    final highlight = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 0.9,
      height: radius * 0.36,
    );
    canvas.drawOval(
      highlight,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.78),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(highlight),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BreathOrbPainter old) =>
      old.light != light || old.depth != depth;
}

class _PhaseArcPainter extends CustomPainter {
  _PhaseArcPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, base);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * progress, false, fill);
  }

  @override
  bool shouldRepaint(_PhaseArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    for (final delay in <double>[0, 0.25]) {
      final p = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - p) + 0.5
        ..color = color.withValues(alpha: 0.35 * (1 - p));
      canvas.drawCircle(center, radius * (0.6 + 0.5 * p), paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.t,
    required this.inward,
    required this.orbitColor,
    required this.colors,
  });

  final double t;
  final bool inward;
  final Color orbitColor;
  final List<Color> colors;

  static const int _count = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2 - 10;
    final inner = size.width * 0.22;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.36);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.95,
        height: size.height * 0.36,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = orbitColor.withValues(alpha: 0.17),
    );
    final drift = math.sin(t * 2 * math.pi) * 0.18;
    for (var i = 0; i < _count; i++) {
      final seed = i / _count;
      final angle = seed * 2 * math.pi + drift;
      // Mỗi hạt lệch pha nhau để không bay cùng lúc.
      var p = (t + seed) % 1;
      if (inward) p = 1 - p;
      final r = inner + (outer - inner) * p;
      final fade = math.sin(p * math.pi);
      final depth = (math.sin(angle) + 1) / 2;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: fade * (0.44 + 0.48 * depth),
        );
      canvas.drawCircle(
        Offset(math.cos(angle) * r, math.sin(angle) * r * 0.42),
        (2 + 2.5 * fade) * (0.75 + 0.45 * depth),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.t != t || old.inward != inward || old.orbitColor != orbitColor;
}
