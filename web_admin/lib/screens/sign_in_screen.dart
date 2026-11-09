import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import '../config.dart';
import '../viewmodels/messages.dart';
import '../viewmodels/session_view_model.dart';
import '../widgets/admin_widgets.dart';

/// Màn 1 · Đăng nhập: Google Sign-In, từ chối tài khoản không phải staff.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final signIn = ref.watch(signInViewModelProvider);
    final vm = ref.read(signInViewModelProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final Widget body = switch (session) {
      AsyncLoading() => const LoadingView(message: 'Đang kiểm tra tài khoản…'),
      AsyncError(:final error) => _Panel(
        mascot: 'lac',
        title: 'Chưa kiểm tra được tài khoản',
        message: errorMessage(error),
        children: <Widget>[
          FilledButton(
            onPressed: () => ref.invalidate(sessionProvider),
            child: const Text('Thử lại'),
          ),
          TextButton(onPressed: vm.signOut, child: const Text('Đăng xuất')),
        ],
      ),
      AsyncData(value: Rejected(:final user)) => _Panel(
        mascot: 'lac',
        title: 'Tài khoản này không có quyền vào web admin',
        message:
            '${user.email.isEmpty ? 'Tài khoản' : user.email} là tài khoản '
            'người dùng app. Web admin chỉ dành cho staff và admin. Nhờ admin '
            'cấp quyền rồi đăng nhập lại.',
        children: <Widget>[
          FilledButton(
            onPressed: vm.signOut,
            child: const Text('Đăng nhập bằng tài khoản khác'),
          ),
        ],
      ),
      _ => _Panel(
        mascot: 'thong-tha',
        title: 'Nốt · Web admin',
        message:
            'Quản lý kho thẻ thử thách, duyệt thẻ người dùng gửi và gửi '
            'thông báo tới app. Dành cho staff và admin.',
        children: <Widget>[
          FilledButton.icon(
            onPressed: signIn.busy ? null : vm.signIn,
            icon: signIn.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(
              signIn.busy ? 'Đang mở Google…' : 'Đăng nhập với Google',
            ),
          ),
          if (useFirebaseEmulator) const _EmulatorEmailSignIn(),
          if (signIn.error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                signIn.error!,
                style: text.bodySmall?.copyWith(color: scheme.error),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    };

    return Scaffold(
      backgroundColor: scheme.primary,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: NotePatternBackground()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, minHeight: 360),
              child: Card(
                margin: const EdgeInsets.all(AppSpace.s24),
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s24),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.mascot,
    required this.title,
    required this.message,
    required this.children,
  });

  final String mascot;
  final String title;
  final String message;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(child: AdminMascot(mascot, size: 112)),
        const SizedBox(height: AppSpace.s16),
        Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpace.s8),
        Text(
          message,
          style: text.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.s24),
        for (final child in children) ...<Widget>[
          child,
          const SizedBox(height: AppSpace.s8),
        ],
      ],
    );
  }
}

/// Chỉ có khi build với `USE_FIREBASE_EMULATOR=true`: đăng nhập bằng tài
/// khoản email tạo trên Auth Emulator, để test cục bộ không cần Google.
class _EmulatorEmailSignIn extends ConsumerStatefulWidget {
  const _EmulatorEmailSignIn();

  @override
  ConsumerState<_EmulatorEmailSignIn> createState() =>
      _EmulatorEmailSignInState();
}

class _EmulatorEmailSignInState extends ConsumerState<_EmulatorEmailSignIn> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(signInViewModelProvider.notifier)
      .signInWithEmail(_email.text, _password.text);

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('Tài khoản thử trên Emulator'),
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: AppSpace.s8),
    children: <Widget>[
      TextField(
        controller: _email,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      const SizedBox(height: AppSpace.s8),
      TextField(
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Mật khẩu'),
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: AppSpace.s8),
      OutlinedButton(onPressed: _submit, child: const Text('Đăng nhập email')),
    ],
  );
}
