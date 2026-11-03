import 'dart:async';
import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/messaging_service.dart';

const String _inboxKey = 'fcm_inbox';
const int _inboxLimit = 50;

/// Thêm một thông báo vào hộp thư trên máy. Dùng được cả trong isolate nền.
Future<void> _saveToInbox(ReceivedNotification item) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final raw = prefs.getStringList(_inboxKey) ?? <String>[];
  final next = <String>[jsonEncode(item.toJson()), ...raw];
  await prefs.setStringList(_inboxKey, next.take(_inboxLimit).toList());
}

ReceivedNotification _fromMessage(RemoteMessage m, MessageOrigin origin) =>
    ReceivedNotification(
      title: m.notification?.title ?? '${m.data['title'] ?? ''}',
      body: m.notification?.body ?? '${m.data['body'] ?? ''}',
      receivedAt: m.sentTime ?? DateTime.now(),
      origin: origin,
    );

/// Hiện thực bằng `firebase_messaging`. Khi app đang mở, Android không tự hiện
/// thông báo nên dùng `flutter_local_notifications` để hiện heads-up.
class FirebaseMessagingService implements MessagingService {
  FirebaseMessagingService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _local = local ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  bool _started = false;
  final StreamController<String> _routes = StreamController<String>.broadcast();
  String? _pendingRoute;

  static const AndroidNotificationDetails _channel = AndroidNotificationDetails(
    'fcm',
    'Thông báo từ Nốt',
    channelDescription: 'Thông báo đẩy từ Firebase Cloud Messaging',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  Future<void> _record(RemoteMessage m, MessageOrigin origin) async {
    await _saveToInbox(_fromMessage(m, origin));
  }

  @override
  Future<void> start() async {
    if (_started || kIsWeb) return;
    _started = true;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      FirebaseMessaging.onMessage.listen((m) async {
        await _record(m, MessageOrigin.foreground);
        final n = m.notification;
        if (n != null) {
          await _local.show(
            id: m.hashCode,
            title: n.title,
            body: n.body,
            notificationDetails: const NotificationDetails(android: _channel),
          );
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((m) async {
        await _record(m, MessageOrigin.background);
        _routes.add(routeFromData(m.data));
      });
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        await _record(initial, MessageOrigin.terminated);
        _pendingRoute = routeFromData(initial.data);
        _routes.add(_pendingRoute!);
      }
      unawaited(_logToken());
    } on Object catch (error) {
      debugPrint('[fcm] không khởi động được: $error');
    }
  }

  Future<void> _logToken() async {
    final value = await token();
    debugPrint('[fcm] token: $value');
  }

  NotificationPermission _map(AuthorizationStatus status) => switch (status) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => NotificationPermission.granted,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => NotificationPermission.denied,
    AuthorizationStatus.notDetermined => NotificationPermission.notAsked,
  };

  @override
  Future<NotificationPermission> permission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return _map(settings.authorizationStatus);
    } on Object {
      return NotificationPermission.notAsked;
    }
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission();
      return _map(settings.authorizationStatus);
    } on Object {
      return NotificationPermission.denied;
    }
  }

  @override
  Future<void> openSystemSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  @override
  Stream<String> get openedRoutes => _routes.stream;

  @override
  String? takePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  @override
  Future<String?> token() async {
    try {
      // Token đăng ký cổng FCM HTTP v1 nhận trực tiếp; API register()/FID mới
      // chưa dùng được với REST nên giữ getToken().
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } on Object {
      return null;
    }
  }

  @override
  Future<List<ReceivedNotification>> inbox() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return <ReceivedNotification>[
      for (final raw in prefs.getStringList(_inboxKey) ?? const <String>[])
        ReceivedNotification.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    ];
  }
}

/// Chạy trong isolate riêng khi app ở nền hoặc đã tắt. Thông báo có phần
/// `notification` do hệ thống tự hiện; ở đây chỉ ghi message dạng data-only.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification == null &&
      (message.data['title'] != null || message.data['body'] != null)) {
    await _saveToInbox(_fromMessage(message, MessageOrigin.background));
  }
}
