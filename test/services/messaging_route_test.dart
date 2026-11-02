import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/services/messaging_service.dart';

/// Chạm thông báo FCM chỉ được mở màn nội bộ trong danh sách cho phép.
void main() {
  group('routeFromData', () {
    test('route hợp lệ: mở đúng màn', () {
      expect(routeFromData(<String, dynamic>{'route': '/jar'}), '/jar');
      expect(
        routeFromData(<String, dynamic>{'route': '/challenges'}),
        '/challenges',
      );
      expect(
        routeFromData(<String, dynamic>{'route': '/self-control'}),
        '/self-control',
      );
    });

    test('thiếu route hoặc sai kiểu: về Hôm nay', () {
      expect(routeFromData(<String, dynamic>{}), '/today');
      expect(routeFromData(<String, dynamic>{'route': 5}), '/today');
      expect(routeFromData(<String, dynamic>{'route': null}), '/today');
    });

    test('route lạ hoặc bên ngoài: bị từ chối, về Hôm nay', () {
      expect(
        routeFromData(<String, dynamic>{'route': 'https://evil.example'}),
        '/today',
      );
      expect(routeFromData(<String, dynamic>{'route': '//evil'}), '/today');
      expect(routeFromData(<String, dynamic>{'route': '/welcome'}), '/today');
      expect(
        routeFromData(<String, dynamic>{'route': '/dev/components'}),
        '/today',
      );
    });
  });

  group('NoopMessagingService', () {
    test('không có quyền và hộp thư rỗng khi FCM không khả dụng', () async {
      const service = NoopMessagingService();
      expect(await service.permission(), NotificationPermission.notAsked);
      expect(await service.inbox(), isEmpty);
      expect(await service.token(), isNull);
      expect(service.takePendingRoute(), isNull);
    });
  });
}
