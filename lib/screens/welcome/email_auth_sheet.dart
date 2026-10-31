import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Form email của S01: đăng nhập, đăng ký và quên mật khẩu (flow P2).
class EmailAuthSheet extends ConsumerStatefulWidget {
  const EmailAuthSheet({required this.mode, super.key});

  final EmailFormMode mode;

  @override
  ConsumerState<EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends ConsumerState<EmailAuthSheet> {
  // Chữ đang gõ là state cục bộ của form; kiểm tra và gửi đi nằm ở ViewModel.
  final _email = TextEditingController();
  final _password = TextEditingController();

  static const Set<AuthAction> _formActions = <AuthAction>{
    AuthAction.emailSignIn,
    AuthAction.register,
    AuthAction.passwordReset,
  };

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authViewModelProvider);
    final viewModel = ref.read(authViewModelProvider.notifier);
    final register = widget.mode == EmailFormMode.register;

    ref.listen(authViewModelProvider, (_, next) {
      final signedIn =
          next.succeeded &&
          (next.source == AuthAction.emailSignIn ||
              next.source == AuthAction.register);
      if (signedIn && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    void submit() =>
        viewModel.submitEmail(widget.mode, _email.text, _password.text);

    final message = _formActions.contains(state.source) ? state.message : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screen,
        0,
        AppSpace.screen,
        AppSpace.s16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            register ? 'Tạo tài khoản' : 'Đăng nhập bằng email',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpace.s16),
          AppTextField(
            controller: _email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: state.emailError,
            autofocus: true,
          ),
          const SizedBox(height: AppSpace.s12),
          AppTextField(
            controller: _password,
            label: 'Mật khẩu',
            helper: register ? 'Ít nhất 8 ký tự' : null,
            obscureText: true,
            textInputAction: TextInputAction.done,
            errorText: state.passwordError,
            onSubmitted: (_) => submit(),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpace.s12),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: state.succeeded
                      ? AppColors.of(context).success
                      : theme.colorScheme.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: register ? 'Đăng ký' : 'Đăng nhập',
            expand: true,
            loading:
                state.busy == AuthAction.emailSignIn ||
                state.busy == AuthAction.register,
            onPressed: state.isBusy ? null : submit,
          ),
          if (!register)
            AppButton(
              label: 'Quên mật khẩu?',
              variant: AppButtonVariant.text,
              loading: state.busy == AuthAction.passwordReset,
              onPressed: state.isBusy
                  ? null
                  : () => viewModel.sendPasswordReset(_email.text),
            ),
        ],
      ),
    );
  }
}
