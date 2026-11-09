import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/first_group.dart';
import '../models/image_ref.dart';
import '../models/note.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/clock.dart';
import '../services/crash_reporter.dart';
import '../services/draft_store.dart';
import '../services/group_repository.dart';
import '../services/note_repository.dart';
import '../services/remote_config_service.dart';
import 'error_messages.dart';
import 'image_upload_view_model.dart';
import 'today_view_model.dart';

/// Việc màn S03 làm khi người dùng bấm Back (handout mục 3).
enum ComposerBack {
  /// Bước 1 chưa có dữ liệu: đóng luồng, về S02.
  close,

  /// Bước 1 có dữ liệu (ảnh): hỏi "Giữ nốt đang ghi?".
  confirmKeepDraft,

  /// Bước 2–3: lùi về bước trước (ViewModel đã đổi bước).
  previousStep,
}

/// Số bước của S03: chụp khoảnh khắc → chiến thắng → vài dòng.
const int kComposerSteps = 3;

class NoteComposerState {
  const NoteComposerState({
    required this.step,
    required this.quickWins,
    this.draft = const NoteDraft(),
    this.saving = false,
    this.savedNoteId,
    this.message,
    this.group,
  });

  /// Bước 1–[kComposerSteps]: 1 ảnh, 2 chiến thắng, 3 vài dòng.
  final int step;
  final NoteDraft draft;

  /// Chip "Hoặc chọn nhanh" (Remote Config `quick_win_chips`).
  final List<String> quickWins;
  final bool saving;

  /// Đã lưu xong: màn hình chuyển sang S04 của nốt này.
  final String? savedNoteId;

  /// Lỗi lưu cho SnackBar.
  final String? message;

  /// Nhóm lần đầu sẽ chứa nốt ("Thử lần nữa" ở S05e).
  final FirstGroup? group;

  /// Bước 1 (ảnh) tuỳ chọn: "Tiếp" chỉ mở khi đã có ảnh, còn không thì dùng
  /// "Bỏ qua".
  bool get canContinue => switch (step) {
    1 => draft.image != null,
    _ => draft.title.trim().isNotEmpty,
  };

  NoteComposerState copyWith({
    int? step,
    NoteDraft? draft,
    bool? saving,
    String? savedNoteId,
    String? Function()? message,
    FirstGroup? Function()? group,
  }) => NoteComposerState(
    step: step ?? this.step,
    quickWins: quickWins,
    draft: draft ?? this.draft,
    saving: saving ?? this.saving,
    savedNoteId: savedNoteId ?? this.savedNoteId,
    message: message == null ? this.message : message(),
    group: group == null ? this.group : group(),
  );
}

/// Tham số của S03: bước mở đầu (`?step=`) và nhóm lần đầu (`?group=`).
typedef ComposerArgs = ({int step, String? groupId});

final noteComposerViewModelProvider = NotifierProvider.autoDispose
    .family<NoteComposerViewModel, NoteComposerState, ComposerArgs>(
      NoteComposerViewModel.new,
    );

/// ViewModel của S03 · Ghi nốt (flow F1).
class NoteComposerViewModel extends Notifier<NoteComposerState> {
  NoteComposerViewModel(this.args);

  final ComposerArgs args;

  /// Lúc mở bước 1, để đo tiêu chí "ghi nốt dưới 30 giây" (`duration_ms`).
  late DateTime _openedAt;

  NoteRepository get _notes => ref.read(noteRepositoryProvider);
  GroupRepository get _groups => ref.read(groupRepositoryProvider);
  DraftStore get _drafts => ref.read(draftStoreProvider);

  @override
  NoteComposerState build() {
    _openedAt = ref.read(clockProvider).now();
    // Ảnh vừa tải lên xong: gắn vào nháp rồi đưa khối chọn ảnh về đầu.
    ref.listen(imageUploadViewModelProvider(ImageFolder.note), (
      previous,
      next,
    ) {
      final image = next.image;
      if (next.phase == ImageUploadPhase.done &&
          image != null &&
          previous?.phase != ImageUploadPhase.done) {
        state = state.copyWith(draft: state.draft.copyWith(image: image));
        ref
            .read(imageUploadViewModelProvider(ImageFolder.note).notifier)
            .reset();
      }
    });
    unawaited(_restoreDraft());
    if (args.groupId case final id?) unawaited(_loadGroup(id));
    return NoteComposerState(
      step: args.step.clamp(1, kComposerSteps),
      quickWins: ref.read(remoteConfigServiceProvider).quickWinChips,
    );
  }

  /// Mở lại nháp đã giữ, nếu người dùng chưa bắt đầu nhập.
  Future<void> _restoreDraft() async {
    final NoteDraft? draft;
    try {
      draft = await _drafts.load();
    } on Object {
      return;
    }
    if (!ref.mounted || draft == null || state.draft.hasInput) return;
    state = state.copyWith(draft: draft);
  }

  Future<void> _loadGroup(String id) async {
    FirstGroup? group;
    try {
      group = await _groups.get(id);
    } on Object {
      // Không đọc được thì coi như nhóm hệ thống / nhóm chưa có nốt.
    }
    group ??= FirstGroups.systemById(id);
    if (ref.mounted && group != null) {
      state = state.copyWith(group: () => group);
    }
  }

