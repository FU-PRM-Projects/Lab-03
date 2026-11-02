import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../models/note_type.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import 'error_messages.dart';

/// Trạng thái màn Viết nhật ký: chữ đang viết nằm ở ô nhập của màn hình.
class JournalState {
  const JournalState({this.saving = false, this.savedNoteId, this.message});

  final bool saving;

  /// Lưu xong: màn hình chuyển sang S04 của nốt này.
  final String? savedNoteId;

  /// Lỗi hiện SnackBar.
  final String? message;

  JournalState copyWith({
    bool? saving,
    String? Function()? savedNoteId,
    String? Function()? message,
  }) => JournalState(
    saving: saving ?? this.saving,
    savedNoteId: savedNoteId == null ? this.savedNoteId : savedNoteId(),
    message: message == null ? this.message : message(),
  );
}

final journalViewModelProvider =
    NotifierProvider.autoDispose<JournalViewModel, JournalState>(
      JournalViewModel.new,
    );

/// ViewModel của Viết nhật ký: viết tự do, bí thì chèn câu hỏi gợi ý, xong thì
/// chọn câu rõ ràng nhất làm tiêu đề và lưu thành nốt Nhật ký.
class JournalViewModel extends Notifier<JournalState> {
  /// Câu hỏi gợi ý khi bí ("Bí rồi? Hỏi mình đi").
  static const List<String> prompts = <String>[
    'Chuyện gì đã xảy ra?',
    'Lúc đó mình nghĩ gì?',
    'Mình cảm thấy gì?',
    'Điều mình thật sự lo là gì?',
    'Lần sau mình sẽ…',
  ];

  @override
  JournalState build() => const JournalState();

  /// Tách bài viết thành các câu để chọn "điều rõ ràng nhất": bỏ các câu hỏi
  /// gợi ý đã chèn, câu dài quá tiêu đề thì cắt ở ranh giới từ.
  static List<String> sentences(String text) {
    final parts = text
        .split(RegExp(r'(?<=[.!?…])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !prompts.contains(s));
    final seen = <String>{};
    return <String>[
      for (final s in parts)
        if (seen.add(s)) _fitTitle(s),
    ];
  }

  static String _fitTitle(String sentence) {
    if (sentence.length <= NoteLimits.title) return sentence;
    final cut = sentence.substring(0, NoteLimits.title - 1);
    final space = cut.lastIndexOf(' ');
    return '${space > 0 ? cut.substring(0, space) : cut}…';
  }

  /// Lưu nốt Nhật ký: [title] là câu đã chọn, [text] là cả bài viết.
  Future<void> save({required String title, required String text}) async {
    if (state.saving || title.trim().isEmpty) return;
    state = state.copyWith(saving: true, message: () => null);
    try {
      final note = await ref
          .read(noteRepositoryProvider)
          .add(
            NoteDraft(
              type: NoteType.nhatKy,
              title: title.trim(),
              body: _fitBody(text.trim()),
            ),
            createdAt: ref.read(clockProvider).now(),
          );
      if (!ref.mounted) return;
      state = state.copyWith(saving: false, savedNoteId: () => note.id);
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        saving: false,
        message: () => ErrorMessages.save(error),
      );
    }
  }

  static String _fitBody(String text) => text.length <= NoteLimits.body
      ? text
      : text.substring(0, NoteLimits.body);

  void clearMessage() => state = state.copyWith(message: () => null);
}
