import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/challenge.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/challenge_detail_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mascot.dart';
import '../../widgets/quick_win_chip.dart';
import '../../widgets/state_views.dart';

/// S08 · Chi tiết thử thách (flow F3, P3).
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({required this.challengeId, super.key});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = challengeDetailViewModelProvider(challengeId);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    ref.listen(provider, (previous, next) {
      if (next.savedNoteId != null && previous?.savedNoteId == null) {
        context.go(AppRoutes.noteSaved(next.savedNoteId!));
      }
      if (next.message != null && previous?.message != next.message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
        viewModel.clearMessage();
      }
    });

    Future<void> easier() async {
      final ok = await viewModel.showEasier();
      if (!context.mounted) return;
      if (ok) {
        context.go(AppRoutes.challenges);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Đây đã là thẻ nhẹ nhất rồi.')),
          );
      }
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Thử thách'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.contentMaxWidth,
            ),
            child: switch (state.challenge) {
              Loading<Challenge>() || Empty<Challenge>() =>
                const LoadingState.spinner(message: 'Đang mở thẻ…'),
              Failure<Challenge>(:final message, :final offline) => Padding(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: ErrorState(
                  title: 'Chưa mở được thẻ thử thách',
                  cause: message,
                  kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
                  onRetry: viewModel.retry,
                ),
              ),
              Data<Challenge>(:final value) => _Detail(
                challenge: value,
                state: state,
                viewModel: viewModel,
                onDone: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => _ResultSheet(provider: provider),
                ),
                onEasier: easier,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.challenge,
    required this.state,
    required this.viewModel,
    required this.onDone,
    required this.onEasier,
  });

  final Challenge challenge;
  final ChallengeDetailState state;
  final ChallengeDetailViewModel viewModel;
  final VoidCallback onDone;
  final VoidCallback onEasier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final minutes = state.minutes ?? challenge.minutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: <Widget>[
              Text(
                challenge.label,
                style: AppTextStyles.of(context).overline
                    .copyWith(color: colors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpace.s8),
              Semantics(
                header: true,
                child: Text(
                  challenge.title,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              if (challenge.tip.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpace.s12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpace.s8),
                    Expanded(
                      child: Text(
                        challenge.tip,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.s24),
              Text('Bạn hồi hộp cỡ nào?', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpace.s8),
              SegmentedButton<int>(
                segments: <ButtonSegment<int>>[
                  for (var level = 1; level <= 5; level++)
                    ButtonSegment<int>(
                      value: level,
                      label: Text('$level'),
                      tooltip: switch (level) {
                        1 => 'Hồi hộp 1: Bình tĩnh',
                        5 => 'Hồi hộp 5: Run lắm',
                        _ => 'Hồi hộp $level',
                      },
                    ),
                ],
                selected: <int>{?state.anxiety},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                onSelectionChanged: (selection) => selection.isEmpty
                    ? viewModel.setAnxiety(state.anxiety ?? 0)
                    : viewModel.setAnxiety(selection.first),
              ),
              const SizedBox(height: AppSpace.s4),
              Row(
                children: <Widget>[
                  Text('Bình tĩnh', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text('Run lắm', style: theme.textTheme.bodySmall),
                ],
              ),
              if (challenge.script.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpace.s24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.tintLavender,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: AppSpace.s4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Câu mẫu', style: theme.textTheme.labelLarge),
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          '“${challenge.script}”',
                          style: AppTextStyles.of(context).body17,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (state.isMovement) ...<Widget>[
                const SizedBox(height: AppSpace.s24),
                Text('Bạn đã vận động', style: theme.textTheme.titleMedium),
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: minutes > 0
                          ? () => viewModel.setMinutes(minutes - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                      tooltip: 'Bớt 1 phút',
                    ),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          '$minutes phút',
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: minutes < ChallengeDetailViewModel.maxMinutes
                          ? () => viewModel.setMinutes(minutes + 1)
                          : null,
                      icon: const Icon(Icons.add),
                      tooltip: 'Thêm 1 phút',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.s24),
              const Center(child: Mascot(state: MascotState.tapTrung)),
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
            children: <Widget>[
              // Chấm hồi hộp không bắt buộc: "Xong rồi" luôn bật.
              AppButton(label: 'Xong rồi', expand: true, onPressed: onDone),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Đổi thẻ dễ hơn',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: onEasier,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sheet "Kết quả?": hai lựa chọn và một dòng cảm giác sau.
class _ResultSheet extends ConsumerStatefulWidget {
  const _ResultSheet({required this.provider});

  final NotifierProvider<ChallengeDetailViewModel, ChallengeDetailState>
  provider;

  @override
  ConsumerState<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends ConsumerState<_ResultSheet> {
  final _feeling = TextEditingController();
  ChallengeOutcome? _outcome;

  @override
  void dispose() {
    _feeling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(widget.provider);
    final viewModel = ref.read(widget.provider.notifier);

    ref.listen(widget.provider, (previous, next) {
      if (next.savedNoteId != null && previous?.savedNoteId == null) {
        Navigator.of(context).pop();
      }
    });

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
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
              Text('Kết quả?', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpace.s12),
              Wrap(
                spacing: AppSpace.s8,
                children: <Widget>[
                  for (final outcome in ChallengeOutcome.values)
                    QuickWinChip(
                      label: state.outcomeLabel(outcome),
                      selected: _outcome == outcome,
                      onSelected: (_) => setState(() => _outcome = outcome),
                    ),
                ],
              ),
              if (_outcome == ChallengeOutcome.notAsHoped) ...<Widget>[
                const SizedBox(height: AppSpace.s8),
                Text(
                  state.isMovement
                      ? 'Dừng sớm vẫn được ghi vào hũ.'
                      : 'Vẫn tính là dũng cảm: bạn đã mở lời.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.s16),
              AppTextField(
                label: 'Cảm giác sau',
                helper: 'Không bắt buộc',
                controller: _feeling,
                maxLength: ChallengeDetailViewModel.feelingMaxLength,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpace.s16),
              AppButton(
                label: 'Lưu',
                expand: true,
                loading: state.saving,
                onPressed: _outcome == null || state.saving
                    ? null
                    : () => viewModel.save(_outcome!, _feeling.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
