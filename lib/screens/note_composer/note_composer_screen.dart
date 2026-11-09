import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/image_ref.dart';
import '../../models/note.dart';
import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/image_upload_view_model.dart';
import '../../viewmodels/note_composer_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_image_picker.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/quick_win_chip.dart';

/// S03 · Ghi nốt (3 bước: chụp khoảnh khắc → chiến thắng → vài dòng).
class NoteComposerScreen extends ConsumerStatefulWidget {
  const NoteComposerScreen({this.step = 1, this.groupId, super.key});

  /// Bước mở đầu 1–3 (`?step=`).
  final int step;

  /// Xếp nốt vào nhóm lần đầu này (`?group=`, "Thử lần nữa" ở S05e).
  final String? groupId;

  @override
  ConsumerState<NoteComposerScreen> createState() => _NoteComposerScreenState();
}

class _NoteComposerScreenState extends ConsumerState<NoteComposerScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  ComposerArgs get _args => (step: widget.step, groupId: widget.groupId);

  NoteComposerViewModel get _viewModel =>
      ref.read(noteComposerViewModelProvider(_args).notifier);

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
    final provider = noteComposerViewModelProvider(_args);
    final state = ref.watch(provider);

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
        appBar: AppTopBar(
          title: 'Ghi nốt',
          // Bước 1 là "đóng form"; bước 2–3 lùi về bước trước.
          leading: state.step == 1 ? AppBarLeading.close : AppBarLeading.back,
          onLeading: _onBack,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSize.narrowContentMaxWidth,
              ),
              // Figma `content`: lề 16, các khối cách 16, nút dính đáy (spacer
              // co giãn); bàn phím hoặc chữ lớn thì cuộn.
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpace.s16,
                        children: <Widget>[
                          _StepProgress(step: state.step),
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            child: KeyedSubtree(
                              key: ValueKey<int>(state.step),
                              child: switch (state.step) {
                                1 => _PhotoStep(
                                  image: state.draft.image,
                                  onRemoveImage: _viewModel.removeImage,
                                ),
                                2 => _WinStep(
                                  state: state,
                                  controller: _title,
                                  onChanged: _viewModel.setTitle,
                                  onPick: _viewModel.pickQuickWin,
                                  onSubmitted: _viewModel.next,
                                  onClearGroup: _viewModel.clearGroup,
                                ),
                                _ => _JournalStep(
                                  controller: _body,
                                  onChanged: _viewModel.setBody,
                                  image: state.draft.image,
                                ),
                              },
                            ),
                          ),
                          const Spacer(),
                          ..._actions(state),
                        ],
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

  /// Nút cuối màn theo từng bước: nút chính, rồi nút chữ "Bỏ qua" (cách 16).
  List<Widget> _actions(NoteComposerState state) {
    final saving = state.saving;
    final viewModel = _viewModel;
    final uploading = ref
        .watch(imageUploadViewModelProvider(ImageFolder.note))
        .busy;

    return <Widget>[
      if (state.step == kComposerSteps)
        AppButton(
          label: 'Lưu vào hũ',
          expand: true,
          loading: saving,
          onPressed: saving ? null : viewModel.save,
        )
      else
        AppButton(
          label: 'Tiếp',
          expand: true,
          // Bước ảnh: chờ tải xong mới đi tiếp, kẻo mất ảnh.
          onPressed: state.canContinue && !saving && !uploading
              ? viewModel.next
              : null,
        ),
      if (state.step == 1)
        AppButton(
          label: 'Bỏ qua',
          variant: AppButtonVariant.text,
          expand: true,
          onPressed: uploading ? null : viewModel.skipPhoto,
        ),
      if (state.step == 2)
        AppButton(
          label: 'Bỏ qua phần kể thêm',
          variant: AppButtonVariant.text,
          expand: true,
          loading: saving,
          onPressed: state.canContinue && !saving
              ? () => viewModel.save(skipJournal: true)
              : null,
        ),
      if (state.step == kComposerSteps)
        AppButton(
          label: 'Bỏ qua',
          variant: AppButtonVariant.text,
          expand: true,
          onPressed: saving ? null : () => viewModel.save(skipJournal: true),
        ),
    ];
  }
}

