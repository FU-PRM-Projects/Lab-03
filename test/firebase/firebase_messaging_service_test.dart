import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/firebase/firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMessaging extends Fake implements FirebaseMessaging {}

class _FakeLocal extends Fake implements FlutterLocalNotificationsPlugin {}

/// Hộp thư FCM lưu trong SharedPreferences, chung cho mọi tài khoản trên máy.
void main() {
  late FirebaseMessagingService service;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'fcm_inbox': <String>[
        '{"title":"Nốt nhắc nhẹ","body":"Của tài khoản trước","at":0,'
            '"origin":"foreground"}',
      ],
    });
    service = FirebaseMessagingService(
      messaging: _FakeMessaging(),
      local: _FakeLocal(),
    );
  });

  test('clearInbox xoá hết thông báo đã lưu', () async {
    expect(await service.inbox(), hasLength(1));
    await service.clearInbox();
    expect(await service.inbox(), isEmpty);
  });
}
