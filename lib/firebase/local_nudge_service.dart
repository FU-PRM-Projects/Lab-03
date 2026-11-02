import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../router/app_routes.dart';
import '../services/nudge_service.dart';

/// [NudgeService] bằng `flutter_local_notifications`: lịch nằm trên máy nên
/// vẫn nhắc khi app đang tắt hoặc sau khi khởi động lại máy.
class LocalNudgeService implements NudgeService {
  LocalNudgeService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _opened = StreamController<String>.broadcast();
  Future<bool>? _ready;

  static const int _awakeId = 1;

  static const NotificationDetails _awakeDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'awake',
      'Giờ tỉnh',
      channelDescription: 'Nhắc nhẹ trong khung giờ dễ lướt vô thức.',
      icon: '@mipmap/ic_launcher',
    ),
  );

  /// Khởi tạo một lần: múi giờ của máy và plugin. `false` khi nền tảng không
  /// hỗ trợ (web build trên CI): mọi lệnh sau đó bỏ qua.
  Future<bool> _init() => _ready ??= () async {
    if (kIsWeb) return false;
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload case final route?) _opened.add(route);
        },
      );
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on tz.LocationNotFoundException {
      return false;
    }
  }();

  @override
  Future<void> scheduleAwakeNudge(int minutes) async {
    if (!await _init()) return;
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60 % 24,
      minutes % 60,
    );
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    try {
      await _plugin.zonedSchedule(
        id: _awakeId,
        scheduledDate: at,
        notificationDetails: _awakeDetails,
        // Lời nhắc nhẹ: lệch vài phút không sao, khỏi xin quyền báo thức chính xác.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Đến giờ tỉnh rồi',
        body: 'Đang lướt à? Chạm để dừng lại và ghi 1 lần tự chủ.',
        payload: AppRoutes.selfControl,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException {
      // Lời nhắc là phần thêm; không chặn việc lưu cài đặt vì lỗi này.
    }
  }

  @override
  Future<void> cancelAwakeNudge() async {
    if (!await _init()) return;
    try {
      await _plugin.cancel(id: _awakeId);
    } on PlatformException {
      // Như trên.
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      return await android?.requestNotificationsPermission() ?? true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<String> get openedRoutes => _opened.stream;

  @override
  Future<String?> launchRoute() async {
    if (!await _init()) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return details.notificationResponse?.payload;
    } on PlatformException {
      return null;
    }
  }
}
