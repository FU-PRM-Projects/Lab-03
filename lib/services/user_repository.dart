import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_core/models/user_role.dart';

import '../models/app_user.dart';

/// Hồ sơ `users/{uid}` và dữ liệu của người dùng lưu trên máy.
abstract interface class UserRepository {
  /// Tạo `users/{uid}` với `role = user` ở lần đăng nhập đầu; không làm gì
  /// nếu hồ sơ đã có.
  Future<void> ensureProfile(AppUser user);

  /// Vai trò trong `users/{uid}.role`; `null` khi chưa có hồ sơ (lần đăng
  /// nhập đầu, hồ sơ sẽ được tạo với `role = user`).
  Future<UserRole?> roleOf(String uid);

  /// Xoá dữ liệu của người dùng còn trên máy (bộ nhớ đệm, nháp) khi đăng xuất.
  Future<void> clearLocalData();
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => throw UnimplementedError('userRepositoryProvider chưa được gắn'),
);
