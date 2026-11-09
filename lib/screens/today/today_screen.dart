import 'dart:math' as math;

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
import '../../widgets/note_wall.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/shortcut_button.dart';
import '../../widgets/state_views.dart';
import '../../widgets/streak_card.dart';
import '../common/note_kind_sheet.dart';
import '../common/screen_skeleton.dart';
import '../streak/streak_share_page.dart';

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
      raisedHeader: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              Color.alphaBlend(
                theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
                theme.colorScheme.surface,
              ),
            ],
          ),
        ),
        child: ListView(
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
            const NoteWall(),
            if (summary case final summary?) ...<Widget>[
              const SizedBox(height: AppSpace.s16),
              StreakCard(
                streak: summary.streak,
                // Mở Hành trình ở tab Thống kê để xem chuỗi và kỷ lục.
                onTap: () => context.go(AppRoutes.journeyTab('stats')),
              ),
            ],
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
            FilledButtonTheme(
              data: FilledButtonThemeData(
                style: (theme.filledButtonTheme.style ?? const ButtonStyle())
                    .copyWith(
                      elevation: const WidgetStatePropertyAll(1),
                      shadowColor: WidgetStatePropertyAll(
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
              ),
              child: AppButton(
                label: hasDraft ? 'Tiếp tục ghi nốt' : 'Ghi nốt',
                icon: hasDraft ? Icons.edit_note : Icons.add,
                expand: true,
                // Có nháp thì vào thẳng S03; chưa có thì hỏi chiến thắng hay nhật ký.
                onPressed: hasDraft
                    ? () => context.push(AppRoutes.newNote())
                    : () => openNoteKindSheet(context),
              ),
            ),
            // Thẻ chuỗi ở trên đã chiếm một khối; giữ 32 để hàng lối tắt vẫn
            // chạm được trên màn 360 × 800 (thanh tab nổi bắt đầu ở 718).
            const SizedBox(height: AppSpace.s16 * 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Mỗi lối tắt chia đều chiều rộng để thêm nút "Chia sẻ" vẫn vừa
              // màn 360.
              children: <Widget>[
                // Icon nói đúng hành động (bàn tay dừng, luồng gió, lá cờ như
                // tab Thử thách) kèm dòng phụ nói mục đích (deviation D-25).
                Expanded(
                  child: Center(
                    child: ShortcutButton(
                      iconAsset: 'assets/icons/hand-stop.svg',
                      label: 'Dừng lại',
                      caption: 'ghi 1 lần tự chủ',
                      onTap: () => context.push(AppRoutes.selfControl),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ShortcutButton(
                      iconAsset: 'assets/icons/wind.svg',
                      // Đọc liền thành câu: "Stress? Thở 90 giây để thả lỏng".
                      label: 'Stress?',
                      caption: 'Thở 90 giây để thả lỏng',
                      onTap: () => context.push(AppRoutes.breathe),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ShortcutButton(
                      iconAsset: 'assets/icons/tab-flag.svg',
                      label: 'Thử thách',
                      caption: 'thẻ hôm nay',
                      onTap: () => context.go(AppRoutes.challenges),
                    ),
                  ),
                ),
                if (summary case final summary?)
                  Expanded(
                    child: Center(
                      child: ShortcutButton(
                        iconAsset: 'assets/icons/share.svg',
                        label: 'Chia sẻ',
                        caption: 'khoe chuỗi ngày',
                        onTap: () {
                          if (summary.streak.current <= 0) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ghi nốt đầu tiên để mở chuỗi, rồi chia sẻ nhé.',
                                  ),
                                ),
                              );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  StreakSharePage(streak: summary.streak),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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
      Empty<TodaySummary>() => _jar(context, const <NoteType>[], 0),
      Data<TodaySummary>(:final value) => _jar(
        context,
        value.jarNotes,
        value.monthCount,
      ),
    };
  }

  /// Figma `scene`: nền tròn 230 `primary-container`, hũ cao 203 lệch phải,
  /// mascot Xong đứng trước hũ ở góc dưới trái.
  Widget _jar(
    BuildContext context,
    List<NoteType> notes,
    int monthCount,
  ) => SizedBox(
    height: _scene.height,
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox.fromSize(
          size: _scene,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 1150),
            builder: (context, time, _) {
              final sway = math.sin(time * math.pi * 2) * (1 - time);
              return Stack(
                children: <Widget>[
                  const Positioned(
                    left: 49,
                    top: 10,
                    child: SizedBox.square(
                      dimension: 230,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment(-0.42, -0.56),
                            radius: 1,
                            colors: [
                              Color(0xFFF4F6FF),
                              AppPalette.primaryContainer,
                              Color(0xFFD0DAF8),
                            ],
                            stops: [0, 0.65, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _JarAccents(sway)),
                    ),
                  ),
                  Positioned(
                    left: 104,
                    top: 196,
                    child: Transform.scale(
                      scale: 1 - 0.16 * (1 - time),
                      child: const SizedBox(
                        width: 168,
                        height: 33,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0x293E529E), Color(0x003E529E)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 101,
                    top: 18 - 9 * (1 - time) + 4 * sway,
                    child: Transform.rotate(
                      angle: sway * 0.045,
                      child: JarIllustration(
                        notes: notes,
                        semanticLabel: monthCount == 0
                            ? 'Hũ chiến thắng, chưa có nốt tháng này. Mở hũ'
                            : 'Hũ chiến thắng, $monthCount nốt tháng này. Mở hũ',
                        onTap: onOpenJar,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 40,
                    top: 222,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 100,
                        height: 15,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0x203E529E), Color(0x003E529E)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 40,
                    top: 120 - 6 * sway,
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
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// Những tờ giấy nhỏ và ánh sáng ở lớp sau của cảnh Hôm nay.
class _JarAccents extends CustomPainter {
  const _JarAccents(this.sway);

  final double sway;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final orbit = Paint()
      ..color = const Color(0x537C8EDE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final arc = Rect.fromLTWH(35, 46, size.width - 56, 149);
    canvas.drawArc(arc, 3.42, 0.9, false, orbit);
    canvas.drawArc(arc, -0.46, 1.31, false, orbit);

    for (final (x, y, angle, color) in const [
      (74.0, 53.0, -0.39, Color(0xFFA5B1F0)),
      (48.0, 108.0, 0.30, Color(0xFFFFCB91)),
      (285.0, 67.0, 0.42, Color(0xFF8FD7BE)),
      (294.0, 169.0, -0.26, Color(0xFFACB7F4)),
    ]) {
      canvas.save();
      canvas.translate(x, y + 12 * angle * sway);
      canvas.rotate(angle + sway * 0.25);
      final sheet = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -8, 14, 16),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        sheet.shift(const Offset(2, 3)),
        paint..color = const Color(0x187485C2),
      );
      canvas.drawRRect(sheet, paint..color = color);
      canvas.drawLine(
        const Offset(-3, -2),
        const Offset(3, -2),
        paint
          ..color = const Color(0xAFFFFFFF)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    for (final (x, y, radius) in const [
      (94.0, 26.0, 6.0),
      (267.0, 34.0, 8.0),
      (311.0, 112.0, 6.0),
      (277.0, 205.0, 5.0),
    ]) {
      final center = Offset(x, y - 5 * sway);
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - radius)
          ..quadraticBezierTo(
            center.dx + 1,
            center.dy - 1,
            center.dx + radius,
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx + 1,
            center.dy + 1,
            center.dx,
            center.dy + radius,
          )
          ..quadraticBezierTo(
            center.dx - 1,
            center.dy + 1,
            center.dx - radius,
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx - 1,
            center.dy - 1,
            center.dx,
            center.dy - radius,
          )
          ..close(),
        paint..color = const Color(0xFFACB8F5),
      );
    }
  }

  @override
  bool shouldRepaint(_JarAccents oldDelegate) => sway != oldDelegate.sway;
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
            image: note.image,
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
