import '../models/streak.dart';

/// Nội dung chia sẻ của một chuỗi ngày. Không chứa nội dung nốt hay thông tin
/// cá nhân — chỉ con số chuỗi, kỷ lục và mốc.
abstract final class StreakShareText {
  static String message(StreakSummary streak) {
    return <String>[
      '🔥 Chuỗi ${streak.current} ngày ghi nốt cùng Nốt!',
      if (streak.record > streak.current)
        'Kỷ lục của mình: ${streak.record} ngày.',
      if (streak.isMilestone) 'Vừa chạm mốc ${streak.current} ngày.',
      'Mỗi ngày một nốt tích cực.',
    ].join('\n');
  }

  static String fileName(StreakSummary streak) =>
      'not-chuoi-${streak.current}-ngay.png';
}
