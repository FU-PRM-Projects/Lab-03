import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/app_user.dart';
import 'package:lab03/router/auth_redirect.dart';

void main() {
  const user = AppUser(uid: 'u1');
  const signedIn = AsyncData<AppUser?>(user);
  const signedOut = AsyncData<AppUser?>(null);
  const loading = AsyncLoading<AppUser?>();

  String? redirect(AsyncValue<AppUser?> auth, String location) =>
      authRedirect(auth, Uri.parse(location));

  group('chưa biết trạng thái đăng nhập', () {
    test('mọi route chờ ở /splash, giữ đích', () {
      expect(redirect(loading, '/jar'), '/splash?next=%2Fjar');
      expect(redirect(loading, '/splash?next=/jar'), isNull);
    });
  });

  group('chưa đăng nhập', () {
    test('route trong app về /welcome kèm next', () {
      expect(redirect(signedOut, '/jar/n1'), '/welcome?next=%2Fjar%2Fn1');
      expect(
        redirect(signedOut, '/note/new?step=1'),
        '/welcome?next=%2Fnote%2Fnew%3Fstep%3D1',
      );
    });

    test('từ /splash sang /welcome, giữ next', () {
      expect(redirect(signedOut, '/splash?next=/jar'), '/welcome?next=%2Fjar');
      expect(redirect(signedOut, '/splash'), '/welcome');
    });

    test('đã ở /welcome thì đứng yên', () {
      expect(redirect(signedOut, '/welcome?next=/jar'), isNull);
    });

    test('lỗi đọc trạng thái coi như chưa đăng nhập', () {
      expect(
        redirect(const AsyncError<AppUser?>('x', StackTrace.empty), '/today'),
        '/welcome?next=%2Ftoday',
      );
    });
  });

  group('đã đăng nhập', () {
    test('rời /welcome tới next hoặc /today', () {
      expect(redirect(signedIn, '/welcome?next=/jar'), '/jar');
      expect(redirect(signedIn, '/welcome'), '/today');
      expect(
        redirect(signedIn, '/splash?next=/challenges/c1'),
        '/challenges/c1',
      );
    });

    test('route trong app không bị chuyển', () {
      expect(redirect(signedIn, '/jar'), isNull);
      expect(redirect(signedIn, '/settings'), isNull);
    });
  });

  test('safeNext chỉ nhận đường dẫn nội bộ', () {
    expect(safeNext('/jar'), '/jar');
    expect(safeNext('https://evil.example'), isNull);
    expect(safeNext('//evil.example'), isNull);
    expect(safeNext('/welcome'), isNull);
    expect(safeNext(null), isNull);
  });
}
