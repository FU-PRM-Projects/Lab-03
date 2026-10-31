import 'dart:async';

import 'package:lab03/models/app_user.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/user_repository.dart';

const AppUser testUser = AppUser(
  uid: 'u-minh',
  email: 'minh.test@example.com',
  displayName: 'Minh',
);

/// [AuthService] trong bộ nhớ. Giống Firebase: người nghe mới nhận ngay trạng
/// thái hiện tại.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? signedIn}) : _user = signedIn;

  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  /// Lỗi ném ra ở lần gọi đăng nhập/đăng ký/gửi link kế tiếp.
  AppException? nextError;

  /// Giữ lần đăng nhập Google chưa xong để test thấy trạng thái Loading.
  Completer<void>? googleGate;

  int signOutCount = 0;
  final List<String> resetEmails = <String>[];

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  Future<AppUser> _signIn(AppUser user) async {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    _set(user);
    return user;
  }

  @override
  Stream<AppUser?> authStateChanges() => Stream<AppUser?>.multi((controller) {
    controller.add(_user);
    final sub = _changes.stream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithGoogle() async {
    await googleGate?.future;
    return _signIn(testUser);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _signIn(AppUser(uid: 'u-$email', email: email));

  @override
  Future<AppUser> registerWithEmail(String email, String password) =>
      _signIn(AppUser(uid: 'u-$email', email: email));

  @override
  Future<void> sendPasswordReset(String email) async {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    resetEmails.add(email);
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    _set(null);
  }
}

class FakeUserRepository implements UserRepository {
  final List<AppUser> profiles = <AppUser>[];
  int clearCount = 0;
  AppException? ensureError;

  @override
  Future<void> ensureProfile(AppUser user) async {
    if (ensureError != null) throw ensureError!;
    profiles.add(user);
  }

  @override
  Future<void> clearLocalData() async => clearCount++;
}
