import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../models/note_type.dart';
import '../services/clock.dart';
import '../services/draft_store.dart';
import '../services/note_repository.dart';
import '../utils/dates.dart';
import 'auth_view_model.dart';
import 'error_messages.dart';
import 'view_state.dart';

/// Nội dung S02 · Hôm nay.
class TodaySummary {
  const TodaySummary({
    required this.todayCount,
    required this.monthCount,
    required this.jarNotes,
    this.fallenNote,
    this.pendingSync = false,
  });

  final int todayCount;
  final int monthCount;

  /// Các nốt mới nhất của tháng, để vẽ tờ nốt trong hình hũ.
  final List<NoteType> jarNotes;

  /// Nốt cũ "rơi ra" khi hôm qua có tâm trạng Mệt hoặc Rối (S02, P6).
  final Note? fallenNote;

  /// Còn nốt chưa đồng bộ: hiện banner Offline.
  final bool pendingSync;
}

/// Ngày hiện tại cho tiêu đề S02.
final todayDateProvider = Provider<DateTime>(
  (ref) => ref.watch(clockProvider).now(),
);

/// Có nháp S03 đang chờ: nút chính của S02 đổi thành "Tiếp tục ghi nốt".
final hasDraftProvider = FutureProvider<bool>(
  (ref) async => await ref.watch(draftStoreProvider).load() != null,
);

final todayViewModelProvider =
    NotifierProvider<TodayViewModel, ViewState<TodaySummary>>(
      TodayViewModel.new,
    );

/// ViewModel của S02. Theo dõi nốt từ đầu tháng (hoặc từ hôm qua nếu hôm nay
/// là mùng 1) nên hũ tự cập nhật khi có nốt mới.
class TodayViewModel extends Notifier<ViewState<TodaySummary>> {
  /// Chưa có dữ liệu sau chừng này thì chuyển sang Error state (T3 → T2).
  static const Duration loadTimeout = Duration(seconds: 10);

  /// Số tờ nốt tối đa vẽ trong hũ.
  static const int jarCapacity = 12;

  Note? _fallenNote;
  bool _fallenLoaded = false;

  NoteRepository get _notes => ref.read(noteRepositoryProvider);

  @override
  ViewState<TodaySummary> build() {
    // Dựng lại khi đổi tài khoản.
    ref.watch(authUserProvider.select((user) => user.value?.uid));
    _fallenNote = null;
    _fallenLoaded = false;

    final now = ref.read(clockProvider).now();
    final monthStart = Dates.startOfMonth(now);
    final yesterday = Dates.startOfYesterday(now);
    final since = yesterday.isBefore(monthStart) ? yesterday : monthStart;

    final timeout = Timer(loadTimeout, () {
      if (state is Loading<TodaySummary>) {
        state = const Failure<TodaySummary>(ErrorMessages.slow, offline: true);
      }
    });
    final sub = _notes
        .watchSince(since)
        .listen(
          (notes) => _onNotes(notes, now),
          onError: (Object error) => state = ErrorMessages.failure(error),
        );
    ref.onDispose(() {
      timeout.cancel();
      sub.cancel();
    });
    return const Loading<TodaySummary>();
  }

  Future<void> _onNotes(List<Note> notes, DateTime now) async {
    final monthStart = Dates.startOfMonth(now);
    final yesterday = Dates.startOfYesterday(now);
    final month = notes.where((n) => !n.createdAt.isBefore(monthStart));
    final hadLowDay = notes.any(
      (n) => Dates.sameDay(n.createdAt, yesterday) && (n.mood?.isLow ?? false),
    );

    if (hadLowDay && !_fallenLoaded) {
      _fallenLoaded = true;
      _fallenNote = await _pickFallenNote(before: yesterday, now: now);
      if (!ref.mounted) return;
    }

    state = Data<TodaySummary>(
      TodaySummary(
        todayCount: notes.where((n) => Dates.sameDay(n.createdAt, now)).length,
        monthCount: month.length,
        jarNotes: month.take(jarCapacity).map((n) => n.type).toList(),
        fallenNote: hadLowDay ? _fallenNote : null,
        pendingSync: notes.any((n) => n.pendingSync),
      ),
    );
  }

  /// Một chiến thắng cũ, đổi theo ngày để mỗi ngày tệ thấy một nốt khác.
  /// Không có thì thôi: đây là phần thêm, không phải lỗi.
  Future<Note?> _pickFallenNote({
    required DateTime before,
    required DateTime now,
  }) async {
    try {
      final old = (await _notes.list(
        before: before,
        limit: 20,
      )).where((n) => n.type == NoteType.chienThang).toList();
      return old.isEmpty ? null : old[now.day % old.length];
    } on Object {
      return null;
    }
  }

  void retry() => ref.invalidateSelf();
}
