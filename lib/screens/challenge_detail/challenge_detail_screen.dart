import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/challenge.dart';
import '../../models/discord_room.dart';
import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
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
                // Thẻ Discord: S08d chọn câu chào rồi mở phòng; quay lại
                // app thì S08 thành "Bạn vừa ghé phòng chung".
                onOpenRoom: () async {
                  final visited = await context.push<bool>(
                    AppRoutes.challengeGreeting(challengeId),
                  );
                  if (visited ?? false) viewModel.markVisitedDiscord();
                },
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
    required this.onOpenRoom,
  });

  final Challenge challenge;
  final ChallengeDetailState state;
  final ChallengeDetailViewModel viewModel;
  final VoidCallback onDone;
  final VoidCallback onEasier;
  final VoidCallback onOpenRoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = state.minutes ?? challenge.minutes;
    if (challenge.onDiscord && state.visitedDiscord) {
      return _DiscordReturn(
        challenge: challenge,
        state: state,
        viewModel: viewModel,
      );
    }
    final room = DiscordRooms.byKey(challenge.discordRoom ?? '');

    // Figma S08: thẻ thử thách, lời dặn, thang hồi hộp, câu mở lời; hai nút
    // dính đáy (spacer co giãn), màn thấp thì cuộn.
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
              spacing: AppSpace.s16,
              children: <Widget>[
                _ChallengeHeader(challenge: challenge),
                if (challenge.tip.isNotEmpty)
                  Text(challenge.tip, style: theme.textTheme.bodyLarge),
                _AnxietyScale(
                  value: state.anxiety,
                  onChanged: viewModel.setAnxiety,
                ),
                if (challenge.script.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
                    child: Semantics(
                      label: 'Câu mở lời gợi ý',
                      child: Text(
                        '“${challenge.script}”',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                if (state.isMovement)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Bạn đã vận động',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                                style: theme.textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                minutes < ChallengeDetailViewModel.maxMinutes
                                ? () => viewModel.setMinutes(minutes + 1)
                                : null,
                            icon: const Icon(Icons.add),
                            tooltip: 'Thêm 1 phút',
                          ),
                        ],
                      ),
                    ],
                  ),
                const Spacer(),
                if (room != null) ...<Widget>[
                  AppButton(
                    label: 'Mở ${room.name}',
                    expand: true,
                    onPressed: onOpenRoom,
                  ),
                  // "Để mai" như Back: không trừ gì (F3).
                  AppButton(
                    label: 'Để mai',
                    variant: AppButtonVariant.text,
                    expand: true,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.challenges),
                  ),
                ] else ...<Widget>[
                  // Chấm hồi hộp không bắt buộc: "Xong rồi" luôn bật.
                  AppButton(label: 'Xong rồi', expand: true, onPressed: onDone),
                  AppButton(
                    label: 'Đổi thẻ dễ hơn',
                    variant: AppButtonVariant.text,
                    expand: true,
                    onPressed: onEasier,
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

/// Figma S08 · quay lại từ Discord: "Bạn vừa ghé phòng chung", thang "Sau đó
/// bạn thấy sao?", một câu kể thêm; "Mình đã chào, ghi nốt" hoặc "Mới ghé
/// phòng thôi" (vẫn ghi, ghé cũng là một bước).
class _DiscordReturn extends StatefulWidget {
  const _DiscordReturn({
    required this.challenge,
    required this.state,
    required this.viewModel,
  });

  final Challenge challenge;
  final ChallengeDetailState state;
  final ChallengeDetailViewModel viewModel;

  @override
  State<_DiscordReturn> createState() => _DiscordReturnState();
}

class _DiscordReturnState extends State<_DiscordReturn> {
  final _feeling = TextEditingController();

  @override
  void dispose() {
    _feeling.dispose();
    super.dispose();
  }

  void _save(ChallengeOutcome outcome) =>
      widget.viewModel.save(outcome, _feeling.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saving = widget.state.saving;

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
              spacing: AppSpace.s16,
              children: <Widget>[
                _ChallengeHeader(
                  challenge: widget.challenge,
                  title: 'Bạn vừa ghé phòng chung',
                  mascot: MascotState.xong,
                ),
                Text(
                  'Ghé mà chưa chào cũng là một bước.',
                  style: theme.textTheme.bodyLarge,
                ),
                _AnxietyScale(
                  question: 'Sau đó bạn thấy sao?',
                  value: widget.state.anxietyAfter,
                  onChanged: widget.viewModel.setAnxietyAfter,
                ),
                AppTextField(
                  label: 'Kể một câu (không bắt buộc)',
                  hint: 'Ví dụ: “Mình đã chào, có 2 người chào lại.”',
                  controller: _feeling,
                  maxLength: ChallengeDetailViewModel.feelingMaxLength,
                ),
                const Spacer(),
                AppButton(
                  label: 'Mình đã chào, ghi nốt',
                  expand: true,
                  loading: saving,
                  onPressed: saving
                      ? null
                      : () => _save(ChallengeOutcome.smooth),
                ),
                AppButton(
                  label: 'Mới ghé phòng thôi',
                  variant: AppButtonVariant.text,
                  expand: true,
                  onPressed: saving
                      ? null
                      : () => _save(ChallengeOutcome.notAsHoped),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma `Card/thử thách`: nền tint xanh lá, bo 24, mascot Tập Trung, nhãn
/// chủ đề Caption/12 Bold màu success và tên thử thách Headline/22.
class _ChallengeHeader extends StatelessWidget {
  const _ChallengeHeader({
    required this.challenge,
    this.title,
    this.mascot = MascotState.tapTrung,
  });

  final Challenge challenge;

  /// Thay tên thử thách ("Bạn vừa ghé phòng chung").
  final String? title;
  final MascotState mascot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.noteTint(NoteType.thuThach),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s20,
          vertical: AppSpace.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s12,
          children: <Widget>[
            Mascot(state: mascot, size: 120.96),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s8,
              children: <Widget>[
                Text(
                  challenge.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.success,
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    title ?? challenge.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      letterSpacing: -0.44,
                    ),
                    textAlign: TextAlign.center,
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

/// Figma `hồi hộp`: 5 nút tròn 48 trải đều, nút chọn nền primary; hai nhãn
/// đầu thang Label/13 bên dưới. Chạm lại nút đang chọn để bỏ chọn (ViewModel).
class _AnxietyScale extends StatelessWidget {
  const _AnxietyScale({
    required this.value,
    required this.onChanged,
    this.question = 'Bạn hồi hộp cỡ nào?',
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final String question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final caption = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s12,
      children: <Widget>[
        Text(
          question,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (var level = 1; level <= 5; level++)
              _AnxietyDot(
                level: level,
                selected: value == level,
                onTap: () => onChanged(level),
              ),
          ],
        ),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Bình tĩnh', style: caption),
              Text('Run lắm', style: caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnxietyDot extends StatelessWidget {
  const _AnxietyDot({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final int level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: switch (level) {
        1 => 'Hồi hộp 1: Bình tĩnh',
        5 => 'Hồi hộp 5: Run lắm',
        _ => 'Hồi hộp $level',
      },
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerLow,
        shape: CircleBorder(
          side: selected
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: AppSize.minTouch,
            child: Center(
              child: Text(
                '$level',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
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
