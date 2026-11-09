import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note.dart';
import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../utils/jar_sections.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/jar_view_model.dart';
import '../../viewmodels/note_deleter.dart';
import '../../viewmodels/note_wall_view_model.dart';
import '../../viewmodels/today_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/mascot.dart';
import '../../widgets/milestone_sticker.dart';
import '../../widgets/note_card.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/shake_jar.dart';
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
              // Có action thì Flutter mặc định giữ SnackBar mãi; cần tự tắt
              // cùng lúc với hết giờ hoàn tác.
              persist: false,
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
              pins: ref.watch(noteWallProvider).asData?.value ?? const {},
              now: ref.watch(todayDateProvider),
              onRetryMore: viewModel.loadMore,
              filter: ref.watch(jarFilterProvider),
              listMode: ref.watch(jarListModeProvider),
              onFilter: ref.read(jarFilterProvider.notifier).select,
              onListMode: ref.read(jarListModeProvider.notifier).set,
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
    required this.pins,
    required this.now,
    required this.onRetryMore,
    required this.filter,
    required this.listMode,
    required this.onFilter,
    required this.onListMode,
  });

  final JarData data;
  final Map<String, DateTime> pins;
  final DateTime now;
  final VoidCallback onRetryMore;

  /// Chỉ hiện loại này; `null` là Tất cả.
  final NoteType? filter;

  /// Danh sách gọn (`Card/Nốt`) thay cho lưới tờ nốt.
  final bool listMode;
  final ValueChanged<NoteType?> onFilter;
  final ValueChanged<bool> onListMode;

  /// 2 cột trên điện thoại, 3 cột từ 600 dp, 4 cột từ 840 dp (handout S05).
  static int _columns(double width) => width >= 840
      ? 4
      : width >= 600
      ? 3
      : 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = _columns(MediaQuery.sizeOf(context).width);
    final count = data.monthCount;
    final available = data.notes
        .where((note) => !pins.containsKey(note.id))
        .toList();
    final sections = JarSections.group(<Note>[
      for (final note in available)
        if (filter == null || note.type == filter) note,
    ], now);

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
                  ShakeJar(
                    notes: available,
                    onOpenNote: (note) =>
                        context.push(AppRoutes.noteDetail(note.id)),
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
                        if (available.isNotEmpty)
                          Text(
                            'Lắc điện thoại hoặc chạm hũ',
                            style: theme.textTheme.bodySmall,
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
          padding: const EdgeInsets.only(bottom: AppSpace.s4),
          sliver: SliverToBoxAdapter(
            child: _JarControls(
              filter: filter,
              listMode: listMode,
              onFilter: onFilter,
              onListMode: onListMode,
            ),
          ),
        ),
        if (sections.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpace.screen),
            sliver: SliverToBoxAdapter(
              child: Text(
                filter == null
                    ? 'Chưa có nốt nào trong hũ.'
                    : 'Chưa có nốt ${filter!.label} nào trong phần đã tải.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        for (final section in sections) ...<Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.s16,
              AppSpace.screen,
              AppSpace.s8,
            ),
            sliver: SliverToBoxAdapter(child: _SectionHeader(section: section)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            sliver: listMode
                ? _ListSection(section: section, now: now)
                : _GridSection(section: section, columns: columns, now: now),
          ),
        ],
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
      // Nằm trên thanh tab nổi, không bị nó che phần dưới.
      useRootNavigator: true,
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
                    MilestoneSticker(month: month.month, unlocked: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loại đang lọc trên S05 (trạng thái giao diện); `null` là Tất cả.
final jarFilterProvider = NotifierProvider<JarFilter, NoteType?>(JarFilter.new);

class JarFilter extends Notifier<NoteType?> {
  @override
  NoteType? build() => null;

  void select(NoteType? type) => state = type;
}

/// S05 đang ở kiểu danh sách gọn (`true`) hay lưới tờ nốt (`false`).
final jarListModeProvider = NotifierProvider<JarListMode, bool>(
  JarListMode.new,
);

class JarListMode extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Hàng chip lọc loại (cuộn ngang) và nút đổi lưới / danh sách.
class _JarControls extends StatelessWidget {
  const _JarControls({
    required this.filter,
    required this.listMode,
    required this.onFilter,
    required this.onListMode,
  });

  final NoteType? filter;
  final bool listMode;
  final ValueChanged<NoteType?> onFilter;
  final ValueChanged<bool> onListMode;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, NoteType? type) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.minTouch),
      child: ChoiceChip(
        label: Text(label),
        selected: filter == type,
        onSelected: (_) => onFilter(type),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          // Mép phải hàng chip mờ dần thay vì bị nút đổi kiểu cắt ngang, để
          // thấy rõ hàng chip còn cuộn tiếp được.
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: <Color>[Color(0xFF000000), Color(0x00000000)],
              stops: <double>[0.82, 1],
            ).createShader(bounds),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                0,
                AppSpace.s24,
                0,
              ),
              child: Row(
                spacing: AppSpace.s8,
                children: <Widget>[
                  chip('Tất cả', null),
                  for (final type in NoteType.values) chip(type.label, type),
                ],
              ),
            ),
          ),
        ),
        // Nút tròn có viền, tách hẳn khỏi hàng chip.
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpace.s4,
            right: AppSpace.s12,
          ),
          child: IconButton(
            onPressed: () => onListMode(!listMode),
            tooltip: listMode ? 'Xem dạng lưới' : 'Xem dạng danh sách',
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerLow,
              side: BorderSide(color: scheme.outlineVariant),
            ),
            icon: Icon(
              listMode ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Hôm nay" ở bên trái, "2 nốt" ở bên phải.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final JarSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = section.notes.length;

    return Semantics(
      header: true,
      label: '${section.title}, $count nốt',
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(section.title, style: theme.textTheme.labelLarge),
          ),
          Text(
            '$count nốt',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng dưới tờ nốt: chỉ tâm trạng trong "Hôm nay" / "Hôm qua", ngày ·
/// tâm trạng ở các nhóm khác; rỗng khi không có gì mới để nói (nhãn loại đã
/// có ở đầu tờ).
String _noteMeta(Note note, JarSection section, DateTime now) => <String>[
  if (section.showsDay) ViDateFormat.relativeDay(note.createdAt, now),
  ?note.mood?.label,
].join(' · ');

/// Figma `lưới nốt`: tờ nốt rộng bằng nhau, cao tối thiểu 120 và cao theo
/// tiêu đề (tối đa 3 dòng); tờ cùng hàng cao bằng nhau.
class _GridSection extends StatelessWidget {
  const _GridSection({
    required this.section,
    required this.columns,
    required this.now,
  });

  final JarSection section;
  final int columns;
  final DateTime now;

  /// Thấp hơn 120 của Figma để lưới bớt dày; tờ vẫn cao theo tiêu đề.
  static const double _tileMinHeight = 96;

  @override
  Widget build(BuildContext context) {
    final notes = section.notes;

    return SliverList.separated(
      itemCount: (notes.length + columns - 1) ~/ columns,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.grid),
      itemBuilder: (context, row) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.grid,
          children: <Widget>[
            for (var i = row * columns; i < (row + 1) * columns; i++)
              Expanded(
                child: i < notes.length
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: _tileMinHeight,
                        ),
                        child: NoteTile(
                          key: ValueKey<String>(notes[i].id),
                          type: notes[i].type,
                          title: notes[i].title,
                          dateLabel: _noteMeta(notes[i], section, now),
                          onTap: () =>
                              context.push(AppRoutes.noteDetail(notes[i].id)),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kiểu danh sách gọn: mỗi nốt một `Card/Nốt` (ô màu nhỏ + tên + dòng phụ).
class _ListSection extends StatelessWidget {
  const _ListSection({required this.section, required this.now});

  final JarSection section;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final notes = section.notes;

    return SliverList.separated(
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s8),
      itemBuilder: (context, i) => NoteCard(
        key: ValueKey<String>(notes[i].id),
        type: notes[i].type,
        title: notes[i].title,
        meta: <String>[
          notes[i].type.label,
          _noteMeta(notes[i], section, now),
        ].where((part) => part.isNotEmpty).join(' · '),
        onTap: () => context.push(AppRoutes.noteDetail(notes[i].id)),
      ),
    );
  }
}
