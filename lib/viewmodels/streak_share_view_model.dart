import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/streak.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/app_exception.dart';
import '../services/clock.dart';
import '../services/crash_reporter.dart';
import '../services/streak_share_service.dart';

enum StreakSharePhase { idle, saving, sharing, done, failed }

class StreakShareState {
  const StreakShareState({
    this.phase = StreakSharePhase.idle,
    this.id,
    this.message,
  });

  final StreakSharePhase phase;

  /// Id document `sharedStreaks` vừa lưu (có sau bước lưu ảnh).
  final String? id;

  /// Lỗi hoặc lời nhắc khi hộp chia sẻ không mở được.
  final String? message;

  bool get busy =>
      phase == StreakSharePhase.saving || phase == StreakSharePhase.sharing;
}

final streakShareViewModelProvider =
    NotifierProvider.autoDispose<StreakShareViewModel, StreakShareState>(
      StreakShareViewModel.new,
    );

/// "Chia sẻ chuỗi": lưu ảnh PNG vào Firestore (base64) rồi mở hộp chia sẻ.
class StreakShareViewModel extends Notifier<StreakShareState> {
  @override
  StreakShareState build() => const StreakShareState();

  Future<void> share({
    required StreakSummary streak,
    required Uint8List png,
    required String fileName,
    required String text,
    Rect? origin,
  }) async {
    if (state.busy) return;
    state = const StreakShareState(phase: StreakSharePhase.saving);
    String? id;
    try {
      final service = ref.read(streakShareServiceProvider);
      id = await service.save(
        streak: streak,
        png: png,
        createdAt: ref.read(clockProvider).now(),
      );
      if (!ref.mounted) return;
      state = StreakShareState(phase: StreakSharePhase.sharing, id: id);
      await service.share(
        png: png,
        fileName: fileName,
        text: text,
        origin: origin,
      );
      if (!ref.mounted) return;
      state = StreakShareState(phase: StreakSharePhase.done, id: id);
      unawaited(
        ref.read(analyticsServiceProvider).track(
          AnalyticsEvents.streakShared,
          <String, Object>{
            AnalyticsParams.streakLength: streak.current,
            AnalyticsParams.streakMilestone: streak.isMilestone
                ? streak.current
                : 0,
            AnalyticsParams.method: 'image',
          },
        ),
      );
    } on Object catch (error, stack) {
      unawaited(
        ref
            .read(crashReporterProvider)
            .recordError(error, stack, reason: 'streak_share'),
      );
      if (!ref.mounted) return;
      // Ảnh đã lưu xong thì chỉ hộp chia sẻ lỗi; giữ id để người dùng thử lại.
      state = id == null
          ? StreakShareState(
              phase: StreakSharePhase.failed,
              message: _saveMessage(error),
            )
          : StreakShareState(
              phase: StreakSharePhase.done,
              id: id,
              message: 'Đã lưu ảnh chuỗi; chưa mở được hộp chia sẻ.',
            );
    }
  }

  static String _saveMessage(Object error) => switch (error) {
    AppException(code: 'image-too-large') =>
      'Ảnh chuỗi quá lớn để lưu. Thử lại nhé.',
    AppException(kind: AppErrorKind.network) =>
      'Chưa lưu được ảnh: kiểm tra Wi-Fi rồi thử lại.',
    AppException(kind: AppErrorKind.permissionDenied) => 'Chưa lưu được ảnh: không có quyền ghi hoặc phiên đăng nhập đã hết. Đăng nhập lại rồi thử lại.',
    _ => 'Chưa chia sẻ được chuỗi. Thử lại nhé.',
  };
}
