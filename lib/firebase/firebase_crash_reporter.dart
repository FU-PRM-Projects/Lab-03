import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../services/crash_reporter.dart';

/// Hiện thực [CrashReporter] bằng Firebase Crashlytics.
class FirebaseCrashReporter implements CrashReporter {
  const FirebaseCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) => FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: reason,
    fatal: fatal,
  );

  @override
  Future<void> setUser(String? uid) =>
      FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');

  @override
  Future<void> setKey(String key, Object value) =>
      FirebaseCrashlytics.instance.setCustomKey(key, value);

  @override
  Future<String> testCrash() async {
    // Lỗi cố ý, fatal để báo cáo được gửi ngay mà không làm tắt app (khác
    // với `FirebaseCrashlytics.instance.crash()`).
    await FirebaseCrashlytics.instance.recordError(
      StateError('Crashlytics test crash'),
      StackTrace.current,
      reason: 'test_crash',
      fatal: true,
    );
    return 'Đã gửi crash thử — xem Crashlytics sau khoảng 5 phút.';
  }

  @override
  Future<String> forceCrash() async {
    // Crash native: app tắt ngay, báo cáo gửi lên ở lần mở app kế tiếp.
    FirebaseCrashlytics.instance.crash();
    return '';
  }
}
