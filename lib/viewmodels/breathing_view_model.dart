import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../models/note_type.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import '../services/self_control_services.dart';
import '../utils/dates.dart';
import 'error_messages.dart';

enum BreathPhase {
  inhale('Hít vào…'),
  hold('Giữ hơi…'),
  exhale('Thở ra…');

  const BreathPhase(this.label);

  final String label;
}

/// Kiểu thở ở sheet "Đổi kiểu thở".
enum BreathPattern {
  fourSix(label: '4-6', inhale: 4, hold: 0, exhale: 6),
  fourSevenEight(label: '4-7-8', inhale: 4, hold: 7, exhale: 8);

  const BreathPattern({
    required this.label,
    required this.inhale,
    required this.hold,
    required this.exhale,
  });

  final String label;
  final int inhale;
  final int hold;
  final int exhale;

  int get cycle => inhale + hold + exhale;

  /// "4 giây vào · 6 giây ra".
  String get description => hold == 0
      ? '$inhale giây vào · $exhale giây ra'
      : '$inhale giây vào · $hold giây giữ · $exhale giây ra';

  /// Bước thở ở giây thứ [second] của vòng.
  (BreathPhase, int secondsLeft) phaseAt(int second) {
    final t = second % cycle;
    if (t < inhale) return (BreathPhase.inhale, inhale - t);
    if (t < inhale + hold) return (BreathPhase.hold, inhale + hold - t);
    return (BreathPhase.exhale, cycle - t);
  }
}

class BreathingState {
  const BreathingState({
    this.pattern = BreathPattern.fourSix,
    this.elapsed = 0,
    this.after = false,
    this.todayStops,
    this.alternative,
    this.saving = false,
    this.savedNoteId,
    this.message,
  });

  /// Một vòng thở dài 90 giây (handout S10).
  static const int roundSeconds = 90;

  /// Việc thay thế ở màn sau khi thở.
  static const List<String> alternatives = <String>[
    'Đi bộ 5 phút',
    'Uống nước',
    'Nhắn một người bạn',
    'Đi ngủ',
  ];

  final BreathPattern pattern;

  /// Số giây đã thở trong vòng hiện tại.
  final int elapsed;

  /// Đã bấm "Cơn sóng đã hạ": màn sau khi thở.
  final bool after;

  /// "3 lần dừng lại hôm nay"; `null` khi chưa đếm xong.
  final int? todayStops;
  final String? alternative;
  final bool saving;
  final String? savedNoteId;
  final String? message;

  int get remaining => (roundSeconds - elapsed).clamp(0, roundSeconds);

  /// Hết 90 giây: "Xong một vòng".
  bool get roundDone => remaining == 0;

  BreathPhase get phase => pattern.phaseAt(elapsed).$1;

  /// Số giây của bước hiện tại, để vòng tròn co giãn đúng nhịp.
  int get phaseSeconds => switch (phase) {
    BreathPhase.inhale => pattern.inhale,
    BreathPhase.hold => pattern.hold,
    BreathPhase.exhale => pattern.exhale,
  };

  BreathingState copyWith({
    BreathPattern? pattern,
    int? elapsed,
    bool? after,
    int? todayStops,
    String? alternative,
    bool? saving,
    String? savedNoteId,
    String? Function()? message,
  }) => BreathingState(
    pattern: pattern ?? this.pattern,
    elapsed: elapsed ?? this.elapsed,
    after: after ?? this.after,
    todayStops: todayStops ?? this.todayStops,
    alternative: alternative ?? this.alternative,
    saving: saving ?? this.saving,
    savedNoteId: savedNoteId ?? this.savedNoteId,
    message: message == null ? this.message : message(),
  );
}

final breathingViewModelProvider =
    NotifierProvider.autoDispose<BreathingViewModel, BreathingState>(
      BreathingViewModel.new,
    );

/// ViewModel của S10 · Thở 90 giây. Mở là thở ngay, không gọi mạng (tiêu chí
/// mở dưới 2 giây); chỉ đọc dữ liệu ở màn sau khi thở.
class BreathingViewModel extends Notifier<BreathingState> {
  Timer? _ticker;

  /// Đọc một lần ở `build`: `onDispose` không được dùng `ref`.
  late ScreenGuard _guard;

  @override
  BreathingState build() {
    _guard = ref.read(screenGuardProvider);
    unawaited(_guard.setKeepScreenOn(true));
    ref.onDispose(() {
      _ticker?.cancel();
      unawaited(_guard.setKeepScreenOn(false));
    });
    _start();
    return const BreathingState();
  }

  void _start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final next = state.elapsed + 1;
    state = state.copyWith(elapsed: next);
    if (state.roundDone) {
      _ticker?.cancel();
      unawaited(_guard.setKeepScreenOn(false));
    }
  }

  /// "Thở thêm 1 vòng": đặt lại 90 giây.
  void restart() {
    state = state.copyWith(elapsed: 0, after: false);
    unawaited(_guard.setKeepScreenOn(true));
    _start();
  }

  /// "Đổi kiểu thở": bắt đầu lại vòng với kiểu mới.
  void changePattern(BreathPattern pattern) {
    state = state.copyWith(pattern: pattern);
    restart();
  }

  /// "Cơn sóng đã hạ": dừng đồng hồ, sang màn sau khi thở.
  Future<void> finish() async {
    _ticker?.cancel();
    unawaited(_guard.setKeepScreenOn(false));
    state = state.copyWith(after: true);
    final now = ref.read(clockProvider).now();
    try {
      final today = await ref
          .read(noteRepositoryProvider)
          .watchSince(Dates.startOfDay(now))
          .first;
      if (!ref.mounted) return;
      state = state.copyWith(
        todayStops: today.where((n) => n.type == NoteType.tuChu).length,
      );
    } on Object {
      // Số lần chỉ là lời động viên; không có thì thôi.
    }
  }

  void chooseAlternative(String alternative) =>
      state = state.copyWith(alternative: alternative);

  /// "Ghi vào hũ": +1 lần tự chủ rồi mở S04.
  Future<void> saveToJar() async {
    if (state.saving) return;
    final alternative = state.alternative;
    state = state.copyWith(saving: true, message: () => null);
    try {
      final note = await ref
          .read(noteRepositoryProvider)
          .add(
            NoteDraft(
              type: NoteType.tuChu,
              title: alternative == null
                  ? 'Thở 90 giây, vượt qua cơn thôi thúc'
                  : 'Thở 90 giây rồi ${alternative.toLowerCase()}',
            ),
            createdAt: ref.read(clockProvider).now(),
          );
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

  void clearMessage() => state = state.copyWith(message: () => null);
}
