import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/mood.dart';
import '../models/note_type.dart';
import '../models/onboarding.dart';

/// Tham số Nốt AI trên Remote Config (Spec Figma, mục 6 của
/// `design-traceability.md`). Đổi trên Console không cần build lại.
class AiConfig {
  const AiConfig({
    this.enabled = true,
    this.onboardingEnabled = true,
    this.model = defaultModel,
    this.timeoutMs = 8000,
    this.maxChars = 500,
    this.promptSort = defaultPromptSort,
    this.promptOnboarding = defaultPromptOnboarding,
    this.promptGreeting = defaultPromptGreeting,
  });

  /// `ai_enabled`: tắt thì mọi tính năng AI đi nhánh dự phòng.
  final bool enabled;

  /// `ai_onboarding_enabled`: hồ sơ khởi đầu bằng AI (S13f).
  final bool onboardingEnabled;

  /// `ai_model`.
  final String model;

  /// `ai_timeout_ms`: quá thời gian thì coi như lỗi `timeout`.
  final int timeoutMs;

  /// `ai_max_chars`: độ dài tối đa đoạn kể gửi đi.
  final int maxChars;

  /// `ai_prompt_sort`, `ai_prompt_onboarding`, `ai_prompt_greeting`.
  final String promptSort;
  final String promptOnboarding;
  final String promptGreeting;

  static const String defaultModel = 'gemini-2.5-flash';

  static const String defaultPromptSort =
      'Bạn là Tụi Nốt, bạn đồng hành nhẹ nhàng của một sinh viên. Người dùng '
      'kể tự do về một ngày. Tách đoạn kể thành tối đa 5 nốt ngắn, mỗi nốt '
      'là một việc làm được: chien_thang (việc làm được, chiến thắng nhỏ, kể '
      'cả đã thử bắt chuyện hoặc vận động), tu_chu (đã dừng một thói quen như '
      'lướt điện thoại), nhat_ky (suy nghĩ, cảm xúc). Tiêu đề viết '
      'ngôi thứ nhất, tiếng Việt, tối đa 40 ký tự, không lặp lại tên người, '
      'không bịa thêm việc. Đoán tâm trạng cả ngày (vui, on, binh_thuong, met, '
      'roi) hoặc null nếu không rõ. needs_support = true khi người dùng nói '
      'tới tự hại, tuyệt vọng hoặc không an toàn.';

  static const String defaultPromptOnboarding =
      'Bạn là Tụi Nốt. Dựa trên câu trả lời khảo sát, chọn cấp bắt đầu cho '
      'chủ đề Dũng cảm (1–3) và Vận động (1–2), đúng 3 thẻ trong danh sách '
      'thẻ được cho (chỉ dùng id có sẵn, ưu tiên thẻ dễ khi người dùng ngại), '
      'giờ nhắc ghi nốt buổi tối dạng HH:MM trong khoảng 19:00–23:30, và một '
      'nhãn hồ sơ tiếng Việt thân thiện tối đa 30 ký tự.';

  static const String defaultPromptGreeting =
      'Bạn là Tụi Nốt. Viết 3 câu chào ngắn (tối đa 120 ký tự), tự nhiên, '
      'thân thiện, tiếng Việt, để một sinh viên hơi ngại dán vào phòng trò '
      'chuyện chung trên Discord. Không dùng tên người, không hỏi thông tin '
      'cá nhân.';
}

/// Lý do AI không trả kết quả; ghi vào `ai_error {reason}`.
enum AiErrorReason { disabled, quota, network, timeout, parse, blocked }

class AiException implements Exception {
  const AiException(this.reason, [this.detail]);

  final AiErrorReason reason;
  final String? detail;

  @override
  String toString() => 'AiException($reason, $detail)';
}

/// Tính năng AI, ghi vào tham số `feature` của Analytics.
enum AiFeature {
  note('note'),
  onboarding('onboarding'),
  greeting('greeting');

  const AiFeature(this.id);

  final String id;
}

/// Một nốt Gemini tách ra từ đoạn kể (S03b).
class AiNoteSuggestion {
  const AiNoteSuggestion({required this.type, required this.title});

  final NoteType type;

  /// Tối đa [titleMax] ký tự.
  final String title;

  static const int titleMax = 40;

  /// Loại AI được chọn: nốt Thử thách cần kết quả thử thách đi kèm nên chỉ
  /// tạo từ màn thử thách.
  static const List<NoteType> types = <NoteType>[
    NoteType.chienThang,
    NoteType.tuChu,
    NoteType.nhatKy,
  ];
}

/// Kết quả "Nốt sắp xếp giúp".
class AiSortResult {
  const AiSortResult({
    required this.notes,
    this.mood,
    this.needsSupport = false,
  });

  final List<AiNoteSuggestion> notes;
  final Mood? mood;

  /// Đoạn kể có dấu hiệu cần hỗ trợ: hiện thẻ "Nói với người bạn tin".
  final bool needsSupport;

  static const int maxNotes = 5;
}

/// Gọi Gemini qua Firebase AI Logic. Lỗi là [AiException]; chỗ gọi luôn có
/// nhánh dự phòng.
abstract interface class AiService {
  AiConfig get config;

  /// S03b: tách [text] (đã che email, số điện thoại) thành nốt.
  Future<AiSortResult> sortNotes(String text);

  /// S13f: hồ sơ khởi đầu từ câu trả lời khảo sát và kho thẻ.
  Future<StarterPlan> starterPlan(
    OnboardingAnswers answers,
    List<Challenge> catalog,
  );

  /// S08d: 3 câu chào cho phòng [room] khi làm thẻ [challengeTitle].
  Future<List<String>> greetings({
    required String challengeTitle,
    required String room,
  });
}

/// Bản không có AI (test, Emulator): mọi lời gọi báo `disabled`.
class DisabledAiService implements AiService {
  const DisabledAiService({this.config = const AiConfig(enabled: false)});

  @override
  final AiConfig config;

  static Never _off() => throw const AiException(AiErrorReason.disabled);

  @override
  Future<AiSortResult> sortNotes(String text) async => _off();

  @override
  Future<StarterPlan> starterPlan(
    OnboardingAnswers answers,
    List<Challenge> catalog,
  ) async => _off();

  @override
  Future<List<String>> greetings({
    required String challengeTitle,
    required String room,
  }) async => _off();
}

final aiServiceProvider = Provider<AiService>(
  (ref) => const DisabledAiService(),
);

/// Che email và số điện thoại trước khi gửi đi (Final: không gửi dữ liệu cá
/// nhân), rồi cắt còn [maxChars] ký tự.
String scrubForAi(String text, {required int maxChars}) {
  var out = text
      .replaceAll(RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+'), '[email]')
      .replaceAll(RegExp(r'(\+?\d[\d .-]{7,}\d)'), '[số điện thoại]')
      .trim();
  if (out.length > maxChars) out = out.substring(0, maxChars);
  return out;
}
