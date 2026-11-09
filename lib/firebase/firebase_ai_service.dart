import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/challenge.dart';
import '../models/mood.dart';
import '../models/note_type.dart';
import '../models/onboarding.dart';
import '../services/ai_service.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';

/// [AiService] bằng Gemini qua Firebase AI Logic (Gemini Developer API). App
/// Check gắn tự động khi đã `activate` (xem `firebase_bootstrap.dart`).
///
/// Mọi lời gọi ghi `ai_request` và, khi lỗi, `ai_error {reason}`; kết quả
/// được kiểm tra lại theo giới hạn của app trước khi trả về (JSON sai hoặc
/// vượt giới hạn là lỗi `parse`).
class FirebaseAiService implements AiService {
  FirebaseAiService({required this.configSource, required this.analytics});

  /// Đọc lại mỗi lần gọi để đổi trên Remote Config có tác dụng ngay.
  final AiConfig Function() configSource;
  final AnalyticsService analytics;

  @override
  AiConfig get config => configSource();

  GenerativeModel _model(String instructions, Schema schema) =>
      FirebaseAI.googleAI().generativeModel(
        model: config.model,
        systemInstruction: Content.system(instructions),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
          temperature: 0.4,
        ),
      );

  Future<Map<String, Object?>> _ask(
    AiFeature feature, {
    required String instructions,
    required Schema schema,
    required String input,
  }) async {
    final cfg = config;
    if (!cfg.enabled ||
        (feature == AiFeature.onboarding && !cfg.onboardingEnabled)) {
      await _error(feature, AiErrorReason.disabled);
      throw const AiException(AiErrorReason.disabled);
    }
    await analytics.logEvent(AnalyticsEvents.aiRequest, <String, Object>{
      'feature': feature.id,
      'char_count': input.length,
    });
    try {
      final response = await _model(instructions, schema)
          .generateContent(<Content>[Content.text(input)])
          .timeout(Duration(milliseconds: cfg.timeoutMs));
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const AiException(AiErrorReason.blocked);
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, Object?>) {
        throw const AiException(AiErrorReason.parse);
      }
      return decoded;
    } on AiException catch (e) {
      await _error(feature, e.reason);
      rethrow;
    } on TimeoutException {
      await _error(feature, AiErrorReason.timeout);
      throw const AiException(AiErrorReason.timeout);
    } on FormatException {
      await _error(feature, AiErrorReason.parse);
      throw const AiException(AiErrorReason.parse);
    } on QuotaExceeded catch (e) {
      await _error(feature, AiErrorReason.quota);
      throw AiException(AiErrorReason.quota, e.message);
    } on Object catch (e) {
      // ServiceApiNotEnabled, ServerException, lỗi App Check…: báo chung là
      // mạng / dịch vụ, flow đi nhánh dự phòng.
      await _error(feature, AiErrorReason.network);
      throw AiException(AiErrorReason.network, e.toString());
    }
  }

  Future<void> _error(AiFeature feature, AiErrorReason reason) =>
      analytics.logEvent(AnalyticsEvents.aiError, <String, Object>{
        'feature': feature.id,
        'reason': reason.name,
      });

  Never _bad(AiFeature feature) {
    unawaited(_error(feature, AiErrorReason.parse));
    throw const AiException(AiErrorReason.parse);
  }

  @override
  Future<AiSortResult> sortNotes(String text) async {
    final input = scrubForAi(text, maxChars: config.maxChars);
    if (input.isEmpty) throw const AiException(AiErrorReason.parse);
    final json = await _ask(
      AiFeature.note,
      instructions: config.promptSort,
      input: input,
      schema: Schema.object(
        properties: <String, Schema>{
          'notes': Schema.array(
            maxItems: AiSortResult.maxNotes,
            items: Schema.object(
              properties: <String, Schema>{
                'type': Schema.enumString(
                  enumValues: <String>[for (final t in NoteType.values) t.id],
                ),
                'title': Schema.string(),
              },
            ),
          ),
          'mood': Schema.enumString(
            enumValues: <String>[for (final m in Mood.values) m.id],
            nullable: true,
          ),
          'needs_support': Schema.boolean(),
        },
      ),
    );
    final notes = <AiNoteSuggestion>[];
    for (final item in json['notes'] is List ? json['notes']! as List : []) {
      if (item is! Map) continue;
      var type = NoteType.fromId(item['type'] as String?);
      if (type == NoteType.thuThach) type = NoteType.chienThang;
      final title = (item['title'] as String? ?? '').trim();
      if (type == null || title.isEmpty) continue;
      notes.add(
        AiNoteSuggestion(
          type: type,
          title: title.length <= AiNoteSuggestion.titleMax
              ? title
              : '${title.substring(0, AiNoteSuggestion.titleMax - 1)}…',
        ),
      );
      if (notes.length == AiSortResult.maxNotes) break;
    }
    final needsSupport = json['needs_support'] == true;
    if (notes.isEmpty && !needsSupport) _bad(AiFeature.note);
    return AiSortResult(
      notes: notes,
      mood: Mood.fromId(json['mood'] as String?),
      needsSupport: needsSupport,
    );
  }

  @override
  Future<StarterPlan> starterPlan(
    OnboardingAnswers answers,
    List<Challenge> catalog,
  ) async {
    final cards = catalog.where((c) => !c.mine && !c.onDiscord).toList();
    final input = jsonEncode(<String, Object?>{
      'answers': answers.toAiInput(),
      'cards': <Map<String, Object?>>[
        for (final c in cards)
          <String, Object?>{
            'id': c.id,
            'topic': c.topic.id,
            'level': c.level,
            'title': c.title,
          },
      ],
    });
    final json = await _ask(
      AiFeature.onboarding,
      instructions: config.promptOnboarding,
      input: input,
      schema: Schema.object(
        properties: <String, Schema>{
          'profile_label': Schema.string(),
          'dung_cam_level': Schema.integer(minimum: 1, maximum: 3),
          'van_dong_level': Schema.integer(minimum: 1, maximum: 2),
          'card_ids': Schema.array(
            items: Schema.string(),
            minItems: 3,
            maxItems: 3,
          ),
          'remind_time': Schema.string(),
        },
      ),
    );
    final label = (json['profile_label'] as String? ?? '').trim();
    final brave = json['dung_cam_level'];
    final move = json['van_dong_level'];
    final ids = json['card_ids'] is List
        ? (json['card_ids']! as List).whereType<String>().toList()
        : const <String>[];
    final picked = <Challenge>[
      for (final id in ids.toSet()) ...cards.where((c) => c.id == id),
    ];
    final remind = _parseClock(json['remind_time'] as String?);
    if (label.isEmpty ||
        label.length > StarterPlan.labelMax ||
        brave is! int ||
        brave < 1 ||
        brave > 3 ||
        move is! int ||
        move < 1 ||
        move > 2 ||
        picked.length != StarterPlan.cardCount ||
        remind == null) {
      _bad(AiFeature.onboarding);
    }
    return StarterPlan(
      profileLabel: label,
      startLevels: <ChallengeTopic, int>{
        ChallengeTopic.dungCam: brave,
        ChallengeTopic.vanDong: move,
      },
      cards: picked,
      remindMinutes: remind,
      fromAi: true,
    );
  }

  /// "21:30" → 1290; ngoài 19:00–23:30 hoặc sai dạng thì `null`.
  static int? _parseClock(String? raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw?.trim() ?? '');
    if (match == null) return null;
    final minutes = int.parse(match[1]!) * 60 + int.parse(match[2]!);
    if (minutes < 19 * 60 || minutes > 23 * 60 + 30) return null;
    return minutes;
  }

  @override
  Future<List<String>> greetings({
    required String challengeTitle,
    required String room,
  }) async {
    final json = await _ask(
      AiFeature.greeting,
      instructions: config.promptGreeting,
      input: 'Thử thách: $challengeTitle. Phòng: #$room.',
      schema: Schema.object(
        properties: <String, Schema>{
          'lines': Schema.array(
            items: Schema.string(),
            minItems: 3,
            maxItems: 3,
          ),
        },
      ),
    );
    final lines = <String>[
      for (final line in json['lines'] is List ? json['lines']! as List : [])
        if (line is String && line.trim().isNotEmpty && line.length <= 120)
          line.trim(),
    ];
    if (lines.isEmpty) _bad(AiFeature.greeting);
    return lines.take(3).toList();
  }
}
