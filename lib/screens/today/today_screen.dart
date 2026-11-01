import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note.dart';
import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/today_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/jar_illustration.dart';
import '../../widgets/mascot.dart';
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
          AppSpace.s16,
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
          const SizedBox(height: AppSpace.s16),
          Text(
            'Hôm nay bạn làm được gì?',
            style: theme.textTheme.titleLarge?.copyWith(letterSpacing: -0.44),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: hasDraft ? 'Tiếp tục ghi nốt' : 'Ghi nốt',
            icon: hasDraft ? Icons.edit_note : Icons.add,
            expand: true,
            onPressed: () => context.push(AppRoutes.newNote()),
          ),
          // Figma: khoảng đệm 16 + 2 khoảng cách 16 giữa nút và lối tắt.
          const SizedBox(height: AppSpace.s16 * 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Icon nói đúng hành động (bàn tay dừng, luồng gió, lá cờ như
              // tab Thử thách) kèm dòng phụ nói mục đích (deviation D-25).
              ShortcutButton(
                iconAsset: 'assets/icons/hand-stop.svg',
                label: 'Dừng lại',
                caption: 'ghi 1 lần tự chủ',
                onTap: () => context.push(AppRoutes.selfControl),
              ),
              ShortcutButton(
                iconAsset: 'assets/icons/wind.svg',
                // Đọc liền thành câu: "Stress? Thở 90 giây để thả lỏng".
                label: 'Stress?',
                caption: 'Thở 90 giây để thả lỏng',
                onTap: () => context.push(AppRoutes.breathe),
              ),
              ShortcutButton(
                iconAsset: 'assets/icons/tab-flag.svg',
                label: 'Thử thách',
                caption: 'thẻ hôm nay',
                onTap: () => context.go(AppRoutes.challenges),
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

  /// Khung `scene` của Figma: 328 × 250.
  static const Size _scene = Size(328, 250);

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Loading<TodaySummary>() => SizedBox(
        height: _scene.height,
        child: const LoadingState.spinner(message: 'Đang mở hũ…'),
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

  /// Figma `scene`: nền tròn 230 `primary-container`, hũ cao 203 lệch phải,
  /// mascot Xong đứng trước hũ ở góc dưới trái.
  Widget _jar(List<NoteType> notes, int monthCount) => SizedBox(
    height: _scene.height,
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox.fromSize(
          size: _scene,
          child: Stack(
            children: <Widget>[
              const Positioned(
                left: 49,
                top: 10,
                child: SizedBox.square(
                  dimension: 230,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.primaryContainer,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 101,
                top: 18,
                child: JarIllustration(
                  notes: notes,
                  semanticLabel: monthCount == 0
                      ? 'Hũ chiến thắng, chưa có nốt tháng này. Mở hũ'
                      : 'Hũ chiến thắng, $monthCount nốt tháng này. Mở hũ',
                  onTap: onOpenJar,
                ),
              ),
              Positioned(
                left: 40,
                top: 120,
                child: IgnorePointer(
                  child: SvgPicture.asset(
                    MascotState.xong.asset,
                    width: 100.8,
                    height: 113.4,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
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
        // Cao theo nội dung (tiêu đề + trích nhật ký), không chừa khoảng trống.
        IntrinsicHeight(
          child: NoteTile(
            type: note.type,
            title: note.title,
            tagSuffix: note.isFirst ? 'Lần đầu' : null,
            excerpt: note.body.isEmpty ? null : '“${note.body}”',
            dateLabel: <String>[
              ViDateFormat.shortDate(note.createdAt),
              ?note.mood?.label,
            ].join(' · '),
            onTap: () => context.push(AppRoutes.noteDetail(note.id)),
          ),
        ),
      ],
    );
  }
}