  /// Bỏ "Xếp vào nhóm" ở bước 2: nốt lưu như bình thường.
  void clearGroup() => state = state.copyWith(group: () => null);

  void setTitle(String title) =>
      state = state.copyWith(draft: state.draft.copyWith(title: title));

  /// Chạm chip: điền tên chip vào ô chiến thắng (vẫn sửa tiếp được).
  void pickQuickWin(String label) => setTitle(label);

  void setBody(String body) =>
      state = state.copyWith(draft: state.draft.copyWith(body: body));

  /// "Gỡ ảnh": nốt lưu không kèm ảnh (ảnh cũ vẫn nằm trên Cloudinary).
  void removeImage() =>
      state = state.copyWith(draft: state.draft.copyWith(clearImage: true));

  bool get _uploadingImage =>
      ref.read(imageUploadViewModelProvider(ImageFolder.note)).busy;

  void next() {
    if (!state.canContinue || state.step >= kComposerSteps) return;
    // Ảnh còn đang tải: đi tiếp lúc này sẽ làm mất ảnh.
    if (state.step == 1 && _uploadingImage) return;
    state = state.copyWith(step: state.step + 1);
  }

  /// "Bỏ qua" ở bước chụp ảnh: sang bước chiến thắng, nốt không kèm ảnh.
  void skipPhoto() {
    if (state.step != 1 || _uploadingImage) return;
    state = state.copyWith(step: 2);
  }

  ComposerBack back() {
    switch (state.step) {
      case 1:
        return state.draft.hasInput
            ? ComposerBack.confirmKeepDraft
            : ComposerBack.close;
      default:
        state = state.copyWith(step: state.step - 1);
        return ComposerBack.previousStep;
    }
  }

  /// "Giữ nháp" ở dialog thoát giữa chừng.
  Future<void> keepDraft() async {
    await _drafts.save(state.draft);
    ref.invalidate(hasDraftProvider);
  }

  /// "Bỏ" ở dialog thoát giữa chừng.
  Future<void> discardDraft() async {
    await _drafts.clear();
    ref.invalidate(hasDraftProvider);
  }

  /// Lưu nốt. [skipJournal] cho "Bỏ qua phần kể thêm" (bước 2) và "Bỏ qua"
  /// (bước 3): lưu với nhật ký rỗng.
  Future<void> save({bool skipJournal = false}) async {
    if (state.saving || state.savedNoteId != null) return;
    // Ảnh còn đang tải: `draft.image` chưa có, lưu lúc này sẽ tạo nốt không
    // ảnh rồi rời màn hình làm huỷ luôn lần tải. Chờ tải xong (hoặc huỷ).
    if (ref.read(imageUploadViewModelProvider(ImageFolder.note)).busy) return;
    final title = state.draft.title.trim();
    if (title.isEmpty ||
        title.length > NoteLimits.title ||
        state.draft.body.length > NoteLimits.body) {
      return;
    }

    final group = state.group;
    final toSave = NoteDraft(
      mood: state.draft.mood,
      title: title,
      body: skipJournal ? '' : state.draft.body.trim(),
      groupId: group?.id,
      isFirst: group != null && group.noteCount == 0,
      image: state.draft.image,
    );

    state = state.copyWith(saving: true, message: () => null);
    try {
      final note = await _notes.add(
        toSave,
        createdAt: ref.read(clockProvider).now(),
      );
      if (group != null) {
        try {
          await _groups.recordNote(group, note);
        } on Object {
          // Nốt đã lưu và mang groupId; số đếm của nhóm chỉ lệch tạm thời.
        }
      }
      unawaited(
        ref.read(analyticsServiceProvider).track(
          AnalyticsEvents.noteSaved,
          <String, Object>{
            AnalyticsParams.mood: toSave.mood?.name ?? 'none',
            AnalyticsParams.noteType: 'chien_thang',
            AnalyticsParams.hasJournal: '${toSave.body.isNotEmpty}',
            AnalyticsParams.durationMs: ref
                .read(clockProvider)
                .now()
                .difference(_openedAt)
                .inMilliseconds,
          },
        ),
      );
      try {
        await _drafts.clear();
      } on Object {
        // Nốt đã lưu; nháp cũ chỉ làm S02 hiện "Tiếp tục ghi nốt".
      }
      if (!ref.mounted) return;
      ref.invalidate(hasDraftProvider);
      state = state.copyWith(saving: false, savedNoteId: note.id);
    } on Object catch (error) {
      unawaited(
        ref
            .read(crashReporterProvider)
            .recordError(error, null, reason: 'note_save'),
      );
      try {
        await _drafts.save(state.draft);
      } on Object {
        // Không giữ được nháp thì vẫn còn nội dung trên màn hình.
      }
      if (!ref.mounted) return;
      ref.invalidate(hasDraftProvider);
      state = state.copyWith(
        saving: false,
        message: () => ErrorMessages.save(error),
      );
    }
  }

  void clearMessage() => state = state.copyWith(message: () => null);
}
