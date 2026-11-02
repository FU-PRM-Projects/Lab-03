import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../services/crash_reporter.dart';
import '../services/note_repository.dart';

/// Nốt đang chờ xoá và lỗi của lần xoá gần nhất.
class PendingDelete {
  const PendingDelete({this.note, this.failure});

  /// Nốt vừa bấm Xoá, còn hoàn tác được; S05 ẩn nốt này khỏi lưới.
  final Note? note;

  /// Hết giờ hoàn tác mà xoá thật không được (SnackBar ở S05).
  final String? failure;
}

final noteDeleterProvider = NotifierProvider<NoteDeleter, PendingDelete>(
  NoteDeleter.new,
);

/// Xoá có hoàn tác (flow P5): nốt bị ẩn ngay, chỉ xoá trên Firestore khi hết
/// [undoWindow] mà người dùng không bấm Hoàn tác.
///
/// Nằm ngoài ViewModel của S06 vì việc xoá còn chạy sau khi S06 đã đóng.
class NoteDeleter extends Notifier<PendingDelete> {
  static const Duration undoWindow = Duration(seconds: 5);

  Timer? _timer;

  @override
  PendingDelete build() {
    ref.onDispose(() => _timer?.cancel());
    return const PendingDelete();
  }

  /// Bắt đầu xoá [note]. Nốt đang chờ trước đó (nếu có) được xoá luôn.
  void deleteWithUndo(Note note) {
    final previous = state.note;
    _timer?.cancel();
    if (previous != null) unawaited(_commit(previous));
    state = PendingDelete(note: note);
    _timer = Timer(undoWindow, () => _commit(note));
  }

  /// "Hoàn tác": nốt hiện lại đúng chỗ cũ trong lưới.
  void undo() {
    _timer?.cancel();
    _timer = null;
    state = const PendingDelete();
  }

  void clearFailure() => state = PendingDelete(note: state.note);

  Future<void> _commit(Note note) async {
    try {
      await ref.read(noteRepositoryProvider).delete(note.id);
      if (!ref.mounted) return;
      if (state.note?.id == note.id) state = const PendingDelete();
    } on Object catch (error, stack) {
      unawaited(
        ref
            .read(crashReporterProvider)
            .recordError(error, stack, reason: 'note_delete'),
      );
      if (!ref.mounted) return;
      state = PendingDelete(
        // Giữ nốt khác đang chờ xoá (nếu có).
        note: state.note?.id == note.id ? null : state.note,
        failure: 'Chưa xoá được nốt "${note.title}". Thử lại sau nhé.',
      );
    }
  }
}
