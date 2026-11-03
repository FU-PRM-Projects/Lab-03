import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/services/analytics_events.dart';
import 'package:lab03/services/analytics_service.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/draft_store.dart';
import 'package:lab03/services/user_repository.dart';
import 'package:lab03/viewmodels/auth_view_model.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeUserRepository users;
  late FakeDraftStore drafts;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  AuthViewModel vm() => container.read(authViewModelProvider.notifier);
  AuthState state() => container.read(authViewModelProvider);

  setUp(() {
    auth = FakeAuthService();
    users = FakeUserRepository();
    drafts = FakeDraftStore();
    analytics = FakeAnalyticsService();
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users),
        draftStoreProvider.overrideWithValue(drafts),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
  });

  group('Google', () {
    test('thành công: tạo hồ sơ users/{uid}', () async {
      await vm().signInWithGoogle();
      expect(state().succeeded, isTrue);
      expect(state().message, isNull);
      expect(users.profiles.single, testUser);
    });

    test('huỷ chọn tài khoản: báo "Bạn đã huỷ đăng nhập."', () async {
      auth.nextError = const AppException(AppErrorKind.cancelled);
      await vm().signInWithGoogle();
      expect(state().message, 'Bạn đã huỷ đăng nhập.');
      expect(state().source, AuthAction.google);
      expect(state().succeeded, isFalse);
      expect(users.profiles, isEmpty);
    });

    test('mất mạng: báo kiểm tra Wi-Fi', () async {
      auth.nextError = const AppException(AppErrorKind.network);
      await vm().signInWithGoogle();
      expect(state().message, 'Không có mạng. Kiểm tra Wi-Fi rồi thử lại.');
    });

    test('lỗi tạo hồ sơ không làm hỏng đăng nhập', () async {
      users.ensureError = const AppException(AppErrorKind.permissionDenied);
      await vm().signInWithGoogle();
      expect(state().succeeded, isTrue);
      expect(auth.currentUser, testUser);
    });
  });

  group('form email (P2)', () {
    test('dữ liệu sai: lỗi dưới ô, không gọi service', () async {
      await vm().submitEmail(EmailFormMode.signIn, 'minh@', '123');
      expect(state().emailError, 'Email chưa đúng dạng, ví dụ ten@gmail.com.');
      expect(state().passwordError, 'Mật khẩu cần ít nhất 8 ký tự.');
      expect(auth.currentUser, isNull);
    });

    test('ô trống báo cần nhập', () async {
      await vm().submitEmail(EmailFormMode.register, '  ', '');
      expect(state().emailError, 'Nhập email của bạn.');
      expect(state().passwordError, 'Nhập mật khẩu.');
    });

    test('đăng ký thành công, bỏ khoảng trắng ở email', () async {
      await vm().submitEmail(
        EmailFormMode.register,
        ' ngoc@example.com ',
        'matkhau123',
      );
      expect(state().succeeded, isTrue);
      expect(auth.currentUser?.email, 'ngoc@example.com');
    });

    test('email đã có tài khoản', () async {
      auth.nextError = const AppException(
        AppErrorKind.invalidInput,
        code: 'email-already-in-use',
      );
      await vm().submitEmail(
        EmailFormMode.register,
        'ngoc@example.com',
        'matkhau123',
      );
      expect(state().message, 'Email này đã có tài khoản. Thử đăng nhập nhé.');
    });

    test('sai mật khẩu', () async {
      auth.nextError = const AppException(
        AppErrorKind.invalidInput,
        code: 'invalid-credential',
      );
      await vm().submitEmail(
        EmailFormMode.signIn,
        'ngoc@example.com',
        'matkhau123',
      );
      expect(state().message, 'Email hoặc mật khẩu chưa đúng.');
    });
  });

  group('quên mật khẩu', () {
    const sent =
        'Nếu email này có tài khoản, Nốt đã gửi link đặt lại mật khẩu.';

    test('gửi link và báo câu chung', () async {
      await vm().sendPasswordReset('ngoc@example.com');
      expect(auth.resetEmails, <String>['ngoc@example.com']);
      expect(state().message, sent);
      expect(state().succeeded, isTrue);
    });

    test(
      'email chưa có tài khoản vẫn báo cùng câu (không lộ tài khoản)',
      () async {
        auth.nextError = const AppException(
          AppErrorKind.invalidInput,
          code: 'user-not-found',
        );
        await vm().sendPasswordReset('nobody@example.com');
        expect(state().message, sent);
      },
    );
  });

  test(
    'đăng nhập ghi login + userId; đăng xuất ghi logout rồi xoá userId',
    () async {
      await vm().signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(analytics.userId, testUser.uid);
      expect(analytics.events.single.name, AnalyticsEvents.login);
      expect(analytics.events.single.params[AnalyticsParams.method], 'google');

      await vm().signOut();
      expect(analytics.events.last.name, AnalyticsEvents.logout);
      expect(analytics.userId, isNull);
    },
  );

  test('đăng xuất xoá dữ liệu trên máy (kể cả nháp S03)', () async {
    await vm().signInWithGoogle();
    drafts.draft = const NoteDraft(title: 'Đi bộ');
    await vm().signOut();
    expect(auth.signOutCount, 1);
    expect(users.clearCount, 1);
    expect(drafts.draft, isNull);
    expect(auth.currentUser, isNull);
  });

  test('không chạy hai việc cùng lúc', () async {
    final first = vm().signInWithGoogle();
    await vm().submitEmail(EmailFormMode.signIn, 'a@b.co', 'matkhau123');
    await first;
    expect(auth.currentUser, testUser);
  });
}
