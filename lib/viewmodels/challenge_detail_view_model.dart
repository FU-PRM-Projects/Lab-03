import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/challenge_repository.dart';
import '../services/clock.dart';
import '../services/crash_reporter.dart';
import '../services/note_repository.dart';
import '../services/remote_config_service.dart';
import 'challenges_view_model.dart';
import 'error_messages.dart';
import 'view_state.dart';

class ChallengeDetailState {
  const ChallengeDetailState({
    this.challenge = const Loading<Challenge>(),
    this.anxiety,
    this.anxietyAfter,
    this.visitedDiscord = false,
    this.minutes,
    this.saving = false,
    this.savedNoteId,
    this.message,
  });

  final ViewState<Challenge> challenge;

  /// "Bạn hồi hộp cỡ nào?" 1–5; không bắt buộc.
  final int? anxiety;

  /// "Sau đó bạn thấy sao?" 1–5 sau khi ghé Discord; không bắt buộc.
  final int? anxietyAfter;

  /// Đã mở phòng Discord và quay lại app: S08 thành "Bạn vừa ghé phòng
  /// chung".
  final bool visitedDiscord;

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
    int? Function()? anxietyAfter,
    bool? visitedDiscord,
    int? minutes,
    bool? saving,
    String? savedNoteId,
    String? Function()? message,
  }) => ChallengeDetailState(
    challenge: challenge ?? this.challenge,
    anxiety: anxiety == null ? this.anxiety : anxiety(),
    anxietyAfter: anxietyAfter == null ? this.anxietyAfter : anxietyAfter(),
    visitedDiscord: visitedDiscord ?? this.visitedDiscord,
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
      unawaited(
        ref.read(analyticsServiceProvider).track(
          AnalyticsEvents.challengeOpened,
          <String, Object>{
            AnalyticsParams.challengeId: challenge.id,
            AnalyticsParams.noteType: challenge.topic.id,
          },
        ),
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

  void setAnxietyAfter(int level) => state = state.copyWith(
    anxietyAfter: () => state.anxietyAfter == level ? null : level,
  );

  /// Quay lại từ phòng Discord (S08d mở link rồi người dùng trở về app).
  void markVisitedDiscord() => state = state.copyWith(visitedDiscord: true);

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
            // Thẻ Discord: chào được, hoặc mới ghé phòng (vẫn là một bước).
            _ when challenge.onDiscord => switch (outcome) {
              ChallengeOutcome.smooth => 'Mình đã chào ở phòng chung.',
              ChallengeOutcome.notAsHoped => 'Mình đã ghé phòng chung.',
            },
            // Thẻ của riêng mình: thử một chút cũng là làm.
            (_, ChallengeOutcome.notAsHoped) when challenge.mine =>
              'Mình đã bắt đầu rồi.',
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
                anxietyAfter: state.anxietyAfter,
                minutes: movement ? minutes : null,
              ),
            ),
            createdAt: ref.read(clockProvider).now(),
          );
      unawaited(
        ref.read(analyticsServiceProvider).track(
          AnalyticsEvents.challengeCompleted,
          <String, Object>{
            AnalyticsParams.challengeId: challenge.id,
            if (movement) AnalyticsParams.minutes: minutes,
          },
        ),
      );
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
    // Thẻ tự thêm không có cấp: nốt đã ghi là đủ, hôm sau làm lại được.
    if (challenge.mine) return;
    try {
      final catalog = ChallengeDeck.available(
        await _challenges.catalog(),
        discord: ref.read(remoteConfigServiceProvider).discordEnabled,
      );
      final progress = await _challenges.progressOf(challenge.topic);
      await _challenges.complete(
        challenge.topic,
        challenge.id,
        level: ChallengeDeck.levelAfter(challenge, progress, catalog),
      );
      if (ref.mounted) {
        ref.read(challengesViewModelProvider.notifier).clearEasier();
      }
    } on Object catch (error, stack) {
      // Nốt đã nằm trong hũ; tiến độ được tính lại lần làm thẻ sau.
      unawaited(
        ref
            .read(crashReporterProvider)
            .recordError(error, stack, reason: 'challenge_progress'),
      );
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
