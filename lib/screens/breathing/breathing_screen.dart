import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
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
      appBar: const AppTopBar(title: 'Thở cùng Nốt'),
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

  /// Vòng tròn to khi hít vào / giữ hơi, nhỏ khi thở ra.
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
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final big = state.phase != BreathPhase.exhale;
    final status = state.roundDone
        ? 'Xong một vòng'
        : 'Còn ${ViDateFormat.countdown(state.remaining)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: _big + AppSpace.s16,
                  child: Center(
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
                        color: theme.colorScheme.primaryContainer,
                      ),
                      alignment: Alignment.center,
                      child: const Mascot(
                        state: MascotState.thongTha,
                        size: 72,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.roundDone ? 'Bạn làm tốt lắm' : state.phase.label,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  state.pattern.description,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  status,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s8,
            AppSpace.screen,
            AppSpace.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton(
                label: 'Đổi kiểu thở',
                variant: AppButtonVariant.tonal,
                expand: true,
                onPressed: () => _choosePattern(context),
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Cơn sóng đã hạ',
                expand: true,
                onPressed: viewModel.finish,
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Thở thêm 1 vòng',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: viewModel.restart,
              ),
            ],
          ),
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
    final stops = state.todayStops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: <Widget>[
              const Center(child: Mascot(state: MascotState.xong, size: 120)),
              const SizedBox(height: AppSpace.s16),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  'Bạn đã vượt qua!',
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              if (stops != null && stops > 0) ...<Widget>[
                const SizedBox(height: AppSpace.s8),
                Text(
                  '$stops lần dừng lại hôm nay',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpace.s24),
              Text('Làm gì tiếp?', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpace.s8),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: <Widget>[
                  for (final alternative in BreathingState.alternatives)
                    QuickWinChip(
                      label: alternative,
                      selected: state.alternative == alternative,
                      onSelected: (_) =>
                          viewModel.chooseAlternative(alternative),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s8,
            AppSpace.screen,
            AppSpace.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton(
                label: 'Ghi vào hũ',
                expand: true,
                loading: state.saving,
                onPressed: state.saving ? null : viewModel.saveToJar,
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Về Hôm nay',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: () => context.go(AppRoutes.today),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
