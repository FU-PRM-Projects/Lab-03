import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/app.dart';
import 'package:lab03/models/challenge.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/models/onboarding.dart';
import 'package:lab03/router/app_routes.dart';
import 'package:lab03/screens/note_composer/free_tell_screen.dart';
import 'package:lab03/services/ai_service.dart';
import 'package:lab03/services/analytics_service.dart';
import 'package:lab03/viewmodels/free_tell_view_model.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

class FakeAi implements AiService {
  FakeAi({this.result, this.error});

  AiSortResult? result;
  AiErrorReason? error;
  final List<String> sent = <String>[];

  @override
  AiConfig get config => const AiConfig();

  @override
  Future<AiSortResult> sortNotes(String text) async {
    sent.add(text);
    if (error != null) throw AiException(error!);
    return result!;
  }

  @override
  Future<StarterPlan> starterPlan(
    OnboardingAnswers answers,
    List<Challenge> catalog,
  ) async => throw const AiException(AiErrorReason.disabled);

  @override
  Future<List<String>> greetings({
    required String challengeTitle,
    required String room,
  }) async => throw const AiException(AiErrorReason.disabled);
}

void main() {
  test('che email và số điện thoại, cắt theo ai_max_chars', () {
    final out = scrubForAi(
      'Mình nhắn cho lan.nguyen@fpt.edu.vn và gọi 0912 345 678 rồi đi học',
      maxChars: 500,
    );
    expect(out, isNot(contains('@fpt')));
    expect(out, isNot(contains('0912')));
    expect(out, contains('[email]'));
    expect(out, contains('[số điện thoại]'));
    expect(scrubForAi('a' * 900, maxChars: 500), hasLength(500));
  });

  test('mỗi lý do lỗi AI có câu báo và gợi ý ghi tay', () {
    for (final reason in AiErrorReason.values) {
      expect(FreeTellViewModel.messageFor(reason), isNotEmpty);
    }
  });

  late FakeAnalyticsService analytics;

  Future<TestServices> openFreeTell(
    WidgetTester tester,
    FakeAi ai, {
    Size size = phone360,
  }) async {
    final services = TestServices();
    analytics = FakeAnalyticsService();
    setScreenSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...services.overrides,
          aiServiceProvider.overrideWithValue(ai),
          analyticsServiceProvider.overrideWithValue(analytics),
        ],
        child: const NotApp(),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(routerOf(tester).push(AppRoutes.freeTell));
    await tester.pumpAndSettle();
    expect(find.byType(FreeTellScreen), findsOneWidget);
    return services;
  }

  testWidgets(
    'A1: lần đầu hỏi đồng ý, Tụi Nốt tách nốt, sửa rồi lưu nốt đã chọn',
    (tester) async {
      final ai = FakeAi(
        result: const AiSortResult(
          notes: <AiNoteSuggestion>[
            AiNoteSuggestion(
              type: NoteType.chienThang,
              title: 'Hỏi thầy một câu sau giờ học',
            ),
            AiNoteSuggestion(type: NoteType.tuChu, title: 'Dừng lướt lúc 23h'),
            AiNoteSuggestion(type: NoteType.nhatKy, title: 'Hơi mệt'),
          ],
          mood: Mood.on,
        ),
      );
      // Màn cao để thấy đủ 3 gợi ý cùng lúc.
      final services = await openFreeTell(
        tester,
        ai,
        size: const Size(412, 1600),
      );

      await tester.enterText(
        find.byType(TextField),
        'Chiều nay hỏi thầy một câu sau giờ học, tối dừng lướt lúc 11 giờ.',
      );
      await tester.pump();
      await tester.tap(find.text('Nhờ Tụi Nốt sắp xếp'));
      await tester.pumpAndSettle();

      // Sheet quyền riêng tư lần đầu.
      expect(find.text('Nốt AI sắp xếp giúp'), findsOneWidget);
      expect(find.textContaining('Không gửi: tên và email'), findsOneWidget);
      await tester.tap(find.text('Đồng ý và sắp xếp'));
      await tester.pumpAndSettle();
      expect(services.selfControl.settings.aiEnabled, isTrue);
      expect(ai.sent, hasLength(1));

      expect(
        find.text('Gợi ý từ Nốt AI · kiểm tra trước khi lưu'),
        findsOneWidget,
      );
      expect(find.text('Lưu 3 nốt'), findsOneWidget);

      // Bỏ nốt thứ 3, sửa tiêu đề nốt đầu.
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Hỏi thầy một câu sau giờ học'),
        'Hỏi thầy về bài tập lớn',
      );
      await tester.pump();
      expect(find.text('Lưu 2 nốt'), findsOneWidget);
      await tester.tap(find.text('Lưu 2 nốt'));
      await tester.pumpAndSettle();

      expect(find.byType(FreeTellScreen), findsNothing);
      final saved = services.notes.notes;
      expect(
        saved.map((n) => n.title),
        unorderedEquals(<String>[
          'Dừng lướt lúc 23h',
          'Hỏi thầy về bài tập lớn',
        ]),
      );
      expect(saved.every((n) => n.mood == Mood.on), isTrue);
      expect(
        analytics.events.where((e) => e.name == 'ai_result_accepted'),
        hasLength(1),
      );
    },
  );

  testWidgets('A1: AI lỗi thì giữ đoạn kể và gợi ý ghi tay', (tester) async {
    final ai = FakeAi(error: AiErrorReason.timeout);
    final services = await openFreeTell(tester, ai);
    services.selfControl.settings = services.selfControl.settings.copyWith(
      aiEnabled: true,
    );
    await tester.enterText(
      find.byType(TextField),
      'Hôm nay dọn bàn học và đi bộ 20 phút.',
    );
    await tester.pump();
    await tester.tap(find.text('Nhờ Tụi Nốt sắp xếp'));
    await tester.pumpAndSettle();
    // Lần đầu vẫn hỏi đồng ý (cài đặt đọc lúc mở màn).
    if (find.text('Đồng ý và sắp xếp').evaluate().isNotEmpty) {
      await tester.tap(find.text('Đồng ý và sắp xếp'));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('mạng chậm'), findsOneWidget);
    expect(find.text('Hôm nay dọn bàn học và đi bộ 20 phút.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Ghi tay'), findsOneWidget);
    expect(services.notes.notes, isEmpty);
  });

  testWidgets('A1: cần hỗ trợ thì hiện thẻ "người bạn tin"', (tester) async {
    final ai = FakeAi(
      result: const AiSortResult(
        notes: <AiNoteSuggestion>[],
        needsSupport: true,
      ),
    );
    await openFreeTell(tester, ai);
    await tester.enterText(
      find.byType(TextField),
      'Dạo này mình thấy mọi thứ vô nghĩa quá.',
    );
    await tester.pump();
    await tester.tap(find.text('Nhờ Tụi Nốt sắp xếp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng ý và sắp xếp'));
    await tester.pumpAndSettle();
    expect(find.text('Hình như hôm nay hơi nặng nề'), findsOneWidget);
    expect(find.textContaining('115'), findsOneWidget);
  });
}
