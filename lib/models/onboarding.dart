import 'challenge.dart';

/// S13a "Bạn thấy sao khi bắt chuyện với người lạ?".
enum StrangerLevel {
  veryShy(1, 'Rất ngại', 'Chào một câu thôi cũng thấy khó'),
  shy(2, 'Hơi ngại', 'Nói được, nhưng tim đập nhanh'),
  okay(3, 'Bình thường', 'Cần thì vẫn hỏi được'),
  comfortable(4, 'Khá thoải mái', 'Mình hay là người mở lời');

  const StrangerLevel(this.value, this.label, this.hint);

  /// 1–4, lưu trên Firestore và gửi cho AI.
  final int value;
  final String label;
  final String hint;

  static StrangerLevel? fromValue(Object? value) {
    for (final level in values) {
      if (level.value == value) return level;
    }
    return null;
  }
}

/// S13c "Bạn vận động thế nào?".
enum MoveHabit {
  rarely('it_khi', 'Ít khi', 'Ngồi nhiều, hiếm khi đi bộ'),
  sometimes('thinh_thoang', 'Thỉnh thoảng', 'Vài lần một tuần'),
  often('thuong_xuyen', 'Thường xuyên', 'Gần như ngày nào cũng vận động');

  const MoveHabit(this.id, this.label, this.hint);

  final String id;
  final String label;
  final String hint;

  static MoveHabit? fromId(Object? id) {
    for (final move in values) {
      if (move.id == id) return move;
    }
    return null;
  }
}

/// S13c "Lúc nào bạn rảnh nhất?".
enum FreeSlot {
  morning('sang', 'Buổi sáng'),
  afternoon('chieu', 'Buổi chiều'),
  evening('toi', 'Buổi tối'),
  lateNight('khuya', 'Đêm khuya');

  const FreeSlot(this.id, this.label);

  final String id;
  final String label;

  static FreeSlot? fromId(Object? id) {
    for (final slot in values) {
      if (slot.id == id) return slot;
    }
    return null;
  }
}

/// S13d "Bạn muốn tập điều gì?" (chọn tối đa [maxCount]).
enum OnboardingGoal {
  talkMore('bot_ngai', 'Bớt ngại nói chuyện'),
  moveMore('van_dong', 'Vận động đều hơn'),
  lessScrolling('bot_luot', 'Bớt lướt điện thoại'),
  sleepEarly('ngu_som', 'Ngủ sớm hơn'),
  noticeGood('ghi_nhan', 'Ghi nhận điều tốt mỗi ngày');

  const OnboardingGoal(this.id, this.label);

  final String id;
  final String label;

  static const int maxCount = 2;

  static OnboardingGoal? fromId(Object? id) {
    for (final goal in values) {
      if (goal.id == id) return goal;
    }
    return null;
  }
}

/// Câu trả lời 4 bước làm quen (`users/{uid}/private/onboarding`). Bước bỏ
/// qua thì để `null` / rỗng.
class OnboardingAnswers {
  const OnboardingAnswers({
    this.stranger,
    this.habits = const <String>{},
    this.move,
    this.freeSlot,
    this.goals = const <OnboardingGoal>{},
  });

  final StrangerLevel? stranger;

  /// Thói quen muốn bớt, cùng danh sách với S09.
  final Set<String> habits;
  final MoveHabit? move;
  final FreeSlot? freeSlot;
  final Set<OnboardingGoal> goals;

  OnboardingAnswers copyWith({
    StrangerLevel? Function()? stranger,
    Set<String>? habits,
    MoveHabit? Function()? move,
    FreeSlot? Function()? freeSlot,
    Set<OnboardingGoal>? goals,
  }) => OnboardingAnswers(
    stranger: stranger == null ? this.stranger : stranger(),
    habits: habits ?? this.habits,
    move: move == null ? this.move : move(),
    freeSlot: freeSlot == null ? this.freeSlot : freeSlot(),
    goals: goals ?? this.goals,
  );

  /// Đầu vào của AI (Spec Figma): không có tên, email hay nội dung nốt.
  Map<String, Object?> toAiInput() => <String, Object?>{
    'stranger_level': stranger?.value,
    'habits': habits.toList()..sort(),
    'move': move?.id,
    'free_slot': freeSlot?.id,
    'goals': goals.map((g) => g.id).toList(),
  };
}

