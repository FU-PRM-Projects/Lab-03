import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/breathing_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mascot.dart';
import '../../widgets/quick_win_chip.dart';

/// S10 · Thở 90 giây. Mở thẳng, không chờ dữ liệu (tiêu chí < 2 giây).
class BreathingScreen extends ConsumerWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(breathingViewModelProvider);
    final viewModel = ref.read(breathingViewModelProvider.notifier);

    ref.listen(breathingViewModelProvider, (previous, next) {
      // Rung nhẹ mỗi lần đổi hít / thở (handout S10).
      if (previous != null &&
          !next.after &&
          !next.roundDone &&
          previous.phase != next.phase) {
        HapticFeedback.lightImpact();
      }
      if (next.savedNoteId != null && previous?.savedNoteId == null) {
        context.go(AppRoutes.noteSaved(next.savedNoteId!));
      }
      if (next.message != null && previous?.message != next.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
        viewModel.clearMessage();
      }
    });

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Thở cùng Nốt',
        leading: AppBarLeading.close,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.narrowContentMaxWidth,
            ),
            child: state.after
                ? _After(state: state, viewModel: viewModel)
                : _Breathing(state: state, viewModel: viewModel),
          ),
        ),
      ),
    );
  }
}

class _Breathing extends StatelessWidget {
  const _Breathing({required this.state, required this.viewModel});

  final BreathingState state;
  final BreathingViewModel viewModel;

  /// Figma `vòng thở`: vòng ngoài 240 (mono/1), vòng trong primary-container
  /// to khi hít vào / giữ hơi, nhỏ khi thở ra.
  static const double _ring = 240;
  static const double _big = 220;
  static const double _small = 140;

  void _choosePattern(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final pattern in BreathPattern.values)
              ListTile(
                title: Text('Kiểu ${pattern.label}'),
                subtitle: Text(pattern.description),
                trailing: state.pattern == pattern
                    ? const Icon(Icons.check)
                    : null,
                selected: state.pattern == pattern,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  viewModel.changePattern(pattern);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final big = state.phase != BreathPhase.exhale;
    final status = state.roundDone
        ? 'Xong một vòng'
        : 'Còn ${ViDateFormat.countdown(state.remaining)}';

    return _SpacedBody(
      top: <Widget>[
        Container(
          width: _ring,
          height: _ring,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.mono1,
          ),
          alignment: Alignment.center,
          child: AnimatedContainer(
            // Không có chuyển động: đổi kích thước theo bước.
            duration: noMotion || state.roundDone
                ? Duration.zero
                : Duration(seconds: state.phaseSeconds),
            curve: Curves.easeInOut,
            width: big ? _big : _small,
            height: big ? _big : _small,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
            ),
            alignment: Alignment.center,
            child: const Mascot(state: MascotState.thongTha, size: 102.6),
          ),
        ),
        Column(
          spacing: AppSpace.s8,
          children: <Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                state.roundDone ? 'Bạn làm tốt lắm' : state.phase.label,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: -0.56,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              state.pattern.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        // Figma `thời gian`: thanh 6 dp chạy theo vòng 90 giây.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s8,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 1 - state.remaining / BreathingState.roundSeconds,
                minHeight: AppSpace.s6,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            Text(
              status,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: () => _choosePattern(context),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onPrimaryContainer,
              textStyle: theme.textTheme.labelLarge,
              minimumSize: const Size(AppSize.minTouch, AppSize.minTouch),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
            ),
            child: const Text('Đổi kiểu thở'),
          ),
        ),
      ],
      bottom: <Widget>[
        AppButton(
          label: 'Cơn sóng đã hạ',
          variant: AppButtonVariant.tonal,
          expand: true,
          onPressed: viewModel.finish,
        ),
        AppButton(
          label: 'Thở thêm 1 vòng',
          variant: AppButtonVariant.text,
          expand: true,
          onPressed: viewModel.restart,
        ),
      ],
    );
  }
}

class _After extends StatelessWidget {
  const _After({required this.state, required this.viewModel});

  final BreathingState state;
  final BreathingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stops = state.todayStops;

    return _SpacedBody(
      top: <Widget>[
        Container(
          width: 170,
          height: 170,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.mono1,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
            ),
            alignment: Alignment.center,
            child: const OverflowBox(
              maxWidth: 140,
              maxHeight: 140,
              child: Mascot(state: MascotState.xong, size: 102.6),
            ),
          ),
        ),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            'Bạn đã vượt qua!',
            style: theme.textTheme.headlineMedium?.copyWith(
              letterSpacing: -0.56,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Figma `Lần dừng hôm nay`: số Headline/28 + chú thích trên nền
        // primary-container.
        if (stops != null && stops > 0)
          Semantics(
            label: '$stops lần dừng lại hôm nay',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(AppSpace.s16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                spacing: AppSpace.s12,
                children: <Widget>[
                  Text(
                    '$stops',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: -0.56,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'lần dừng lại hôm nay',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s8,
          children: <Widget>[
            Text(
              'Làm gì tiếp?',
              style: AppTextStyles.of(context).title17Bold
                  .copyWith(letterSpacing: -0.17),
            ),
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: <Widget>[
                for (final alternative in BreathingState.alternatives)
                  QuickWinChip(
                    label: alternative,
                    selected: state.alternative == alternative,
                    onSelected: (_) => viewModel.chooseAlternative(alternative),
                  ),
              ],
            ),
          ],
        ),
      ],
      bottom: <Widget>[
        AppButton(
          label: 'Ghi vào hũ',
          expand: true,
          loading: state.saving,
          onPressed: state.saving ? null : viewModel.saveToJar,
        ),
        AppButton(
          label: 'Về Hôm nay',
          variant: AppButtonVariant.text,
          expand: true,
          onPressed: () => context.go(AppRoutes.today),
        ),
      ],
    );
  }
}

/// Bố cục S10: nội dung căn giữa giữa hai khoảng co giãn, nút dính đáy, các
/// khối cách nhau 16; màn thấp hoặc chữ lớn thì cuộn.
class _SpacedBody extends StatelessWidget {
  const _SpacedBody({required this.top, required this.bottom});

  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.s16,
              AppSpace.screen,
              AppSpace.s24,
            ),
            // Căn giữa để vòng thở giữ đúng kích thước; khối nào cần rộng hết
            // (thanh thời gian, chip, nút) tự kéo giãn.
            child: Column(
              spacing: AppSpace.s16,
              children: <Widget>[
                const Spacer(),
                ...top,
                const Spacer(),
                ...bottom,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
