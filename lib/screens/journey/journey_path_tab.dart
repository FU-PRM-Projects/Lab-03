import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/note_type.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/journey_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/state_views.dart';

/// S11a · Con đường: chặng hiện tại của từng chủ đề thử thách.
class JourneyPathTab extends StatelessWidget {
  const JourneyPathTab({required this.state, required this.onRetry, super.key});

  final ViewState<List<PathStage>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Loading<List<PathStage>>() => const LoadingState.spinner(
        message: 'Đang vẽ con đường…',
      ),
      Failure<List<PathStage>>(:final message, :final offline) => Padding(
        padding: const EdgeInsets.all(AppSpace.screen),
        child: ErrorState(
          title: 'Chưa tải được con đường',
          cause: message,
          kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
          onRetry: onRetry,
        ),
      ),
      Empty<List<PathStage>>() => const Padding(
        padding: EdgeInsets.all(AppSpace.screen),
        child: EmptyState(
          title: 'Chưa có chặng nào',
          message: 'Thẻ thử thách sẽ sớm có. Ghé lại sau nhé.',
        ),
      ),
      Data<List<PathStage>>(:final value) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.s8,
          AppSpace.screen,
          AppSpace.tabContentBottom,
        ),
        children: <Widget>[
          for (final stage in value) ...<Widget>[
            _StageCard(stage: stage),
            const SizedBox(height: AppSpace.s12),
            for (final node in stage.nodes) _PathNodeRow(node: node),
            if (stage.hasNextLevel)
              _LockedNext(label: 'Chặng ${stage.level + 1}'),
            const SizedBox(height: AppSpace.s24),
          ],
        ],
      ),
    };
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage});

  final PathStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final total = stage.nodes.length;
    final title = stage.current?.challenge.title ?? 'Đã xong chặng này';

    return Semantics(
      button: true,
      label:
          'Chặng ${stage.level}, ${stage.topic.label}: $title, '
          'đã làm ${stage.done} trên $total. Mở Thử thách',
      excludeSemantics: true,
      child: Material(
        color: colors.noteTint(NoteType.thuThach),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.go(AppRoutes.challenges),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'CHẶNG ${stage.level} · ${stage.topic.label.toUpperCase()}',
                  style: AppTextStyles.of(context).overline
                      .copyWith(color: colors.onSurfaceMuted),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpace.s12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : stage.done / total,
                          minHeight: AppSpace.s8,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Text(
                      '${stage.done}/$total',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PathNodeRow extends StatelessWidget {
  const _PathNodeRow({required this.node});

  final PathNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final challenge = node.challenge;
    final (icon, background, foreground, status) = switch (node.status) {
      PathNodeStatus.done => (
        Icons.check,
        AppColors.of(context).success,
        scheme.onPrimary,
        'đã xong',
      ),
      PathNodeStatus.current => (
        Icons.star,
        scheme.primary,
        scheme.onPrimary,
        'đang làm',
      ),
      PathNodeStatus.locked => (
        Icons.lock_outline,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        'chưa mở',
      ),
    };
    final current = node.status == PathNodeStatus.current;

    return Semantics(
      button: current,
      label: '${challenge.title}, $status',
      excludeSemantics: true,
      onTap: current
          ? () => context.push(AppRoutes.challengeDetail(challenge.id))
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: current
            ? () => context.push(AppRoutes.challengeDetail(challenge.id))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s6),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background,
                ),
                child: SizedBox.square(
                  dimension: AppSize.shortcut,
                  child: Icon(icon, color: foreground),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Text(
                  current
                      ? '${challenge.title} · ${challenge.minutes} phút'
                      : challenge.title,
                  style: current
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodyMedium?.copyWith(
                          color: node.status == PathNodeStatus.locked
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                ),
              ),
              if (current) const Mascot(state: MascotState.tapTrung, size: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedNext extends StatelessWidget {
  const _LockedNext({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '$label, chưa mở',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s6),
        child: Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 2),
              ),
              child: SizedBox.square(
                dimension: AppSize.shortcut,
                child: Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
