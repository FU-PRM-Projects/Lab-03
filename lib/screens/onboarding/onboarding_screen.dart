import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note_type.dart';
import '../../models/onboarding.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mascot.dart';
import '../../widgets/quick_win_chip.dart';

/// S13a–g · Làm quen (flow A2): 4 câu hỏi, Tụi Nốt đang đọc, rồi hồ sơ khởi
/// đầu với cấp bắt đầu, 3 thẻ và giờ nhắc. Mở một lần sau lần đăng nhập đầu
/// tiên, làm lại được từ S12.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const List<String> _titles = <String>[
    'Bắt chuyện với người lạ, bạn thấy sao?',
    'Bạn muốn bớt thói quen nào?',
    'Nhịp sống của bạn thế nào?',
    'Bạn muốn tập điều gì?',
  ];

  static const List<String> _subtitles = <String>[
    'Tụi Nốt chọn cấp thử thách Dũng cảm vừa sức cho bạn.',
    'Chọn bao nhiêu cũng được. Bạn đổi lại được ở màn Tự chủ.',
    'Để chọn thẻ Vận động và giờ nhắc ghi nốt hợp với bạn.',
    'Chọn tối đa ${OnboardingGoal.maxCount} điều.',
  ];

  void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.today);

  Future<void> _confirmSkip(BuildContext context, WidgetRef ref) async {
    final skip = await showAppDialog(
      context: context,
      title: 'Bỏ qua làm quen?',
      message:
          'Tụi Nốt sẽ dùng thẻ cấp 1 và giờ nhắc 21:30. Bạn làm lại được ở '
          'Cài đặt bất cứ lúc nào.',
      confirmLabel: 'Bỏ qua',
      cancelLabel: 'Trả lời tiếp',
    );
    if (skip ?? false) {
      await ref.read(onboardingViewModelProvider.notifier).skipAll();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    ref.listen(onboardingViewModelProvider, (previous, next) {
      if (next.finished && !(previous?.finished ?? false)) _close(context);
      if (next.message != null && next.message != previous?.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
        viewModel.clearMessage();
      }
    });

    final questions = state.phase == OnboardingPhase.questions;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (questions && state.step == 0) {
          _confirmSkip(context, ref);
        } else {
          viewModel.back();
        }
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: questions
              ? 'Làm quen ${state.step + 1}/${OnboardingState.stepCount}'
              : 'Hồ sơ khởi đầu',
          leading: questions && state.step == 0
              ? AppBarLeading.close
              : AppBarLeading.back,
          onLeading: questions && state.step == 0
              ? () => _confirmSkip(context, ref)
              : viewModel.back,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSize.contentMaxWidth,
              ),
              child: switch (state.phase) {
                OnboardingPhase.questions => _Questions(state: state),
                OnboardingPhase.thinking => const _Thinking(),
                // "Bỏ qua làm quen": đang lưu, chưa có hồ sơ để hiện.
                OnboardingPhase.saving when state.plan == null => const Center(
                  child: CircularProgressIndicator(),
                ),
                OnboardingPhase.plan ||
                OnboardingPhase.saving => _PlanView(state: state),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Questions extends ConsumerWidget {
  const _Questions({required this.state});

  final OnboardingState state;

  bool get _answered => switch (state.step) {
    0 => state.answers.stranger != null,
    1 => state.answers.habits.isNotEmpty,
    2 => state.answers.move != null || state.answers.freeSlot != null,
    _ => state.answers.goals.isNotEmpty,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);
    final a = state.answers;
    final step = state.step;

    final Widget options = switch (step) {
      0 => _Choices<StrangerLevel>(
        values: StrangerLevel.values,
        selected: a.stranger,
        label: (v) => v.label,
        hint: (v) => v.hint,
        onSelect: viewModel.setStranger,
      ),
      1 => Wrap(
        spacing: AppSpace.s8,
        runSpacing: AppSpace.s8,
        children: <Widget>[
          for (final habit in state.habitOptions)
            QuickWinChip(
              label: habit,
              selected: a.habits.contains(habit),
              onSelected: (_) => viewModel.toggleHabit(habit),
            ),
        ],
      ),
      2 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Bạn vận động thế nào?', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpace.s8),
          _Choices<MoveHabit>(
            values: MoveHabit.values,
            selected: a.move,
            label: (v) => v.label,
            hint: (v) => v.hint,
            onSelect: viewModel.setMove,
          ),
          const SizedBox(height: AppSpace.s20),
          Text('Lúc nào bạn rảnh nhất?', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpace.s8),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: <Widget>[
              for (final slot in FreeSlot.values)
                QuickWinChip(
                  label: slot.label,
                  selected: a.freeSlot == slot,
                  onSelected: (_) => viewModel.setFreeSlot(slot),
                ),
            ],
          ),
        ],
      ),
      _ => Wrap(
        spacing: AppSpace.s8,
        runSpacing: AppSpace.s8,
        children: <Widget>[
          for (final goal in OnboardingGoal.values)
            QuickWinChip(
              label: goal.label,
              selected: a.goals.contains(goal),
              onSelected:
                  a.goals.contains(goal) ||
                      a.goals.length < OnboardingGoal.maxCount
                  ? (_) => viewModel.toggleGoal(goal)
                  : null,
            ),
        ],
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r4),
            child: LinearProgressIndicator(
              value: (step + 1) / OnboardingState.stepCount,
              minHeight: AppSpace.s6,
              semanticsLabel:
                  'Bước ${step + 1} trên '
                  '${OnboardingState.stepCount}',
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: <Widget>[
              const Align(
                alignment: Alignment.centerLeft,
                child: Mascot(state: MascotState.thongTha, size: 64),
              ),
              const SizedBox(height: AppSpace.s12),
              Semantics(
                header: true,
                child: Text(
                  OnboardingScreen._titles[step],
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                OnboardingScreen._subtitles[step],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.s20),
              options,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s8,
            AppSpace.screen,
            AppSpace.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton(
                label: step == OnboardingState.stepCount - 1 ? 'Xong' : 'Tiếp',
                expand: true,
                onPressed: _answered ? viewModel.next : null,
              ),
              AppButton(
                label: 'Bỏ qua câu này',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: () => viewModel.next(skip: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Danh sách lựa chọn một đáp án (thẻ có nhãn và dòng phụ).
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.hint,
    required this.onSelect,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final String Function(T) hint;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s8),
            child: Semantics(
              selected: value == selected,
              inMutuallyExclusiveGroup: true,
              button: true,
              child: Material(
                color: value == selected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  side: BorderSide(
                    color: value == selected
                        ? scheme.primary
                        : scheme.outlineVariant,
                    width: value == selected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  onTap: () => onSelect(value),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.s16),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                label(value),
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                hint(value),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (value == selected)
                          Icon(Icons.check_circle, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// S13e · Tụi Nốt đang đọc.
class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Mascot(state: MascotState.tapTrung, size: 120),
          const SizedBox(height: AppSpace.s16),
          Text(
            'Tụi Nốt đang đọc câu trả lời của bạn…',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.s16),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

/// S13f (AI) / S13g (bảng luật) · Hồ sơ khởi đầu + 3 thẻ.
class _PlanView extends ConsumerWidget {
  const _PlanView({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = state.plan!;
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);
    final remind = ViDateFormat.clock(plan.remindMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: <Widget>[
              const Center(child: Mascot(state: MascotState.xong)),
              const SizedBox(height: AppSpace.s12),
              Text(
                'BẠN LÀ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Semantics(
                header: true,
                child: Text(
                  plan.profileLabel,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                [
                  for (final MapEntry(key: topic, value: level)
                      in plan.startLevels.entries)
                    '${topic.label} cấp $level',
                ].join(' · '),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (!plan.fromAi) ...<Widget>[
                const SizedBox(height: AppSpace.s12),
                Text(
                  'Nốt AI đang nghỉ, nên Tụi Nốt chọn theo câu trả lời của '
                  'bạn.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpace.s20),
              Text('3 thẻ để bắt đầu', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpace.s8),
              if (plan.cards.isEmpty)
                Text(
                  'Chưa tải được kho thẻ. Thẻ sẽ có ở tab Thử thách.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                for (final card in plan.cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.noteTint(NoteType.thuThach),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.s16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              card.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(card.title, style: theme.textTheme.titleSmall),
                          ],
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: AppSpace.s12),
              Text(
                'Nhắc ghi nốt mỗi tối lúc $remind',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s8,
            AppSpace.screen,
            AppSpace.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton(
                label: 'Bắt đầu',
                expand: true,
                loading: state.phase == OnboardingPhase.saving,
                onPressed: state.phase == OnboardingPhase.saving
                    ? null
                    : viewModel.finish,
              ),
              AppButton(
                label: 'Sửa câu trả lời',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: state.phase == OnboardingPhase.saving
                    ? null
                    : viewModel.back,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
