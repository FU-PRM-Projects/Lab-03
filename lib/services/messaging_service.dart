import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thông báo đẩy (FCM) ở trạng thái nào của app khi nhận.
enum MessageOrigin {
  /// App đang mở.
  foreground,

  /// App chạy nền, người dùng chạm thông báo.
  background,

  /// App đã tắt, người dùng chạm thông báo để mở.
  terminated,
}

/// Một thông báo đã nhận, lưu trong hộp thư của app (khu demo S12).
class ReceivedNotification {
  const ReceivedNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.origin,
  });

  factory ReceivedNotification.fromJson(Map<String, dynamic> json) =>
      ReceivedNotification(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
          json['at'] as int? ?? 0,
        ),
        origin: MessageOrigin.values.firstWhere(
          (o) => o.name == json['origin'],
          orElse: () => MessageOrigin.foreground,
        ),
      );

  final String title;
  final String body;
  final DateTime receivedAt;
  final MessageOrigin origin;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'body': body,
    'at': receivedAt.millisecondsSinceEpoch,
    'origin': origin.name,
  };
}

/// Quyền nhận thông báo của hệ điều hành.
enum NotificationPermission { granted, denied, notAsked }

/// FCM: xin quyền, lấy token và gom thông báo đã nhận vào hộp thư.
abstract interface class MessagingService {
  /// Gắn bộ nghe (foreground, chạm từ nền, mở từ app tắt). Gọi một lần.
  Future<void> start();

  Future<NotificationPermission> permission();

  /// Hiện hộp thoại xin quyền của hệ điều hành.
  Future<NotificationPermission> requestPermission();

  /// Mở phần cài đặt thông báo của app trên máy.
  Future<void> openSystemSettings();

  /// Token của máy này; `null` khi chưa có (chưa cấp quyền, mất mạng).
  Future<String?> token();

  /// Hộp thư, mới nhất trước.
  Future<List<ReceivedNotification>> inbox();
}

/// Không làm gì: test và nền tảng không có FCM.
class NoopMessagingService implements MessagingService {
  const NoopMessagingService();

  @override
  Future<void> start() async {}

  @override
  Future<NotificationPermission> permission() async =>
      NotificationPermission.notAsked;

  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.notAsked;

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<String?> token() async => null;

  @override
  Future<List<ReceivedNotification>> inbox() async =>
      const <ReceivedNotification>[];
}

final messagingServiceProvider = Provider<MessagingService>(
  (ref) => const NoopMessagingService(),
);

/// Số lần hộp thư đổi, để màn đang mở đọc lại.
class InboxRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final inboxRevisionProvider = NotifierProvider<InboxRevision, int>(
  InboxRevision.new,
);

final inboxProvider = FutureProvider<List<ReceivedNotification>>((ref) {
  ref.watch(inboxRevisionProvider);
  return ref.watch(messagingServiceProvider).inbox();
});

/// Quyền thông báo hiện tại, đọc lại khi màn S12 mở.
final notificationPermissionProvider =
    FutureProvider.autoDispose<NotificationPermission>((ref) {
      // Người dùng có thể đổi quyền ở cài đặt hệ thống rồi quay lại app.
      final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
      ref.onDispose(listener.dispose);
      return ref.watch(messagingServiceProvider).permission();
    });
