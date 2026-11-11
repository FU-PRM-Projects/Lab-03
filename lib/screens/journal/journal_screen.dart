import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note.dart';
import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/journal_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/quick_win_chip.dart';

/// Viết nhật ký: viết ra suy nghĩ, bí thì chạm câu hỏi gợi ý, xong thì chọn
/// câu rõ ràng nhất làm tiêu đề nốt Nhật ký (deviation D-29).
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _text = TextEditingController();
  final _stopwatch = Stopwatch()..start();
  Timer? _ticker;
  bool _showPrompts = false;

  /// Đang ở bước "Điều rõ ràng nhất là gì?".
  bool _picking = false;
  String? _title;

  JournalViewModel get _viewModel =>
      ref.read(journalViewModelProvider.notifier);

  /// Lưu nháp sau khi ngừng gõ một lúc, để không ghi bộ nhớ máy mỗi phím.
  Timer? _draftDebounce;
  late final AppLifecycleListener _lifecycle;

  /// Đang hỏi "Tiếp tục bản nháp?": chưa lưu nháp mới để không ghi đè nháp cũ.
  bool _checkingDraft = true;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_picking) setState(() {});
    });
    _text.addListener(_scheduleDraftSave);
    // App bị đưa xuống nền (có thể bị hệ điều hành tắt sau đó): lưu ngay.
    _lifecycle = AppLifecycleListener(onHide: _saveDraftNow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraft());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _draftDebounce?.cancel();
    _lifecycle.dispose();
    _text.dispose();
    super.dispose();
  }

  /// Flow P4: trang viết dở từ lần trước (app bị tắt giữa chừng).
  Future<void> _offerDraft() async {
    final draft = await _viewModel.loadDraft();
    if (!mounted) return;
    if (draft != null && _text.text.trim().isEmpty) {
      final resume = await showAppDialog(
        context: context,
        title: 'Tiếp tục bản nháp?',
        message:
            'Bạn còn một trang nhật ký viết dở từ lần trước '
            '(${draft.trim().length} ký tự).',
        confirmLabel: 'Viết tiếp',
        cancelLabel: 'Bắt đầu trang mới',
      );
      if (!mounted) return;
      if (resume ?? false) {
        _text.value = TextEditingValue(
          text: draft,
          selection: TextSelection.collapsed(offset: draft.length),
        );
      } else {
        await _viewModel.clearDraft();
      }
    }
    _checkingDraft = false;
  }

  void _scheduleDraftSave() {
    if (_checkingDraft) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 800), _saveDraftNow);
  }

  void _saveDraftNow() {
    if (_checkingDraft) return;
    _draftDebounce?.cancel();
    unawaited(_viewModel.saveDraft(_text.text));
  }

  void _close() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.today);

  Future<void> _onBack() async {
    if (_picking) {
      setState(() => _picking = false);
      return;
    }
    if (_text.text.trim().isEmpty) {
      _draftDebounce?.cancel();
      await _viewModel.clearDraft();
      if (mounted) _close();
      return;
    }
    final leave = await showAppDialog(
      context: context,
      title: 'Bỏ trang đang viết?',
      message: 'Những gì bạn vừa viết sẽ không được lưu.',
      confirmLabel: 'Bỏ',
      cancelLabel: 'Viết tiếp',
      kind: AppDialogKind.destructive,
    );
    if ((leave ?? false) && mounted) {
      _draftDebounce?.cancel();
      _checkingDraft = true; // không lưu lại khi ô nhập bị huỷ
      await _viewModel.clearDraft();
      if (mounted) _close();
    }
  }

  /// Chèn câu hỏi gợi ý xuống dòng mới, con trỏ đặt ngay dưới để viết tiếp.
  void _insertPrompt(String prompt) {
    final current = _text.text.trimRight();
    final next = current.isEmpty ? '$prompt\n' : '$current\n$prompt\n';
    if (next.length > NoteLimits.body) return;
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() {});
  }

  void _done() {
    final options = JournalViewModel.sentences(_text.text);
    setState(() {
      _picking = true;
      _title = options.length == 1 ? options.single : null;
    });
  }

  String get _elapsed {
    final seconds = _stopwatch.elapsed.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalViewModelProvider);

    ref.listen(journalViewModelProvider, (previous, next) {
      if (next.savedNoteId != null && previous?.savedNoteId == null) {
        // Nốt đã lưu và nháp đã xoá ở ViewModel: không lưu nháp lại nữa.
        _draftDebounce?.cancel();
        _checkingDraft = true;
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
        if (!didPop) unawaited(_onBack());
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: 'Viết nhật ký',
          leading: _picking ? AppBarLeading.back : AppBarLeading.close,
          onLeading: _onBack,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSize.narrowContentMaxWidth,
              ),
              child: CustomScrollView(
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
                      child: _picking
                          ? _PickStep(
                              options: JournalViewModel.sentences(_text.text),
                              selected: _title,
                              saving: state.saving,
                              onSelect: (title) =>
                                  setState(() => _title = title),
                              onSave: () => _viewModel.save(
                                title: _title!,
                                text: _text.text,
                              ),
                            )
                          : _WriteStep(
                              controller: _text,
                              elapsed: _elapsed,
                              showPrompts: _showPrompts,
                              onChanged: (_) => setState(() {}),
                              onTogglePrompts: () =>
                                  setState(() => _showPrompts = !_showPrompts),
                              onPrompt: _insertPrompt,
                              onDone: _text.text.trim().isEmpty ? null : _done,
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

class _WriteStep extends StatelessWidget {
  const _WriteStep({
    required this.controller,
    required this.elapsed,
    required this.showPrompts,
    required this.onChanged,
    required this.onTogglePrompts,
    required this.onPrompt,
    required this.onDone,
  });

  final TextEditingController controller;
  final String elapsed;
  final bool showPrompts;
  final ValueChanged<String> onChanged;
  final VoidCallback onTogglePrompts;
  final ValueChanged<String> onPrompt;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s12,
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Viết ra những suy nghĩ trong tâm trí bạn',
                  style: theme.textTheme.titleLarge?.copyWith(
                    letterSpacing: -0.44,
                  ),
                ),
              ),
            ),
            // Đếm lên để thấy mình đã viết bao lâu; không ép giờ.
            Semantics(
              label: 'Đã viết $elapsed',
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s4,
                children: <Widget>[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  Text(
                    elapsed,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        AppTextField(
          label: 'Suy nghĩ của bạn',
          hint: 'Cứ viết liền tay, không cần hay, không cần đúng…',
          controller: controller,
          autofocus: true,
          minLines: 8,
          maxLines: 16,
          maxLength: NoteLimits.body,
          keyboardType: TextInputType.multiline,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpace.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: QuickWinChip(
            label: showPrompts ? 'Ẩn câu hỏi gợi ý' : 'Bí rồi? Hỏi mình đi',
            selected: showPrompts,
            onSelected: (_) => onTogglePrompts(),
          ),
        ),
        if (showPrompts) ...<Widget>[
          const SizedBox(height: AppSpace.s8),
          Text(
            'Chạm một câu để thêm vào trang rồi viết tiếp.',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: <Widget>[
              for (final prompt in JournalViewModel.prompts)
                QuickWinChip(
                  label: prompt,
                  selected: false,
                  onSelected: (_) => onPrompt(prompt),
                ),
            ],
          ),
        ],
        const Spacer(),
        const SizedBox(height: AppSpace.s16),
        AppButton(label: 'Xong', expand: true, onPressed: onDone),
      ],
    );
  }
}

/// "Điều rõ ràng nhất là gì?": chạm một câu để làm tiêu đề nốt.
class _PickStep extends StatelessWidget {
  const _PickStep({
    required this.options,
    required this.selected,
    required this.saving,
    required this.onSelect,
    required this.onSave,
  });

  final List<String> options;
  final String? selected;
  final bool saving;
  final ValueChanged<String> onSelect;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Điều rõ ràng nhất là gì?',
            style: theme.textTheme.titleLarge?.copyWith(letterSpacing: -0.44),
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        Text(
          'Đọc lại và chạm một câu bạn muốn nhớ. Câu đó thành tiêu đề nốt.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        for (final option in options) ...<Widget>[
          _SentenceTile(
            text: option,
            selected: option == selected,
            onTap: () => onSelect(option),
          ),
          const SizedBox(height: AppSpace.s8),
        ],
        const Spacer(),
        const SizedBox(height: AppSpace.s16),
        AppButton(
          label: 'Lưu vào hũ',
          expand: true,
          loading: saving,
          onPressed: selected == null || saving ? null : onSave,
        ),
      ],
    );
  }
}

class _SentenceTile extends StatelessWidget {
  const _SentenceTile({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.r12);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide(color: scheme.primary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s12,
                vertical: AppSpace.s12,
              ),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
