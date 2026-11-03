import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ghi sự kiện Analytics (Stage 5). Widget và ViewModel chỉ biết interface
/// này, không import `firebase_analytics`.
abstract interface class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);

  Future<void> logScreen(String screenName);

  Future<void> setUserId(String? uid);
}

/// In ra console: mặc định cho test và khi chạy Emulator, để vẫn "thấy" sự
/// kiện mà không gửi gì lên Google.
class DebugAnalyticsService implements AnalyticsService {
  const DebugAnalyticsService();

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    debugPrint('[analytics] $name ${parameters ?? const <String, Object>{}}');
  }

  @override
  Future<void> logScreen(String screenName) =>
      logEvent('screen_view', <String, Object>{'firebase_screen': screenName});

  @override
  Future<void> setUserId(String? uid) async {
    debugPrint('[analytics] setUserId ${uid == null ? 'null' : 'set'}');
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const DebugAnalyticsService(),
);

/// Ghi sự kiện mà không bao giờ làm hỏng luồng chính của người dùng.
extension SafeAnalytics on AnalyticsService {
  Future<void> track(String name, [Map<String, Object>? parameters]) async {
    try {
      await logEvent(name, parameters);
    } on Object catch (error) {
      debugPrint('[analytics] bỏ qua $name: $error');
    }
  }
}
