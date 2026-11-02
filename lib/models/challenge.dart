/// Chủ đề thử thách. [subtype] là giá trị lưu trên nốt `thu_thach` để S11b
/// đếm "Người lạ" và "Vận động" trong "Cân bằng 5 điều tốt".
enum ChallengeTopic {
  dungCam(id: 'dung_cam', label: 'Dũng cảm', subtype: 'nguoi_la'),
  vanDong(id: 'van_dong', label: 'Vận động', subtype: 'van_dong');

  const ChallengeTopic({
    required this.id,
    required this.label,
    required this.subtype,
  });

  final String id;
  final String label;
  final String subtype;

  static ChallengeTopic? fromId(String? id) {
    for (final topic in values) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}

/// Giới hạn thẻ người dùng tự thêm (khớp firestore.rules).
abstract final class CustomChallengeLimits {
  static const int titleMax = 80;
  static const int tipMax = 120;
  static const int minutesMax = 600;

  /// Số thẻ tự thêm tối đa; quá nhiều thẻ thì chồng thẻ mất ý nghĩa "nhỏ".
  static const int count = 20;
}

/// Một thẻ trong kho `challenges/{id}` (chỉ đọc với người dùng, D-10), hoặc
/// thẻ người dùng tự thêm ở `users/{uid}/customChallenges/{id}` ([mine]).
class Challenge {
  const Challenge({
    required this.id,
    required this.topic,
    required this.level,
    required this.order,
    required this.title,
    required this.minutes,
    this.tip = '',
    this.script = '',
    this.discordRoom,
    this.mine = false,
  });

  final String id;
  final ChallengeTopic topic;

  /// Cấp 1, 2, …; làm hết thẻ của một cấp thì mở cấp sau.
  final int level;

  /// Thứ tự trong cấp.
  final int order;
  final String title;

  /// Thời gian gợi ý ("2 PHÚT"); thử thách vận động dùng làm số phút mặc định.
  final int minutes;

  /// Mẹo ngắn ("Hỏi ngắn thôi, 30 giây là đủ.").
  final String tip;

  /// Câu mẫu để nói (thử thách dũng cảm); rỗng nếu không có.
  final String script;

  /// Thẻ làm trên Discord: mã phòng (`chao_hoi`). Ẩn khi `discord_enabled`
  /// tắt.
  final String? discordRoom;

  /// Thẻ do chính người dùng thêm: không thuộc cấp nào, làm lại được mỗi ngày.
  final bool mine;

  bool get onDiscord => discordRoom != null;

  /// "DŨNG CẢM · 2 PHÚT"; thẻ Discord là "DŨNG CẢM · CẤP 3 · DISCORD"; thẻ
  /// tự thêm là "CỦA BẠN · DŨNG CẢM · 2 PHÚT".
  String get label => mine
      ? 'CỦA BẠN · ${topic.label.toUpperCase()} · $minutes PHÚT'
      : onDiscord
      ? '${topic.label.toUpperCase()} · CẤP $level · DISCORD'
      : '${topic.label.toUpperCase()} · $minutes PHÚT';
}

/// Tiến độ của một chủ đề (`users/{uid}/challengeProgress/{topic}`).
class ChallengeProgress {
  const ChallengeProgress({this.level = 1, this.completed = const <String>{}});

  final int level;

  /// Id các thẻ đã làm (kể cả kết quả "không như ý").
  final Set<String> completed;
}

/// Kết quả một thử thách, lưu kèm nốt `thu_thach`.
enum ChallengeOutcome {
  smooth(id: 'suon_se'),
  notAsHoped(id: 'khong_nhu_y');

  const ChallengeOutcome({required this.id});

  final String id;

  static ChallengeOutcome? fromId(String? id) {
    for (final outcome in values) {
      if (outcome.id == id) return outcome;
    }
    return null;
  }
}

/// Phần thử thách của một nốt `thu_thach` (handout S08).
class ChallengeResult {
  const ChallengeResult({
    required this.challengeId,
    required this.subtype,
    required this.outcome,
    this.anxietyBefore,
    this.anxietyAfter,
    this.minutes,
  });

  final String challengeId;

  /// `nguoi_la` hoặc `van_dong`.
  final String subtype;
  final ChallengeOutcome outcome;

  /// Mức hồi hộp 1–5 trước khi làm; không bắt buộc.
  final int? anxietyBefore;

  /// "Sau đó bạn thấy sao?" 1–5 khi quay lại từ Discord; không bắt buộc.
  final int? anxietyAfter;

  /// Số phút vận động thực tế (P3, dừng sớm vẫn lưu).
  final int? minutes;

  @override
  bool operator ==(Object other) =>
      other is ChallengeResult &&
      other.challengeId == challengeId &&
      other.subtype == subtype &&
      other.outcome == outcome &&
      other.anxietyBefore == anxietyBefore &&
      other.anxietyAfter == anxietyAfter &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(
    challengeId,
    subtype,
    outcome,
    anxietyBefore,
    anxietyAfter,
    minutes,
  );
}
