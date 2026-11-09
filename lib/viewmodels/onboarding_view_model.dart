import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/onboarding.dart';
import '../models/self_control.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/challenge_repository.dart';
import '../services/onboarding_services.dart';
import '../services/self_control_services.dart';
import 'auth_view_model.dart';

/// Pha của luồng làm quen A2.
enum OnboardingPhase {
  /// S13a–d: 4 câu hỏi.
  questions,

  /// S13e: Tụi Nốt đang đọc.
  thinking,

  /// S13f / S13g: hồ sơ khởi đầu + 3 thẻ.
  plan,

  /// Đang lưu sau khi bấm "Bắt đầu".
  saving,
}

class OnboardingState {
  const OnboardingState({
    this.step = 0,
    this.answers = const OnboardingAnswers(),
    this.habitOptions = HabitList.suggestions,
    this.phase = OnboardingPhase.questions,
    this.plan,
    this.message,
    this.finished = false,
  });

  /// 0–3 ứng với S13a–d.
  final int step;
  final OnboardingAnswers answers;

  /// Chip thói quen ở S13b: gợi ý của S09 cộng thói quen người dùng đã thêm.
  final List<String> habitOptions;
  final OnboardingPhase phase;
  final StarterPlan? plan;

  /// Lỗi lưu cho SnackBar.
  final String? message;

  /// Đã lưu xong: màn hình chuyển về S02.
  final bool finished;

  static const int stepCount = 4;

  OnboardingState copyWith({
    int? step,
    OnboardingAnswers? answers,
    List<String>? habitOptions,
    OnboardingPhase? phase,
    StarterPlan? Function()? plan,
    String? Function()? message,
    bool? finished,
  }) => OnboardingState(
    step: step ?? this.step,
    answers: answers ?? this.answers,
    habitOptions: habitOptions ?? this.habitOptions,
    phase: phase ?? this.phase,
    plan: plan == null ? this.plan : plan(),
    message: message == null ? this.message : message(),
    finished: finished ?? this.finished,
  );
}

final onboardingViewModelProvider =
    NotifierProvider.autoDispose<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );

/// `true` khi người dùng đang đăng nhập chưa làm quen (S02 mở S13a một lần).
final needsOnboardingProvider = StreamProvider.autoDispose<bool>((ref) {
  final uid = ref.watch(authUserProvider.select((u) => u.value?.uid));
  if (uid == null) return Stream<bool>.value(false);
  return ref.watch(onboardingRepositoryProvider).watchDone().map((d) => !d);
});

