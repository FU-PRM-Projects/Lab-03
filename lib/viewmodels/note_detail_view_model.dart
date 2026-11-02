import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/crash_reporter.dart';
import '../services/note_repository.dart';
import 'error_messages.dart';
import 'jar_view_model.dart';
import 'note_deleter.dart';
import 'view_state.dart';

class NoteDetailState {
  const NoteDetailState({
    this.note = const Loading<Note>(),
    this.editing = false,
    this.title = '',
    this.body = '',
    this.saving = false,
    this.message,
  });

  final ViewState<Note> note;

  /// Chế độ sửa: tiêu đề và nhật ký thành ô nhập.
  final bool editing;
  final String title;
  final String body;
  final bool saving;

  /// Lỗi lưu cho SnackBar.
  final String? message;

  Note? get loaded => switch (note) {
    Data<Note>(:final value) => value,
    _ => null,
  };

  /// Có sửa gì so với nốt đã lưu: Back hỏi "Bỏ thay đổi?".
  bool get hasChanges {
    final current = loaded;
    return editing &&
        current != null &&
        (title.trim() != current.title || body.trim() != current.body);
  }

  String? get titleError {
    if (!editing) return null;
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'Viết vài chữ cho nốt này nhé.';
    if (trimmed.length > NoteLimits.title) {
      return 'Tối đa ${NoteLimits.title} ký tự.';
    }
    return null;
  }

  bool get canSave =>
      hasChanges &&
      titleError == null &&
      body.length <= NoteLimits.body &&
      !saving;

  NoteDetailState copyWith({
    ViewState<Note>? note,
    bool? editing,
    String? title,
    String? body,
    bool? saving,
    String? Function()? message,
  }) => NoteDetailState(
    note: note ?? this.note,
    editing: editing ?? this.editing,
    title: title ?? this.title,
    body: body ?? this.body,
    saving: saving ?? this.saving,
    message: message == null ? this.message : message(),
  );
}

/// Tham số: id nốt, và có mở sẵn chế độ sửa không ("Viết thêm" ở S04).
typedef NoteDetailArgs = ({String id, bool edit});

final noteDetailViewModelProvider = NotifierProvider.autoDispose
    .family<NoteDetailViewModel, NoteDetailState, NoteDetailArgs>(
      NoteDetailViewModel.new,
    );

/// ViewModel của S06 · Chi tiết nốt (flow P4, P5, P6).
class NoteDetailViewModel extends Notifier<NoteDetailState> {
  NoteDetailViewModel(this.args);

  final NoteDetailArgs args;

  /// Câu gợi ý khi bí ý (flow P4), xoay vòng mỗi lần chạm "Gợi ý".
  static const List<String> prompts = <String>[
    'Điều gì làm bạn thấy nhẹ hơn hôm nay?',
    'Ai đã giúp bạn một chút hôm nay?',
    'Nếu kể cho bạn thân nghe, bạn sẽ kể gì trước?',
    'Ngày mai bạn muốn giữ lại điều gì từ hôm nay?',
  ];

  int _nextPrompt = 0;

  NoteRepository get _notes => ref.read(noteRepositoryProvider);

  @override
  NoteDetailState build() {
    unawaited(_load());
    return const NoteDetailState();
  }

  Future<void> _load() async {
    try {
      final note = await _notes.get(args.id);
      if (!ref.mounted) return;
      state = state.copyWith(note: Data<Note>(note));
      unawaited(
        ref.read(analyticsServiceProvider).track(
          AnalyticsEvents.noteViewed,
          <String, Object>{AnalyticsParams.noteType: note.type.id},
        ),
      );
      if (args.edit) startEdit();
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(note: ErrorMessages.failure<Note>(error));
      }
    }
  }

  void retry() {
    state = state.copyWith(note: const Loading<Note>());
    unawaited(_load());
  }

  void startEdit() {
    final note = state.loaded;
    if (note == null) return;
    state = state.copyWith(editing: true, title: note.title, body: note.body);
  }

  void cancelEdit() => state = state.copyWith(editing: false);

  void setTitle(String title) => state = state.copyWith(title: title);

  void setBody(String body) => state = state.copyWith(body: body);

  /// "Gợi ý": thêm một câu hỏi gợi mở vào cuối nhật ký.
  void addPrompt() {
    final prompt = prompts[_nextPrompt % prompts.length];
    _nextPrompt++;
    final body = state.body.trimRight();
    final next = body.isEmpty ? '$prompt\n' : '$body\n\n$prompt\n';
    if (next.length > NoteLimits.body) return;
    state = state.copyWith(body: next);
  }

  Future<void> save() async {
    if (!state.canSave) return;
    state = state.copyWith(saving: true, message: () => null);
    try {
      final note = await _notes.update(
        args.id,
        title: state.title,
        body: state.body,
      );
      if (!ref.mounted) return;
      ref.read(jarViewModelProvider.notifier).applyEdit(note);
      state = state.copyWith(
        note: Data<Note>(note),
        editing: false,
        saving: false,
      );
    } on Object catch (error, stack) {
      unawaited(
        ref
            .read(crashReporterProvider)
            .recordError(error, stack, reason: 'note_update'),
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        saving: false,
        message: () => ErrorMessages.update(error),
      );
    }
  }

  void clearMessage() => state = state.copyWith(message: () => null);

  /// "Xoá" ở dialog: ẩn nốt, chờ 5 giây hoàn tác rồi mới xoá thật.
  void delete() {
    final note = state.loaded;
    if (note == null) return;
    ref.read(noteDeleterProvider.notifier).deleteWithUndo(note);
  }
}
