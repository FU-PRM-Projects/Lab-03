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
  static const double _jarHeight = 140;

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
            AppSpace.s8,
            AppSpace.screen,
            AppSpace.s16,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              if (data.pendingSync) ...<Widget>[
                const OfflineBanner(),
                const SizedBox(height: AppSpace.s16),
              ],
              JarIllustration(
                notes: data.jarTypes,
                height: _jarHeight,
                semanticLabel: 'Hũ chiến thắng',
              ),
              const SizedBox(height: AppSpace.s12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      count == null
                          ? 'Tháng ${data.month}'
                          : '$count nốt tháng ${data.month}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (data.stickers.isNotEmpty)
                    TextButton(
                      onPressed: () => _showStickers(context, data.stickers),
                      child: Text('${data.stickers.length} nhãn dán ›'),
                    ),
                ],
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppSpace.grid,
              crossAxisSpacing: AppSpace.grid,
              childAspectRatio: AppSize.noteTile.aspectRatio,
            ),
            itemCount: data.notes.length,
            itemBuilder: (context, i) {
              final note = data.notes[i];
              return NoteTile(
                key: ValueKey<String>(note.id),
                type: note.type,
                title: note.title,
                dateLabel: _dateLabel(note),
                onTap: () => context.push(AppRoutes.noteDetail(note.id)),
              );
            },
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
