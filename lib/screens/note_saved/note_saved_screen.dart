import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
import '../common/view_state_view.dart';

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
    final dateLabel = <String>[
      if (summary.savedToday)
        'Hôm nay'
      else
        ViDateFormat.shortDate(note.createdAt),
      ?note.mood?.label,
    ].join(' · ');

    // Figma: nội dung căn giữa giữa hai khoảng đệm co giãn, các khối cách
    // nhau 16; màn thấp hoặc chữ phóng to thì cuộn được.
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
              children: <Widget>[
                if (note.pendingSync) ...<Widget>[
                  const OfflineBanner(),
                  const SizedBox(height: AppSpace.s16),
                ],
                const Spacer(),
                _Celebration(jarNotes: summary.jarNotes),
                const SizedBox(height: AppSpace.s16),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    milestone ? 'Mốc ${summary.milestone} nốt!' : 'Đã vào hũ!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: -0.56,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  'Nốt thứ ${summary.monthCount} tháng này.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpace.s16),
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
                if (milestone)
                  Center(
                    child: MilestoneSticker(label: 'Th$month', unlocked: true),
                  )
                else
                  _MilestoneProgress(summary: summary, month: month),
                const Spacer(),
                const SizedBox(height: AppSpace.s16),
                if (milestone) ...<Widget>[
                  AppButton(label: 'Gắn vào hũ', expand: true, onPressed: onPin),
                  const SizedBox(height: AppSpace.s16),
                  AppButton(
                    label: 'Để sau',
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
      ],
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
