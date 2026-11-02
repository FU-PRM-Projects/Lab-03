import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../models/note_type.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import '../utils/dates.dart';
import 'auth_view_model.dart';
import 'error_messages.dart';
import 'note_deleter.dart';
import 'view_state.dart';

/// Nội dung S05 · Hũ & Nhật ký.
class JarData {
  const JarData({
    required this.notes,
    required this.month,
    this.monthCount,
    this.stickers = const <DateTime>[],
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  /// Nốt đã tải, mới nhất trước, không gồm nốt đang chờ xoá.
  final List<Note> notes;

  /// Tháng hiện tại cho dòng "24 nốt tháng 10".
  final int month;

  /// `null` khi chưa đếm xong.
  final int? monthCount;

  /// Các tháng có nhãn dán (ngày 1 của tháng), mới nhất trước.
  final List<DateTime> stickers;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;

  /// Loại của các tờ nốt vẽ trong hũ nhỏ trên đầu lưới.
  List<NoteType> get jarTypes => notes.take(8).map((n) => n.type).toList();

  /// Còn nốt chưa đồng bộ: hiện banner Offline trên lưới.
  bool get pendingSync => notes.any((n) => n.pendingSync);
}

final jarViewModelProvider = NotifierProvider<JarViewModel, ViewState<JarData>>(
  JarViewModel.new,
);

/// ViewModel của S05. Trang đầu ([pageSize] nốt mới nhất) được theo dõi trực
/// tiếp nên nốt mới hoặc vừa sửa hiện ngay; các trang sau tải khi cuộn tới
/// cuối.
class JarViewModel extends Notifier<ViewState<JarData>> {
  /// Bằng `limit` mặc định của [NoteRepository.watchRecent] và
  /// [NoteRepository.list].
  static const int pageSize = 30;

  /// Chưa có dữ liệu sau chừng này thì chuyển sang Error state (T3 → T2).
  static const Duration loadTimeout = Duration(seconds: 10);

  List<Note>? _firstPage;
  List<Note> _older = <Note>[];
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  int? _monthCount;
  List<DateTime> _stickers = const <DateTime>[];

  NoteRepository get _notes => ref.read(noteRepositoryProvider);

  @override
  ViewState<JarData> build() {
    ref.watch(authUserProvider.select((user) => user.value?.uid));
    _firstPage = null;
    _older = <Note>[];
    _hasMore = false;
    _loadingMore = false;
    _loadMoreFailed = false;
    _monthCount = null;
    _stickers = const <DateTime>[];

    // Nốt chờ xoá / hoàn tác: dựng lại lưới từ dữ liệu đã có.
    ref.listen(noteDeleterProvider, (_, _) => _emit());

    final timeout = Timer(loadTimeout, () {
      if (state is Loading<JarData>) {
        state = const Failure<JarData>(ErrorMessages.slow, offline: true);
      }
    });
    final sub = _notes.watchRecent().listen(
      _onFirstPage,
      onError: (Object error) {
        // Đã có dữ liệu cũ thì giữ lưới (banner Offline lo phần báo).
        if (_firstPage == null) state = ErrorMessages.failure(error);
      },
    );
    ref.onDispose(() {
      timeout.cancel();
      sub.cancel();
    });
    return const Loading<JarData>();
  }

  void _onFirstPage(List<Note> notes) {
    final firstLoad = _firstPage == null;
    _firstPage = notes;
    if (firstLoad) _hasMore = notes.length == pageSize;
    // Bỏ khỏi các trang sau những nốt đã lọt vào trang đầu.
    final ids = notes.map((n) => n.id).toSet();
    _older = _older.where((n) => !ids.contains(n.id)).toList();
    _emit();
    unawaited(_refreshCounts());
  }

  Future<void> _refreshCounts() async {
    final now = ref.read(clockProvider).now();
    try {
      final count = await _notes.countBetween(
        Dates.startOfMonth(now),
        Dates.startOfNextMonth(now),
      );
      final stickers = await _notes.listStickers();
      if (!ref.mounted) return;
      _monthCount = count;
      _stickers = stickers.map(Dates.parseMonthId).nonNulls.toList();
      _emit();
    } on Object {
      // Số đếm chỉ là phần thêm trên đầu lưới.
    }
  }

  void _emit() {
    final first = _firstPage;
    if (first == null) return;
    final pending = ref.read(noteDeleterProvider).note;
    final pendingId = pending?.id;
    final notes = <Note>[
      ...first,
      ..._older,
    ].where((n) => n.id != pendingId).toList();
    if (notes.isEmpty && !_hasMore) {
      state = const Empty<JarData>();
      return;
    }
    // Số đếm từ Firestore còn tính nốt đang chờ xoá; trừ đi để khớp lưới.
    final now = ref.read(clockProvider).now();
    final countsPending =
        pending != null &&
        !pending.createdAt.isBefore(Dates.startOfMonth(now)) &&
        pending.createdAt.isBefore(Dates.startOfNextMonth(now));
    final monthCount = _monthCount;
    state = Data<JarData>(
      JarData(
        notes: notes,
        month: now.month,
        monthCount: monthCount == null || !countsPending
            ? monthCount
            : (monthCount - 1).clamp(0, monthCount),
        stickers: _stickers,
        hasMore: _hasMore,
        loadingMore: _loadingMore,
        loadMoreFailed: _loadMoreFailed,
      ),
    );
  }

  /// "2026-10" → 01/10/2026.
  /// Tải trang kế khi cuộn gần cuối lưới.
  Future<void> loadMore() async {
    final first = _firstPage;
    if (first == null || !_hasMore || _loadingMore) return;
    final all = <Note>[...first, ..._older];
    if (all.isEmpty) return;
    _loadingMore = true;
    _loadMoreFailed = false;
    _emit();
    try {
      final page = await _notes.list(before: all.last.createdAt);
      if (!ref.mounted) return;
      _older = <Note>[..._older, ...page];
      _hasMore = page.length == pageSize;
    } on Object {
      if (!ref.mounted) return;
      _loadMoreFailed = true;
    }
    _loadingMore = false;
    _emit();
  }

  /// S06 sửa xong một nốt ở trang sau (trang đầu tự cập nhật).
  void applyEdit(Note note) {
    final i = _older.indexWhere((n) => n.id == note.id);
    if (i < 0) return;
    _older = List<Note>.of(_older)..[i] = note;
    _emit();
  }

  /// Kéo xuống để tải lại, hoặc "Thử lại" ở Error state.
  void refresh() => ref.invalidateSelf();
}
