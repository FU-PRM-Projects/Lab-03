import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_tokens.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/mascot.dart';
import 'email_auth_sheet.dart';

/// S01 · Chào mừng & Đăng nhập.
///
/// Đăng nhập xong, router tự chuyển tới `next` hoặc S02 (xem
/// `router/auth_redirect.dart`), nên màn này không tự điều hướng.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({this.next, super.key});

  /// Đích sau khi đăng nhập (`?next=`), ví dụ khi mở từ thông báo (P7).
  final String? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    final googleBusy = state.busy == AuthAction.google;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Expanded(child: _Hero()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    0,
                    AppSpace.screen,
                    AppSpace.s24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AppButton(
                        label: 'Tiếp tục với Google',
                        loading: googleBusy,
                        onPressed: state.isBusy
                            ? null
                            : viewModel.signInWithGoogle,
                      ),
                      const SizedBox(height: AppSpace.s12),
                      AppButton(
                        label: 'Đăng nhập bằng email',
                        variant: AppButtonVariant.outlined,
                        onPressed: state.isBusy
                            ? null
                            : () => openEmailForm(EmailFormMode.signIn),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      AppButton(
                        label: 'Chưa có tài khoản? Đăng ký',
                        variant: AppButtonVariant.text,
                        onPressed: state.isBusy
                            ? null
                            : () => openEmailForm(EmailFormMode.register),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.screen),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpace.s24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Mascot(state: MascotState.thongTha, size: 80),
              Mascot(state: MascotState.xong, size: 112),
              Mascot(state: MascotState.tapTrung, size: 80),
            ],
          ),
          const SizedBox(height: AppSpace.s24),
          Semantics(
            header: true,
            child: Text('Nốt', style: theme.textTheme.displayMedium),
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            'Mỗi ngày một nốt tích cực.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
