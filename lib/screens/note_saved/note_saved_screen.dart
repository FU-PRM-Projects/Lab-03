import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/first_group.dart';
import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/note_saved_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/jar_illustration.dart';
import '../../widgets/mascot.dart';
import '../../widgets/milestone_sticker.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/streak_celebration.dart';
import '../common/view_state_view.dart';
import '../streak/streak_share_page.dart';

/// S04 · Nốt đã vào hũ.
class NoteSavedScreen extends ConsumerWidget {
  const NoteSavedScreen({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = noteSavedViewModelProvider(noteId);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    void goToday() => context.go(AppRoutes.today);

    // Back và "Về Hôm nay" đều về S02 (handout mục 3).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goToday();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSize.narrowContentMaxWidth,
              ),
              child: ViewStateView<SavedNoteSummary>(
                state: state,
                onRetry: viewModel.retry,
                errorTitle: 'Chưa mở được nốt vừa lưu',
                empty: const SizedBox.shrink(),
                data: (summary) => _SavedContent(
                  summary: summary,
                  onDone: goToday,
                  onWriteMore: () => context.go(
                    AppRoutes.noteDetail(summary.note.id, edit: true),
                  ),
                  onPin: () async {
                    final error = await viewModel.pinSticker();
                    if (!context.mounted) return;
                    if (error == null) {
                      goToday();
                    } else {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedContent extends StatelessWidget {
  const _SavedContent({
    required this.summary,
    required this.onDone,
    required this.onWriteMore,
    required this.onPin,
  });

  final SavedNoteSummary summary;
  final VoidCallback onDone;
  final VoidCallback onWriteMore;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = summary.note;
    final month = note.createdAt.month;
    final milestone = summary.reachedMilestone;
    final first = summary.firstInGroup;
    final group = summary.group;
    final dateLabel = <String>[
      if (summary.savedToday)
        'Hôm nay'
      else
        ViDateFormat.shortDate(note.createdAt),
      if (first) 'Lần đầu' else ?note.mood?.label,
    ].join(' · ');
    final (title, subtitle) = milestone
        ? (
            'Mốc ${summary.milestone} nốt!',
            'Tụi Nốt mang về nhãn dán tháng $month.',
          )
        : first
        ? ('Lần đầu tiên!', 'Nhóm “${group!.name}” có thêm một nấc.')
        : ('Đã vào hũ!', 'Nốt thứ ${summary.monthCount} tháng này.');

    // Figma: nội dung căn giữa giữa hai khoảng đệm co giãn, các khối cách
    // nhau 16; màn thấp hoặc chữ phóng to thì cuộn được.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.s16,
                AppSpace.screen,
                AppSpace.s24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (note.pendingSync) ...<Widget>[
                    const OfflineBanner(),
                    const SizedBox(height: AppSpace.s16),
                  ],
                  if (milestone)
                    _MilestoneCelebration(month: month)
                  else
                    _Celebration(jarNotes: summary.jarNotes),
                  const SizedBox(height: AppSpace.s16),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: -0.56,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.s16),
                  if (summary.firstNoteToday) ...<Widget>[
                    StreakCelebration(
                      streak: summary.streak,
                      onShare: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              StreakSharePage(streak: summary.streak),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s16),
                  ],
                  if (milestone)
                    _StickerCollection(summary: summary)
                  else ...<Widget>[
                    // Tờ nốt 220 × 120 nghiêng 3° như vừa thả vào hũ.
                    Center(
                      child: Transform.rotate(
                        angle: 3 * math.pi / 180,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 220,
                            maxWidth: 220,
                            minHeight: 120,
                          ),
                          child: IntrinsicHeight(
                            child: NoteTile(
                              type: note.type,
                              title: note.title,
                              dateLabel: dateLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s16),
                    if (first)
                      _GroupProgress(
                        name: group!.name,
                        count: summary.groupCount,
                      )
                    else
                      _MilestoneProgress(summary: summary, month: month),
                  ],
                  const SizedBox(height: AppSpace.s16),
                  if (milestone) ...<Widget>[
                    AppButton(
                      label: 'Gắn vào hũ',
                      expand: true,
                      onPressed: onPin,
                    ),
                    const SizedBox(height: AppSpace.s16),
                    AppButton(
                      label: 'Để sau',
                      variant: AppButtonVariant.text,
                      expand: true,
                      onPressed: onDone,
                    ),
                  ] else if (first) ...<Widget>[
                    AppButton(
                      label: 'Xem nhóm ${group!.name}',
                      expand: true,
                      onPressed: () =>
                          context.go(AppRoutes.groupDetail(group.id)),
                    ),
                    const SizedBox(height: AppSpace.s16),
                    AppButton(
                      label: 'Về Hôm nay',
                      variant: AppButtonVariant.text,
                      expand: true,
                      onPressed: onDone,
                    ),
                  ] else ...<Widget>[
                    AppButton(
                      label: 'Về Hôm nay',
                      expand: true,
                      onPressed: onDone,
                    ),
                    const SizedBox(height: AppSpace.s16),
                    AppButton(
                      label: 'Viết thêm',
                      variant: AppButtonVariant.text,
                      expand: true,
                      onPressed: onWriteMore,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma S04 · đạt mốc tháng: mascot Thong Thả bên trái nhãn dán tháng cỡ
/// 108.8 (cách 12, căn đáy), confetti 240 × 140 phủ phía trên.
class _MilestoneCelebration extends StatelessWidget {
  const _MilestoneCelebration({required this.month});

  final int month;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: AppSpace.s12,
              children: <Widget>[
                const Mascot(state: MascotState.thongTha, size: 97.2),
                MilestoneSticker(month: month, unlocked: true, size: 108.8),
              ],
            ),
            Positioned(
              left: -9.6,
              top: -28,
              child: IgnorePointer(
                child: SvgPicture.asset(
                  'assets/illustrations/confetti.svg',
                  width: 240,
                  height: 140,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `Bộ sưu tập`: khối primary-container bo 16, đệm 16; các tháng đã có
/// nhãn dán rồi ô "?" của tháng sau.
class _StickerCollection extends StatelessWidget {
  const _StickerCollection({required this.summary});

  final SavedNoteSummary summary;

  @override
  Widget build(BuildContext context) {
    final stickers = <Widget>[
      for (final m in summary.stickerMonths)
        MilestoneSticker(month: m.month, unlocked: true),
      MilestoneSticker(month: summary.nextStickerMonth.month, unlocked: false),
    ];
    final full = stickers.length == 4;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s16),
        child: Row(
          // Đủ 4 ô thì dàn đều như Figma; ít hơn thì gom giữa.
          mainAxisAlignment: full
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: full ? 0 : AppSpace.s12,
          children: <Widget>[
            for (final sticker in stickers)
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: sticker),
              ),
          ],
        ),
      ),
    );
  }
}

/// Figma `illustration` + `Decor/Confetti`: mascot Xong bên trái hũ (cách
/// 13.44, căn đáy), confetti 240 × 140 phủ phía trên.
class _Celebration extends StatelessWidget {
  const _Celebration({required this.jarNotes});

  final List<NoteType> jarNotes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 13.44,
              children: <Widget>[
                SvgPicture.asset(
                  MascotState.xong.asset,
                  width: 118.27,
                  height: 133.06,
                  excludeFromSemantics: true,
                ),
                JarIllustration(
                  notes: jarNotes,
                  semanticLabel: 'Hũ chiến thắng',
                  height: 203.84,
                ),
              ],
            ),
            Positioned(
              left: 33.2,
              top: 32.1,
              child: IgnorePointer(
                child: SvgPicture.asset(
                  'assets/illustrations/confetti.svg',
                  width: 240,
                  height: 140,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma S04 · Lần đầu tiên!: "Bắt chuyện · tới mốc Lần 3" và "2/3".
class _GroupProgress extends StatelessWidget {
  const _GroupProgress({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium;
    final next = FirstGroups.nextMilestone(count);
    final label = next == null
        ? '$name · đã qua mốc Lần 10'
        : '$name · tới mốc ${FirstGroups.milestoneLabel(next)}';
    final ratio = next == null ? '$count lần' : '$count/$next';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s8,
      children: <Widget>[
        Row(
          spacing: AppSpace.s8,
          children: <Widget>[
            Expanded(child: Text(label, style: style)),
            Text(
              ratio,
              style: style?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r4),
          child: LinearProgressIndicator(
            value: next == null ? 1 : count / next,
            minHeight: AppSpace.s8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            semanticsLabel: '$label, $ratio',
          ),
        ),
      ],
    );
  }
}

/// Figma `Mốc tháng`: "Mốc tháng 10" và "24/25 nốt" ở hai đầu (Label/13
/// SemiBold), thanh 8 bo 4.
class _MilestoneProgress extends StatelessWidget {
  const _MilestoneProgress({required this.summary, required this.month});

  final SavedNoteSummary summary;
  final int month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s8,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Mốc tháng $month', style: style),
            Text(
              '${summary.monthCount}/${summary.milestone} nốt',
              style: style?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r4),
          child: LinearProgressIndicator(
            value: summary.progress,
            minHeight: AppSpace.s8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            semanticsLabel:
                'Mốc tháng $month, '
                '${summary.monthCount} trên ${summary.milestone} nốt',
          ),
        ),
      ],
    );
  }
}
