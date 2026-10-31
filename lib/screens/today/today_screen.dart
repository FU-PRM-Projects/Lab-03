import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note.dart';
import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/today_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/jar_illustration.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/shortcut_button.dart';
import '../../widgets/state_views.dart';
import '../common/screen_skeleton.dart';

/// S02 · Hôm nay (tab 1).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(todayViewModelProvider);
    final hasDraft = ref.watch(hasDraftProvider).value ?? false;
    final summary = switch (state) {
      Data<TodaySummary>(:final value) => value,
      _ => null,
    };

    return TabScaffold(
      title: ViDateFormat.dayHeader(ref.watch(todayDateProvider)),
      showAddNote: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.s8,
          AppSpace.screen,
          AppSpace.tabContentBottom,
        ),
        children: <Widget>[
          if (summary?.pendingSync ?? false) ...<Widget>[
            const OfflineBanner(),
            const SizedBox(height: AppSpace.s16),
          ],
          _Jar(
            state: state,
            onOpenJar: () => context.go(AppRoutes.jar),
            onRetry: ref.read(todayViewModelProvider.notifier).retry,
          ),
          if (summary?.fallenNote case final note?) ...<Widget>[
            const SizedBox(height: AppSpace.s16),
            _FallenNote(note: note),
          ],
          const SizedBox(height: AppSpace.s24),
          Text(
            'Hôm nay bạn làm được gì?',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: hasDraft ? 'Tiếp tục ghi nốt' : 'Ghi nốt',
            icon: hasDraft ? Icons.edit_note : Icons.add,
            expand: true,
            onPressed: () => context.push(AppRoutes.newNote()),
          ),
          const SizedBox(height: AppSpace.s16),
          // Ba lối tắt chia đều chiều ngang; nhãn xuống dòng khi chật.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ShortcutButton(
                  icon: Icons.pan_tool_outlined,
                  label: 'Dừng lại',
                  onTap: () => context.push(AppRoutes.selfControl),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: ShortcutButton(
                  icon: Icons.air,
                  label: 'Thở 90 giây',
                  onTap: () => context.push(AppRoutes.breathe),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: ShortcutButton(
                  icon: Icons.flag_outlined,
                  label: 'Thử thách',
                  onTap: () => context.go(AppRoutes.challenges),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hình hũ theo trạng thái tải. Lỗi chỉ thay phần hũ: nút Ghi nốt và lối tắt
/// vẫn dùng được (handout S02, Offline).
class _Jar extends StatelessWidget {
  const _Jar({
    required this.state,
    required this.onOpenJar,
    required this.onRetry,
  });

  final ViewState<TodaySummary> state;
  final VoidCallback onOpenJar;
  final VoidCallback onRetry;

  static const double _height = 240;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Loading<TodaySummary>() => const SizedBox(
        height: _height,
        child: LoadingState.spinner(message: 'Đang mở hũ…'),
      ),
      Failure<TodaySummary>(:final message, :final offline) => ErrorState(
        title: 'Chưa tải được hũ',
        cause: message,
        kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
        onRetry: onRetry,
      ),
      Empty<TodaySummary>() => _jar(const <NoteType>[], 0),
      Data<TodaySummary>(:final value) => _jar(
        value.jarNotes,
        value.monthCount,
      ),
    };
  }

  Widget _jar(List<NoteType> notes, int monthCount) => JarIllustration(
    notes: notes,
    semanticLabel: monthCount == 0
        ? 'Hũ chiến thắng, chưa có nốt tháng này. Mở hũ'
        : 'Hũ chiến thắng, $monthCount nốt tháng này. Mở hũ',
    onTap: onOpenJar,
  );
}

/// Nốt cũ rơi ra khỏi hũ sau một ngày Mệt / Rối; chạm để đọc lại (S06).
class _FallenNote extends StatelessWidget {
  const _FallenNote({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Hôm qua hơi mệt. Nhớ lại lần này nhé:',
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
            onTap: () => context.push(AppRoutes.noteDetail(note.id)),
          ),
        ),
      ],
    );
  }
}
