import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/note_saved_view_model.dart';
import '../../widgets/app_button.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: <Widget>[
              if (note.pendingSync) ...<Widget>[
                const OfflineBanner(),
                const SizedBox(height: AppSpace.s16),
              ],
              // `Decor/Confetti` (240 × 140) phía sau mascot Xong.
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/illustrations/confetti.svg',
                      width: 240,
                      excludeFromSemantics: true,
                    ),
                    const Mascot(state: MascotState.xong, size: 120),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  milestone ? 'Mốc ${summary.milestone} nốt!' : 'Đã vào hũ!',
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                'Nốt thứ ${summary.monthCount} tháng này.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.s24),
              SizedBox(
                height: AppSize.noteTile.height,
                child: NoteTile(
                  type: note.type,
                  title: note.title,
                  dateLabel: dateLabel,
                ),
              ),
              const SizedBox(height: AppSpace.s24),
              if (milestone)
                Center(
                  child: MilestoneSticker(label: 'Th$month', unlocked: true),
                )
              else ...<Widget>[
                Text(
                  'Mốc tháng $month · '
                  '${summary.monthCount}/${summary.milestone} nốt',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpace.s8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: summary.progress,
                    minHeight: AppSpace.s8,
                    semanticsLabel:
                        'Mốc tháng $month, '
                        '${summary.monthCount} trên ${summary.milestone} nốt',
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s8,
            AppSpace.screen,
            AppSpace.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: milestone
                ? <Widget>[
                    AppButton(
                      label: 'Gắn vào hũ',
                      expand: true,
                      onPressed: onPin,
                    ),
                    const SizedBox(height: AppSpace.s8),
                    AppButton(
                      label: 'Để sau',
                      variant: AppButtonVariant.text,
                      expand: true,
                      onPressed: onDone,
                    ),
                  ]
                : <Widget>[
                    AppButton(
                      label: 'Về Hôm nay',
                      expand: true,
                      onPressed: onDone,
                    ),
                    const SizedBox(height: AppSpace.s8),
                    AppButton(
                      label: 'Viết thêm',
                      variant: AppButtonVariant.text,
                      expand: true,
                      onPressed: onWriteMore,
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}
