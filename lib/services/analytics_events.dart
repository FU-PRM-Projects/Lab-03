/// Tên sự kiện và tham số Analytics (docs/analytics-plan.md mục 4).
///
/// Chỉ log enum, id kỹ thuật, số đếm và thời lượng: không log tiêu đề, nội
/// dung nốt, email hay tên nhóm.
abstract final class AnalyticsEvents {
  static const String login = 'login';
  static const String logout = 'logout';
  static const String noteSaved = 'note_saved';
  static const String challengeCompleted = 'challenge_completed';
  static const String reportExported = 'report_exported';
  static const String challengeOpened = 'challenge_opened';
  static const String noteViewed = 'note_viewed';
  static const String selfControlLogged = 'self_control_logged';
  static const String streakExtended = 'streak_extended';
  static const String streakShared = 'streak_shared';
  static const String screenView = 'screen_view';
}

abstract final class AnalyticsParams {
  static const String method = 'method';
  static const String mood = 'mood';
  static const String noteType = 'note_type';
  static const String hasJournal = 'has_journal';
  static const String durationMs = 'duration_ms';
  static const String challengeId = 'challenge_id';
  static const String minutes = 'minutes';
  static const String format = 'format';
  static const String hasHabit = 'has_habit';
  static const String streakLength = 'streak_length';
  static const String streakMilestone = 'streak_milestone';
  static const String screenName = 'firebase_screen';
}
