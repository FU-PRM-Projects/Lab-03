import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';

/// Hồ sơ `users/{uid}` và dữ liệu của người dùng lưu trên máy.
abstract interface class UserRepository {
  /// Tạo `users/{uid}` với `role = user` ở lần đăng nhập đầu; không làm gì
  /// nếu hồ sơ đã có.
  Future<void> ensureProfile(AppUser user);

  /// Xoá dữ liệu của người dùng còn trên máy (bộ nhớ đệm, nháp) khi đăng xuất.
  Future<void> clearLocalData();
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => throw UnimplementedError('userRepositoryProvider chưa được gắn'),
);
