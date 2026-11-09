import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/onboarding.dart';
import 'ai_service.dart';

/// Câu trả lời làm quen (`users/{uid}/private/onboarding`). Lỗi là
/// `AppException`.
abstract interface class OnboardingRepository {
  /// `true` khi đã làm xong (hoặc bỏ qua) làm quen; `null` khi chưa tải được.
  Stream<bool> watchDone();

  /// Câu trả lời lần trước, để chọn sẵn khi làm lại từ S12.
  Future<OnboardingAnswers?> load();

  /// Lưu câu trả lời và đánh dấu đã xong. Có [plan] thì đặt giờ nhắc ghi
  /// nốt buổi tối và nâng cấp bắt đầu của từng chủ đề (nếu người dùng chưa ở
  /// cấp cao hơn).
  Future<void> finish(OnboardingAnswers answers, StarterPlan? plan);
}

/// Dựng hồ sơ khởi đầu. Bản AI (Gemini) gắn ở Final; mặc định là bảng luật.
abstract interface class StarterPlanService {
  Future<StarterPlan> plan(OnboardingAnswers answers, List<Challenge> catalog);
}

class RulesStarterPlanService implements StarterPlanService {
  const RulesStarterPlanService();

  @override
  Future<StarterPlan> plan(
    OnboardingAnswers answers,
    List<Challenge> catalog,
  ) async => StarterPlanRules.build(answers, catalog);
}

/// Mặc định coi như đã làm quen, để test và màn cũ không bị chuyển sang
/// làm quen; `main.dart` gắn bản Firestore.
final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => const _AlreadyOnboarded(),
);

/// Gemini trước; lỗi hoặc tắt thì `OnboardingViewModel` dùng bảng luật.
final starterPlanServiceProvider = Provider<StarterPlanService>(
  (ref) => AiStarterPlanService(ref.watch(aiServiceProvider)),
);

class AiStarterPlanService implements StarterPlanService {
  const AiStarterPlanService(this._ai);

  final AiService _ai;

  @override
  Future<StarterPlan> plan(
    OnboardingAnswers answers,
    List<Challenge> catalog,
  ) => _ai.starterPlan(answers, catalog);
}

class _AlreadyOnboarded implements OnboardingRepository {
  const _AlreadyOnboarded();

  @override
  Stream<bool> watchDone() => Stream<bool>.value(true);

  @override
  Future<OnboardingAnswers?> load() async => null;

  @override
  Future<void> finish(OnboardingAnswers answers, StarterPlan? plan) async {}
}
