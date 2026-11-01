import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/self_control.dart';

/// "Thói quen muốn bớt" của người dùng đang đăng nhập. Lỗi là `AppException`.
abstract interface class HabitRepository {
  /// Phát lại mỗi khi danh sách đổi; chưa có tài liệu thì là danh sách rỗng.
  Stream<HabitList> watch();

  /// Chọn hoặc bỏ chọn [habit] (lưu ngay, handout S09).
  Future<void> setSelected(String habit, {required bool selected});

  /// "+ Thêm": thêm và chọn luôn [habit].
  Future<void> addCustom(String habit);
}

/// Cài đặt của người dùng (S09 Giờ tỉnh, S12). Lỗi là `AppException`.
abstract interface class SettingsRepository {
  /// Chưa có tài liệu thì phát cài đặt mặc định.
  Stream<UserSettings> watch();

  Future<void> save(UserSettings settings);
}

/// Xác thực bằng vân tay / khuôn mặt / mã máy (`local_auth`).
abstract interface class LocalAuthService {
  /// `true` khi xác thực thành công; `false` khi người dùng huỷ, sai, hoặc
  /// máy chưa đặt khoá màn hình.
  Future<bool> authenticate(String reason);
}

/// Cờ cửa sổ của Android.
abstract interface class ScreenGuard {
  /// Ẩn màn hình khỏi danh sách app gần đây và ảnh chụp (S09).
  Future<void> setSecure(bool enabled);

  /// Giữ màn hình sáng (S10 khi đang thở).
  Future<void> setKeepScreenOn(bool enabled);
}

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => throw UnimplementedError('habitRepositoryProvider chưa được gắn'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('settingsRepositoryProvider chưa được gắn'),
);

final localAuthServiceProvider = Provider<LocalAuthService>(
  (ref) => throw UnimplementedError('localAuthServiceProvider chưa được gắn'),
);

final screenGuardProvider = Provider<ScreenGuard>(
  (ref) => throw UnimplementedError('screenGuardProvider chưa được gắn'),
);
