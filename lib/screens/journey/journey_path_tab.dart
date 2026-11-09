import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/challenge.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/journey_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/state_views.dart';
import 'journey_scene.dart';

/// S11a · Con đường: chặng hiện tại của từng chủ đề thử thách.
///
/// Banner chặng màu primary, rồi con đường **leo lên** (góp ý của giảng viên,
/// D-34): thẻ đã xong ở dưới, thẻ chưa mở ở trên, đích ở đỉnh là huy hiệu của
/// chủ đề và mở chặng sau. Phía sau là khung cảnh của chủ đề: Dũng cảm leo núi,
/// Vận động đi qua khu vườn ([JourneyScenePainter]). Màn mở sẵn ở thẻ đang làm.
/// Khác Figma (D-18): hàng chip chọn chủ đề ở trên, mỗi lần chỉ hiện đường của
/// một chủ đề; mỗi nút ghi tên thử thách bên cạnh.
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
      Data<List<PathStage>>(:final value) => _TopicPaths(stages: value),
    };
  }
}

/// Chủ đề đang xem trên S11a (trạng thái giao diện, giữ qua lần đổi tab con);
/// `null` là mặc định.
final selectedPathTopicProvider = NotifierProvider<SelectedPathTopic, String?>(
  SelectedPathTopic.new,
);

class SelectedPathTopic extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String topicId) => state = topicId;
}

/// Chip chủ đề + banner chặng + con đường của chủ đề đang chọn.
class _TopicPaths extends ConsumerWidget {
  const _TopicPaths({required this.stages});

  final List<PathStage> stages;

  /// Chủ đề đã chọn, mặc định là chủ đề đầu tiên còn thẻ đang làm.
  PathStage _selected(String? topicId) {
    for (final stage in stages) {
      if (stage.topic.id == topicId) return stage;
    }
    return stages.firstWhere(
      (s) => s.current != null,
      orElse: () => stages.first,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = _selected(ref.watch(selectedPathTopicProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpace.s16),
        if (stages.length > 1) ...<Widget>[
          _TopicChips(
            stages: stages,
            selected: stage,
            onSelected: (s) =>
                ref.read(selectedPathTopicProvider.notifier).select(s.topic.id),
          ),
          const SizedBox(height: AppSpace.s12),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: _StageBanner(stage: stage),
        ),
        const SizedBox(height: AppSpace.s12),
        Expanded(child: _ClimbView(stage: stage)),
      ],
    );
  }
}

/// Con đường leo lên trên nền cảnh: nút đầu tiên ở chân, đích ở đỉnh. Cuộn từ
/// dưới lên; mở màn (và mỗi lần đổi chủ đề) cuộn sẵn tới thẻ đang làm.
class _ClimbView extends StatefulWidget {
  const _ClimbView({required this.stage});

  final PathStage stage;

  @override
  State<_ClimbView> createState() => _ClimbViewState();
}

class _ClimbViewState extends State<_ClimbView> {
  ScrollController? _controller;
  String? _topicId;

  /// Khoảng cách dọc giữa hai nút.
  static const double _step = 140;

  /// Mép trên của nhãn đích: nằm dưới dải mờ đầu khung cuộn.
  static const double _summitLabelTop = 64;

  /// Đỉnh núi / gốc cây lớn: chừa chỗ cho nhãn đích, cờ và tán cây phía trên.
  static const double _summitY = 230;

  /// Từ mép trên tới nút cao nhất (đích + khoảng thở dưới đỉnh).
  static const double _summitSpace = _summitY + 70;

  /// Nút đầu tiên nằm trên thanh tab nổi, biển chặng và chân cảnh.
  static const double _bottomInset = AppSpace.tabContentBottom + 72;

  /// Biển "Chặng N" ở chân đường, ngay trên thanh tab nổi.
  static const double _startSignBottom = AppSpace.tabContentBottom + 8;