/// Hồ sơ khởi đầu (S13f): nhãn, cấp bắt đầu của từng chủ đề, 3 thẻ gợi ý và
/// giờ nhắc ghi nốt buổi tối.
class StarterPlan {
  const StarterPlan({
    required this.profileLabel,
    required this.startLevels,
    required this.cards,
    required this.remindMinutes,
    this.fromAi = false,
  });

  /// Tối đa [labelMax] ký tự.
  final String profileLabel;
  final Map<ChallengeTopic, int> startLevels;
  final List<Challenge> cards;

  /// Số phút kể từ 0h (giống `UserSettings.eveningReminder`).
  final int remindMinutes;

  /// `false`: lấy từ bảng luật vì Nốt AI tắt hoặc lỗi (S13g).
  final bool fromAi;

  static const int labelMax = 30;
  static const int cardCount = 3;
}

/// Bảng luật trong app: luôn cho ra một kế hoạch, dùng khi AI tắt, lỗi hoặc
/// trả kết quả không hợp lệ (S13g).
abstract final class StarterPlanRules {
  static StarterPlan build(OnboardingAnswers a, List<Challenge> catalog) {
    final braveLevel = switch (a.stranger) {
      StrangerLevel.okay || StrangerLevel.comfortable => 2,
      _ => 1,
    };
    final moveLevel = a.move == MoveHabit.often ? 2 : 1;
    final levels = <ChallengeTopic, int>{
      ChallengeTopic.dungCam: braveLevel,
      ChallengeTopic.vanDong: moveLevel,
    };

    // Chủ đề người dùng muốn tập lên trước; mặc định Dũng cảm.
    final first =
        a.goals.contains(OnboardingGoal.moveMore) &&
            !a.goals.contains(OnboardingGoal.talkMore)
        ? ChallengeTopic.vanDong
        : ChallengeTopic.dungCam;
    final second = first == ChallengeTopic.dungCam
        ? ChallengeTopic.vanDong
        : ChallengeTopic.dungCam;

    List<Challenge> pick(ChallengeTopic topic, int count) {
      final level = levels[topic]!;
      final cards =
          catalog
              .where((c) => c.topic == topic && !c.mine && !c.onDiscord)
              .toList()
            ..sort((x, y) {
              // Đúng cấp bắt đầu trước, rồi cấp gần nhất, rồi thứ tự.
              final dx = (x.level - level).abs();
              final dy = (y.level - level).abs();
              return dx != dy ? dx.compareTo(dy) : x.order.compareTo(y.order);
            });
      return cards.take(count).toList();
    }

    final cards = <Challenge>[...pick(first, 2), ...pick(second, 1)];
    // Kho thiếu thẻ một chủ đề thì lấy thêm từ chủ đề kia.
    if (cards.length < StarterPlan.cardCount) {
      for (final card in pick(first, StarterPlan.cardCount + 2)) {
        if (cards.length >= StarterPlan.cardCount) break;
        if (!cards.any((c) => c.id == card.id)) cards.add(card);
      }
    }

    return StarterPlan(
      profileLabel: _label(a),
      startLevels: levels,
      cards: cards,
      remindMinutes: switch (a.freeSlot) {
        FreeSlot.lateNight => 22 * 60 + 30,
        FreeSlot.evening || null => 21 * 60 + 30,
        _ => 20 * 60 + 30,
      },
    );
  }

  static String _label(OnboardingAnswers a) {
    if (a.stranger == StrangerLevel.veryShy ||
        a.stranger == StrangerLevel.shy) {
      return 'Người mới tập bắt chuyện';
    }
    if (a.goals.contains(OnboardingGoal.lessScrolling) || a.habits.isNotEmpty) {
      return 'Đang tập bớt lướt';
    }
    if (a.move == MoveHabit.often ||
        a.goals.contains(OnboardingGoal.moveMore)) {
      return 'Người thích vận động';
    }
    if (a.goals.contains(OnboardingGoal.sleepEarly)) return 'Đang tập ngủ sớm';
    return 'Người gom điều tốt nhỏ';
  }
}
