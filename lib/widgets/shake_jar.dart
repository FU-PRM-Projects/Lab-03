import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/note.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'jar_illustration.dart';
import 'note_type_icon.dart';

class ShakeJar extends StatefulWidget {
  const ShakeJar({required this.notes, required this.onOpenNote, super.key});

  final List<Note> notes;
  final ValueChanged<Note> onOpenNote;

  @override
  State<ShakeJar> createState() => _ShakeJarState();
}

class _ShakeJarState extends State<ShakeJar>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  final _jarKey = GlobalKey();
  final _papers = <_JarPaper>[];
  late final Ticker _ticker = createTicker(_step);
  StreamSubscription<UserAccelerometerEvent>? _sensor;
  Timer? _settle;
  Duration _previousFrame = Duration.zero;
  Note? _drawn;
  double _flight = 0;
  double _energyTime = 0;
  double _angle = 0;
  double _spin = 0;
  bool _showing = false;
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final enabled = supported && TickerMode.valuesOf(context).enabled;
    if (enabled == _listening) return;
    _listening = enabled;
    if (enabled) {
      _sensor = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onMotion, onError: (Object _) {}, cancelOnError: true);
    } else {
      unawaited(_sensor?.cancel());
      _sensor = null;
      _settle?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant ShakeJar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      oldWidget.notes.take(JarIllustration.capacity).map((n) => n.id).toList(),
      widget.notes.take(JarIllustration.capacity).map((n) => n.id).toList(),
    )) {
      _papers.clear();
    }
  }

  void _onMotion(UserAccelerometerEvent event) {
    if (!mounted || _showing || ModalRoute.isCurrentOf(context) == false) {
      return;
    }
    final strength = event.x * event.x + event.y * event.y + event.z * event.z;
    if (strength < 12 * 12) return;
    _shake(Offset(event.x, -event.y) * 8);
  }

  void _shake(Offset impulse) {
    if (_showing || widget.notes.isEmpty) return;
    if (!MediaQuery.disableAnimationsOf(context)) {
      if (_papers.isEmpty) {
        for (
          var i = 0;
          i < math.min(widget.notes.length, JarIllustration.capacity);
          i++
        ) {
          final (center, angle) = JarIllustration.restPose(i);
          _papers.add(_JarPaper(center, angle));
        }
      }
      _spin = (_spin + impulse.dx * 0.022).clamp(-5, 5);
      for (final paper in _papers) {
        final variation = 0.75 + _random.nextDouble() * 0.5;
        final kick = Offset(impulse.dx, impulse.dy - 125) * variation;
        paper.velocity += kick;
        if (paper.velocity.distanceSquared > 360 * 360) {
          paper.velocity *= 360 / paper.velocity.distance;
        }
        paper.spin = (_random.nextDouble() - 0.5) * 14;
      }
      _energyTime = 1.55;
      _startTicker();
    }
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 330), () {
      if (!mounted ||
          !TickerMode.valuesOf(context).enabled ||
          ModalRoute.isCurrentOf(context) == false ||
          widget.notes.isEmpty) {
        return;
      }
      final note = widget.notes[_random.nextInt(widget.notes.length)];
      _showing = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        unawaited(_openDrawnNote(note));
      } else {
        _drawn = note;
        _flight = 0;
        _startTicker();
      }
    });
  }

  void _startTicker() {
    if (_ticker.isActive) return;
    _previousFrame = Duration.zero;
    unawaited(_ticker.start());
  }

  void _step(Duration elapsed) {
    final seconds = ((elapsed - _previousFrame).inMicroseconds / 1e6).clamp(
      0.0,
      1 / 24,
    );
    _previousFrame = elapsed;
    final steps = math.max(1, (seconds * 120).ceil());
    final dt = seconds / steps;
    setState(() {
      for (var i = 0; i < steps; i++) {
        _spin += (-100 * _angle - 10 * _spin) * dt;
        _angle += _spin * dt;
        _stepPapers(dt);
      }
      _energyTime -= seconds;
      if (_drawn != null) _flight += seconds / 0.56;
    });
    if (_drawn case final note? when _flight >= 1) {
      setState(() {
        _drawn = null;
        _flight = 0;
      });
      if (ModalRoute.isCurrentOf(context) != false) {
        unawaited(_openDrawnNote(note));
      } else {
        _showing = false;
      }
    }
    if (_energyTime <= 0 && _drawn == null) {
      _angle = 0;
      _spin = 0;
      _ticker.stop();
    }
  }

  void _stepPapers(double dt) {
    final gravity = Offset(-math.sin(_angle), math.cos(_angle)) * 430;
    for (final paper in _papers) {
      paper.velocity = (paper.velocity + gravity * dt) * math.exp(-1.5 * dt);
      paper.center += paper.velocity * dt;
      paper.angle += paper.spin * dt;
      paper.spin *= math.exp(-2.2 * dt);
    }
    for (var i = 0; i < _papers.length; i++) {
      for (var j = i + 1; j < _papers.length; j++) {
        _papers[i].collide(_papers[j]);
      }
    }
    for (final paper in _papers) {
      paper.contain();
    }
  }

  Future<void> _openDrawnNote(Note note) async {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    final overlayBox = overlay?.context.findRenderObject();
    final jarBox = _jarKey.currentContext?.findRenderObject();
    final origin = jarBox is RenderBox && overlayBox is RenderBox
        ? jarBox.localToGlobal(
            Offset(
              jarBox.size.width * 26 / 120,
              -jarBox.size.height * 45 / 140,
            ),
            ancestor: overlayBox,
          )
        : null;
    try {
      final open = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Đóng nốt',
        barrierColor: const Color(0x990F1533),
        transitionDuration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 420),
        pageBuilder: (context, _, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: _DrawnPaper(note: note),
            ),
          ),
        ),
        transitionBuilder: (context, animation, _, child) {
          if (reducedMotion) return child;
          final t = animation.value;
          final travel = Curves.easeOutCubic.transform(t);
          final size = MediaQuery.sizeOf(context);
          final center = size.center(Offset.zero);
          final start = origin == null
              ? center - const Offset(0, 80)
              : Offset(
                  origin.dx.clamp(20, size.width - 20),
                  origin.dy.clamp(20, size.height - 20),
                );
          final offset =
              (start - center) * (1 - travel) -
              Offset(0, 28 * math.sin(math.pi * travel));
          return Transform.translate(
            offset: offset,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(-0.75 * (1 - travel))
                ..rotateZ(-0.035 - 0.285 * (1 - travel)),
              child: Transform.scale(
                scale: 0.13 + 0.87 * Curves.easeOutBack.transform(t),
                child: FadeTransition(opacity: animation, child: child),
              ),
            ),
          );
        },
      );
      if (mounted && open == true) widget.onOpenNote(note);
    } finally {
      _showing = false;
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    unawaited(_sensor?.cancel());
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateY(_angle * 1.25)
        ..rotateZ(_angle),
      child: JarIllustration(
        key: _jarKey,
        notes: widget.notes
            .map((note) => note.type)
            .take(JarIllustration.capacity)
            .toList(),
        height: 147,
        semanticLabel: 'Hũ chiến thắng',
        paperPoses: [for (final paper in _papers) (paper.center, paper.angle)],
        ejection: _drawn == null ? null : (_drawn!.type, _flight.clamp(0, 1)),
        onTap: widget.notes.isEmpty
            ? null
            : () => _shake(Offset(_random.nextBool() ? 145 : -145, -55)),
      ),
    );
  }
}

