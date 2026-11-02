import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thông báo trên máy (không qua server): lời nhắc "Giờ tỉnh" ở S09.
abstract interface class NudgeService {
  /// Nhắc mỗi ngày lúc [minutes] (phút kể từ 0h, giờ trên máy); gọi lại thì
  /// thay lịch cũ. Chạm vào thông báo mở S09.
  Future<void> scheduleAwakeNudge(int minutes);

  Future<void> cancelAwakeNudge();

  /// Xin quyền hiện thông báo (Android 13+). `true` khi được phép.
  Future<bool> requestPermission();

  /// Đường dẫn cần mở khi người dùng chạm vào thông báo: phát khi app đang
  /// chạy; lần mở app từ thông báo thì đọc [launchRoute].
  Stream<String> get openedRoutes;

  /// Đường dẫn của thông báo đã mở app (app đang tắt), nếu có.
  Future<String?> launchRoute();
}

final nudgeServiceProvider = Provider<NudgeService>(
  (ref) => throw UnimplementedError('nudgeServiceProvider chưa được gắn'),
);
