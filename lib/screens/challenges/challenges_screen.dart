import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/challenges_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/mascot.dart';
import '../../widgets/state_views.dart';
import '../common/screen_skeleton.dart';

/// S07 · Thử thách (tab 3).
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  final _pages = PageController();

  /// Thẻ đang xem (trạng thái giao diện, không phải dữ liệu).
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    if (duration == Duration.zero) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page, duration: duration, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengesViewModelProvider);
    final viewModel = ref.read(challengesViewModelProvider.notifier);

    // "Đổi thẻ dễ hơn" ở S08: thẻ dễ hơn nằm đầu chồng, đưa về thẻ đầu.
    ref.listen(challengesViewModelProvider, (previous, next) {
      if (next case Data<List<DeckCard>>(:final value)
          when value.first.easier && _pages.hasClients) {
        _goTo(0);
      }
    });

    return TabScaffold(
      title: 'Thử thách',
      body: switch (state) {
        Loading<List<DeckCard>>() => const LoadingState.spinner(
          message: 'Đang chọn thẻ cho bạn…',
        ),
        Failure<List<DeckCard>>(:final message, :final offline) => Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: ErrorState(
            title: 'Chưa tải được thẻ thử thách',
            cause: message,
            kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
            onRetry: viewModel.retry,
          ),
        ),
        Empty<List<DeckCard>>() => const Padding(
          padding: EdgeInsets.all(AppSpace.screen),
          child: EmptyState(
            title: 'Bạn đã làm hết thẻ thử thách!',
            message: 'Thẻ mới sẽ được thêm sớm. Ghé lại sau nhé.',
            mascot: MascotState.xong,
          ),
        ),
        Data<List<DeckCard>>(:final value) => _Deck(
          cards: value,
          page: _page.clamp(0, value.length - 1),
          controller: _pages,
          onPageChanged: (page) => setState(() => _page = page),
          onGoTo: _goTo,
        ),
      },
    );
  }
}

class _Deck extends StatelessWidget {
  const _Deck({
    required this.cards,
    required this.page,
    required this.controller,
    required this.onPageChanged,
    required this.onGoTo,
  });

  final List<DeckCard> cards;
  final int page;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoTo;

  /// Thẻ cao tối đa 60% màn (handout S07), trong khoảng này.
  static const double _minCardHeight = 320;
  static const double _maxCardHeight = 460;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = cards[page];
    final cardHeight = MediaQuery.sizeOf(context).height * 0.6;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        0,
        AppSpace.s8,
        0,
        AppSpace.tabContentBottom,
      ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      current.header,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${current.levelDone}/${current.levelTotal}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: current.levelTotal == 0
                      ? 0
                      : current.levelDone / current.levelTotal,
                  minHeight: AppSpace.s8,
                  semanticsLabel:
                      '${current.header}, đã làm ${current.levelDone} '
                      'trên ${current.levelTotal} thẻ',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        SizedBox(
          height: cardHeight.clamp(_minCardHeight, _maxCardHeight),
          child: Semantics(
            // Người dùng trình đọc màn hình đổi thẻ bằng thao tác cuộn.
            onScrollLeft: page < cards.length - 1
                ? () => onGoTo(page + 1)
                : null,
            onScrollRight: page > 0 ? () => onGoTo(page - 1) : null,
            child: PageView.builder(
              controller: controller,
              itemCount: cards.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.screen,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSize.narrowContentMaxWidth,
                    ),
                    child: _ChallengeCard(card: cards[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              onPressed: page > 0 ? () => onGoTo(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Thẻ trước',
            ),
            for (var i = 0; i < cards.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == page
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                  child: const SizedBox.square(dimension: AppSpace.s8),
                ),
              ),
            IconButton(
              onPressed: page < cards.length - 1
                  ? () => onGoTo(page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Thẻ sau',
            ),
          ],
        ),
        Text(
          'Vuốt để đổi thẻ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.card});

  final DeckCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final challenge = card.challenge;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.noteTint(NoteType.thuThach),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (card.easier) ...<Widget>[
              Text(
                'THẺ DỄ HƠN',
                style: AppTextStyles.of(context).overline
                    .copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: AppSpace.s4),
            ],
            Text(
              challenge.label,
              style: AppTextStyles.of(context).overline
                  .copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpace.s8),
            Text(
              challenge.title,
              style: theme.textTheme.headlineSmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const Center(child: Mascot(state: MascotState.tapTrung)),
            const Spacer(),
            AppButton(
              label: 'Nhận thử thách',
              expand: true,
              onPressed: () =>
                  context.push(AppRoutes.challengeDetail(challenge.id)),
            ),
          ],
        ),
      ),
    );
  }
}
