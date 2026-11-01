import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/note_detail_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mascot.dart';
import '../../widgets/note_type_icon.dart';
import '../../widgets/state_views.dart';

/// S06 · Chi tiết nốt (xem / sửa / xoá).
class NoteDetailScreen extends ConsumerStatefulWidget {
  const NoteDetailScreen({required this.noteId, this.edit = false, super.key});

  final String noteId;

  /// Mở sẵn chế độ sửa (`?edit=1`, từ "Viết thêm" ở S04).
  final bool edit;

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  NoteDetailArgs get _args => (id: widget.noteId, edit: widget.edit);
  NoteDetailViewModel get _viewModel =>
      ref.read(noteDetailViewModelProvider(_args).notifier);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.jar);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showAppDialog(
      context: context,
      title: 'Bỏ thay đổi?',
      message: 'Những gì bạn vừa sửa sẽ không được lưu.',
      confirmLabel: 'Bỏ thay đổi',
      cancelLabel: 'Sửa tiếp',
    );
    if ((discard ?? false) && mounted) {
      _viewModel.cancelEdit();
      _leave();
    }
  }

  Future<void> _confirmDelete() async {
    final delete = await showAppDialog(
      context: context,
      title: 'Xoá nốt này?',
      message: 'Bạn có 5 giây để hoàn tác.',
      confirmLabel: 'Xoá',
      kind: AppDialogKind.destructive,
    );
    if ((delete ?? false) && mounted) {
      _viewModel.delete();
      // Về S05, nơi hiện snackbar Hoàn tác (handout S06).
      context.go(AppRoutes.jar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = noteDetailViewModelProvider(_args);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (next.editing && !(previous?.editing ?? false)) {
        _sync(_title, next.title);
        _sync(_body, next.body);
      } else if (next.editing) {
        // "Gợi ý" đổi nhật ký từ ViewModel.
        _sync(_body, next.body);
      }
      if (next.message != null && previous?.message != next.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
        _viewModel.clearMessage();
      }
    });

    final loaded = state.loaded;
    return PopScope(
      canPop: !state.hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: 'Chi tiết nốt',
          actions: loaded == null || state.editing
              ? null
              : <Widget>[
                  IconButton(
                    onPressed: _viewModel.startEdit,
                    icon: const _BarIcon('edit'),
                    tooltip: 'Sửa',
                  ),
                  // Figma: action thứ hai là "⋯", Xoá nằm trong menu.
                  PopupMenuButton<VoidCallback>(
                    tooltip: 'Tuỳ chọn',
                    icon: const _BarIcon('more'),
                    onSelected: (action) => action(),
                    itemBuilder: (context) => <PopupMenuEntry<VoidCallback>>[
                      PopupMenuItem<VoidCallback>(
                        value: _confirmDelete,
                        child: const Text('Xoá nốt'),
                      ),
                    ],
                  ),
                ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSize.contentMaxWidth,
              ),
              child: switch (state.note) {
                Loading<Note>() || Empty<Note>() => const LoadingState.spinner(
                  message: 'Đang mở nốt…',
                ),
                Failure<Note>(:final message, :final offline) => Padding(
                  padding: const EdgeInsets.all(AppSpace.screen),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ErrorState(
                        title: 'Chưa mở được nốt',
                        cause: message,
                        kind: offline
                            ? ErrorKind.offline
                            : ErrorKind.loadFailed,
                        onRetry: _viewModel.retry,
                      ),
                      const SizedBox(height: AppSpace.s8),
                      AppButton(
                        label: 'Về Hũ',
                        variant: AppButtonVariant.text,
                        onPressed: () => context.go(AppRoutes.jar),
                      ),
                    ],
                  ),
                ),
                Data<Note>(:final value) =>
                  state.editing
                      ? _EditView(
                          state: state,
                          title: _title,
                          body: _body,
                          viewModel: _viewModel,
                        )
                      : _ReadView(note: value),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadView extends StatelessWidget {
  const _ReadView({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final mood = note.mood;
    final tagColor = note.type.tagColor(scheme, colors);

    // Figma S06: mascot tâm trạng + chú thích, thẻ `Note/lớn` (nền tint theo
    // loại, bo 24, lề 24), rồi nhật ký Body/16 màu on-surface-variant.
    // Cao hết vùng nội dung để bắt đầu từ trên, không bị `Center` đẩy xuống.
    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
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
            Column(
              spacing: AppSpace.s8,
              children: <Widget>[
                Mascot(
                  state: mood?.mascot ?? MascotState.thongTha,
                  size: 124.2,
                ),
                if (mood != null)
                  Text(
                    'Tâm trạng hôm đó: ${mood.label}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.noteTint(note.type),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s12,
                  children: <Widget>[
                    Row(
                      spacing: AppSpace.s6,
                      children: <Widget>[
                        SvgPicture.asset(
                          note.type.tagIconAsset,
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            tagColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${note.type.label.toUpperCase()} · '
                            '${ViDateFormat.shortDate(note.createdAt)}',
                            style: AppTextStyles.of(context).overline
                                .copyWith(color: tagColor, letterSpacing: 0.72),
                          ),
                        ),
                      ],
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        note.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          letterSpacing: -0.18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (note.body.isNotEmpty)
              Text(
                note.body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Icon 24 dp nét 2 trên app bar (`Icon/Pencil`, "⋯").
class _BarIcon extends StatelessWidget {
  const _BarIcon(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: 24,
    height: 24,
    colorFilter: ColorFilter.mode(
      Theme.of(context).colorScheme.onSurface,
      BlendMode.srcIn,
    ),
  );
}

class _EditView extends StatelessWidget {
  const _EditView({
    required this.state,
    required this.title,
    required this.body,
    required this.viewModel,
  });

  final NoteDetailState state;
  final TextEditingController title;
  final TextEditingController body;
  final NoteDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  label: 'Tiêu đề',
                  controller: title,
                  maxLength: NoteLimits.title,
                  errorText: state.titleError,
                  onChanged: viewModel.setTitle,
                ),
                const SizedBox(height: AppSpace.s16),
                AppTextField(
                  label: 'Nhật ký',
                  helper: 'Không bắt buộc',
                  controller: body,
                  // "Viết thêm" từ S04: gõ được ngay.
                  autofocus: true,
                  minLines: 5,
                  maxLines: 12,
                  maxLength: NoteLimits.body,
                  keyboardType: TextInputType.multiline,
                  onChanged: viewModel.setBody,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: 'Gợi ý',
                    icon: Icons.lightbulb_outline,
                    variant: AppButtonVariant.text,
                    onPressed: viewModel.addPrompt,
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
            AppSpace.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppButton(
                label: 'Lưu',
                expand: true,
                loading: state.saving,
                onPressed: state.canSave ? viewModel.save : null,
              ),
              const SizedBox(height: AppSpace.s16),
              AppButton(
                label: 'Huỷ',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: state.saving ? null : viewModel.cancelEdit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
