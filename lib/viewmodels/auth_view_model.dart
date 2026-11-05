import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/app_exception.dart';
import '../services/auth_service.dart';
import '../services/crash_reporter.dart';
import '../services/draft_store.dart';
import '../services/messaging_service.dart';
import '../services/user_repository.dart';
import '../utils/validators.dart';

/// Người dùng hiện tại; router dùng để chuyển hướng theo đăng nhập.
final authUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

/// Việc đăng nhập đang chạy, để màn hình đặt nút tương ứng ở trạng thái
/// Loading và khoá các nút còn lại.
enum AuthAction { google, emailSignIn, register, passwordReset, signOut }

/// Kiểu form email ở S01.
enum EmailFormMode { signIn, register }

class AuthState {
  const AuthState({
    this.busy,
    this.message,
    this.source,
    this.succeeded = false,
    this.emailError,
    this.passwordError,
  });

  final AuthAction? busy;

  /// Câu thông báo cho người dùng (lỗi, hoặc xác nhận đã gửi link).
  final String? message;

  /// Việc vừa kết thúc, để mỗi màn chỉ hiện thông báo của việc nó gây ra.
  final AuthAction? source;

  /// [source] kết thúc thành công.
  final bool succeeded;
  final String? emailError;
  final String? passwordError;

  bool get isBusy => busy != null;
}

/// ViewModel của S01 (đăng nhập, đăng ký, quên mật khẩu) và đăng xuất ở S12.
class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthService get _auth => ref.read(authServiceProvider);
  UserRepository get _users => ref.read(userRepositoryProvider);

  Future<void> signInWithGoogle() => _run(
    AuthAction.google,
    () => _afterSignIn(_auth.signInWithGoogle(), 'google'),
  );

  /// Kiểm tra form rồi đăng nhập hoặc đăng ký bằng email (flow P2).
  Future<void> submitEmail(
    EmailFormMode mode,
    String email,
    String password,
  ) async {
    final emailError = Validators.email(email);
    final passwordError = Validators.password(password);
    if (emailError != null || passwordError != null) {
      state = AuthState(emailError: emailError, passwordError: passwordError);
      return;
    }

    final trimmed = email.trim();
    await switch (mode) {
      EmailFormMode.signIn => _run(
        AuthAction.emailSignIn,
        () => _afterSignIn(_auth.signInWithEmail(trimmed, password), 'email'),
      ),
      EmailFormMode.register => _run(
        AuthAction.register,
        () => _afterSignIn(_auth.registerWithEmail(trimmed, password), 'email'),
      ),
    };
  }

  /// Gửi link đặt lại mật khẩu. Luôn báo cùng một câu dù email có tài khoản
  /// hay không, để không lộ email nào đã đăng ký (P2).
  Future<void> sendPasswordReset(String email) async {
    final emailError = Validators.email(email);
    if (emailError != null) {
      state = AuthState(emailError: emailError);
      return;
    }
    await _run(AuthAction.passwordReset, () async {
      try {
        await _auth.sendPasswordReset(email.trim());
      } on AppException catch (e) {
        if (e.kind != AppErrorKind.invalidInput) rethrow;
      }
      return 'Nếu email này có tài khoản, Nốt đã gửi link đặt lại mật khẩu.';
    });
  }

  /// Đăng xuất và xoá dữ liệu của người dùng còn trên máy.
  Future<void> signOut() => _run(AuthAction.signOut, () async {
    final analytics = ref.read(analyticsServiceProvider);
    await analytics.track(AnalyticsEvents.logout);
    await analytics.setUserId(null).onError((_, _) {});
    await _auth.signOut();
    try {
      await _users.clearLocalData();
      await ref.read(draftStoreProvider).clear();
      // Hộp thư FCM nằm trên máy, không theo tài khoản: xoá để người đăng
      // nhập sau không đọc được thông báo cũ.
      await ref.read(messagingServiceProvider).clearInbox();
      ref.read(inboxRevisionProvider.notifier).bump();
    } on Object {
      // Không chặn đăng xuất nếu chưa xoá được bộ nhớ đệm; lần sau xoá lại.
    }
    return null;
  });

  /// Xoá thông báo và lỗi dưới ô (khi mở lại form, hoặc sau khi đã hiện
  /// SnackBar).
  void clearMessage() => state = AuthState(busy: state.busy);

  /// Tạo hồ sơ ở lần đăng nhập đầu. Lỗi tạo hồ sơ không làm hỏng đăng nhập:
  /// hồ sơ sẽ được tạo lại ở lần đăng nhập sau.
  Future<String?> _afterSignIn(Future<AppUser> signIn, String method) async {
    final user = await signIn;
    final analytics = ref.read(analyticsServiceProvider);
    await analytics.setUserId(user.uid).onError((_, _) {});
    unawaited(
      analytics.track(AnalyticsEvents.login, <String, Object>{
        AnalyticsParams.method: method,
      }),
    );
    try {
      await _users.ensureProfile(user);
    } on AppException catch (error, stack) {
      unawaited(
        ref
            .read(crashReporterProvider)
            .recordError(error, stack, reason: 'ensureProfile'),
      );
    }
    return null;
  }

  Future<void> _run(AuthAction action, Future<String?> Function() task) async {
    if (state.isBusy) return;
    state = AuthState(busy: action);
    try {
      final message = await task();
      state = AuthState(message: message, source: action, succeeded: true);
    } on AppException catch (e) {
      state = AuthState(message: _messageFor(action, e), source: action);
    }
  }

  static String _messageFor(AuthAction action, AppException e) {
    if (e.kind == AppErrorKind.network) {
      return 'Không có mạng. Kiểm tra Wi-Fi rồi thử lại.';
    }
    return switch ((action, e.kind, e.code)) {
      (AuthAction.google, AppErrorKind.cancelled, _) => 'Bạn đã huỷ đăng nhập.',
      (_, _, 'email-already-in-use') =>
        'Email này đã có tài khoản. Thử đăng nhập nhé.',
      (_, _, 'weak-password') => 'Mật khẩu yếu quá. Thử mật khẩu dài hơn.',
      (AuthAction.emailSignIn, AppErrorKind.invalidInput, _) =>
        'Email hoặc mật khẩu chưa đúng.',
      (AuthAction.signOut, _, _) => 'Chưa đăng xuất được. Thử lại.',
      _ => 'Không đăng nhập được. Thử lại.',
    };
  }
}
