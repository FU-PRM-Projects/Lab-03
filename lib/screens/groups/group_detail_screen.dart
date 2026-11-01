import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/first_group.dart';
import '../../models/note.dart';
import '../../router/app_routes.dart';
import '../../services/clock.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/group_deleter.dart';
import '../../viewmodels/group_detail_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mascot.dart';
import '../../widgets/note_card.dart';
import '../../widgets/state_views.dart';

/// S05e · Chi tiết nhóm lần đầu.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  final String groupId;

  /// Số nốt gần nhất hiện ở "Gần nhất".
  static const int _recentCount = 3;

  Future<void> _rename(BuildContext context, WidgetRef ref, String name) =>
      showDialog<void>(
        context: context,
        builder: (_) => _RenameDialog(
          initial: name,
          onSave: ref
              .read(groupDetailViewModelProvider(groupId).notifier)
              .rename,
        ),
      );

  /// Xoá với Hoàn tác 5 giây (`GroupDeleter`): về S05 ngay, nhóm biến khỏi
  /// kệ; nốt vẫn ở trong hũ, chỉ rời nhóm.
  void _delete(BuildContext context, WidgetRef ref, FirstGroup group) {
    final deleter = ref.read(groupDeleterProvider.notifier)
      ..deleteWithUndo(group);
    final messenger = ScaffoldMessenger.of(context);
    context.go(AppRoutes.jar);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã xoá nhóm “${group.name}” · nốt vẫn ở trong hũ'),
          duration: GroupDeleter.undoWindow,
          action: SnackBarAction(label: 'Hoàn tác', onPressed: deleter.undo),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupDetailViewModelProvider(groupId));
    final detail = switch (state) {
      Data<GroupDetail>(:final value) => value,
      _ => null,
    };

    return Scaffold(
      appBar: AppTopBar(
        title: detail?.group.name ?? 'Nhóm lần đầu',
        actions: detail == null
            ? null
            : <Widget>[
                IconButton(
                  onPressed: () => _rename(context, ref, detail.group.name),
                  tooltip: 'Đổi tên nhóm',
                  icon: const _BarIcon('edit'),
                ),
                if (detail.group.createdAt != null)
                  PopupMenuButton<VoidCallback>(
                    tooltip: 'Tuỳ chọn',
                    icon: const _BarIcon('more'),
                    onSelected: (action) => action(),
                    itemBuilder: (context) => <PopupMenuEntry<VoidCallback>>[
                      PopupMenuItem<VoidCallback>(
                        value: () => _delete(context, ref, detail.group),
                        child: const Text('Xoá nhóm'),
                      ),
                    ],
                  ),
              ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          Loading<GroupDetail>() => const LoadingState.spinner(
            message: 'Đang mở nhóm…',
          ),
          Empty<GroupDetail>() => const Padding(
            padding: EdgeInsets.all(AppSpace.screen),
            child: EmptyState(
              title: 'Không tìm thấy nhóm này',
              message: 'Có thể nhóm đã bị xoá. Về Hũ để xem các nhóm khác.',
            ),
          ),
          Failure<GroupDetail>(:final message, :final offline) => Padding(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: ErrorState(
              title: 'Chưa mở được nhóm',
              cause: message,
              kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
              onRetry: ref
                  .read(groupDetailViewModelProvider(groupId).notifier)
                  .retry,
            ),
          ),
          Data<GroupDetail>(:final value) => _Body(
            detail: value,
            recent: value.notes.take(_recentCount).toList(),
            now: ref.read(clockProvider).now(),
            onTry: () =>
                context.push(AppRoutes.newNote(groupId: value.group.id)),
            onRename: () => _rename(context, ref, value.group.name),
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.detail,
    required this.recent,
    required this.now,
    required this.onTry,
    required this.onRename,
  });

  final GroupDetail detail;
  final List<Note> recent;
  final DateTime now;
  final VoidCallback onTry;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = AppTextStyles.of(context).title17Bold
        .copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.17);
    final group = detail.group;
    final trend = detail.anxietyTrend;

    // Figma S05e: thẻ lần đầu, mốc của nhóm, xu hướng hồi hộp, nốt gần nhất;
    // hai nút dính đáy.
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s16,
              children: <Widget>[
                _FirstCard(group: group),
                Semantics(
                  header: true,
                  child: Text('Mốc của nhóm', style: heading),
                ),
                Row(
                  spacing: AppSpace.s12,
                  children: <Widget>[
                    for (final m in FirstGroups.milestones)
                      _GroupSticker(
                        label: FirstGroups.milestoneLabel(m),
                        reached: detail.reached(m),
                      ),
                  ],
                ),
                if (trend != null)
                  Text(
                    trend,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (recent.isNotEmpty) ...<Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      'Gần nhất · ${detail.count} nốt',
                      style: heading,
                    ),
                  ),
                  for (final note in recent)
                    NoteCard(
                      type: note.type,
                      title: note.title,
                      meta: <String>[
                        if (note.challenge?.anxietyBefore case final a?)
                          'Hồi hộp $a/5'
                        else
                          note.type.label,
                        ViDateFormat.relativeDay(note.createdAt, now),
                      ].join(' · '),
                      onTap: () => context.push(AppRoutes.noteDetail(note.id)),
                    ),
                ],
                const Spacer(),
                AppButton(
                  label: detail.count == 0 ? 'Ghi lần đầu' : 'Thử lần nữa',
                  expand: true,
                  onPressed: onTry,
                ),
                AppButton(
                  label: 'Đổi tên nhóm',
                  variant: AppButtonVariant.text,
                  expand: true,
                  onPressed: onRename,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma `Card/lần đầu`: mascot Xong + "LẦN ĐẦU · 12/10" + tên nốt lần đầu.
class _FirstCard extends StatelessWidget {
  const _FirstCard({required this.group});

  final FirstGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final first = group.firstAt;
    final title = group.firstNoteTitle;

    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        spacing: AppSpace.s12,
        children: <Widget>[
          Mascot(
            state: title == null ? MascotState.doi : MascotState.xong,
            size: 63,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s4,
              children: <Widget>[
                Text(
                  first == null
                      ? 'CHƯA CÓ LẦN ĐẦU'
                      : 'LẦN ĐẦU · ${ViDateFormat.shortDate(first)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  title ?? 'Lần đầu bạn làm việc này, ghi lại cho Nốt nhé.',
                  style: AppTextStyles.of(context).title17Bold.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `Sticker/Mốc` cỡ 64: đã mở nền heat/3 có mascot Xong; chưa mở viền
/// đứt và dấu "?".
class _GroupSticker extends StatelessWidget {
  const _GroupSticker({required this.label, required this.reached});

  final String label;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: 'Mốc $label, ${reached ? 'đã mở' : 'chưa mở'}',
      excludeSemantics: true,
      child: SizedBox(
        width: 72,
        child: Column(
          spacing: AppSpace.s6,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached
                    ? const Color(0xFFFFD24A)
                    : scheme.surfaceContainerHighest,
                border: reached
                    ? null
                    : Border.all(color: scheme.outline, width: 1.5),
              ),
              alignment: Alignment.center,
              child: reached
                  ? const Mascot(state: MascotState.xong, size: 51.84)
                  : Text(
                      '?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: reached ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial, required this.onSave});

  final String initial;
  final Future<String?> Function(String name) onSave;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final error = await widget.onSave(_controller.text);
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
      title: const Text('Đổi tên nhóm'),
      content: AppTextField(
        label: 'Tên nhóm',
        controller: _controller,
        autofocus: true,
        maxLength: FirstGroups.nameMaxLength,
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
          label: 'Lưu',
          loading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
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
