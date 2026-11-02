import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/self_control.dart';
import '../services/nudge_service.dart';
import '../services/self_control_services.dart';
import 'auth_view_model.dart';

/// Giữ các lời nhắc khớp với cài đặt của người đang đăng nhập:
/// - "Nhắc ghi nốt buổi tối": mỗi ngày lúc [UserSettings.eveningReminder].
/// - "Giờ tỉnh": bật thì nhắc lúc bắt đầu khung giờ, tắt thì huỷ.
///
/// Đăng xuất thì huỷ cả hai. `NotApp` watch provider này nên nó sống suốt
/// phiên.
final nudgeSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(authUserProvider.select((user) => user.value?.uid));
  final nudges = ref.watch(nudgeServiceProvider);
  if (uid == null) {
    for (final nudge in Nudge.values) {
      unawaited(nudges.cancel(nudge));
    }
    return;
  }

  final scheduled = <Nudge, int?>{};
  var asked = false;
  void sync(Nudge nudge, int? at) {
    if (scheduled.containsKey(nudge) && scheduled[nudge] == at) return;
    scheduled[nudge] = at;
    if (at == null) {
      unawaited(nudges.cancel(nudge));
      return;
    }
    // Xin quyền một lần mỗi phiên, lúc lời nhắc bắt đầu có tác dụng.
    if (!asked) {
      asked = true;
      unawaited(nudges.requestPermission());
    }
    unawaited(nudges.schedule(nudge, at));
  }

  final subscription = ref.watch(settingsRepositoryProvider).watch().listen(
    (settings) {
      sync(Nudge.evening, settings.eveningReminder);
      sync(Nudge.awake, settings.awakeEnabled ? settings.awakeStart : null);
    },
    // Đọc cài đặt lỗi thì giữ lịch cũ; lần đổi cài đặt sau sẽ đặt lại.
    onError: (Object _) {},
  );
  ref.onDispose(subscription.cancel);
});
