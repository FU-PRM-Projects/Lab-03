import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';

/// Đăng nhập và trạng thái đăng nhập.
///
/// Mọi lỗi được ném dưới dạng `AppException`.
abstract interface class AuthService {
  /// Phát người dùng hiện tại mỗi khi trạng thái đăng nhập đổi; `null` khi
  /// chưa đăng nhập.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithEmail(String email, String password);

  Future<AppUser> registerWithEmail(String email, String password);

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

/// Gắn hiện thực thật ở `main.dart`, bản fake ở test.
final authServiceProvider = Provider<AuthService>(
  (ref) => throw UnimplementedError('authServiceProvider chưa được gắn'),
);
