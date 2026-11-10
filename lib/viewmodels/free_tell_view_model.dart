import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../services/ai_service.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import 'error_messages.dart';

/// Pha của S03b "Kể tự do" (flow A1).
enum FreeTellPhase {
  /// Đang viết đoạn kể.
  writing,

  /// Tụi Nốt đang đọc (đang gọi Gemini).
  thinking,

  /// Gợi ý để người dùng xem, sửa, chọn.
  review,

  /// Đang lưu các nốt đã chọn.
  saving,

  /// Đã lưu: màn hình đóng.
  saved,
}

/// Một gợi ý người dùng đang sửa.
class EditableSuggestion {
  const EditableSuggestion({
    required this.type,
    required this.title,
    required this.originalTitle,
    required this.originalType,
    this.keep = true,
  });

  factory EditableSuggestion.from(AiNoteSuggestion s) => EditableSuggestion(
    type: s.type,
    title: s.title,
    originalTitle: s.title,
    originalType: s.type,
  );

  final NoteType type;
  final String title;
  final String originalTitle;
  final NoteType originalType;
  final bool keep;

  bool get edited => title.trim() != originalTitle || type != originalType;

  EditableSuggestion copyWith({NoteType? type, String? title, bool? keep}) =>
      EditableSuggestion(
        type: type ?? this.type,
        title: title ?? this.title,
        originalTitle: originalTitle,
        originalType: originalType,
        keep: keep ?? this.keep,
      );
}

class FreeTellState {
  const FreeTellState({
    this.phase = FreeTellPhase.writing,
    this.suggestions = const <EditableSuggestion>[],
    this.mood,
    this.needsSupport = false,
    this.error,
    this.savedCount = 0,
  });

  final FreeTellPhase phase;
  final List<EditableSuggestion> suggestions;
  final Mood? mood;

  /// Gemini thấy đoạn kể có dấu hiệu cần hỗ trợ.
  final bool needsSupport;

  /// Câu báo lỗi AI (giữ đoạn kể, gợi ý ghi tay) hoặc lỗi lưu.
  final String? error;
  final int savedCount;

  int get keptCount => suggestions.where((s) => s.keep).length;

  FreeTellState copyWith({
    FreeTellPhase? phase,
    List<EditableSuggestion>? suggestions,
    Mood? Function()? mood,
    bool? needsSupport,
    String? Function()? error,
    int? savedCount,
  }) => FreeTellState(
    phase: phase ?? this.phase,
    suggestions: suggestions ?? this.suggestions,
    mood: mood == null ? this.mood : mood(),
    needsSupport: needsSupport ?? this.needsSupport,
    error: error == null ? this.error : error(),
    savedCount: savedCount ?? this.savedCount,
  );
}

final freeTellViewModelProvider =
    NotifierProvider.autoDispose<FreeTellViewModel, FreeTellState>(
      FreeTellViewModel.new,
    );

/// ViewModel của S03b "Kể tự do · Nốt sắp xếp giúp". Đoạn kể không được
/// lưu; chỉ các nốt người dùng giữ lại mới được ghi vào hũ.
class FreeTellViewModel extends Notifier<FreeTellState> {
  /// Lần gọi mới nhất; bấm "Huỷ" khi đang đọc thì bỏ qua kết quả cũ.
  int _request = 0;

  @override
  FreeTellState build() => const FreeTellState();

  /// Câu báo lỗi theo lý do (luồng A1: giữ đoạn viết, gợi ý chọn tay).
  static String messageFor(AiErrorReason reason) => switch (reason) {
    AiErrorReason.disabled =>
      'Nốt AI đang nghỉ. Đoạn kể vẫn còn đây, bạn ghi tay giúp mình nhé.',
    AiErrorReason.quota =>
      'Hôm nay Tụi Nốt đọc nhiều quá rồi. Bạn ghi tay giúp mình, mai thử lại '
          'nhé.',
    AiErrorReason.network || AiErrorReason.timeout =>
      'Tụi Nốt chưa đọc được vì mạng chậm. Kiểm tra Wi-Fi rồi thử lại, hoặc '
          'ghi tay.',
    AiErrorReason.parse || AiErrorReason.blocked =>
      'Tụi Nốt chưa hiểu đoạn này. Thử kể rõ hơn một chút, hoặc ghi tay.',
  };

