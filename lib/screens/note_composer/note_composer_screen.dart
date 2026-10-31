import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/mood.dart';
import '../../models/note.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/note_composer_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mood_option.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/quick_win_chip.dart';

/// S03 · Ghi nốt (3 bước: tâm trạng → chiến thắng → vài dòng).
class NoteComposerScreen extends ConsumerStatefulWidget {
  const NoteComposerScreen({this.step = 1, super.key});

  /// Bước mở đầu 1–3 (`?step=`).
  final int step;

  @override
  ConsumerState<NoteComposerScreen> createState() => _NoteComposerScreenState();
}

class _NoteComposerScreenState extends ConsumerState<NoteComposerScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  NoteComposerViewModel get _viewModel =>
      ref.read(noteComposerViewModelProvider(widget.step).notifier);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Giữ ô nhập khớp với nháp khi ViewModel đổi nội dung (mở lại nháp, chạm
  /// chip chiến thắng nhanh).
  void _sync(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.today);
    }
  }

  Future<void> _onBack() async {
    switch (_viewModel.back()) {
      case ComposerBack.close:
        _close();
      case ComposerBack.previousStep:
        break;
      case ComposerBack.confirmKeepDraft:
        final keep = await showAppDialog(
          context: context,
          title: 'Giữ nốt đang ghi?',
          message: 'Nốt sẽ chờ ở Hôm nay.',
          confirmLabel: 'Giữ nháp',
          cancelLabel: 'Bỏ',
        );
        // Đóng dialog bằng Back: ở lại màn này.
        if (keep == null || !mounted) return;
        await (keep ? _viewModel.keepDraft() : _viewModel.discardDraft());
        if (mounted) _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = noteComposerViewModelProvider(widget.step);
    final state = ref.watch(provider);
    final textStyles = AppTextStyles.of(context);
    final scheme = Theme.of(context).colorScheme;

    ref.listen(provider, (previous, next) {
      _sync(_title, next.draft.title);
      _sync(_body, next.draft.body);
      if (next.savedNoteId != null && previous?.savedNoteId == null) {
        // S04 thay route S03 (go, không push) theo handout mục 3.
        context.go(AppRoutes.noteSaved(next.savedNoteId!));
      }
      if (next.message != null && previous?.message != next.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
        _viewModel.clearMessage();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: const AppTopBar(title: 'Ghi nốt'),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSize.narrowContentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      AppSpace.s8,
                      AppSpace.screen,
                      0,
                    ),
                    child: Text(
                      'Bước ${state.step}/3',
                      style: textStyles.overline.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpace.screen),
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        child: KeyedSubtree(
                          key: ValueKey<int>(state.step),
                          child: switch (state.step) {
                            1 => _MoodStep(
                              state: state,
                              onSelect: _viewModel.selectMood,
                            ),
                            2 => _WinStep(
                              state: state,
                              controller: _title,
                              onChanged: _viewModel.setTitle,
                              onPick: _viewModel.pickQuickWin,
                              onSubmitted: _viewModel.next,
                            ),
                            _ => _JournalStep(
                              controller: _body,
                              onChanged: _viewModel.setBody,
                            ),
                          },
                        ),
                      ),
                    ),
                  ),
                  _Actions(state: state, viewModel: _viewModel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodStep extends StatelessWidget {
  const _MoodStep({required this.state, required this.onSelect});

  final NoteComposerState state;
  final ValueChanged<Mood> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Hôm nay bạn thấy thế nào?',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpace.s24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.s12,
          runSpacing: AppSpace.s12,
          children: <Widget>[
            for (final mood in Mood.values)
              MoodOption(
                mood: mood,
                selected: state.draft.mood == mood,
                onTap: () => onSelect(mood),
              ),
          ],
        ),
        if (state.isRoughDay) ...<Widget>[
          const SizedBox(height: AppSpace.s24),
          Text('Ngày rối: 1 chip là đủ.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpace.s12),
          const _FirstAidCard(),
        ],
      ],
    );
  }
}

