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
/// đang làm có bong bóng tên thử thách, chưa mở) như một con đường.
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
              _LockedNext(
                label: 'Chặng ${stage.level + 1}',
                dx: _zigzag(stage.nodes.length),
              ),
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
        child: Semantics(
          label: '${challenge.title}, đã xong',
          excludeSemantics: true,
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
      ),
      PathNodeStatus.locked => _Placed(
        dx: dx,
        child: Semantics(
          label: '${challenge.title}, chưa mở',
          excludeSemantics: true,
          child: _PathDot(
            color: scheme.surfaceContainerHighest,
            edge: _lockedEdge,
            child: Icon(Icons.lock, size: 22, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    };
  }
}

/// Đặt nút lệch [dx] so với giữa, mỗi nút một hàng cao 64.
class _Placed extends StatelessWidget {
  const _Placed({required this.dx, required this.child});

  final double dx;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: Center(
      child: Transform.translate(offset: Offset(dx, 0), child: child),
    ),
  );
}

/// Nút đang làm: vòng 84 primary-container quanh nút 64 có icon lấp lánh,
/// bong bóng "tên · N phút" phía trên và Nốt Đợi đứng cạnh. Chạm để mở S08.
class _CurrentNode extends StatelessWidget {
  const _CurrentNode({required this.node, required this.dx});

  final PathNode node;
  final double dx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final challenge = node.challenge;
    void open() => context.push(AppRoutes.challengeDetail(challenge.id));

    return Semantics(
      button: true,
      label: '${challenge.title}, đang làm',
      excludeSemantics: true,
      onTap: open,
      child: SizedBox(
        height: 150,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // Mascot đứng phía đối diện với hướng lệch của nút.
            Positioned(
              left: dx >= 0 ? AppSpace.s8 : null,
              right: dx < 0 ? AppSpace.s8 : null,
              // Dưới bong bóng, ngang với nút, để không che tên thử thách.
              bottom: 0,
              child: const IgnorePointer(
                child: Mascot(state: MascotState.doi, size: 94.5),
              ),
            ),
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: GestureDetector(
                  onTap: open,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                          border: Border.all(
                            color: scheme.outlineVariant,
                            width: 2,
                          ),
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
                          ),
                        ),
                      ),
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
                      SizedBox.square(
                        dimension: 84,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SvgPicture.asset(
                              'assets/illustrations/path-current-ring.svg',
                              width: 84,
                              height: 84,
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

/// Figma `mốc · chưa mở`: huy hiệu 50 viền outline cho chặng kế tiếp.
class _LockedNext extends StatelessWidget {
  const _LockedNext({required this.label, required this.dx});

  final String label;
  final double dx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Placed(
      dx: dx,
      child: Semantics(
        label: '$label, chưa mở',
        excludeSemantics: true,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerHighest,
            border: Border.all(color: scheme.outline, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            '?',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