  /// Độ lệch ngang của nút thứ [i] so với giữa màn (Figma: 0, +56, +28…).
  static double _zigzag(int i) =>
      const <double>[0, 56, 28, -28, -56, -28, 28][i % 7];

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    // Leo từ dưới lên: thẻ đã xong luôn ở dưới, rồi thẻ đang làm, rồi thẻ chưa
    // mở (giữ thứ tự trong từng nhóm), dù người dùng làm thẻ theo thứ tự nào.
    final nodes = <PathNode>[
      for (final status in PathNodeStatus.values)
        ...stage.nodes.where((n) => n.status == status),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final viewport = constraints.maxHeight;
        final count = math.max(nodes.length, 1);
        final height = math.max(
          viewport,
          _bottomInset + (count - 1) * _step + _summitSpace,
        );
        final points = <Offset>[
          for (var i = 0; i < nodes.length; i++)
            Offset(width / 2 + _zigzag(i), height - _bottomInset - i * _step),
        ];
        final summit = Offset(width / 2, _summitY);
        final start = Offset(width / 2 - 40, height - 30);
        final reached = nodes
            .takeWhile((n) => n.status == PathNodeStatus.done)
            .length;

        // Cuộn sẵn tới thẻ đang làm (hoặc nút cuối đã xong) khi đổi chủ đề.
        if (_topicId != stage.topic.id || _controller == null) {
          _topicId = stage.topic.id;
          // Bỏ controller cũ sau khung hình này, khi cuộn cũ đã tách ra.
          final old = _controller;
          WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
          var offset = 0.0;
          if (points.isNotEmpty) {
            final focus = points[math.min(reached, points.length - 1)];
            offset = (height - focus.dy - viewport * 0.62).clamp(
              0.0,
              math.max(0.0, height - viewport),
            );
          }
          // Không khôi phục vị trí cũ từ PageStorage: mỗi chủ đề mở ở thẻ đang làm.
          _controller = ScrollController(
            initialScrollOffset: offset,
            keepScrollOffset: false,
          );
        }

        // Mép trên của cảnh mờ dần vào nền màn, không cắt ngang dưới banner.
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const <Color>[Color(0x00000000), Color(0xFF000000)],
            stops: <double>[0, (_fade / rect.height).clamp(0.0, 1.0)],
          ).createShader(rect),
          child: _scroll(
            stage,
            nodes,
            points,
            start,
            summit,
            reached,
            width,
            height,
          ),
        );
      },
    );
  }

  /// Độ cao dải mờ ở mép trên khung cuộn.
  static const double _fade = 48;

  Widget _scroll(
    PathStage stage,
    List<PathNode> nodes,
    List<Offset> points,
    Offset start,
    Offset summit,
    int reached,
    double width,
    double height,
  ) {
    return Builder(
      builder: (context) {
        return SingleChildScrollView(
          key: ValueKey<String>(stage.topic.id),
          controller: _controller,
          reverse: true,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: JourneyScenePainter(
                      topic: stage.topic,
                      points: points,
                      start: start,
                      summit: summit,
                      reached: reached,
                      primary: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                _Summit(stage: stage, top: _summitLabelTop),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _startSignBottom,
                  child: Center(child: _StartSign(stage: stage)),
                ),
                for (final (i, node) in nodes.indexed)
                  node.status == PathNodeStatus.current
                      ? _CurrentNode(node: node, at: points[i], dx: _zigzag(i))
                      : _Placed(
                          node: node,
                          at: points[i],
                          dx: _zigzag(i),
                          width: width,
                        ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hàng chip "Dũng cảm · 1/5", "Vận động · 0/5": cuộn ngang khi có nhiều chủ
/// đề, chip đang chọn nền primary.
class _TopicChips extends StatelessWidget {
  const _TopicChips({
    required this.stages,
    required this.selected,
    required this.onSelected,
  });

  final List<PathStage> stages;
  final PathStage selected;
  final ValueChanged<PathStage> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Row(
        spacing: AppSpace.s8,
        children: <Widget>[
          for (final stage in stages)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.minTouch),
              child: ChoiceChip(
                label: Text(
                  '${stage.topic.label} · '
                  '${stage.done}/${stage.nodes.length}',
                ),
                selected: stage.topic == selected.topic,
                onSelected: (_) => onSelected(stage),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Màu đổ bóng đặc dưới banner và nút (primary đậm, xám cho nút khoá).
const Color _primaryEdge = Color(0xFF252F80);
const Color _lockedEdge = Color(0xFFBDBFC7);

/// Figma `Banner chặng`: nền primary bo 20, bóng đặc 4, chữ trắng.
///
/// Chạm banner mở S08 của thẻ đang làm (giống chạm nút trên con đường); nút sổ
/// tay bên phải mở tab Thử thách để xem cả danh sách thẻ. Xong hết chặng thì
/// không còn thẻ đang làm, cả banner mở Thử thách.
class _StageBanner extends StatelessWidget {
  const _StageBanner({required this.stage});

  final PathStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onPrimary = scheme.onPrimary;
    final total = stage.nodes.length;
    final current = stage.current;
    final title = current?.challenge.title ?? 'Đã xong chặng này';
    final radius = BorderRadius.circular(20);
    void openList() => context.go(AppRoutes.challenges);
    final VoidCallback open = current == null
        ? openList
        : () => context.push(AppRoutes.challengeDetail(current.challenge.id));

    return Semantics(
      container: true,
      explicitChildNodes: true,
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
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s16,
                vertical: AppSpace.s12,
              ),
              child: Row(
                spacing: AppSpace.s12,
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          'Đang leo ${stage.topic.label}: $title, '
                          'đã làm ${stage.done} trên $total. '
                          '${current == null ? 'Mở Thử thách' : 'Mở thẻ'}',
                      onTap: open,
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.s6,
                        children: <Widget>[
                          Text(
                            'ĐANG LEO · ${stage.topic.label.toUpperCase()}',
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
                  ),
                  Semantics(
                    button: true,
                    label: 'Danh sách thẻ. Mở Thử thách',
                    onTap: openList,
                    excludeSemantics: true,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: openList,
                        child: const _NotebookBadge(),
                      ),
                    ),
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

/// Nhãn tên thử thách trên nền cảnh: viên thuốc trắng để đọc rõ trên núi,
/// trời hay đồi.
class _LabelPill extends StatelessWidget {
  const _LabelPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s10,
          vertical: AppSpace.s4,
        ),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: color,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Nút đã xong hoặc chưa mở, tâm tại [at]; tên thử thách ở phía còn nhiều chỗ:
/// nút lệch trái thì chữ bên phải và ngược lại.
class _Placed extends StatelessWidget {
  const _Placed({
    required this.node,
    required this.at,
    required this.dx,
    required this.width,
  });

  final PathNode node;
  final Offset at;
  final double dx;
  final double width;

  static const double _dot = AppSize.shortcut;
  static const double _gap = AppSpace.s8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final challenge = node.challenge;
    final done = node.status == PathNodeStatus.done;
    final labelOnRight = dx <= 0;
    final left = at.dx - _dot / 2;

    return Positioned(
      left: 0,
      right: 0,
      top: at.dy - _dot / 2,
      height: _dot + 6,
      child: Semantics(
        label: '${challenge.title}, ${done ? 'đã xong' : 'chưa mở'}',
        excludeSemantics: true,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: left,
              top: 0,
              child: done
                  ? _PathDot(
                      color: scheme.primary,
                      edge: _primaryEdge,
                      child: SvgPicture.asset(
                        'assets/icons/check-bold.svg',
                        width: 26,
                        height: 26,
                      ),
                    )
                  : _PathDot(
                      color: scheme.surface,
                      edge: _lockedEdge,
                      child: Icon(
                        Icons.lock,
                        size: 22,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Positioned(
              left: labelOnRight ? left + _dot + _gap : AppSpace.s8,
              right: labelOnRight ? AppSpace.s8 : width - left + _gap,
              top: 0,
              height: _dot,
              child: Align(
                alignment: labelOnRight
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: _LabelPill(
                  text: challenge.title,
                  color: done ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút đang làm, tâm tại [at]: vòng 84 quanh nút 64 có icon lấp lánh, bong
/// bóng "tên · N phút" phía trên và Nốt đang leo đứng sát bên. Chạm để mở S08.
class _CurrentNode extends StatelessWidget {
  const _CurrentNode({required this.node, required this.at, required this.dx});

  final PathNode node;
  final Offset at;
  final double dx;

  static const double _ring = 84;
  static const double _mascot = 63;
  static const double _bubbleArea = 52;

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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

    final left = at.dx - _ring / 2;
    final mascotRight = dx <= 0;

    return Positioned(
      left: 0,
      right: 0,
      top: at.dy - _ring / 2 - _bubbleArea,
      height: _bubbleArea + _ring,
      child: Semantics(
        button: true,
        label: '${challenge.title}, đang làm',
        excludeSemantics: true,
        onTap: open,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: AppSpace.screen,
              right: AppSpace.screen,
              top: 0,
              child: GestureDetector(
                onTap: open,
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
                  ],
                ),
              ),
            ),
            Positioned(
              left: left,
              top: _bubbleArea,
              child: GestureDetector(onTap: open, child: ring),
            ),
            Positioned(
              left: mascotRight
                  ? left + _ring + AppSpace.s8
                  : left - AppSpace.s8 - _mascot * 0.89,
              top: _bubbleArea + _ring - _mascot,
              child: const IgnorePointer(
                child: Mascot(state: MascotState.doi, size: _mascot),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Đích ở đỉnh: huy hiệu của chủ đề, và chặng sau mở khi xong mọi thẻ. Núi có
/// cờ cắm trên đỉnh; vườn có cây lớn (vẽ ở nền).
class _Summit extends StatelessWidget {
  const _Summit({required this.stage, required this.top});

  final PathStage stage;

  /// Khoảng cách từ mép trên nội dung tới nhãn.
  final double top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final place = stage.topic == ChallengeTopic.dungCam
        ? 'Lên đỉnh'
        : 'Tới cây lớn';
    final total = stage.nodes.length;
    final conquered = total > 0 && stage.done == total;
    final badge = 'huy hiệu ${stage.topic.label}';
    // Đỉnh là cửa sang chặng sau: chặng này ở chân đường, chặng sau ở trên.
    final title = stage.hasNextLevel
        ? 'Chặng ${stage.level + 1} · ${stage.topic.label}'
        : 'Đích · ${stage.topic.label}';
    final subtitle = conquered
        ? 'Đã chinh phục · nhận $badge'
        : '$place nhận $badge · xong $total thẻ để mở';
    final locked = !conquered && stage.hasNextLevel;

    return Positioned(
      left: AppSpace.screen,
      right: AppSpace.screen,
      top: top,
      child: Semantics(
        label: <String>[title, if (locked) 'chưa mở', subtitle].join('. '),
        excludeSemantics: true,
        child: Column(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s12,
                  vertical: AppSpace.s6,
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpace.s6,
                      children: <Widget>[
                        Icon(
                          locked
                              ? Icons.lock_rounded
                              : Icons.emoji_events_rounded,
                          size: 18,
                          color: locked
                              ? scheme.onSurfaceVariant
                              : AppPalette.heat4,
                        ),
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Biển "Chặng N · xuất phát" ở chân đường: chặng đang leo nằm dưới, chặng
/// sau nằm trên đỉnh, nên thứ tự chặng đọc từ dưới lên như con đường.
class _StartSign extends StatelessWidget {
  const _StartSign({required this.stage});

  final PathStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = 'Chặng ${stage.level} · xuất phát';

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: _primaryEdge, offset: Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s12,
            vertical: AppSpace.s6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s6,
            children: <Widget>[
              Icon(Icons.flag_rounded, size: 16, color: scheme.onPrimary),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.of(context).overline
                    .copyWith(color: scheme.onPrimary, letterSpacing: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
