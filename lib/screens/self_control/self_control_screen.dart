import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/self_control.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/self_control_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mascot.dart';
import '../../widgets/quick_win_chip.dart';
import '../../widgets/setting_row.dart';
import '../../widgets/state_views.dart';

/// S09 · Tự chủ (flow F2).
class SelfControlScreen extends ConsumerStatefulWidget {
  const SelfControlScreen({super.key});

  @override
  ConsumerState<SelfControlScreen> createState() => _SelfControlScreenState();
}

class _SelfControlScreenState extends ConsumerState<SelfControlScreen> {
  late final AppLifecycleListener _lifecycle;

  SelfControlViewModel get _viewModel =>
      ref.read(selfControlViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Rời app thì khoá lại mục thói quen (handout S09).
    _lifecycle = AppLifecycleListener(onPause: () => _viewModel.lock());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _pickAwakeTimes(UserSettings settings) async {
    TimeOfDay toTime(int minutes) =>
        TimeOfDay(hour: minutes ~/ 60 % 24, minute: minutes % 60);
    final start = await showTimePicker(
      context: context,
      initialTime: toTime(settings.awakeStart),
      helpText: 'GIỜ TỈNH BẮT ĐẦU',
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: toTime(settings.awakeEnd),
      helpText: 'GIỜ TỈNH KẾT THÚC',
    );
    if (end == null) return;
    await _viewModel.setAwakeTimes(
      start.hour * 60 + start.minute,
      end.hour * 60 + end.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(selfControlViewModelProvider);

    ref.listen(selfControlViewModelProvider, (previous, next) {
      if (next.savedNoteId != null && previous?.savedNoteId == null) {
        context.go(AppRoutes.noteSaved(next.savedNoteId!));
      }
      if (next.message != null && previous?.message != next.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
        _viewModel.clearMessage();
      }
    });

    final summary = switch (state.summary) {
      Data<SelfControlSummary>(:final value) => value,
      _ => null,
    };

    return Scaffold(
      appBar: const AppTopBar(title: 'Tự chủ'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.contentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.screen),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Semantics(
                        label: summary == null
                            ? 'Đang đếm số lần tự chủ tháng này'
                            : '${summary.monthCount} lần tự chủ tháng này',
                        excludeSemantics: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              summary == null ? '–' : '${summary.monthCount}',
                              style: theme.textTheme.displayMedium,
                            ),
                            Text(
                              'lần tự chủ tháng này',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Mascot(state: MascotState.tapTrung),
                  ],
                ),
                const SizedBox(height: AppSpace.s24),
                // Dùng được ngay, kể cả khi đang tải hoặc đang khoá (F2: 2 chạm).
                AppButton(
                  label: 'Mình vừa dừng lại',
                  icon: Icons.pan_tool_outlined,
                  expand: true,
                  loading: state.saving,
                  onPressed: state.saving ? null : _viewModel.recordStop,
                ),
                const SizedBox(height: AppSpace.s8),
                AppButton(
                  label: 'Khó dừng? Thở 90 giây',
                  variant: AppButtonVariant.tonal,
                  icon: Icons.air,
                  expand: true,
                  onPressed: () => context.push(AppRoutes.breathe),
                ),
                const SizedBox(height: AppSpace.s24),
                Text(
                  'THÓI QUEN MUỐN BỚT',
                  style: AppTextStyles.of(context).overline
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpace.s8),
                switch (state.summary) {
                  Loading<SelfControlSummary>() ||
                  Empty<SelfControlSummary>() => const LoadingState.spinner(),
                  Failure<SelfControlSummary>(:final message, :final offline) =>
                    ErrorState(
                      title: 'Chưa tải được phần Tự chủ',
                      cause: message,
                      kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
                      onRetry: _viewModel.retry,
                    ),
                  Data<SelfControlSummary>(:final value) =>
                    state.habitsLocked
                        ? _LockedHabits(
                            unlocking: state.unlocking,
                            onUnlock: _viewModel.unlock,
                          )
                        : _Habits(habits: value.habits, viewModel: _viewModel),
                },
                if (summary != null) ...<Widget>[
                  const SizedBox(height: AppSpace.s16),
                  SettingRow.toggle(
                    title: 'Giờ tỉnh',
                    subtitle: 'Nhắc nhẹ khi dễ lướt vô thức',
                    value: summary.settings.awakeEnabled,
                    onChanged: _viewModel.setAwakeEnabled,
                  ),
                  SettingRow.value(
                    title: 'Khung giờ',
                    value:
                        '${ViDateFormat.clock(summary.settings.awakeStart)} – '
                        '${ViDateFormat.clock(summary.settings.awakeEnd)}',
                    onTap: () => _pickAwakeTimes(summary.settings),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mục thói quen khi bật "Khoá phần Tự chủ": không lộ tên thói quen.
class _LockedHabits extends StatelessWidget {
  const _LockedHabits({required this.unlocking, required this.onUnlock});

  final bool unlocking;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.of(context).tintGray,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: Text(
                    'Phần này đang khoá cho riêng bạn.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s12),
            AppButton(
              label: 'Mở khoá',
              variant: AppButtonVariant.outlined,
              icon: Icons.fingerprint,
              loading: unlocking,
              onPressed: unlocking ? null : onUnlock,
            ),
          ],
        ),
      ),
    );
  }
}

class _Habits extends StatelessWidget {
  const _Habits({required this.habits, required this.viewModel});

  final HabitList habits;
  final SelfControlViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpace.s8,
          runSpacing: AppSpace.s8,
          children: <Widget>[
            for (final habit in habits.all)
              QuickWinChip(
                label: habit,
                selected: habits.selected.contains(habit),
                onSelected: (_) => viewModel.toggleHabit(habit),
              ),
            QuickWinChip(
              label: '+ Thêm',
              selected: false,
              onSelected: (_) => showDialog<void>(
                context: context,
                builder: (_) => _AddHabitDialog(onAdd: viewModel.addHabit),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s8),
        AppButton(
          label: 'Mình đã lỡ lướt quá đà',
          variant: AppButtonVariant.text,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => _SlipSheet(onSave: viewModel.recordSlip),
          ),
        ),
      ],
    );
  }
}

