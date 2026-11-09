import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

/// `Button/google`: nút đăng nhập theo hướng dẫn thương hiệu Google, giống nút
/// "Tiếp tục với Google" ở màn Welcome của app (nền trắng, viền `#747775`,
/// chữ Roboto Medium 14 `#1F1F1F`, logo chính thức). Đang xử lý thì giữ bề
/// rộng và hiện vòng xoay.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  static const Color _border = Color(0xFF747775);
  static const Color _text = Color(0xFF1F1F1F);

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final onTap = loading ? null : onPressed;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s10,
      children: <Widget>[
        SvgPicture.asset(
          'assets/icons/google.svg',
          width: 20,
          height: 20,
          excludeFromSemantics: true,
        ),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: _text,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: loading ? '$label, đang xử lý' : null,
      excludeSemantics: loading,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white,
          foregroundColor: _text,
          side: const BorderSide(color: _border),
          shape: const StadiumBorder(),
        ),
        child: loading
            ? Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Opacity(opacity: 0, child: content),
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              )
            : content,
      ),
    );
  }
}

/// `pattern/note`: hoạ tiết tờ nốt chìm trên nền primary, cùng SVG với màn
/// Welcome của app (opacity 45% có sẵn trong SVG). Ô 360×800 được lát kín
/// thay vì phóng to, để nét vẽ trên màn hình rộng giữ đúng cỡ như trên điện
/// thoại.
class NotePatternBackground extends StatelessWidget {
  const NotePatternBackground({super.key});

  static const Size _tile = Size(360, 800);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.maxWidth / _tile.width).ceil();
          final rows = (constraints.maxHeight / _tile.height).ceil();
          return Stack(
            children: <Widget>[
              for (var row = 0; row < rows; row++)
                for (var column = 0; column < columns; column++)
                  Positioned(
                    left: column * _tile.width,
                    top: row * _tile.height,
                    width: _tile.width,
                    height: _tile.height,
                    child: SvgPicture.asset(
                      'assets/illustrations/note-pattern.svg',
                      excludeFromSemantics: true,
                    ),
                  ),
            ],
          );
        },
      ),
    ),
  );
}

/// Tụi Nốt, cùng bộ SVG với app (component `Mascot` của Lab 2).
class AdminMascot extends StatelessWidget {
  const AdminMascot(this.name, {this.size = 96, this.label, super.key});

  /// `doi`, `lac`, `xong`, `thong-tha`, `tap-trung`…
  final String name;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/mascot/mascot-not-$name.svg',
    width: size,
    height: size,
    semanticsLabel: label,
    excludeFromSemantics: label == null,
  );
}

/// Trạng thái đang tải.
class LoadingView extends StatelessWidget {
  const LoadingView({this.message = 'Đang tải…', super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: message,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpace.s12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

/// Trạng thái trống hoặc lỗi: mascot, tiêu đề, một câu và một nút tuỳ chọn.
class MessageView extends StatelessWidget {
  const MessageView({
    required this.title,
    required this.message,
    this.mascot = 'thong-tha',
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Lỗi tải dữ liệu, có nút Thử lại.
  const MessageView.error({
    required this.message,
    this.onAction,
    this.title = 'Chưa tải được dữ liệu',
    super.key,
  }) : mascot = 'lac',
       actionLabel = 'Thử lại';

  final String title;
  final String message;
  final String mascot;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AdminMascot(mascot),
              const SizedBox(height: AppSpace.s16),
              Text(title, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.s8),
              Text(
                message,
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: AppSpace.s16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung một màn của web admin: tiêu đề, mô tả, nút bên phải, nội dung giới
/// hạn bề rộng cho màn rộng.
class AdminPage extends StatelessWidget {
  const AdminPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.maxWidth = 1200,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s24,
            AppSpace.s24,
            AppSpace.s24,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: AppSpace.s16,
                runSpacing: AppSpace.s12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(title, style: text.headlineSmall),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          subtitle!,
                          style: text.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (actions.isNotEmpty)
                    Wrap(
                      spacing: AppSpace.s8,
                      runSpacing: AppSpace.s8,
                      children: actions,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s20),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ nền surface-card bo `card`, như thẻ của app.
class AdminCard extends StatelessWidget {
  const AdminCard({required this.child, this.padding, this.color, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Padding(
      padding: padding ?? const EdgeInsets.all(AppSpace.s16),
      child: child,
    ),
  );
}

/// Nhãn nhỏ bo tròn (chủ đề, trạng thái).
class AdminChip extends StatelessWidget {
  const AdminChip(this.label, {this.color, this.textColor, super.key});

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s10,
          vertical: AppSpace.s4,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: textColor ?? scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

/// Màu nền / chữ của nhãn chủ đề.
(Color, Color) topicColors(ChallengeTopic topic) => switch (topic) {
  ChallengeTopic.dungCam => (AppPalette.tintViolet, AppPalette.primaryDark),
  ChallengeTopic.vanDong => (AppPalette.tintGreen, AppPalette.success),
};

/// Màu nền / chữ của nhãn trạng thái thẻ gửi.
(Color, Color) statusColors(SubmissionStatus status) => switch (status) {
  SubmissionStatus.pending => (AppPalette.tintOrange, AppPalette.warning),
  SubmissionStatus.approved => (AppPalette.tintGreen, AppPalette.success),
  SubmissionStatus.rejected => (AppPalette.tintRed, AppPalette.error),
};

String formatDateTime(DateTime? value) {
  if (value == null) return 'Đang gửi…';
  String two(int n) => n.toString().padLeft(2, '0');
  final local = value.toLocal();
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? scheme.error : null,
        behavior: SnackBarBehavior.floating,
        width: 480,
      ),
    );
}
