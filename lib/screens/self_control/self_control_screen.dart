import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note_type.dart';
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
import '../../widgets/note_tile.dart';
import '../../widgets/quick_win_chip.dart';
import '../../widgets/setting_row.dart';
import '../../widgets/state_views.dart';
import '../jar/jar_screen.dart';

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

  /// Thói quen đang theo dõi: 0–1 thì ghi luôn (vẫn 2 chạm từ S02), từ 2 thì
  /// hỏi "Bạn vừa dừng gì?" và chạm một chip là ghi. Đang khoá thì không lộ
  /// tên thói quen.
  Future<void> _recordStop(SelfControlSummary? summary, bool locked) async {
    final habits = locked || summary == null
        ? const <String>[]
        : <String>[
            for (final habit in summary.habits.all)
              if (summary.habits.selected.contains(habit)) habit,
          ];
    if (habits.length <= 1) {
      await _viewModel.recordStop(habit: habits.firstOrNull);
      return;
    }
    final habit = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _StopSheet(habits: habits),
    );
    if (habit != null && mounted) {
      await _viewModel.recordStop(habit: habit);
    }
  }

  /// "Ghi lại vừa rồi": hỏi "Vừa rồi thế nào?" rồi đi tiếp nhánh dừng được
  /// (nốt Tự chủ) hoặc nhánh lỡ lướt (nốt Nhật ký, không trừ gì).
  Future<void> _recordMoment(SelfControlSummary? summary, bool locked) async {
    final outcome = await showModalBottomSheet<_Outcome>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _OutcomeSheet(),
    );
    if (outcome == null || !mounted) return;
    switch (outcome) {
      case _Outcome.stopped:
        await _recordStop(summary, locked);
      case _Outcome.slipped:
        _openSlipSheet();
    }
  }

  void _openSlipSheet() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SlipSheet(
      onSave: _viewModel.recordSlip,
      // Mở hũ ở bộ lọc Nhật ký để thấy ngay nốt vừa lưu.
      onOpenJar: () {
        ref.read(jarFilterProvider.notifier).select(NoteType.nhatKy);
        context.go(AppRoutes.jar);
      },
    ),
  );

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
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.s16,
                AppSpace.screen,
                AppSpace.s24,
              ),
              children: <Widget>[
                // Figma `Card/tóm tắt tự chủ`: mascot Tập Trung, số lần
                // Display/44 và chú thích Label/14, căn giữa.
                Semantics(
                  label: summary == null
                      ? 'Đang đếm số lần tự chủ tháng này'
                      : '${summary.monthCount} lần tự chủ tháng này',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.s16),
                    child: Column(
                      spacing: AppSpace.s8,
                      children: <Widget>[
                        const Mascot(state: MascotState.tapTrung, size: 113.4),
                        Column(
                          spacing: AppSpace.s4,
                          children: <Widget>[
                            Text(
                              summary == null ? '–' : '${summary.monthCount}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                letterSpacing: -0.88,
                              ),
                            ),
                            Text(
                              'lần tự chủ tháng này',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w400,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                // Một nút cho cả hai kết quả (dừng được / lỡ lướt); dùng được
                // ngay, kể cả khi đang tải hoặc đang khoá.
                AppButton(
                  label: 'Ghi lại vừa rồi',
                  expand: true,
                  loading: state.saving,
                  onPressed: state.saving
                      ? null
                      : () => _recordMoment(summary, state.habitsLocked),
                ),
                // Thở 90 giây đã có lối tắt "Stress?" ở S02 (deviation D-26).
                const SizedBox(height: AppSpace.s16),
                Text(
                  'THÓI QUEN MUỐN BỚT',
                  style: AppTextStyles.of(context).overline.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.72,
                  ),
                ),
                const SizedBox(height: AppSpace.s2),
                Text(
                  'Chọn thói quen bạn đang muốn bớt. Khi dừng được, Nốt '
                  'hỏi bạn vừa dừng thói quen nào.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                  // Figma: dòng "Giờ tỉnh" hiện luôn khung giờ đang đặt.
                  SettingGroup(
                    children: <Widget>[
                      SettingRow.toggle(
                        title: 'Giờ tỉnh',
                        subtitle:
                            '${ViDateFormat.clock(summary.settings.awakeStart)}'
                            ' – '
                            '${ViDateFormat.clock(summary.settings.awakeEnd)}',
                        value: summary.settings.awakeEnabled,
                        onChanged: _viewModel.setAwakeEnabled,
                      ),
                      SettingRow.value(
                        title: 'Đổi khung giờ',
                        value: '',
                        onTap: () => _pickAwakeTimes(summary.settings),
                      ),
                    ],
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
      ],
    );
  }
}

enum _Outcome { stopped, slipped }

/// "Vừa rồi thế nào?": hai lựa chọn lớn, chạm là đi tiếp.
class _OutcomeSheet extends StatelessWidget {
  const _OutcomeSheet();

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s12,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                'Vừa rồi thế nào?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            _OptionCard(
              type: NoteType.tuChu,
              icon: SvgPicture.asset(
                'assets/icons/hand-stop.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
                excludeFromSemantics: true,
              ),
              title: 'Mình đã dừng được',
              subtitle: '+1 lần tự chủ vào hũ.',
              onTap: () => Navigator.of(context).pop(_Outcome.stopped),
            ),
            _OptionCard(
              type: NoteType.nhatKy,
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              title: 'Mình lỡ lướt quá đà',
              subtitle:
                  'Không sao. Ghi lại cảm giác để lần sau nhận ra sớm '
                  'hơn.',
              onTap: () => Navigator.of(context).pop(_Outcome.slipped),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một lựa chọn trong "Vừa rồi thế nào?": vòng 40 tô màu loại nốt sẽ lưu.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final NoteType type;
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s12,
              AppSpace.s12,
              AppSpace.s8,
              AppSpace.s12,
            ),
            child: Row(
              spacing: AppSpace.s12,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.noteTint(type),
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpace.s2,
                    children: <Widget>[
                      Text(title, style: theme.textTheme.labelLarge),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Bạn vừa dừng gì?": các thói quen đang theo dõi, chạm một chip là ghi.
class _StopSheet extends StatelessWidget {
  const _StopSheet({required this.habits});

  final List<String> habits;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s12,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                'Bạn vừa dừng gì?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Text(
              'Chạm một thói quen để ghi lần tự chủ này vào hũ.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: <Widget>[
                for (final habit in habits)
                  QuickWinChip(
                    label: habit,
                    selected: false,
                    onSelected: (_) => Navigator.of(context).pop(habit),
                  ),
              ],
            ),
          ],
        ),
      ),
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
  const _SlipSheet({required this.onSave, required this.onOpenJar});

  final Future<bool> Function(String feeling) onSave;

  /// "Xem trong hũ": mở hũ ở bộ lọc Nhật ký.
  final VoidCallback onOpenJar;

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
                  const SizedBox(height: AppSpace.s16),
                  IntrinsicHeight(
                    child: NoteTile(
                      type: NoteType.nhatKy,
                      title: SelfControlViewModel.slipTitle,
                      dateLabel: SelfControlViewModel.slipBody(_feeling!),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s12),
                  Text(
                    'Đã lưu vào Nhật ký trong hũ của bạn.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.s16),
                  AppButton(
                    label: 'Về Hôm nay',
                    expand: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.today);
                    },
                  ),
                  const SizedBox(height: AppSpace.s8),
                  AppButton(
                    label: 'Xem trong hũ',
                    variant: AppButtonVariant.text,
                    expand: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOpenJar();
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
