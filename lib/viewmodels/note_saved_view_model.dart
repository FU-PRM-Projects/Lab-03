import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/first_group.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../services/clock.dart';
import '../services/group_repository.dart';
import '../services/note_repository.dart';
import '../utils/dates.dart';
import 'error_messages.dart';
import 'today_view_model.dart';
import 'view_state.dart';

/// Nội dung S04 · Nốt đã vào hũ.
class SavedNoteSummary {
  const SavedNoteSummary({
    required this.note,
    required this.monthCount,
    required this.milestone,
    this.savedToday = true,
    this.jarNotes = const <NoteType>[],
    this.group,
    this.stickers = const <DateTime>[],
  });

  final Note note;

  /// Số nốt của tháng chứa [note], tính cả nốt này ("Nốt thứ 24 tháng này").
  final int monthCount;

  /// Mốc tháng (Remote Config `monthly_milestone`).
  final int milestone;

  /// Nốt ghi hôm nay: nhãn ngày là "Hôm nay" thay cho "24/10".
  final bool savedToday;

  /// Loại các nốt mới nhất của tháng (gồm nốt này), để vẽ tờ nốt trong hũ.
  final List<NoteType> jarNotes;

  /// Nhóm lần đầu chứa nốt, nếu có.
  final FirstGroup? group;

  /// Các tháng đã gắn nhãn dán (`users/{uid}/stickers`).
  final List<DateTime> stickers;

  /// "Bộ sưu tập" ở biến thể mốc: tối đa 3 tháng đã có nhãn dán, cũ trước,
  /// luôn gồm tháng của [note] (vừa đạt mốc).
  List<DateTime> get stickerMonths {
    final current = Dates.startOfMonth(note.createdAt);
    final months = <DateTime>{
      for (final m in stickers)
        if (m.isBefore(current)) Dates.startOfMonth(m),
      current,
    }.toList()..sort();
    return months.length <= 3 ? months : months.sublist(months.length - 3);
  }

  /// Ô "?" cuối bộ sưu tập: tháng kế tiếp, chưa mở.
  DateTime get nextStickerMonth => Dates.startOfNextMonth(note.createdAt);

  /// Nốt đầu tiên của một nhóm: biến thể "Lần đầu tiên!" (khi không trùng
  /// với mốc tháng, vì mốc tháng cần bấm "Gắn vào hũ").
  bool get firstInGroup => note.isFirst && group != null && !reachedMilestone;

  /// Số nốt của nhóm, tính cả nốt này.
  int get groupCount {
    final count = group?.noteCount ?? 0;
    return count < 1 ? 1 : count;
  }

  /// Nốt vừa lưu đúng là nốt chạm mốc: hiện biến thể "Mốc 25 nốt!".
  bool get reachedMilestone => monthCount == milestone;

  /// Tiến độ 0–1 của thanh mốc tháng.
  double get progress =>
      milestone <= 0 ? 1 : (monthCount / milestone).clamp(0, 1);
}

/// Mốc nốt mỗi tháng (S04). Là mục tiêu của app nên không đưa vào Remote Config.
final monthlyMilestoneProvider = Provider<int>(
  (ref) => defaultMonthlyMilestone,
);

const int defaultMonthlyMilestone = 25;

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
      final monthStart = Dates.startOfMonth(note.createdAt);
      FirstGroup? group;
      if (note.groupId case final id?) {
        try {
          group =
              await ref.read(groupRepositoryProvider).get(id) ??
              FirstGroups.systemById(id);
        } on Object {
          group = FirstGroups.systemById(id);
        }
      }
      final recent = await _notes.list(
        before: Dates.startOfNextMonth(note.createdAt),
        limit: TodayViewModel.jarCapacity,
      );
      List<DateTime> stickers;
      try {
        stickers = (await _notes.listStickers())
            .map(Dates.parseMonthId)
            .nonNulls
            .toList();
      } on Object {
        // Bộ sưu tập chỉ là phần thêm; thiếu thì chỉ hiện tháng này.
        stickers = const <DateTime>[];
      }
      if (!ref.mounted) return;
      state = Data<SavedNoteSummary>(
        SavedNoteSummary(
          note: note,
          // Bộ nhớ đệm có thể chưa thấy nốt vừa ghi; nốt này luôn được tính.
          monthCount: count < 1 ? 1 : count,
          milestone: ref.read(monthlyMilestoneProvider),
          savedToday: Dates.sameDay(
            note.createdAt,
            ref.read(clockProvider).now(),
          ),
          jarNotes: <NoteType>[
            for (final n in recent)
              if (!n.createdAt.isBefore(monthStart)) n.type,
          ],
          group: group,
          stickers: stickers,
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