/// "+ Thêm": ô nhập tên thói quen (tối đa 40 ký tự).
class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog({required this.onAdd});

  final Future<String?> Function(String habit) onAdd;

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final error = await widget.onAdd(_controller.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm thói quen muốn bớt'),
      content: AppTextField(
        label: 'Thói quen',
        controller: _controller,
        autofocus: true,
        maxLength: HabitList.maxLength,
        errorText: _error,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        AppButton(
          label: 'Huỷ',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Thêm',
          loading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}

/// Nhánh phục hồi F2: "Lúc đó mình đang thấy gì?", không trừ gì.
class _SlipSheet extends StatefulWidget {
  const _SlipSheet({required this.onSave});

  final Future<bool> Function(String feeling) onSave;

  @override
  State<_SlipSheet> createState() => _SlipSheetState();
}

class _SlipSheetState extends State<_SlipSheet> {
  String? _feeling;
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    final feeling = _feeling;
    if (feeling == null) return;
    setState(() => _saving = true);
    final ok = await widget.onSave(feeling);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.s24,
        ),
        child: _saved
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(child: Mascot(state: MascotState.thongTha)),
                  const SizedBox(height: AppSpace.s12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Nhận ra cũng là bắt đầu tự chủ.',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s24),
                  AppButton(
                    label: 'Về Hôm nay',
                    expand: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.today);
                    },
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Lúc đó mình đang thấy gì?',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    'Không sao cả. Ghi lại để lần sau nhận ra sớm hơn.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s16),
                  Wrap(
                    spacing: AppSpace.s8,
                    runSpacing: AppSpace.s8,
                    children: <Widget>[
                      for (final feeling in SelfControlViewModel.slipFeelings)
                        QuickWinChip(
                          label: feeling,
                          selected: _feeling == feeling,
                          onSelected: (_) => setState(() => _feeling = feeling),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s24),
                  AppButton(
                    label: 'Ghi lại',
                    expand: true,
                    loading: _saving,
                    onPressed: _feeling == null || _saving ? null : _save,
                  ),
                ],
              ),
      ),
    );
  }
}
