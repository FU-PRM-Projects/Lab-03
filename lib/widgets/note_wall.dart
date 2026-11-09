import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../router/app_routes.dart';
import '../services/clock.dart';
import '../theme/app_tokens.dart';
import '../viewmodels/note_wall_view_model.dart';
import 'note_tile.dart';

class NoteWall extends ConsumerStatefulWidget {
  const NoteWall({super.key});

  @override
  ConsumerState<NoteWall> createState() => _NoteWallState();
}

class _NoteWallState extends ConsumerState<NoteWall> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _checkExpiry);
  }

  void _checkExpiry() => setState(() {});

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pins = ref.watch(noteWallProvider).asData?.value ?? const {};
    if (pins.isEmpty) return const SizedBox.shrink();
    final now = ref.read(clockProvider).now();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.06),
              offset: const Offset(0, 2),
              blurRadius: 7,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primaryContainer, scheme.surfaceContainerLow],
          ),
        ),
        child: CustomPaint(
          painter: _Pegboard(scheme.primary.withValues(alpha: 0.13)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s8,
              children: [
                Row(
                  spacing: AppSpace.s8,
                  children: [
                    Icon(
                      Icons.push_pin_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    Expanded(
                      child: Text(
                        'Tường nốt',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        child: Text(
                          '${pins.length} nốt',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ],
                ),
                for (final (index, pin)
                    in pins.entries.toList().reversed.indexed)
                  _WallCard(
                    key: ValueKey((
                      pin.key,
                      pin.value,
                      !pin.value.isAfter(now),
                    )),
                    id: pin.key,
                    expires: pin.value,
                    now: now,
                    tilt: index.isEven ? -0.04 : 0.04,
                  ),
                Row(
                  spacing: AppSpace.s8,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Text(
                        'Nốt tự bay vào hũ sau 2 ngày.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WallCard extends ConsumerWidget {
  const _WallCard({
    required this.id,
    required this.expires,
    required this.now,
    required this.tilt,
    super.key,
  });

  final String id;
  final DateTime expires;
  final DateTime now;
  final double tilt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteWallItemProvider(id));
    final leaving = !expires.isAfter(now);
    final justPinned =
        expires.difference(now) >
        NoteWallViewModel.duration - const Duration(seconds: 8);
    final animate =
        !MediaQuery.disableAnimationsOf(context) && (leaving || justPinned);
    final wall = ref.read(noteWallProvider.notifier);
    final card = note.when(
      data: (value) => _PinnedPaper(
        tilt: tilt,
        child: IntrinsicHeight(
          child: NoteTile(
            type: value.type,
            title: value.title,
            image: value.image,
            dateLabel: leaving ? 'Đang về hũ' : 'Đang dán trên tường',
            onTap: leaving
                ? null
                : () => context.push(AppRoutes.noteDetail(id)),
          ),
        ),
      ),
      loading: () => const Text('Đang mở nốt…'),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(noteWallItemProvider(id)),
        child: const Text('Tải lại nốt'),
      ),
    );
    if (note.isLoading) return card;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: animate ? const Duration(milliseconds: 780) : Duration.zero,
      curve: Curves.easeInOutCubic,
      onEnd: leaving
          ? () => unawaited(wall.release(id, expires).catchError((Object _) {}))
          : null,
      builder: (context, t, child) {
        final progress = leaving ? t : 1 - t;
        final flip = math.sin(progress * math.pi / 2);
        return Opacity(
          opacity: 1 - progress,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..translateByDouble(
                leaving ? 28 * t : 0,
                leaving ? -155 * t : 18 * progress,
                0,
                1,
              )
              ..rotateX(flip * 0.75)
              ..rotateZ(progress * 0.14)
              ..scaleByDouble(1 - progress * 0.4, 1 - progress * 0.4, 1, 1),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}

class _PinnedPaper extends StatelessWidget {
  const _PinnedPaper({required this.tilt, required this.child});

  final double tilt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      child: Transform.rotate(
        angle: tilt,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.09),
                    offset: const Offset(1, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: child,
            ),
            Positioned(
              top: -6,
              child: IgnorePointer(
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.5),
                      colors: [scheme.primaryContainer, scheme.primary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.16),
                        offset: const Offset(1, 3),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pegboard extends CustomPainter {
  const _Pegboard(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 44.0; y < size.height - 12; y += 14) {
      for (var x = 12.0; x < size.width - 10; x += 14) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Pegboard oldDelegate) => color != oldDelegate.color;
}
