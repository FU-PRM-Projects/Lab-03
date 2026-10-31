import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../models/note_type.dart';
import '../models/self_control.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import '../services/self_control_services.dart';
import '../utils/dates.dart';
import '../utils/vi_date_format.dart';
import 'auth_view_model.dart';
import 'error_messages.dart';
import 'view_state.dart';

/// Nội dung S09 · Tự chủ.
class SelfControlSummary {
  const SelfControlSummary({
    required this.monthCount,
    required this.habits,
    required this.settings,
  });

  /// Số lần tự chủ (nốt `tu_chu`) tháng này.
  final int monthCount;
  final HabitList habits;
  final UserSettings settings;
}

class SelfControlState {
  const SelfControlState({
    this.summary = const Loading<SelfControlSummary>(),
    this.unlocked = false,
    this.saving = false,
    this.unlocking = false,
    this.savedNoteId,
    this.message,
  });

  final ViewState<SelfControlSummary> summary;

  /// Đã mở khoá bằng `local_auth` trong lần mở màn này.
  final bool unlocked;
  final bool saving;
  final bool unlocking;

  /// "Mình vừa dừng lại" xong: màn hình chuyển sang S04 của nốt này.
  final String? savedNoteId;
  final String? message;

  /// Mục "Thói quen muốn bớt" đang bị che (bật khoá ở S12, chưa mở khoá).
  bool get habitsLocked => switch (summary) {
    Data<SelfControlSummary>(:final value) =>
      value.settings.lockSelfControl && !unlocked,
    _ => true,
  };

  SelfControlState copyWith({
    ViewState<SelfControlSummary>? summary,
    bool? unlocked,
    bool? saving,
    bool? unlocking,
    String? savedNoteId,
    String? Function()? message,
  }) => SelfControlState(
    summary: summary ?? this.summary,
    unlocked: unlocked ?? this.unlocked,
    saving: saving ?? this.saving,
    unlocking: unlocking ?? this.unlocking,
    savedNoteId: savedNoteId ?? this.savedNoteId,
    message: message == null ? this.message : message(),
  );
}

final selfControlViewModelProvider =
    NotifierProvider.autoDispose<SelfControlViewModel, SelfControlState>(
      SelfControlViewModel.new,
    );

/// ViewModel của S09 (flow F2).
class SelfControlViewModel extends Notifier<SelfControlState> {
  /// Cảm giác gợi ý ở sheet "Lúc đó mình đang thấy gì?" (nhánh phục hồi F2).
  static const List<String> slipFeelings = <String>[
    'Chán',
    'Mệt',
    'Căng thẳng',
    'Cô đơn',
    'Không rõ',
  ];

  static const String _unlockFailed = 'Chưa mở được phần này.';

  int? _monthCount;
  HabitList? _habits;
  UserSettings? _settings;

  NoteRepository get _notes => ref.read(noteRepositoryProvider);
  HabitRepository get _habitRepo => ref.read(habitRepositoryProvider);
  SettingsRepository get _settingsRepo => ref.read(settingsRepositoryProvider);

  @override
  SelfControlState build() {
    ref.watch(authUserProvider.select((user) => user.value?.uid));
    _monthCount = null;
    _habits = null;
    _settings = null;

    // Ẩn màn này khỏi danh sách app gần đây và ảnh chụp (handout S09).
    final guard = ref.read(screenGuardProvider);
    unawaited(guard.setSecure(true));

    final now = ref.read(clockProvider).now();
    void onError(Object error) {
      if (state.summary is! Data<SelfControlSummary>) {
        state = state.copyWith(summary: ErrorMessages.failure(error));
      }
    }

    final subs = <StreamSubscription<Object?>>[
      _notes.watchSince(Dates.startOfMonth(now)).listen((notes) {
        _monthCount = notes.where((n) => n.type == NoteType.tuChu).length;
        _emit();
      }, onError: onError),
      _habitRepo.watch().listen((habits) {
        _habits = habits;
        _emit();
      }, onError: onError),
      _settingsRepo.watch().listen((settings) {
        _settings = settings;
        _emit();
      }, onError: onError),
    ];
    final timeout = Timer(const Duration(seconds: 10), () {
      if (state.summary is Loading<SelfControlSummary>) {
        state = state.copyWith(
          summary: const Failure<SelfControlSummary>(
            ErrorMessages.slow,
            offline: true,
          ),
        );
      }
    });
    ref.onDispose(() {
      timeout.cancel();
      for (final sub in subs) {
        sub.cancel();
      }
      unawaited(guard.setSecure(false));
    });
    return const SelfControlState();
  }

