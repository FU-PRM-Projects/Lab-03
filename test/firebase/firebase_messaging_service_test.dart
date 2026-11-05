import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/firebase/firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMessaging extends Fake implements FirebaseMessaging {}

/// Ghi lại thông báo đã hiện, không gọi plugin thật.
class _FakeLocal extends Fake implements FlutterLocalNotificationsPlugin {
  final List<({String? title, String? payload})> shown =
      <({String? title, String? payload})>[];

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add((title: title, payload: payload));
  }
}

/// Hộp thư FCM lưu trong SharedPreferences, chung cho mọi tài khoản trên máy.
void main() {
  late FirebaseMessagingService service;
  late _FakeLocal local;

  setUp(() {
    local = _FakeLocal();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'fcm_inbox': <String>[
        '{"title":"Nốt nhắc nhẹ","body":"Của tài khoản trước","at":0,'
            '"origin":"foreground"}',
      ],
    });
    service = FirebaseMessagingService(
      messaging: _FakeMessaging(),
      local: local,
    );
  });

  test(
    'tin lúc app đang mở: hiện thông báo kèm màn đích để chạm mở đúng màn',
    () async {
      await service.showForeground(
        const RemoteMessage(
          data: <String, dynamic>{'route': '/jar'},
          notification: RemoteNotification(title: 'Nốt từ Console'),
        ),
      );
      expect(local.shown.single.title, 'Nốt từ Console');
      expect(local.shown.single.payload, '/jar');
      expect((await service.inbox()).first.title, 'Nốt từ Console');
    },
  );

  test('route lạ hoặc thiếu: thông báo vẫn mở về Hôm nay', () async {
    await service.showForeground(
      const RemoteMessage(
        data: <String, dynamic>{'route': 'https://evil.example'},
        notification: RemoteNotification(title: 'Lạ'),
      ),
    );
    expect(local.shown.single.payload, '/today');
  });

  test('clearInbox xoá hết thông báo đã lưu', () async {
    expect(await service.inbox(), hasLength(1));
    await service.clearInbox();
    expect(await service.inbox(), isEmpty);
  });
}