/// ViewModel của S13a–g (flow A2). Câu trả lời lần trước được chọn sẵn khi
/// làm lại từ S12.
class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    unawaited(_prefill());
    return const OnboardingState();
  }

  Future<void> _prefill() async {
    OnboardingAnswers? previous;
    HabitList? habits;
    try {
      previous = await ref.read(onboardingRepositoryProvider).load();
    } on Object {
      // Không tải được câu trả lời cũ: bắt đầu từ trống.
    }
    try {
      habits = await ref.read(habitRepositoryProvider).watch().first;
    } on Object {
      // Như trên.
    }
    if (!ref.mounted) return;
    var answers = previous ?? state.answers;
    if (previous == null && habits != null && habits.selected.isNotEmpty) {
      // Điền sẵn thói quen đã chọn ở S09.
      answers = answers.copyWith(habits: habits.selected);
    }
    state = state.copyWith(
      answers: answers,
      habitOptions: habits?.all ?? state.habitOptions,
    );
  }

  void setStranger(StrangerLevel level) => state = state.copyWith(
    answers: state.answers.copyWith(stranger: () => level),
  );

  void toggleHabit(String habit) {
    final habits = Set<String>.of(state.answers.habits);
    if (!habits.remove(habit)) habits.add(habit);
    state = state.copyWith(answers: state.answers.copyWith(habits: habits));
  }

  void setMove(MoveHabit move) =>
      state = state.copyWith(answers: state.answers.copyWith(move: () => move));

  void setFreeSlot(FreeSlot slot) => state = state.copyWith(
    answers: state.answers.copyWith(freeSlot: () => slot),
  );

  /// Chọn tối đa [OnboardingGoal.maxCount]; chọn thêm khi đã đủ thì bỏ qua.
  void toggleGoal(OnboardingGoal goal) {
    final goals = Set<OnboardingGoal>.of(state.answers.goals);
    if (!goals.remove(goal)) {
      if (goals.length >= OnboardingGoal.maxCount) return;
      goals.add(goal);
    }
    state = state.copyWith(answers: state.answers.copyWith(goals: goals));
  }

  /// "Tiếp" hoặc "Bỏ qua" ([skip] xoá câu trả lời của bước này).
  Future<void> next({bool skip = false}) async {
    var answers = state.answers;
    if (skip) {
      answers = switch (state.step) {
        0 => answers.copyWith(stranger: () => null),
        1 => answers.copyWith(habits: const <String>{}),
        2 => answers.copyWith(move: () => null, freeSlot: () => null),
        _ => answers.copyWith(goals: const <OnboardingGoal>{}),
      };
    }
    unawaited(
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvents.onboardingStep,
        <String, Object>{
          AnalyticsParams.step: state.step + 1,
          AnalyticsParams.skipped: skip ? 1 : 0,
        },
      ),
    );
    if (state.step < OnboardingState.stepCount - 1) {
      state = state.copyWith(step: state.step + 1, answers: answers);
      return;
    }
    state = state.copyWith(answers: answers, phase: OnboardingPhase.thinking);
    await _makePlan();
  }

  void back() {
    if (state.phase != OnboardingPhase.questions) {
      state = state.copyWith(phase: OnboardingPhase.questions);
    } else if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  Future<void> _makePlan() async {
    final answers = state.answers;
    final catalog = await _catalog();
    StarterPlan plan;
    try {
      plan = await ref
          .read(starterPlanServiceProvider)
          .plan(answers, catalog)
          .timeout(const Duration(seconds: 10));
    } on Object {
      // AI lỗi, tắt hoặc quá giờ: bảng luật (S13g).
      plan = StarterPlanRules.build(answers, catalog);
    }
    if (!ref.mounted) return;
    state = state.copyWith(phase: OnboardingPhase.plan, plan: () => plan);
  }

  /// Kho thẻ để chọn 3 thẻ; không tải được thì kế hoạch không có thẻ.
  Future<List<Challenge>> _catalog() async {
    try {
      return await ref.read(challengeRepositoryProvider).catalog();
    } on Object {
      return const <Challenge>[];
    }
  }

  /// "Bắt đầu": lưu câu trả lời, cấp bắt đầu, giờ nhắc và thói quen.
  Future<void> finish() => _save(state.plan);

  /// "Bỏ qua làm quen": chỉ đánh dấu đã xong, không đổi gì khác.
  Future<void> skipAll() async {
    unawaited(
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvents.onboardingStep,
        <String, Object>{
          AnalyticsParams.step: state.step + 1,
          AnalyticsParams.skipped: 1,
        },
      ),
    );
    await _save(null);
  }

  Future<void> _save(StarterPlan? plan) async {
    final answers = state.answers;
    state = state.copyWith(phase: OnboardingPhase.saving, message: () => null);
    try {
      await ref.read(onboardingRepositoryProvider).finish(answers, plan);
      if (plan != null) {
        final habits = ref.read(habitRepositoryProvider);
        for (final habit in answers.habits) {
          await habits.setSelected(habit, selected: true);
        }
        unawaited(
          ref.read(analyticsServiceProvider).logEvent(
            AnalyticsEvents.onboardingDone,
            <String, Object>{
              AnalyticsParams.source: plan.fromAi ? 'ai' : 'rules',
            },
          ),
        );
      }
      if (!ref.mounted) return;
      state = state.copyWith(finished: true);
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: plan == null ? OnboardingPhase.questions : OnboardingPhase.plan,
        message: () => 'Chưa lưu được. Kiểm tra Wi-Fi rồi thử lại nhé.',
      );
    }
  }

  void clearMessage() => state = state.copyWith(message: () => null);
}