  void _emit() {
    final count = _monthCount;
    final habits = _habits;
    final settings = _settings;
    if (count == null || habits == null || settings == null) return;
    state = state.copyWith(
      summary: Data<SelfControlSummary>(
        SelfControlSummary(
          monthCount: count,
          habits: habits,
          settings: settings,
        ),
      ),
    );
  }

  void retry() => ref.invalidateSelf();

  /// "Mình vừa dừng lại": ghi ngay một lần tự chủ (không cần mở khoá).
  Future<void> recordStop() async {
    if (state.saving) return;
    final now = ref.read(clockProvider).now();
    state = state.copyWith(saving: true, message: () => null);
    try {
      final note = await _notes.add(
        NoteDraft(
          type: NoteType.tuChu,
          title: 'Dừng lại lúc ${ViDateFormat.time(now)}',
        ),
        createdAt: now,
      );
      // Stage 5: logEvent(self_control_logged).
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

  /// Nhánh phục hồi: ghi nhẹ "lúc đó mình đang thấy gì?" thành một nốt nhật
  /// ký, không trừ gì. Trả `true` khi đã lưu.
  Future<bool> recordSlip(String feeling) async {
    final now = ref.read(clockProvider).now();
    try {
      await _notes.add(
        NoteDraft(
          type: NoteType.nhatKy,
          title: 'Nhận ra mình đã lướt quá đà',
          body: 'Lúc đó mình đang thấy: ${feeling.toLowerCase()}.',
        ),
        createdAt: now,
      );
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(message: () => ErrorMessages.update(error));
      }
      return false;
    }
  }

  Future<void> toggleHabit(String habit) async {
    final summary = state.summary;
    if (summary is! Data<SelfControlSummary> || state.habitsLocked) return;
    final selected = summary.value.habits.selected.contains(habit);
    await _guard(() => _habitRepo.setSelected(habit, selected: !selected));
  }

  /// "+ Thêm". Trả câu lỗi để hiện dưới ô nhập, `null` khi đã thêm.
  Future<String?> addHabit(String input) async {
    final summary = state.summary;
    if (summary is! Data<SelfControlSummary>) return null;
    final habit = input.trim();
    final habits = summary.value.habits;
    if (habit.isEmpty) return 'Viết tên thói quen nhé.';
    if (habit.length > HabitList.maxLength) {
      return 'Tối đa ${HabitList.maxLength} ký tự.';
    }
    if (habits.all.any((h) => h.toLowerCase() == habit.toLowerCase())) {
      return 'Thói quen này đã có trong danh sách.';
    }
    if (habits.custom.length >= HabitList.maxCustom) {
      return 'Tối đa ${HabitList.maxCustom} thói quen tự thêm.';
    }
    await _guard(() => _habitRepo.addCustom(habit));
    return null;
  }

  Future<void> setAwakeEnabled(bool enabled) =>
      _saveSettings((settings) => settings.copyWith(awakeEnabled: enabled));

  /// Đổi khung "Giờ tỉnh" (phút kể từ 0h).
  Future<void> setAwakeTimes(int start, int end) => _saveSettings(
    (settings) => settings.copyWith(awakeStart: start, awakeEnd: end),
  );

  Future<void> unlock() async {
    if (state.unlocking) return;
    state = state.copyWith(unlocking: true);
    final ok = await ref
        .read(localAuthServiceProvider)
        .authenticate('Mở phần Thói quen muốn bớt');
    if (!ref.mounted) return;
    state = state.copyWith(
      unlocking: false,
      unlocked: ok,
      message: ok ? null : () => _unlockFailed,
    );
  }

  /// Rời app (paused): khoá lại mục thói quen.
  void lock() {
    if (state.unlocked) state = state.copyWith(unlocked: false);
  }

  void clearMessage() => state = state.copyWith(message: () => null);

  Future<void> _saveSettings(UserSettings Function(UserSettings) change) async {
    final current = _settings;
    if (current == null) return;
    await _guard(() => _settingsRepo.save(change(current)));
  }

  Future<void> _guard(Future<void> Function() task) async {
    try {
      await task();
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(message: () => ErrorMessages.update(error));
      }
    }
  }
}
