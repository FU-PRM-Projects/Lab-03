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
  static const String groupViewed = 'group_viewed';
  static const String selfControlLogged = 'self_control_logged';
  static const String streakExtended = 'streak_extended';
  static const String streakShared = 'streak_shared';
  static const String screenView = 'screen_view';
  static const String imageUploaded = 'image_uploaded';

  /// Gửi thẻ tự thêm lên kho chung (luồng liên vai trò).
  static const String challengeSubmitted = 'challenge_submitted';

  /// Mở hộp thư có tin từ web admin.
  static const String inboxOpened = 'inbox_opened';

  /// Làm quen (A2): mỗi bước S13a–d, và khi lưu hồ sơ khởi đầu.
  static const String onboardingStep = 'onboarding_step';
  static const String onboardingDone = 'onboarding_done';

  /// Nốt AI (Final Assignment): mỗi lần gọi Gemini, khi người dùng lưu kết
  /// quả, và khi lỗi (`reason`: quota, network, timeout, disabled, parse,
  /// blocked). Tham số không có nội dung người dùng viết.
  static const String aiRequest = 'ai_request';
  static const String aiResultAccepted = 'ai_result_accepted';
  static const String aiError = 'ai_error';
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
  static const String groupSource = 'group_source';
  static const String groupIdea = 'group_idea';
  static const String noteCount = 'note_count';
  static const String screenName = 'firebase_screen';
  static const String imageFolder = 'image_folder';
  static const String fileSizeKb = 'file_size_kb';
  static const String step = 'step';
  static const String skipped = 'skipped';
  static const String source = 'source';
}
