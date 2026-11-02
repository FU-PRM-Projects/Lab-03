import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_routes.dart';

/// Các lời nhắc hằng ngày của Nốt.
enum Nudge {
  /// "Nhắc ghi nốt buổi tối" (S12, flow F1): chạm vào mở S03a.
  evening(
    id: 2,
    channel: 'evening',
    channelName: 'Nhắc ghi nốt buổi tối',
    channelDescription: 'Nhắc ghi nốt mỗi tối.',
    title: 'Hôm nay bạn làm được gì?',
    body: 'Ghi một nốt nhỏ trước khi ngủ nhé.',
  ),

  /// "Giờ tỉnh" (S09): nhắc lúc bắt đầu khung giờ dễ lướt vô thức, chạm vào
  /// mở S09.
  awake(
    id: 1,
    channel: 'awake',
    channelName: 'Giờ tỉnh',
    channelDescription: 'Nhắc nhẹ trong khung giờ dễ lướt vô thức.',
    title: 'Đến giờ tỉnh rồi',
    body: 'Đang lướt à? Chạm để dừng lại và ghi 1 lần tự chủ.',
  );

  const Nudge({
    required this.id,
    required this.channel,
    required this.channelName,
    required this.channelDescription,
    required this.title,
    required this.body,
  });

  final int id;
  final String channel;
  final String channelName;
  final String channelDescription;
  final String title;
  final String body;

  /// Màn mở ra khi chạm vào thông báo.
  String get route => switch (this) {
    Nudge.evening => AppRoutes.newNote(),
    Nudge.awake => AppRoutes.selfControl,
  };
}

/// Thông báo trên máy (không qua server): các lời nhắc [Nudge].
abstract interface class NudgeService {
  /// Nhắc [nudge] mỗi ngày lúc [minutes] (phút kể từ 0h, giờ trên máy); gọi
  /// lại thì thay lịch cũ.
  Future<void> schedule(Nudge nudge, int minutes);

  Future<void> cancel(Nudge nudge);

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
