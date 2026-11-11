import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_core/not_core.dart';

import '../services/admin_services.dart';
import 'messages.dart';

/// Trạng thái đăng nhập của web admin.
sealed class Session {
  const Session();
}

class SignedOut extends Session {
  const SignedOut();
}

/// Đã đăng nhập Google nhưng vai trò là `user`: web admin từ chối.
class Rejected extends Session {
  const Rejected(this.user);

  final AdminUser user;
}

class StaffSession extends Session {
  const StaffSession(this.user, this.role);

  final AdminUser user;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
}

final authUserProvider = StreamProvider<AdminUser?>(
  (ref) => ref.watch(adminAuthProvider).authStateChanges(),
);

/// Đăng nhập lần đầu thì tạo hồ sơ `role = user` (rules chỉ cho vậy), rồi
/// theo dõi vai trò: chỉ staff và admin được vào.
///
/// Vai trò đọc theo thời gian thực (`users/{uid}` snapshot), không chỉ một lần
/// lúc đăng nhập: admin hạ một staff xuống `user` thì phiên đang mở của người
/// đó chuyển ngay sang màn từ chối, thay vì vẫn hiện quyền cũ rồi mọi thao tác
/// báo "không có quyền" (góp ý CR-F1 trong `docs/test-report.md`).
final sessionProvider = StreamProvider<Session>((ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield const SignedOut();
    return;
  }
  final directory = ref.watch(userDirectoryProvider);
  final analytics = ref.read(adminAnalyticsProvider);
  await directory.ensureProfile(
    user.uid,
    displayName: user.displayName,
    email: user.email,
  );
  UserRole? last;
  await for (final value in directory.watchRole(user.uid)) {
    final role = value ?? UserRole.user;
    if (role == last) continue;
    last = role;
    if (!role.canUseAdmin) {
      await analytics.log('admin_access_denied');
      yield Rejected(user);
    } else {
      await analytics.setUser(user.uid);
      await analytics.log('admin_sign_in', <String, Object>{'role': role.id});
      yield StaffSession(user, role);
    }
  }
});

/// Phiên staff hiện tại; chỉ dùng ở các màn sau khi đã vào shell.
StaffSession requireStaff(Ref ref) {
  final session = ref.read(sessionProvider).value;
  if (session is StaffSession) return session;
  throw const AppException(AppErrorKind.permissionDenied, code: 'not-staff');
}

/// Nút "Đăng nhập với Google" ở màn đăng nhập.
class SignInState {
  const SignInState({this.busy = false, this.error});

  final bool busy;
  final String? error;
}

class SignInViewModel extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  Future<void> signIn() async {
    if (state.busy) return;
    state = const SignInState(busy: true);
    try {
      await ref.read(adminAuthProvider).signInWithGoogle();
      state = const SignInState();
    } on AppException catch (e) {
      state = SignInState(
        error: e.kind == AppErrorKind.cancelled
            ? 'Bạn đã đóng cửa sổ đăng nhập. Thử lại khi sẵn sàng.'
            : errorMessage(e),
      );
    }
  }

  /// Đăng nhập email trên Emulator (không có ở bản thật).
  Future<void> signInWithEmail(String email, String password) async {
    if (state.busy) return;
    state = const SignInState(busy: true);
    try {
      await ref.read(adminAuthProvider).signInWithEmail(email.trim(), password);
      state = const SignInState();
    } on AppException catch (e) {
      state = SignInState(
        error: e.kind == AppErrorKind.invalidInput
            ? 'Email hoặc mật khẩu không đúng.'
            : errorMessage(e),
      );
    }
  }

  Future<void> signOut() async {
    await ref.read(adminAuthProvider).signOut();
    await ref.read(adminAnalyticsProvider).setUser(null);
    state = const SignInState();
  }
}

final signInViewModelProvider = NotifierProvider<SignInViewModel, SignInState>(
  SignInViewModel.new,
);