/// Figma `progress`: "Bước n/3" (Label/13) và 3 vạch 6 dp bo 3, cách 6.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s8,
      children: <Widget>[
        Text(
          'Bước $step/$kComposerSteps',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w400,
            color: scheme.onSurfaceVariant,
          ),
        ),
        ExcludeSemantics(
          child: Row(
            spacing: AppSpace.s6,
            children: <Widget>[
              for (var i = 1; i <= kComposerSteps; i++)
                Expanded(
                  child: Container(
                    height: AppSpace.s6,
                    decoration: BoxDecoration(
                      color: i <= step
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tiêu đề bước: Headline/22 Bold.
class _StepTitle extends StatelessWidget {
  const _StepTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(letterSpacing: -0.44),
    ),
  );
}

/// Bước 1: chụp lại khoảnh khắc (tuỳ chọn). Ảnh tải lên Cloudinary ngay, rồi
/// mới sang phần mô tả.
class _PhotoStep extends ConsumerWidget {
  const _PhotoStep({required this.image, required this.onRemoveImage});

  /// Ảnh đã đính kèm vào nháp.
  final ImageRef? image;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final upload = ref.watch(imageUploadViewModelProvider(ImageFolder.note));
    final uploadViewModel = ref.read(
      imageUploadViewModelProvider(ImageFolder.note).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s16,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s8,
          children: <Widget>[
            const _StepTitle('Chụp lại khoảnh khắc'),
            Text(
              'Ảnh được lưu riêng cho bạn. Không bắt buộc, bạn có thể bỏ qua.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppImagePicker(
          upload: upload,
          image: image,
          previewLabel: 'Ảnh khoảnh khắc của nốt',
          // Khung 2:1 để cả "Chụp ảnh", "Tiếp" và "Bỏ qua" vừa một màn hình.
          aspectRatio: 2,
          onPick: uploadViewModel.pickAndUpload,
          onCancel: uploadViewModel.cancel,
          onRemove: onRemoveImage,
        ),
      ],
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
    required this.onClearGroup,
  });

  final NoteComposerState state;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPick;
  final VoidCallback onSubmitted;
  final VoidCallback onClearGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = state.draft.title.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s16,
      children: <Widget>[
        const _StepTitle('Hôm nay bạn làm được gì?'),
        if (state.group case final group?)
          _GroupBadge(
            name: group.name,
            first: group.noteCount == 0,
            onClear: onClearGroup,
          ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s12,
          children: <Widget>[
            Text('Hoặc chọn nhanh', style: theme.textTheme.labelLarge),
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
          ],
        ),
      ],
    );
  }
}

/// "Xếp vào nhóm “Bắt chuyện”" ở bước 2 khi mở từ S05e; bỏ được bằng ✕.
class _GroupBadge extends StatelessWidget {
  const _GroupBadge({
    required this.name,
    required this.first,
    required this.onClear,
  });

  final String name;
  final bool first;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpace.s14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                first ? 'Lần đầu cho nhóm “$name”' : 'Xếp vào nhóm “$name”',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: onClear,
              tooltip: 'Không xếp vào nhóm',
              icon: const CloseButtonIcon(),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalStep extends StatelessWidget {
  const _JournalStep({
    required this.controller,
    required this.onChanged,
    required this.image,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Ảnh khoảnh khắc đã chụp ở bước 1, hiện lại để mô tả cho đúng nốt này.
  final ImageRef? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s16,
      children: <Widget>[
        const _StepTitle('Viết thêm vài dòng?'),
        if (image != null)
          AppNetworkImage.wide(
            image: image,
            semanticLabel: 'Ảnh khoảnh khắc của nốt',
            aspectRatio: 16 / 9,
          ),
        AppTextField(
          label: 'Kể thêm',
          helper: 'Không bắt buộc',
          controller: controller,
          minLines: 2,
          maxLines: 8,
          maxLength: NoteLimits.body,
          keyboardType: TextInputType.multiline,
          onChanged: onChanged,
        ),
        Text(
          'Bí ý? Thử trả lời: điều gì làm bạn thấy nhẹ hơn hôm nay?',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
