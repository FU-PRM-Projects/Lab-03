import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import '../services/remote_config_service.dart';
import '../utils/dates.dart';
import 'error_messages.dart';
import 'view_state.dart';

/// Nội dung S04 · Nốt đã vào hũ.
class SavedNoteSummary {
  const SavedNoteSummary({
    required this.note,
    required this.monthCount,
    required this.milestone,
    this.savedToday = true,
  });

  final Note note;

  /// Số nốt của tháng chứa [note], tính cả nốt này ("Nốt thứ 24 tháng này").
  final int monthCount;

  /// Mốc tháng (Remote Config `monthly_milestone`).
  final int milestone;

  /// Nốt ghi hôm nay: nhãn ngày là "Hôm nay" thay cho "24/10".
  final bool savedToday;

  /// Nốt vừa lưu đúng là nốt chạm mốc: hiện biến thể "Mốc 25 nốt!".
  bool get reachedMilestone => monthCount == milestone;

  /// Tiến độ 0–1 của thanh mốc tháng.
  double get progress =>
      milestone <= 0 ? 1 : (monthCount / milestone).clamp(0, 1);
}

final noteSavedViewModelProvider = NotifierProvider.autoDispose
    .family<NoteSavedViewModel, ViewState<SavedNoteSummary>, String>(
      NoteSavedViewModel.new,
    );

/// ViewModel của S04. Tham số là id nốt vừa lưu.
class NoteSavedViewModel extends Notifier<ViewState<SavedNoteSummary>> {
  NoteSavedViewModel(this.noteId);

  final String noteId;

  NoteRepository get _notes => ref.read(noteRepositoryProvider);

  @override
  ViewState<SavedNoteSummary> build() {
    unawaited(_load());
    return const Loading<SavedNoteSummary>();
  }

  Future<void> _load() async {
    try {
      final note = await _notes.get(noteId);
      final count = await _notes.countBetween(
        Dates.startOfMonth(note.createdAt),
        Dates.startOfNextMonth(note.createdAt),
      );
      if (!ref.mounted) return;
      state = Data<SavedNoteSummary>(
        SavedNoteSummary(
          note: note,
          // Bộ nhớ đệm có thể chưa thấy nốt vừa ghi; nốt này luôn được tính.
          monthCount: count < 1 ? 1 : count,
          milestone: ref.read(remoteConfigServiceProvider).monthlyMilestone,
          savedToday: Dates.sameDay(
            note.createdAt,
            ref.read(clockProvider).now(),
          ),
        ),
      );
    } on Object catch (error) {
      if (ref.mounted) state = ErrorMessages.failure(error);
    }
  }

  void retry() {
    state = const Loading<SavedNoteSummary>();
    unawaited(_load());
  }

  /// "Gắn vào hũ" khi đạt mốc. Trả câu lỗi để hiện SnackBar, `null` khi xong.
  Future<String?> pinSticker() async {
    final value = state;
    if (value is! Data<SavedNoteSummary>) return null;
    try {
      await _notes.saveMonthSticker(value.value.note.createdAt);
      return null;
    } on Object {
      return 'Chưa gắn được nhãn dán. Thử lại nhé.';
    }
  }
}