/// Thẻ "Sơ cứu 1 phút: 5-4-3-2-1" cho ngày Rối.
class _FirstAidCard extends StatelessWidget {
  const _FirstAidCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.of(context).tintLavender,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Sơ cứu 1 phút: 5-4-3-2-1',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpace.s4),
            Text(
              'Gọi tên 5 thứ bạn thấy, 4 thứ chạm được, 3 âm thanh, '
              '2 mùi và 1 vị.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpace.s12),
            AppButton(
              label: 'Làm cùng Nốt',
              variant: AppButtonVariant.tonal,
              onPressed: () => context.push(AppRoutes.breathe),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinStep extends StatelessWidget {
  const _WinStep({
    required this.state,
    required this.controller,
    required this.onChanged,
    required this.onPick,
    required this.onSubmitted,
  });

  final NoteComposerState state;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPick;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = state.draft.title.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Hôm nay bạn làm được gì?', style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpace.s24),
        AppTextField(
          label: 'Chiến thắng nhỏ',
          controller: controller,
          // Tiêu chí 30 giây: ô tự focus để gõ ngay.
          autofocus: true,
          maxLength: NoteLimits.title,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted(),
        ),
        const SizedBox(height: AppSpace.s16),
        Text('Hoặc chọn nhanh', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpace.s8),
        Wrap(
          spacing: AppSpace.s8,
          runSpacing: AppSpace.s8,
          children: <Widget>[
            for (final label in state.quickWins)
              QuickWinChip(
                label: label,
                selected: title == label,
                onSelected: (_) => onPick(label),
              ),
          ],
        ),
        if (state.oldNote case final Note note) ...<Widget>[
          const SizedBox(height: AppSpace.s24),
          Text(
            'Một chiến thắng cũ của bạn:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          SizedBox(
            height: AppSize.noteTile.height,
            child: NoteTile(
              type: note.type,
              title: note.title,
              dateLabel: ViDateFormat.shortDate(note.createdAt),
            ),
          ),
        ],
      ],
    );
  }
}

class _JournalStep extends StatelessWidget {
  const _JournalStep({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Viết thêm vài dòng?', style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpace.s24),
        AppTextField(
          label: 'Nhật ký hôm nay',
          helper: 'Không bắt buộc',
          controller: controller,
          minLines: 3,
          maxLines: 8,
          maxLength: NoteLimits.body,
          keyboardType: TextInputType.multiline,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          'Bí ý? Thử trả lời: điều gì làm bạn thấy nhẹ hơn hôm nay?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Vùng nút cố định cuối màn, theo từng bước.
class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.viewModel});

  final NoteComposerState state;
  final NoteComposerViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final saving = state.saving;
    final primary = switch (state.step) {
      3 => AppButton(
        label: 'Lưu vào hũ',
        expand: true,
        loading: saving,
        onPressed: saving ? null : viewModel.save,
      ),
      _ => AppButton(
        label: 'Tiếp',
        expand: true,
        onPressed: state.canContinue && !saving ? viewModel.next : null,
      ),
    };
    final skip = switch (state.step) {
      2 => AppButton(
        label: 'Bỏ qua nhật ký',
        variant: AppButtonVariant.text,
        expand: true,
        loading: saving,
        onPressed: state.canContinue && !saving
            ? () => viewModel.save(skipJournal: true)
            : null,
      ),
      3 => AppButton(
        label: 'Bỏ qua',
        variant: AppButtonVariant.text,
        expand: true,
        onPressed: saving ? null : () => viewModel.save(skipJournal: true),
      ),
      _ => null,
    };

    return Padding(
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
          primary,
          if (skip != null) ...<Widget>[
            const SizedBox(height: AppSpace.s8),
            skip,
          ],
        ],
      ),
    );
  }
}
