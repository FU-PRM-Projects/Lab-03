import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/nudge_service.dart';
import '../services/self_control_services.dart';
import 'auth_view_model.dart';

/// Giữ lời nhắc "Giờ tỉnh" khớp với cài đặt của người đang đăng nhập: bật thì
/// nhắc mỗi ngày lúc bắt đầu khung giờ, tắt hoặc đăng xuất thì huỷ. `NotApp`
/// watch provider này nên nó sống suốt phiên.
final awakeNudgeSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(authUserProvider.select((user) => user.value?.uid));
  final nudges = ref.watch(nudgeServiceProvider);
  if (uid == null) {
    unawaited(nudges.cancelAwakeNudge());
    return;
  }

  int? scheduled;
  var asked = false;
  final subscription = ref.watch(settingsRepositoryProvider).watch().listen(
    (settings) {
      final at = settings.awakeEnabled ? settings.awakeStart : null;
      if (at == scheduled) return;
      scheduled = at;
      if (at == null) {
        unawaited(nudges.cancelAwakeNudge());
        return;
      }
      // Xin quyền một lần mỗi phiên, lúc lời nhắc bắt đầu có tác dụng.
      if (!asked) {
        asked = true;
        unawaited(nudges.requestPermission());
      }
      unawaited(nudges.scheduleAwakeNudge(at));
    },
    // Đọc cài đặt lỗi thì giữ lịch cũ; lần đổi cài đặt sau sẽ đặt lại.
    onError: (Object _) {},
  );
  ref.onDispose(subscription.cancel);
});
