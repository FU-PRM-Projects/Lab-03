import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/mascot.dart';
import 'email_auth_sheet.dart';

/// S01 · Chào mừng & Đăng nhập (Figma `03 Final UI`, frame 1196:21855).
///
/// Đăng nhập xong, router tự chuyển tới `next` hoặc S02 (xem
/// `router/auth_redirect.dart`), nên màn này không tự điều hướng.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({this.next, super.key});

  /// Đích sau khi đăng nhập (`?next=`), ví dụ khi mở từ thông báo (P7).
  final String? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);
    final viewModel = ref.read(authViewModelProvider.notifier);

    ref.listen(authViewModelProvider, (_, next) {
      if (next.source == AuthAction.google && next.message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
        viewModel.clearMessage();
      }
    });

    void openEmailForm(EmailFormMode mode) {
      viewModel.clearMessage();
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EmailAuthSheet(mode: mode),
      );
    }

    // Nền primary nên chữ và icon thanh trạng thái màu trắng.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppPalette.primary,
        body: Stack(
          children: <Widget>[
            // `pattern/note`: hoạ tiết tờ nốt chìm (opacity 45% có sẵn trong SVG).
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/illustrations/note-pattern.svg',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      0,
                      AppSpace.screen,
                      AppSpace.s8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Expanded(child: _Hero()),
                        _GoogleButton(
                          loading: state.busy == AuthAction.google,
                          onPressed: state.isBusy
                              ? null
                              : viewModel.signInWithGoogle,
                        ),
                        const SizedBox(height: AppSpace.s12),
                        _OutlinedOnPrimaryButton(
                          label: 'Đăng nhập bằng email',
                          onPressed: state.isBusy
                              ? null
                              : () => openEmailForm(EmailFormMode.signIn),
                        ),
                        const SizedBox(height: AppSpace.s12),
                        _RegisterLink(
                          onPressed: state.isBusy
                              ? null
                              : () => openEmailForm(EmailFormMode.register),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  /// Khung `MascotAnim` trong Figma giữ tỉ lệ 96 × 108 của mascot.
  static Widget _mascot(MascotState state, double width) => SvgPicture.asset(
    state.asset,
    width: width,
    height: width * 108 / 96,
    excludeFromSemantics: true,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 280,
              height: 200,
              padding: const EdgeInsets.only(bottom: AppSpace.s20),
              decoration: BoxDecoration(
                color: AppPalette.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: AppSpace.s4,
                children: <Widget>[
                  _mascot(MascotState.thongTha, 72),
                  _mascot(MascotState.xong, 112),
                  _mascot(MascotState.tapTrung, 72),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Semantics(
              header: true,
              child: Text(
                'Nốt',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: onPrimary,
                  letterSpacing: -0.88,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s8),
            Text(
              'Mỗi ngày một nốt tích cực.',
              style: AppTextStyles.of(context).body17.copyWith(
                color: onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// `Button/google`: nút theo hướng dẫn thương hiệu Google (nền trắng, viền
/// `#747775`, chữ Roboto Medium 14 `#1F1F1F`, logo chính thức).
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});

  static const String _label = 'Tiếp tục với Google';
  static const Color _border = Color(0xFF747775);
  static const Color _text = Color(0xFF1F1F1F);

  final bool loading;
  final VoidCallback? onPressed;

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
        const Flexible(
          child: Text(
            _label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
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
      label: loading ? '$_label, đang xử lý' : null,
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
        // Giữ nội dung (vô hình) dưới vòng xoay để nút không đổi bề rộng.
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

/// `Button/outlined-on-primary`: viền trắng 1.5, chữ Body/16 Bold trắng.
class _OutlinedOnPrimaryButton extends StatelessWidget {
  const _OutlinedOnPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final enabled = onPressed != null;
    final color = enabled ? onPrimary : onPrimary.withValues(alpha: 0.5);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        foregroundColor: onPrimary,
        disabledForegroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

/// `Link/đăng ký`: "Chưa có tài khoản? **Đăng ký**" (chữ đậm gạch chân).
class _RegisterLink extends StatelessWidget {
  const _RegisterLink({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: onPressed == null ? onPrimary.withValues(alpha: 0.5) : onPrimary,
    );

    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s12,
            vertical: AppSpace.s14,
          ),
        ),
        child: Text.rich(
          TextSpan(
            text: 'Chưa có tài khoản? ',
            children: <InlineSpan>[
              TextSpan(
                text: 'Đăng ký',
                style: style?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: style.color,
                ),
              ),
            ],
          ),
          style: style,
        ),
      ),
    );
  }
}
