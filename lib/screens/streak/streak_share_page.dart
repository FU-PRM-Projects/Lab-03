import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/streak.dart';
import '../../services/clock.dart';
import '../../services/streak_share_service.dart';
import '../../theme/app_tokens.dart';
import '../../utils/streak_card_image.dart';
import '../../utils/streak_share_text.dart';
import '../../viewmodels/streak_share_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import '../../widgets/streak_share_card.dart';
import '../common/screen_skeleton.dart';

/// S04b · Chia sẻ chuỗi: xem trước thẻ 9:16 rồi lưu ảnh vào Firestore và mở
/// hộp chia sẻ của hệ thống.
class StreakSharePage extends ConsumerStatefulWidget {
  const StreakSharePage({required this.streak, super.key});

  final StreakSummary streak;

  @override
  ConsumerState<StreakSharePage> createState() => _StreakSharePageState();
}

class _StreakSharePageState extends ConsumerState<StreakSharePage> {
  final GlobalKey _boundaryKey = GlobalKey(debugLabel: 'streak-share-card');
  final GlobalKey _buttonKey = GlobalKey(debugLabel: 'streak-share-button');

  /// Ảnh đang được dựng/chụp; chặn chạm lặp trong lúc chờ.
  bool _rendering = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(streakShareViewModelProvider);
    final date = ref.watch(clockProvider).now();

    ref.listen(streakShareViewModelProvider, (previous, next) {
      if (next.phase == StreakSharePhase.done &&
          previous?.phase != StreakSharePhase.done) {
        _notify(next.message ?? 'Đã lưu ảnh chuỗi để chia sẻ.');
      } else if (next.phase == StreakSharePhase.failed &&
          previous?.phase != StreakSharePhase.failed) {
        _notify(next.message ?? 'Chưa chia sẻ được chuỗi. Thử lại nhé.');
      }
    });

    return NestedScaffold(
      title: 'Chia sẻ chuỗi',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.s16,
                AppSpace.screen,
                AppSpace.s16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSize.narrowContentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpace.s12,
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 9 / 16,
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: StreakShareCard(
                            streak: widget.streak,
                            date: date,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              0,
              AppSpace.screen,
              AppSpace.s24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSize.narrowContentMaxWidth,
                ),
                child: AppButton(
                  key: _buttonKey,
                  label: 'Chia sẻ ảnh',
                  icon: Icons.ios_share_rounded,
                  expand: true,
                  loading: _rendering || state.busy,
                  onPressed: _share,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share() async {
    if (_rendering) return;
    setState(() => _rendering = true);
    try {
      final png = await _render();
      if (!mounted) return;
      if (png == null) {
        _notify('Ảnh chuỗi quá lớn để lưu. Thử lại nhé.');
        return;
      }
      final origin = _shareOrigin();
      await ref
          .read(streakShareViewModelProvider.notifier)
          .share(
            streak: widget.streak,
            png: png,
            fileName: StreakShareText.fileName(widget.streak),
            text: StreakShareText.message(widget.streak),
            origin: origin,
          );
    } on Object {
      if (mounted) _notify('Chưa tạo được ảnh chuỗi. Thử lại nhé.');
    } finally {
      if (mounted) setState(() => _rendering = false);
    }
  }

  /// Chụp thẻ ở các độ phân giải giảm dần cho tới khi ảnh vừa giới hạn
  /// document 1 MiB của Firestore. `null` khi mọi mức đều quá lớn.
  Future<Uint8List?> _render() async {
    final renderer = ref.read(streakImageRendererProvider);
    for (final pixelRatio in const <double>[3, 2, 1.5, 1]) {
      final png = await renderer(_boundaryKey, pixelRatio: pixelRatio);
      if (png.length <= StreakShareLimits.maxPngBytes) return png;
    }
    return null;
  }

  /// Vị trí nút chia sẻ cho `sharePositionOrigin` (iPad cần neo popover).
  Rect? _shareOrigin() {
    final object = _buttonKey.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return null;
    return object.localToGlobal(Offset.zero) & object.size;
  }

  void _notify(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }
}

/// Màn chia sẻ mở từ route mà không có [StreakSummary] (ví dụ gõ tay đường
/// dẫn): chỉ đường về Hôm nay thay vì dựng thẻ rỗng.
class StreakShareUnavailable extends StatelessWidget {
  const StreakShareUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    return NestedScaffold(
      title: 'Chia sẻ chuỗi',
      body: ErrorState(
        title: 'Chưa có chuỗi để chia sẻ',
        cause: 'Mở chuỗi từ thẻ ở Hôm nay rồi chọn chia sẻ.',
        retryLabel: 'Về Hôm nay',
        onRetry: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
