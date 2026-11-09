import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/mood.dart';
import '../../models/self_control.dart';
import '../../router/app_routes.dart';
import '../../services/ai_service.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/free_tell_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mascot.dart';
import '../../widgets/quick_win_chip.dart';

/// S03b · Kể tự do (flow A1): người dùng kể một đoạn, Nốt AI (Gemini) tách
/// thành vài nốt ngắn để xem, sửa, chọn rồi lưu. Lần đầu dùng hỏi đồng ý và
/// nói rõ gửi gì, không gửi gì. AI lỗi / tắt thì giữ đoạn kể, gợi ý ghi tay.
class FreeTellScreen extends ConsumerStatefulWidget {
  const FreeTellScreen({super.key});

  @override
  ConsumerState<FreeTellScreen> createState() => _FreeTellScreenState();
}

class _FreeTellScreenState extends ConsumerState<FreeTellScreen> {
  final _text = TextEditingController();

  static const int _minChars = 10;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  FreeTellViewModel get _viewModel =>
      ref.read(freeTellViewModelProvider.notifier);

  void _close() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.today);

  Future<void> _sort() async {
    final settings = ref.read(settingsViewModelProvider).settings;
    final consented = switch (settings) {
      Data<UserSettings>(:final value) => value.aiEnabled,
      _ => false,
    };
    if (!consented) {
      final ok = await _showConsent();
      if (!(ok ?? false) || !mounted) return;
      await ref.read(settingsViewModelProvider.notifier).setAiEnabled(true);
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await _viewModel.sort(_text.text);
  }

  Future<bool?> _showConsent() {
    final maxChars = ref.read(aiServiceProvider).config.maxChars;
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpace.s8),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
            ],
          ),
        );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s20,
              0,
              AppSpace.s20,
              AppSpace.s20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Nốt AI sắp xếp giúp', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpace.s12),
                line(
                  Icons.send_outlined,
                  'Gửi tới Gemini: đoạn bạn vừa kể (tối đa $maxChars ký tự). '
                  'Email và số điện thoại được che trước khi gửi.',
                ),
                line(
                  Icons.block_outlined,
                  'Không gửi: tên và email tài khoản, ảnh, các nốt cũ.',
                ),
                line(
                  Icons.edit_note_outlined,
                  'Đoạn kể không được lưu. Chỉ những nốt bạn chọn mới vào hũ, '
                  'và bạn sửa được trước khi lưu.',
                ),
                line(
                  Icons.toggle_on_outlined,
                  'Tắt lúc nào cũng được ở Cài đặt → "Nốt AI sắp xếp giúp".',
                ),
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  label: 'Đồng ý và sắp xếp',
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                AppButton(
                  label: 'Để sau',
                  variant: AppButtonVariant.text,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSupport() async {
    await showAppDialog(
      context: context,
      title: 'Hình như hôm nay hơi nặng nề',
      message:
          'Thử kể với một người bạn tin cậy, hoặc ghé phòng tư vấn tâm lý của '
          'trường. Nếu thấy không an toàn, gọi ngay 115.',
      confirmLabel: 'Mình hiểu rồi',
      cancelLabel: 'Để sau',
    );
    _viewModel.dismissSupport();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(freeTellViewModelProvider);
    final config = ref.watch(aiServiceProvider).config;
    // Giữ ViewModel cài đặt sống để biết đã đồng ý dùng Nốt AI chưa.
    ref.watch(settingsViewModelProvider.select((s) => s.settings));

    ref.listen(freeTellViewModelProvider, (previous, next) {
      if (next.phase == FreeTellPhase.saved &&
          previous?.phase != FreeTellPhase.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu ${next.savedCount} nốt vào hũ.')),
        );
        _close();
      }
      if (next.needsSupport && !(previous?.needsSupport ?? false)) {
        _showSupport();
      }
    });

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: 'Kể tự do',
        leading: state.phase == FreeTellPhase.review
            ? AppBarLeading.back
            : AppBarLeading.close,
        onLeading: state.phase == FreeTellPhase.review
            ? _viewModel.backToWriting
            : _close,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.contentMaxWidth,
            ),
            child: switch (state.phase) {
              FreeTellPhase.writing => _Writing(
                text: _text,
                aiOn: config.enabled,
                maxChars: config.maxChars,
                minChars: _minChars,
                error: state.error,
                onSort: _sort,
                onManual: () => context.pushReplacement(AppRoutes.newNote()),
              ),
              FreeTellPhase.thinking => _Thinking(onCancel: _viewModel.cancel),
              FreeTellPhase.review ||
              FreeTellPhase.saving ||
              FreeTellPhase.saved => _Review(state: state),
            },
          ),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

class _Writing extends StatefulWidget {
  const _Writing({
    required this.text,
    required this.aiOn,
    required this.maxChars,
    required this.minChars,
    required this.error,
    required this.onSort,
    required this.onManual,
  });

  final TextEditingController text;
  final bool aiOn;
  final int maxChars;
  final int minChars;
  final String? error;
  final VoidCallback onSort;
  final VoidCallback onManual;

