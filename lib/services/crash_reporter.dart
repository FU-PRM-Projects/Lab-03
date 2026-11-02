import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ghi lỗi lên Crashlytics (Stage 5).
///
/// Mặc định là bản no-op để test và lần chạy Emulator không gửi gì lên
/// Google; `main.dart` gắn bản Firebase khi chạy với project thật.
abstract interface class CrashReporter {
  /// Ghi một lỗi đã bắt được. [fatal] = true cho lỗi làm hỏng luồng chính.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Gửi một lỗi thử để kiểm tra cấu hình; trả về thông báo cho UI.
  Future<String> testCrash();
}

/// Bản không gửi gì lên Google: dùng cho widget test và khi chạy Emulator.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    debugPrint(
      '[crash] ${fatal ? 'fatal' : 'non-fatal'} ${reason ?? ''}: $error',
    );
  }

  @override
  Future<String> testCrash() async {
    debugPrint('[crash] test crash (no-op)');
    return 'Không gửi lên Google (Emulator/test): đã ghi log.';
  }
}

/// Mặc định an toàn: không có Crashlytics cho tới khi `main.dart` override.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => const NoopCrashReporter(),
);
