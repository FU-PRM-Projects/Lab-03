import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
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

  /// Figma: thẻ 400 trên màn 800 (một nửa màn), trong khoảng này.
  static const double _minCardHeight = 320;
  static const double _maxCardHeight = 460;

  /// Hai thẻ sau lộ ra dưới thẻ chính 16 và 30.
  static const double _stackPeek = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = cards[page];
    final cardHeight = (MediaQuery.sizeOf(context).height * 0.5).clamp(
      _minCardHeight,
      _maxCardHeight,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.s16,
        AppSpace.screen,
        AppSpace.tabContentBottom,
      ),
      children: <Widget>[
        // Figma `cấp`: chủ đề · cấp, thanh 100 × 6, số thẻ đã làm.
        Row(
          spacing: AppSpace.s12,
          children: <Widget>[
            Flexible(
              child: Text(current.header, style: theme.textTheme.labelLarge),
            ),
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: current.levelTotal == 0
                      ? 0
                      : current.levelDone / current.levelTotal,
                  minHeight: AppSpace.s6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  semanticsLabel:
                      '${current.header}, đã làm ${current.levelDone} '
                      'trên ${current.levelTotal} thẻ',
                ),
              ),
            ),
            Text(
              '${current.levelDone}/${current.levelTotal}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        // Figma `chồng thẻ`: hai thẻ sau (mono/1, surface-variant) lùi vào 12
        // và 24 mỗi bên, thẻ chính vuốt ngang được.
        SizedBox(
          height: cardHeight + _stackPeek,
          child: Stack(
            children: <Widget>[
              _BackCard(
                inset: 24,
                top: 30,
                height: cardHeight,
                color: scheme.surfaceContainerHighest,
              ),
              _BackCard(
                inset: 12,
                top: 16,
                height: cardHeight,
                color: AppPalette.mono1,
              ),
              SizedBox(
                height: cardHeight,
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
                    itemBuilder: (context, i) => _ChallengeCard(card: cards[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        ExcludeSemantics(
          child: Row(
            spacing: AppSpace.s8,
            children: <Widget>[
              for (var i = 0; i < cards.length; i++)
                Container(
                  width: i == page ? 20 : AppSpace.s8,
                  height: AppSpace.s8,
                  decoration: BoxDecoration(
                    color: i == page
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.r4),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        // Nút chữ: chạm cũng đổi thẻ (thẻ cuối thì quay về thẻ đầu).
        AppButton(
          label: 'Vuốt để đổi thẻ',
          variant: AppButtonVariant.text,
          expand: true,
          onPressed: cards.length < 2
              ? null
              : () => onGoTo((page + 1) % cards.length),
        ),
      ],
    );
  }
}

class _BackCard extends StatelessWidget {
  const _BackCard({
    required this.inset,
    required this.top,
    required this.height,
    required this.color,
  });

  final double inset;
  final double top;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
    left: inset,
    right: inset,
    top: top,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );
}

/// Figma `thẻ chính`: nền tint xanh lá, bo 24, lề 24, nội dung căn giữa cách
/// nhau 12 (mascot, nhãn chủ đề, tên thử thách, nút).
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.card});

  final DeckCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final challenge = card.challenge;
    final caption = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.noteTint(NoteType.thuThach),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpace.s12,
          children: <Widget>[
            const Flexible(
              child: FittedBox(
                child: Mascot(state: MascotState.tapTrung, size: 145.8),
              ),
            ),
            if (card.easier)
              Text(
                'THẺ DỄ HƠN',
                style: caption?.copyWith(color: theme.colorScheme.primary),
              ),
            Text(
              challenge.label,
              style: caption?.copyWith(color: colors.success),
            ),
            Text(
              challenge.title,
              style: theme.textTheme.titleLarge?.copyWith(letterSpacing: -0.44),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
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
