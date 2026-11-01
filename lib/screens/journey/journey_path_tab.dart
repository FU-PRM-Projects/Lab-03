import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/journey_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/state_views.dart';

/// S11a · Con đường: chặng hiện tại của từng chủ đề thử thách.
///
/// Final UI: banner chặng màu primary, rồi các nút tròn đi zig-zag (đã xong,
/// đang làm có bong bóng tên thử thách, chưa mở) như một con đường. Khác
/// Figma (D-18): mỗi nút ghi tên thử thách bên cạnh, chặng sau là một thẻ.
class JourneyPathTab extends StatelessWidget {
  const JourneyPathTab({required this.state, required this.onRetry, super.key});

  final ViewState<List<PathStage>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Loading<List<PathStage>>() => const LoadingState.spinner(
        message: 'Đang vẽ con đường…',
      ),
      Failure<List<PathStage>>(:final message, :final offline) => Padding(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: ErrorState(
          title: 'Chưa tải được con đường',
          cause: message,
          kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
          onRetry: onRetry,
        ),
      ),
      Empty<List<PathStage>>() => const Padding(
        padding: EdgeInsets.all(AppSpace.screen),
        child: EmptyState(
          title: 'Chưa có chặng nào',
          message: 'Thẻ thử thách sẽ sớm có. Ghé lại sau nhé.',
        ),
      ),
      Data<List<PathStage>>(:final value) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.s16,
          AppSpace.screen,
          AppSpace.tabContentBottom,
        ),
        children: <Widget>[
          for (final stage in value) ...<Widget>[
            _StageBanner(stage: stage),
            const SizedBox(height: AppSpace.s16),
            for (final (i, node) in stage.nodes.indexed)
              _PathNodeRow(node: node, dx: _zigzag(i)),
            if (stage.hasNextLevel)
              _NextStage(level: stage.level + 1, cards: stage.nodes.length),
            const SizedBox(height: AppSpace.s24),
          ],
        ],
      ),
    };
  }

  /// Độ lệch ngang của nút thứ [i] so với giữa màn (Figma: 0, +56, +28…).
  static double _zigzag(int i) =>
      const <double>[0, 56, 28, -28, -56, -28, 28][i % 7];
}

/// Màu đổ bóng đặc dưới banner và nút (primary đậm, xám cho nút khoá).
const Color _primaryEdge = Color(0xFF252F80);
const Color _lockedEdge = Color(0xFFBDBFC7);

/// Figma `Banner chặng`: nền primary bo 20, bóng đặc 4, chữ trắng.
class _StageBanner extends StatelessWidget {
  const _StageBanner({required this.stage});

  final PathStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onPrimary = scheme.onPrimary;
    final total = stage.nodes.length;
    final title = stage.current?.challenge.title ?? 'Đã xong chặng này';
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      label:
          'Chặng ${stage.level}, ${stage.topic.label}: $title, '
          'đã làm ${stage.done} trên $total. Mở Thử thách',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const <BoxShadow>[
            BoxShadow(color: _primaryEdge, offset: Offset(0, 4)),
          ],
        ),
        child: Material(
          color: scheme.primary,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () => context.go(AppRoutes.challenges),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s16),
              child: Row(
                spacing: AppSpace.s12,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.s6,
                      children: <Widget>[
                        Text(
                          'CHẶNG ${stage.level} · '
                          '${stage.topic.label.toUpperCase()}',
                          style: AppTextStyles.of(context).overline.copyWith(
                            color: onPrimary.withValues(alpha: 0.8),
                            letterSpacing: 0.72,
                          ),
                        ),
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onPrimary,
                            letterSpacing: -0.18,
                          ),
                        ),
                        Row(
                          spacing: AppSpace.s8,
                          children: <Widget>[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.r4,
                                ),
                                child: LinearProgressIndicator(
                                  value: total == 0 ? 0 : stage.done / total,
                                  minHeight: AppSpace.s8,
                                  color: onPrimary,
                                  backgroundColor: onPrimary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '${stage.done}/$total',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const _NotebookBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma `nút sổ tay chặng`: ô 48 trắng 18% với ba vạch kẻ.
class _NotebookBadge extends StatelessWidget {
  const _NotebookBadge();

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    Widget line(double width) => Container(
      width: width,
      height: 3.5,
      decoration: BoxDecoration(
        color: onPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return Container(
      width: AppSize.minTouch,
      height: AppSize.minTouch,
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 22,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 3.5,
          children: <Widget>[line(22), line(16), line(19)],
        ),
      ),
    );
  }
}

/// Nút tròn 56 có bóng đặc 5 phía dưới (Figma `nút · done`, `nút · lock`).
class _PathDot extends StatelessWidget {
  const _PathDot({
    required this.color,
    required this.edge,
    required this.child,
    this.size = AppSize.shortcut,
  });

  final Color color;
  final Color edge;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: <BoxShadow>[
        BoxShadow(color: edge, offset: const Offset(0, 5)),
      ],
    ),
    alignment: Alignment.center,
    child: child,
  );
}

class _PathNodeRow extends StatelessWidget {
  const _PathNodeRow({required this.node, required this.dx});

  final PathNode node;
  final double dx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final challenge = node.challenge;