  Future<void> sort(String text) async {
    if (state.phase == FreeTellPhase.thinking) return;
    final request = ++_request;
    state = state.copyWith(phase: FreeTellPhase.thinking, error: () => null);
    try {
      final result = await ref.read(aiServiceProvider).sortNotes(text);
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(
        phase: FreeTellPhase.review,
        suggestions: result.notes.map(EditableSuggestion.from).toList(),
        mood: () => result.mood,
        needsSupport: result.needsSupport,
      );
    } on AiException catch (e) {
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(
        phase: FreeTellPhase.writing,
        error: () => messageFor(e.reason),
      );
    }
  }

  /// "Huỷ" khi Tụi Nốt đang đọc: quay lại đoạn kể.
  void cancel() {
    _request++;
    state = state.copyWith(phase: FreeTellPhase.writing);
  }

  void backToWriting() => state = state.copyWith(
    phase: FreeTellPhase.writing,
    suggestions: const <EditableSuggestion>[],
    needsSupport: false,
  );

  void setTitle(int index, String title) =>
      _edit(index, (s) => s.copyWith(title: title));

  void setType(int index, NoteType type) =>
      _edit(index, (s) => s.copyWith(type: type));

  void toggleKeep(int index) => _edit(index, (s) => s.copyWith(keep: !s.keep));

  void setMood(Mood? mood) => state = state.copyWith(mood: () => mood);

  void dismissSupport() => state = state.copyWith(needsSupport: false);

  void _edit(int index, EditableSuggestion Function(EditableSuggestion) f) {
    final list = List.of(state.suggestions);
    list[index] = f(list[index]);
    state = state.copyWith(suggestions: list);
  }

  /// "Lưu N nốt": ghi từng nốt đã giữ (tiêu đề trống thì bỏ).
  Future<void> save() async {
    final kept = state.suggestions
        .where((s) => s.keep && s.title.trim().isNotEmpty)
        .toList();
    if (kept.isEmpty || state.phase == FreeTellPhase.saving) return;
    final mood = state.mood;
    final analytics = ref.read(analyticsServiceProvider);
    state = state.copyWith(phase: FreeTellPhase.saving, error: () => null);
    final repo = ref.read(noteRepositoryProvider);
    final now = ref.read(clockProvider).now();
    var saved = 0;
    try {
      for (final (i, s) in kept.indexed) {
        await repo.add(
          NoteDraft(
            type: s.type,
            mood: mood,
            title: s.title.trim().length <= NoteLimits.title
                ? s.title.trim()
                : s.title.trim().substring(0, NoteLimits.title),
          ),
          // Cách nhau 1 giây để giữ thứ tự trong hũ.
          createdAt: now.add(Duration(seconds: i)),
        );
        saved++;
        // Lần ghi đang chờ vẫn có thể hoàn tất, nhưng không bắt đầu ghi nốt
        // tiếp theo sau khi màn đã đóng và provider bị huỷ.
        if (!ref.mounted) return;
      }
      state = state.copyWith(phase: FreeTellPhase.saved, savedCount: saved);
      unawaited(
        analytics.track(AnalyticsEvents.aiResultAccepted, <String, Object>{
          'feature': AiFeature.note.id,
          'item_count': saved,
          'edited_count': kept.where((s) => s.edited).length,
        }),
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      // Nốt đã lưu thì bỏ khỏi danh sách để bấm lại không lưu trùng.
      final rest = List.of(state.suggestions);
      var removed = 0;
      for (var i = 0; i < rest.length && removed < saved; i++) {
        if (rest[i].keep && rest[i].title.trim().isNotEmpty) {
          rest[i] = rest[i].copyWith(keep: false);
          removed++;
        }
      }
      state = state.copyWith(
        phase: FreeTellPhase.review,
        suggestions: rest,
        error: () => ErrorMessages.save(error),
      );
    }
  }

  void clearError() => state = state.copyWith(error: () => null);
}