  @override
  State<_Writing> createState() => _WritingState();
}

class _WritingState extends State<_Writing> {
  @override
  void initState() {
    super.initState();
    widget.text.addListener(_changed);
  }

  @override
  void dispose() {
    widget.text.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enough = widget.text.text.trim().length >= widget.minChars;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  'Hôm nay của bạn thế nào?',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                widget.aiOn
                    ? 'Kể tự do như nhắn cho bạn thân. Tụi Nốt tách thành vài '
                          'nốt nhỏ để bạn chọn.'
                    : 'Nốt AI đang nghỉ. Bạn vẫn ghi nốt tay như thường nhé.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              TextField(
                controller: widget.text,
                minLines: 6,
                maxLines: 12,
                maxLength: widget.maxChars,
                decoration: const InputDecoration(
                  hintText:
                      'Ví dụ: Sáng dậy đúng giờ, chiều hỏi được thầy một câu, '
                      'tối dừng lướt TikTok lúc 11 giờ…',
                  alignLabelWithHint: true,
                ),
              ),
              if (widget.error != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.s8),
                    child: Text(
                      widget.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
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
              if (widget.aiOn)
                AppButton(
                  label: widget.error == null
                      ? 'Nhờ Tụi Nốt sắp xếp'
                      : 'Thử lại',
                  icon: Icons.auto_awesome,
                  expand: true,
                  onPressed: enough ? widget.onSort : null,
                ),
              AppButton(
                label: 'Ghi tay',
                variant: widget.aiOn
                    ? AppButtonVariant.text
                    : AppButtonVariant.filled,
                expand: true,
                onPressed: widget.onManual,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking({required this.onCancel});

  final VoidCallback onCancel;

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
            'Tụi Nốt đang đọc đoạn kể…',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s16),
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpace.s16),
          TextButton(onPressed: onCancel, child: const Text('Huỷ')),
        ],
      ),
    ),
  );
}

class _Review extends ConsumerWidget {
  const _Review({required this.state});

  final FreeTellState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final viewModel = ref.read(freeTellViewModelProvider.notifier);
    final saving = state.phase != FreeTellPhase.review;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s12,
                      vertical: AppSpace.s4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: scheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: AppSpace.s4),
                        Flexible(
                          child: Text(
                            'Gợi ý từ Nốt AI · kiểm tra trước khi lưu',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              Text('Tâm trạng hôm nay', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpace.s8),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: <Widget>[
                  for (final mood in Mood.values)
                    QuickWinChip(
                      label: mood.label,
                      selected: state.mood == mood,
                      onSelected: saving
                          ? null
                          : (_) => viewModel.setMood(
                              state.mood == mood ? null : mood,
                            ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s20),
              Text(
                state.suggestions.isEmpty
                    ? 'Tụi Nốt chưa tìm thấy việc nào để ghi.'
                    : 'Tụi Nốt tách được ${state.suggestions.length} nốt',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpace.s8),
              for (final (i, s) in state.suggestions.indexed)
                _SuggestionCard(
                  key: ValueKey<int>(i),
                  index: i,
                  suggestion: s,
                  enabled: !saving,
                ),
              if (state.error != null)
                Text(
                  state.error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
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
                label: 'Lưu ${state.keptCount} nốt',
                expand: true,
                loading: saving,
                onPressed: state.keptCount == 0 || saving
                    ? null
                    : viewModel.save,
              ),
              AppButton(
                label: 'Kể lại',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: saving ? null : viewModel.backToWriting,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends ConsumerStatefulWidget {
  const _SuggestionCard({
    required this.index,
    required this.suggestion,
    required this.enabled,
    super.key,
  });

  final int index;
  final EditableSuggestion suggestion;
  final bool enabled;

  @override
  ConsumerState<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<_SuggestionCard> {
  late final _title = TextEditingController(text: widget.suggestion.title);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = widget.suggestion;
    final viewModel = ref.read(freeTellViewModelProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.keep ? scheme.surfaceContainerLow : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: s.keep ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Wrap(
                      spacing: AppSpace.s6,
                      runSpacing: AppSpace.s6,
                      children: <Widget>[
                        for (final type in AiNoteSuggestion.types)
                          ChoiceChip(
                            label: Text(type.label),
                            selected: s.type == type,
                            onSelected: widget.enabled && s.keep
                                ? (_) => viewModel.setType(widget.index, type)
                                : null,
                          ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: s.keep ? 'Bỏ nốt này' : 'Giữ nốt này',
                    child: Checkbox(
                      value: s.keep,
                      onChanged: widget.enabled
                          ? (_) => viewModel.toggleKeep(widget.index)
                          : null,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _title,
                enabled: widget.enabled && s.keep,
                maxLength: AiNoteSuggestion.titleMax,
                decoration: const InputDecoration(labelText: 'Tiêu đề nốt'),
                onChanged: (v) => viewModel.setTitle(widget.index, v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