class _DrawnPaper extends StatelessWidget {
  const _DrawnPaper({required this.note});

  final Note note;
  static const double fold = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final paper = colors.noteTint(note.type);
    final ink = note.type.tagColor(theme.colorScheme, colors);
    return PhysicalShape(
      clipper: const _PaperOutline(),
      clipBehavior: Clip.antiAlias,
      color: paper,
      shadowColor: Colors.black54,
      elevation: 14,
      child: CustomPaint(
        painter: _PaperDetails(ink),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(true),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Một nốt bật ra!',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: ink,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: fold / 2),
                        child: IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    note.type.label,
                    style: theme.textTheme.labelLarge?.copyWith(color: ink),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    note.title,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  Text(
                    'Chạm để đọc lại',
                    style: theme.textTheme.labelMedium?.copyWith(color: ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperOutline extends CustomClipper<Path> {
  const _PaperOutline();

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width - _DrawnPaper.fold, 0)
    ..lineTo(size.width, _DrawnPaper.fold)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_PaperOutline oldClipper) => false;
}

class _PaperDetails extends CustomPainter {
  const _PaperDetails(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    const fold = _DrawnPaper.fold;
    final lines = Paint()
      ..color = ink.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var y = 60.0; y < size.height - 10; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
    }
    canvas.drawPath(
      Path()
        ..moveTo(size.width - fold, 0)
        ..lineTo(size.width - fold, fold)
        ..lineTo(size.width, fold)
        ..close(),
      Paint()..color = ink.withValues(alpha: 0.23),
    );
  }

  @override
  bool shouldRepaint(_PaperDetails oldDelegate) => ink != oldDelegate.ink;
}

class _JarPaper {
  _JarPaper(this.center, this.angle);

  Offset center;
  double angle;
  Offset velocity = Offset.zero;
  double spin = 0;

  // Circular collision shapes approximate the flat squares. This lets the
  // corners overlap slightly like real paper slips in a shallow pile.
  void collide(_JarPaper other) {
    final delta = other.center - center;
    final distance = delta.distance;
    const diameter = 22.0;
    if (distance >= diameter) return;

    final normal = distance > 0.01 ? delta / distance : const Offset(1, 0);
    final separation = normal * ((diameter - distance) * 0.5);
    center -= separation;
    other.center += separation;
    final relative = other.velocity - velocity;
    final speed = relative.dx * normal.dx + relative.dy * normal.dy;
    if (speed >= 0) return;
    final rebound = normal * (speed * 0.58);
    velocity += rebound;
    other.velocity -= rebound;
  }

  void contain() {
    // The lower corners taper inward to match the rounded SVG glass.
    final y = center.dy.clamp(43.0, 119.0);
    final corner = math.max(0.0, y - 105) * 0.45;
    final x = center.dx.clamp(22.0 + corner, 98.0 - corner);
    if (x != center.dx) {
      velocity = Offset(-velocity.dx * 0.42, velocity.dy * 0.84);
      spin *= 0.62;
    }
    if (y != center.dy) {
      final bounce = velocity.dy.abs() > 24 ? -velocity.dy * 0.34 : 0.0;
      velocity = Offset(velocity.dx * 0.77, bounce);
      spin *= 0.7;
    }
    center = Offset(x, y);
  }
}
