import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note.dart';
import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/jar_view_model.dart';
import '../../viewmodels/note_deleter.dart';
import '../../viewmodels/today_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/jar_illustration.dart';
import '../../widgets/mascot.dart';
import '../../widgets/milestone_sticker.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/state_views.dart';
import '../common/screen_skeleton.dart';
import '../groups/group_shelf.dart';

/// S05 · Hũ & Nhật ký (tab 2).
class JarScreen extends ConsumerWidget {
  const JarScreen({super.key});

  /// Còn chừng này điểm ảnh tới cuối lưới thì tải trang kế.
  static const double _loadMoreExtent = 400;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jarViewModelProvider);
    final viewModel = ref.read(jarViewModelProvider.notifier);

    ref.listen(noteDeleterProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      final note = next.note;
      if (note != null && previous?.note?.id != note.id) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Đã xoá nốt · còn 5 giây'),
              duration: NoteDeleter.undoWindow,
              action: SnackBarAction(
                label: 'Hoàn tác',
                onPressed: ref.read(noteDeleterProvider.notifier).undo,
              ),
            ),
          );
      }
      if (next.failure != null && previous?.failure != next.failure) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.failure!)));
        ref.read(noteDeleterProvider.notifier).clearFailure();
      }
    });

    return TabScaffold(
      title: 'Hũ của bạn',
      body: switch (state) {
        Loading<JarData>() => const Padding(
          padding: EdgeInsets.all(AppSpace.screen),
          child: LoadingState.skeleton(message: 'Đang mở hũ…'),
        ),
        Failure<JarData>(:final message, :final offline) => Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: ErrorState(
            title: 'Chưa tải được hũ',
            cause: message,
            kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
            onRetry: viewModel.refresh,
          ),
        ),
        Empty<JarData>() => Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: EmptyState(
            title: 'Hũ còn trống',
            message: 'Ghi chiến thắng đầu tiên nhé.',
            actionLabel: 'Ghi nốt đầu tiên',
            onAction: () => context.push(AppRoutes.newNote()),
          ),
        ),
        Data<JarData>(:final value) => NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < _loadMoreExtent) {
              viewModel.loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async => viewModel.refresh(),
            child: _JarGrid(
              data: value,
              now: ref.watch(todayDateProvider),
              onRetryMore: viewModel.loadMore,
            ),
          ),
        ),
      },
    );
  }
}

class _JarGrid extends StatelessWidget {
  const _JarGrid({
    required this.data,
    required this.now,
    required this.onRetryMore,
  });

  final JarData data;
  final DateTime now;
  final VoidCallback onRetryMore;

  /// Hũ nhỏ trên đầu lưới (S02 dùng hũ lớn 240).
  /// `Illustration/Hũ chiến thắng` cỡ vừa của S05 (126 × 147).
  static const double _jarHeight = 147;

  static const double _tileMinHeight = 120;

  /// 2 cột trên điện thoại, 3 cột từ 600 dp, 4 cột từ 840 dp (handout S05).
  static int _columns(double width) => width >= 840
      ? 4
      : width >= 600
      ? 3
      : 2;

  String _dateLabel(Note note) => <String>[
    ViDateFormat.relativeDay(note.createdAt, now),
    ?note.mood?.label,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = _columns(MediaQuery.sizeOf(context).width);
    final count = data.monthCount;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s16,
            AppSpace.screen,
            AppSpace.s16,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              if (data.pendingSync) ...<Widget>[
                const OfflineBanner(),
                const SizedBox(height: AppSpace.s16),
              ],
              // Figma `hũ`: hũ 126 × 147, bên phải là số nốt (Display/44
              // Bold), "nốt tháng 10" và lối mở nhãn dán, cách nhau 16.
              Row(
                spacing: AppSpace.s16,
                children: <Widget>[
                  JarIllustration(
                    notes: data.jarTypes,
                    height: _jarHeight,
                    semanticLabel: 'Hũ chiến thắng',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.s4,
                      children: <Widget>[
                        if (count != null)
                          Text(
                            '$count',
                            style: theme.textTheme.displayMedium?.copyWith(
                              letterSpacing: -0.88,
                            ),
                          ),
                        Text(
                          count == null
                              ? 'Tháng ${data.month}'
                              : 'nốt tháng ${data.month}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (data.stickers.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                _showStickers(context, data.stickers),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, AppSize.minTouch),
                              alignment: Alignment.centerLeft,
                              textStyle: theme.textTheme.labelLarge,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                            ),
                            child: Text('${data.stickers.length} nhãn dán  ›'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s16),
              const GroupShelf(),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          // Figma `lưới nốt`: tờ nốt rộng bằng nhau, cao tối thiểu 120 và
          // cao theo tiêu đề (tối đa 3 dòng); tờ cùng hàng cao bằng nhau.
          sliver: SliverList.separated(
            itemCount: (data.notes.length + columns - 1) ~/ columns,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.grid),
            itemBuilder: (context, row) => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.grid,
                children: <Widget>[
                  for (var i = row * columns; i < (row + 1) * columns; i++)
                    Expanded(
                      child: i < data.notes.length
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: _tileMinHeight,
                              ),
                              child: NoteTile(
                                key: ValueKey<String>(data.notes[i].id),
                                type: data.notes[i].type,
                                title: data.notes[i].title,
                                dateLabel: _dateLabel(data.notes[i]),
                                onTap: () => context.push(
                                  AppRoutes.noteDetail(data.notes[i].id),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s16,
            AppSpace.screen,
            AppSpace.tabContentBottom,
          ),
          sliver: SliverToBoxAdapter(
            child: data.loadingMore
                ? const LoadingState.spinner(message: 'Đang tải thêm nốt…')
                : data.loadMoreFailed
                ? AppButton(
                    label: 'Chưa tải thêm được · Thử lại',
                    variant: AppButtonVariant.outlined,
                    onPressed: onRetryMore,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  static void _showStickers(BuildContext context, List<DateTime> months) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
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
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Mascot(state: MascotState.xong, size: 48),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Text(
                      'Nhãn dán của bạn',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s16),
              Wrap(
                spacing: AppSpace.s16,
                runSpacing: AppSpace.s16,
                children: <Widget>[
                  for (final month in months)
                    MilestoneSticker(label: 'Th${month.month}', unlocked: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
