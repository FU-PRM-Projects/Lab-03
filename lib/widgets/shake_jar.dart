import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/note.dart';
import '../theme/app_tokens.dart';
import 'jar_illustration.dart';
import 'note_tile.dart';

class ShakeJar extends StatefulWidget {
  const ShakeJar({required this.notes, required this.onOpenNote, super.key});

  final List<Note> notes;
  final ValueChanged<Note> onOpenNote;

  @override
  State<ShakeJar> createState() => _ShakeJarState();
}

class _ShakeJarState extends State<ShakeJar> {
  final _random = math.Random();
  StreamSubscription<UserAccelerometerEvent>? _sensor;
  Timer? _settle;
  double _angle = 0;
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
      _angle = 0;
    }
  }

  void _onMotion(UserAccelerometerEvent event) {
    if (!mounted || _showing || ModalRoute.isCurrentOf(context) == false) {
      return;
    }
    final strength = event.x * event.x + event.y * event.y + event.z * event.z;
    if (strength < 12 * 12) return;
    final direction = event.x.abs() > 2 ? event.x.sign : -event.y.sign;
    _tilt(direction == 0 ? 1 : direction);
  }

  void _tilt(double direction) {
    if (_showing || widget.notes.isEmpty) return;
    setState(() => _angle = direction * 0.23);
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 330), () {
      if (!mounted) return;
      setState(() => _angle = 0);
      if (ModalRoute.isCurrentOf(context) != false) unawaited(_drawNote());
    });
  }

  Future<void> _drawNote() async {
    if (_showing || widget.notes.isEmpty) return;
    _showing = true;
    final note = widget.notes[_random.nextInt(widget.notes.length)];
    try {
      final open = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s12,
              children: [
                Text(
                  'Một nốt bật ra!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.65, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 480),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                  child: IntrinsicHeight(
                    child: NoteTile(
                      type: note.type,
                      title: note.title,
                      dateLabel: 'Chạm để đọc lại',
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = !MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: motion ? _angle : 0),
      duration: motion ? const Duration(milliseconds: 130) : Duration.zero,
      curve: Curves.easeOut,
      builder: (context, angle, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(angle * 1.25)
          ..rotateZ(angle),
        child: child,
      ),
      child: JarIllustration(
        notes: widget.notes
            .map((note) => note.type)
            .take(JarIllustration.capacity)
            .toList(),
        height: 147,
        semanticLabel: 'Hũ chiến thắng',
        onTap: widget.notes.isEmpty
            ? null
            : () => _tilt(_random.nextBool() ? 1 : -1),
      ),
    );
  }
}
