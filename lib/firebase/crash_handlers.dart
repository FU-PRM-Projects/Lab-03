import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Gắn handler để lỗi Flutter đi vào Crashlytics.
///
/// Tắt khi chạy Emulator: Emulator Suite không có Crashlytics, mà app vẫn
/// dùng `google-services.json` của project thật — bật sẽ đẩy crash lúc dev
/// lên dashboard thật.
void installCrashHandlers({required bool enabled}) {
  if (!enabled) return;

  // Lỗi đồng bộ trong framework (build, onPressed, ...).
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Lỗi async không đi qua framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
