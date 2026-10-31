import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../services/challenge_repository.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import 'challenges_view_model.dart';
import 'error_messages.dart';
import 'view_state.dart';

class ChallengeDetailState {
  const ChallengeDetailState({
    this.challenge = const Loading<Challenge>(),
    this.anxiety,
    this.minutes,
    this.saving = false,
    this.savedNoteId,
    this.message,
  });

  final ViewState<Challenge> challenge;

  /// "Bạn hồi hộp cỡ nào?" 1–5; không bắt buộc.
  final int? anxiety;

  /// Số phút vận động thực tế (P3); mặc định là số phút của thẻ.
  final int? minutes;
  final bool saving;
  final String? savedNoteId;
  final String? message;

  Challenge? get loaded => switch (challenge) {
    Data<Challenge>(:final value) => value,
    _ => null,
  };

  bool get isMovement => loaded?.topic == ChallengeTopic.vanDong;

  /// Nhãn hai lựa chọn ở sheet "Kết quả?".
  String outcomeLabel(ChallengeOutcome outcome) =>
      switch ((isMovement, outcome)) {
        (false, ChallengeOutcome.smooth) => 'Suôn sẻ',
        (false, ChallengeOutcome.notAsHoped) => 'Không như ý',
        (true, ChallengeOutcome.smooth) => 'Xong trọn',
        (true, ChallengeOutcome.notAsHoped) => 'Dừng sớm',
      };

  ChallengeDetailState copyWith({
    ViewState<Challenge>? challenge,
    int? Function()? anxiety,
    int? minutes,
    bool? saving,
    String? savedNoteId,
    String? Function()? message,
  }) => ChallengeDetailState(
    challenge: challenge ?? this.challenge,
    anxiety: anxiety == null ? this.anxiety : anxiety(),
    minutes: minutes ?? this.minutes,
    saving: saving ?? this.saving,
    savedNoteId: savedNoteId ?? this.savedNoteId,
    message: message == null ? this.message : message(),
  );
}

final challengeDetailViewModelProvider = NotifierProvider.autoDispose
    .family<ChallengeDetailViewModel, ChallengeDetailState, String>(
      ChallengeDetailViewModel.new,
    );

/// ViewModel của S08 (flow F3, P3).
class ChallengeDetailViewModel extends Notifier<ChallengeDetailState> {
  ChallengeDetailViewModel(this.challengeId);

  final String challengeId;

  /// Ô "cảm giác sau" tối đa 120 ký tự (handout S08).
  static const int feelingMaxLength = 120;

  /// Số phút vận động tối đa nhập được (khớp firestore.rules).
  static const int maxMinutes = 600;

  ChallengeRepository get _challenges => ref.read(challengeRepositoryProvider);

  @override
  ChallengeDetailState build() {
    unawaited(_load());
    return const ChallengeDetailState();
  }

  Future<void> _load() async {
    try {
      final challenge = await _challenges.get(challengeId);
      if (!ref.mounted) return;
      state = state.copyWith(
        challenge: Data<Challenge>(challenge),
        minutes: challenge.minutes,
      );
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(challenge: ErrorMessages.failure(error));
      }
    }
  }

  void retry() {
    state = state.copyWith(challenge: const Loading<Challenge>());
    unawaited(_load());
  }

  /// Chạm lại mức đang chọn để bỏ chấm.
  void setAnxiety(int level) => state = state.copyWith(
    anxiety: () => state.anxiety == level ? null : level,
  );

  void setMinutes(int minutes) =>
      state = state.copyWith(minutes: minutes.clamp(0, maxMinutes));

  /// "Lưu" ở sheet "Kết quả?": tạo nốt thử thách, đánh dấu đã làm (lên cấp
  /// nếu xong cấp) rồi mở S04.
  Future<void> save(ChallengeOutcome outcome, String feeling) async {
    final challenge = state.loaded;
    if (challenge == null || state.saving) return;
    final movement = challenge.topic == ChallengeTopic.vanDong;
    final minutes = state.minutes ?? challenge.minutes;
    final trimmed = feeling.trim();
    final body = trimmed.isNotEmpty
        ? trimmed
        : switch ((movement, outcome)) {
            // "Không như ý" vẫn tính là dũng cảm (F3).
            (false, ChallengeOutcome.notAsHoped) => 'Mình đã mở lời.',
            // Dừng sớm vẫn ghi (P3).
            (true, ChallengeOutcome.notAsHoped) =>
              'Mình đã ra ngoài $minutes phút.',
            _ => '',
          };
    if (body.length > NoteLimits.body) return;

    state = state.copyWith(saving: true, message: () => null);
    try {
      final note = await ref
          .read(noteRepositoryProvider)
          .add(
            NoteDraft(
              type: NoteType.thuThach,
              title: challenge.title,
              body: body,
              challenge: ChallengeResult(
                challengeId: challenge.id,
                subtype: challenge.topic.subtype,
                outcome: outcome,
                anxietyBefore: state.anxiety,
                minutes: movement ? minutes : null,
              ),
            ),
            createdAt: ref.read(clockProvider).now(),
          );
      // Stage 5: logEvent(challenge_completed).
      await _markCompleted(challenge);
      if (!ref.mounted) return;
      state = state.copyWith(saving: false, savedNoteId: note.id);
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        saving: false,
        message: () => ErrorMessages.update(error),
      );
    }
  }

  Future<void> _markCompleted(Challenge challenge) async {
    try {
      final catalog = await _challenges.catalog();
      final progress = await _challenges.progressOf(challenge.topic);
      await _challenges.complete(
        challenge.topic,
        challenge.id,
        level: ChallengeDeck.levelAfter(challenge, progress, catalog),
      );
      if (ref.mounted) {
        ref.read(challengesViewModelProvider.notifier).clearEasier();
      }
    } on Object {
      // Nốt đã nằm trong hũ; tiến độ được tính lại lần làm thẻ sau.
      // Stage 5: ghi non-fatal qua CrashReporter.
    }
  }

  /// "Đổi thẻ dễ hơn": `false` khi đã là thẻ dễ nhất của chủ đề.
  Future<bool> showEasier() async {
    final challenge = state.loaded;
    if (challenge == null) return false;
    return ref
        .read(challengesViewModelProvider.notifier)
        .showEasierThan(challenge);
  }

  void clearMessage() => state = state.copyWith(message: () => null);
}