    return switch (node.status) {
      PathNodeStatus.current => _CurrentNode(node: node, dx: dx),
      PathNodeStatus.done => _Placed(
        dx: dx,
        label: challenge.title,
        labelColor: scheme.onSurface,
        semantics: '${challenge.title}, đã xong',
        child: _PathDot(
          color: scheme.primary,
          edge: _primaryEdge,
          child: SvgPicture.asset(
            'assets/icons/check-bold.svg',
            width: 26,
            height: 26,
          ),
        ),
      ),
      PathNodeStatus.locked => _Placed(
        dx: dx,
        label: challenge.title,
        labelColor: scheme.onSurfaceVariant,
        semantics: '${challenge.title}, chưa mở',
        child: _PathDot(
          color: scheme.surfaceContainerHighest,
          edge: _lockedEdge,
          child: Icon(Icons.lock, size: 22, color: scheme.onSurfaceVariant),
        ),
      ),
    };
  }
}

/// Đặt nút 56 lệch [dx] so với giữa (mỗi nút một hàng cao 64) và ghi tên thử
/// thách ở phía còn nhiều chỗ: nút lệch trái thì chữ bên phải và ngược lại.
class _Placed extends StatelessWidget {
  const _Placed({
    required this.dx,
    required this.label,
    required this.labelColor,
    required this.semantics,
    required this.child,
  });

  final double dx;
  final String label;
  final Color labelColor;
  final String semantics;
  final Widget child;

  static const double _dot = AppSize.shortcut;
  static const double _gap = AppSpace.s8;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(fontWeight: FontWeight.w400, color: labelColor);

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: SizedBox(
        height: 64,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final left = width / 2 + dx - _dot / 2;
            final labelOnRight = dx <= 0;
            return Stack(
              children: <Widget>[
                Positioned(left: left, top: 0, child: child),
                Positioned(
                  left: labelOnRight ? left + _dot + _gap : 0,
                  right: labelOnRight ? 0 : width - left + _gap,
                  top: 0,
                  height: _dot,
                  child: Align(
                    alignment: labelOnRight
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Text(
                      label,
                      style: style,
                      textAlign: labelOnRight ? TextAlign.start : TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Nút đang làm: vòng 84 primary-container quanh nút 64 có icon lấp lánh,
/// bong bóng "tên · N phút" phía trên và Nốt Đợi đứng sát bên nút. Chạm để
/// mở S08.
class _CurrentNode extends StatelessWidget {
  const _CurrentNode({required this.node, required this.dx});

  final PathNode node;
  final double dx;

  static const double _ring = 84;
  static const double _mascot = 63;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final challenge = node.challenge;
    void open() => context.push(AppRoutes.challengeDetail(challenge.id));

    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: scheme.outlineVariant, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s14,
          vertical: AppSpace.s8,
        ),
        child: Text(
          '${challenge.title} · ${challenge.minutes} phút',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    final ring = SizedBox.square(
      dimension: _ring,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/illustrations/path-current-ring.svg',
            width: _ring,
            height: _ring,
          ),
          _PathDot(
            color: scheme.primary,
            edge: _primaryEdge,
            size: 64,
            child: SvgPicture.asset(
              'assets/icons/sparkle.svg',
              width: 28,
              height: 28,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: '${challenge.title}, đang làm',
      excludeSemantics: true,
      onTap: open,
      child: GestureDetector(
        onTap: open,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: <Widget>[
            bubble,
            RotatedBox(
              quarterTurns: 2,
              child: SvgPicture.asset(
                'assets/icons/tooltip-arrow.svg',
                width: 12.12,
                height: 6,
                colorFilter: ColorFilter.mode(
                  scheme.surfaceContainerLow,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            // Vòng nút lệch [dx]; mascot đứng sát phía còn nhiều chỗ.
            SizedBox(
              height: _ring,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final left = constraints.maxWidth / 2 + dx - _ring / 2;
                  final mascotRight = dx <= 0;
                  return Stack(
                    children: <Widget>[
                      Positioned(left: left, top: 0, child: ring),
                      Positioned(
                        left: mascotRight
                            ? left + _ring + AppSpace.s8
                            : left - AppSpace.s8 - _mascot * 0.89,
                        bottom: 0,
                        child: const IgnorePointer(
                          child: Mascot(state: MascotState.doi, size: _mascot),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpace.s8),
          ],
        ),
      ),
    );
  }
}

/// Chặng kế tiếp: thẻ viền đứt "Chặng 2 · mở khi xong 5 thẻ" thay cho dấu "?"
/// khó hiểu.
class _NextStage extends StatelessWidget {
  const _NextStage({required this.level, required this.cards});

  final int level;
  final int cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = 'Chặng $level · mở khi xong $cards thẻ';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s8),
      child: Semantics(
        label: '$text, chưa mở',
        excludeSemantics: true,
        child: CustomPaint(
          foregroundPainter: _DashedBorder(color: scheme.outline),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s14,
              vertical: AppSpace.s12,
            ),
            child: Row(
              spacing: AppSpace.s8,
              children: <Widget>[
                Icon(Icons.lock, size: 18, color: scheme.onSurfaceVariant),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Viền đứt 1 dp bo 12 quanh thẻ chặng kế tiếp.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

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
          const Radius.circular(AppRadius.r12),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
