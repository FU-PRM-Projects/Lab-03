import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/first_group.dart';
import '../services/group_repository.dart';
import '../services/note_repository.dart';

final groupDeleterProvider = NotifierProvider<GroupDeleter, FirstGroup?>(
  GroupDeleter.new,
);

/// Xoá nhóm có Hoàn tác 5 giây, giống `NoteDeleter`: nhóm biến khỏi kệ ngay,
/// chỉ xoá trên Firestore (và gỡ nốt khỏi nhóm) khi hết [undoWindow].
///
/// State là nhóm đang chờ xoá, `null` khi không có.
class GroupDeleter extends Notifier<FirstGroup?> {
  static const Duration undoWindow = Duration(seconds: 5);

  Timer? _timer;

  @override
  FirstGroup? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void deleteWithUndo(FirstGroup group) {
    final previous = state;
    _timer?.cancel();
    if (previous != null) unawaited(_commit(previous));
    state = group;
    _timer = Timer(undoWindow, () => _commit(group));
  }

  void undo() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  Future<void> _commit(FirstGroup group) async {
    try {
      await ref.read(groupRepositoryProvider).delete(group.id);
      // Nốt vẫn ở trong hũ, chỉ rời nhóm.
      await ref.read(noteRepositoryProvider).ungroup(group.id);
    } on Object {
      // Nhóm còn trên Firestore thì hiện lại trên kệ; người dùng xoá lại được.
    }
    if (ref.mounted && state?.id == group.id) state = null;
  }
}
