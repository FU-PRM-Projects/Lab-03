import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/app.dart';
import 'package:lab03/models/challenge.dart';
import 'package:lab03/models/onboarding.dart';
import 'package:lab03/screens/onboarding/onboarding_screen.dart';
import 'package:lab03/screens/today/today_screen.dart';
import 'package:lab03/services/onboarding_services.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository();

  bool _done = false;
  OnboardingAnswers? saved;
  StarterPlan? savedPlan;
  final _changes = StreamController<bool>.broadcast();

  @override
  Stream<bool> watchDone() => Stream<bool>.multi((controller) {
    controller.add(_done);
    final sub = _changes.stream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });

  @override
  Future<OnboardingAnswers?> load() async => saved;

  @override
  Future<void> finish(OnboardingAnswers answers, StarterPlan? plan) async {
    saved = answers;
    savedPlan = plan;
    _done = true;
    _changes.add(true);
  }
}

void main() {
  group('StarterPlanRules', () {
    final catalog = sampleCatalog();

    test('người rất ngại bắt đầu Dũng cảm cấp 1, 3 thẻ không trùng', () {
      final plan = StarterPlanRules.build(
        const OnboardingAnswers(
          stranger: StrangerLevel.veryShy,
          move: MoveHabit.often,
          freeSlot: FreeSlot.lateNight,
        ),
        catalog,
      );
      expect(plan.startLevels[ChallengeTopic.dungCam], 1);
      expect(plan.startLevels[ChallengeTopic.vanDong], 2);
      expect(plan.profileLabel, 'Người mới tập bắt chuyện');
      expect(plan.remindMinutes, 22 * 60 + 30);
      expect(plan.cards.map((c) => c.id).toSet(), hasLength(plan.cards.length));
      expect(plan.cards.every((c) => !c.onDiscord), isTrue);
      expect(plan.fromAi, isFalse);
    });

    test('muốn vận động thì thẻ Vận động lên trước', () {
      final plan = StarterPlanRules.build(
        const OnboardingAnswers(
          goals: <OnboardingGoal>{OnboardingGoal.moveMore},
        ),
        catalog,
      );
      expect(plan.cards.first.topic, ChallengeTopic.vanDong);
      expect(plan.profileLabel.length, lessThanOrEqualTo(StarterPlan.labelMax));
    });

    test('bỏ qua hết vẫn có kế hoạch mặc định', () {
      final plan = StarterPlanRules.build(const OnboardingAnswers(), catalog);
      expect(plan.startLevels.values, everyElement(1));
      expect(plan.remindMinutes, 21 * 60 + 30);
    });

    test('kho thẻ trống: không có thẻ, không lỗi', () {
      final plan = StarterPlanRules.build(
        const OnboardingAnswers(),
        const <Challenge>[],
      );
      expect(plan.cards, isEmpty);
    });

    test('đầu vào AI chỉ có lựa chọn, không có dữ liệu cá nhân', () {
      final input = const OnboardingAnswers(
        stranger: StrangerLevel.shy,
        habits: <String>{'Video ngắn'},
        goals: <OnboardingGoal>{OnboardingGoal.talkMore},
      ).toAiInput();
      expect(input.keys, <String>[
        'stranger_level',
        'habits',
        'move',
        'free_slot',
        'goals',
      ]);
      expect(input['stranger_level'], 2);
      expect(input['goals'], <String>['bot_ngai']);
    });
  });

  testWidgets(
    'A2: lần đầu đăng nhập mở Làm quen, trả lời 4 bước, lưu hồ sơ khởi đầu',
    (tester) async {
      final services = TestServices();
      final onboarding = FakeOnboardingRepository();
      setScreenSize(tester, phone360);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...services.overrides,
            onboardingRepositoryProvider.overrideWithValue(onboarding),
          ],
          child: const NotApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Làm quen 1/4'), findsOneWidget);

      // S13a: chưa chọn thì "Tiếp" tắt.
      await tester.tap(find.text('Hơi ngại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp'));
      await tester.pumpAndSettle();

      // S13b: thói quen.
      expect(find.text('Làm quen 2/4'), findsOneWidget);
      await tester.tap(find.text('Video ngắn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp'));
      await tester.pumpAndSettle();

      // S13c: bỏ qua.
      expect(find.text('Làm quen 3/4'), findsOneWidget);
      await tester.tap(find.text('Bỏ qua câu này'));
      await tester.pumpAndSettle();

      // S13d: tối đa 2 mục tiêu.
      await tester.tap(find.text('Bớt ngại nói chuyện'));
      await tester.tap(find.text('Vận động đều hơn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngủ sớm hơn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();

      // S13g (bảng luật vì chưa có AI).
      expect(find.text('Hồ sơ khởi đầu'), findsOneWidget);
      expect(find.text('Người mới tập bắt chuyện'), findsOneWidget);
      expect(find.textContaining('Nốt AI đang nghỉ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Nhắc ghi nốt mỗi tối lúc 21:30'),
        200,
      );
      expect(find.text('Nhắc ghi nốt mỗi tối lúc 21:30'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      final saved = onboarding.saved!;
      expect(saved.stranger, StrangerLevel.shy);
      expect(saved.move, isNull);
      expect(saved.goals, <OnboardingGoal>{
        OnboardingGoal.talkMore,
        OnboardingGoal.moveMore,
      });
      expect(onboarding.savedPlan, isNotNull);
      expect(services.selfControl.habits.selected, contains('Video ngắn'));
      expect(onboarding.savedPlan!.remindMinutes, 21 * 60 + 30);
    },
  );

  testWidgets('A2: bỏ qua làm quen chỉ đánh dấu đã xong', (tester) async {
    final services = TestServices();
    final onboarding = FakeOnboardingRepository();
    setScreenSize(tester, phone360);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...services.overrides,
          onboardingRepositoryProvider.overrideWithValue(onboarding),
        ],
        child: const NotApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ qua làm quen?'), findsOneWidget);
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(onboarding.saved, isNotNull);
    expect(onboarding.savedPlan, isNull);
  });

  testWidgets('đã làm quen thì không mở lại; S12 mở lại được', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OnboardingScreen), findsNothing);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Làm lại khảo sát làm quen'),
      200,
    );
    await tester.ensureVisible(find.text('Làm lại khảo sát làm quen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Làm lại khảo sát làm quen'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
