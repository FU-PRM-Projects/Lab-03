import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'mascot.dart';

/// Component `Loading state`: Skeleton list và Spinner.
class LoadingState extends StatelessWidget {
  /// Vòng xoay giữa vùng nội dung.
  const LoadingState.spinner({this.message, super.key})
    : skeletonCount = 0,
      columns = 0;

  /// Lưới ô xám nhấp nháy (S05, S11c), có mascot Đợi khi có [message].
  const LoadingState.skeleton({
    this.message,
    this.skeletonCount = 6,
    this.columns = 2,
    super.key,
  });

  final String? message;
  final int skeletonCount;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = message ?? 'Đang tải';

    if (skeletonCount == 0) {
      return Semantics(
        label: label,
        liveRegion: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              if (message != null) ...<Widget>[
                const SizedBox(height: AppSpace.s12),
                Text(message!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s16),
              child: Row(
                children: <Widget>[
                  const Mascot(state: MascotState.doi, size: 48),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Text(message!, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          _Pulse(
            child: GridView.count(
              crossAxisCount: columns,
              mainAxisSpacing: AppSpace.grid,
              crossAxisSpacing: AppSpace.grid,
              childAspectRatio: 158 / 137,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                for (var i = 0; i < skeletonCount; i++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhấp nháy nhẹ; đứng yên khi người dùng bật giảm chuyển động.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _controller, child: widget.child);
}

/// Component `Empty state`: mascot, một câu, một nút.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.mascot = MascotState.doi,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final MascotState mascot;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      background: AppColors.of(context).tintLavender,
      mascot: mascot,
      title: title,
      message: message,
      action: actionLabel == null
          ? null
          : AppButton(label: actionLabel!, onPressed: onAction),
    );
  }
}

/// Kiểu của component `Error state` Lab 2.
enum ErrorKind { offline, loadFailed }

/// Component `Error state`: mascot Lạc, nguyên nhân, nút Thử lại.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.cause,
    required this.onRetry,
    this.kind = ErrorKind.loadFailed,
    this.retryLabel = 'Thử lại',
    super.key,
  });

  final String title;

  /// Nguyên nhân và cách sửa, ví dụ "Kiểm tra Wi-Fi rồi thử lại."
  final String cause;
  final VoidCallback? onRetry;
  final ErrorKind kind;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      background: AppColors.of(context).tintGray,
      mascot: MascotState.lac,
      icon: kind == ErrorKind.offline ? Icons.cloud_off_outlined : null,
      title: title,
      message: cause,
      action: AppButton(
        label: retryLabel,
        onPressed: onRetry,
        icon: Icons.refresh,
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.background,
    required this.mascot,
    required this.title,
    required this.message,
    this.icon,
    this.action,
  });

  final Color background;
  final MascotState mascot;
  final String title;
  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSize.narrowContentMaxWidth,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Mascot(state: mascot, size: 88),
                const SizedBox(height: AppSpace.s16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSpace.s8),
                    ],
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(height: AppSpace.s20),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
