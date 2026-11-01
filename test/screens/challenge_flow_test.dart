import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/challenge.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/screens/challenge_detail/challenge_detail_screen.dart';
import 'package:lab03/screens/challenges/challenges_screen.dart';
import 'package:lab03/screens/note_saved/note_saved_screen.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

/// Flow F3 Thử thách trên cả app: S07 → S08 → S04, đổi thẻ dễ hơn, để mai.
void main() {
  Future<void> openChallenges(WidgetTester tester) async {
    await tester.tap(findTab('Thử thách'));
    await tester.pumpAndSettle();
    expect(find.byType(ChallengesScreen), findsOneWidget);
  }

  for (final size in <Size>[phone360, phone412]) {
    testWidgets('S07 ở ${size.width.toInt()} dp: thẻ, cấp, vuốt đổi thẻ', (
      tester,
    ) async {
      await pumpApp(tester, size: size);
      await openChallenges(tester);
      expect(find.text('Dũng cảm · cấp 1'), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
      expect(find.text('Dũng cảm cấp 1 thẻ 1'), findsOneWidget);
      expect(find.text('DŨNG CẢM · 3 PHÚT'), findsOneWidget);

      await tester.tap(findTab('Thẻ sau'));
      await tester.pumpAndSettle();
      expect(find.text('Dũng cảm cấp 1 thẻ 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('F3: Nhận → chấm hồi hộp → Xong rồi → Không như ý → S04', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await openChallenges(tester);
    await tester.tap(find.text('Nhận thử thách').first);
    await tester.pumpAndSettle();
    expect(find.byType(ChallengeDetailScreen), findsOneWidget);
    expect(find.text('Bạn hồi hộp cỡ nào?'), findsOneWidget);
    expect(find.text('“Câu mẫu 1”'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('Xong rồi'));
    await tester.pumpAndSettle();
    expect(find.text('Kết quả?'), findsOneWidget);
    await tester.tap(find.text('Không như ý'));
    await tester.pump();
    expect(find.text('Vẫn tính là dũng cảm: bạn đã mở lời.'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteSavedScreen), findsOneWidget);
    final saved = services.notes.notes.single;
    expect(saved.type, NoteType.thuThach);
    expect(saved.body, 'Mình đã mở lời.');
    expect(saved.challenge?.anxietyBefore, 3);
    expect(
      services.challenges.progress[ChallengeTopic.dungCam]?.completed,
      <String>{'dc-1-1'},
    );
  });

  testWidgets('Đổi thẻ dễ hơn: về S07 với thẻ cấp thấp hơn trên đầu', (
    tester,
  ) async {
    final services = TestServices();
    services.challenges.progress[ChallengeTopic.dungCam] =
        const ChallengeProgress(
          level: 2,
          completed: <String>{'dc-1-1', 'dc-1-2', 'dc-1-3'},
        );
    await pumpApp(tester, services: services);
    await openChallenges(tester);
    expect(find.text('Dũng cảm · cấp 2'), findsOneWidget);

    await tester.tap(find.text('Nhận thử thách').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đổi thẻ dễ hơn'));
    await tester.pumpAndSettle();

    expect(find.byType(ChallengesScreen), findsOneWidget);
    expect(find.text('THẺ DỄ HƠN'), findsOneWidget);
    expect(find.text('Dũng cảm · cấp 1'), findsOneWidget);
  });

  testWidgets('để mai: Back ở S08 về S07, thẻ giữ nguyên, không ghi gì', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await openChallenges(tester);
    await tester.tap(find.text('Nhận thử thách').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Dũng cảm cấp 1 thẻ 1'), findsOneWidget);
    expect(services.notes.notes, isEmpty);
  });

  testWidgets('P3 vận động: chỉnh số phút, Dừng sớm vẫn lưu', (tester) async {
    final services = await pumpApp(tester);
    await openChallenges(tester);
    // Ba thẻ Dũng cảm đứng trước; sang thẻ Vận động đầu tiên.
    for (var i = 0; i < 3; i++) {
      await tester.tap(findTab('Thẻ sau'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Vận động · cấp 1'), findsOneWidget);
    await tester.tap(find.text('Nhận thử thách').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(findTab('Bớt 1 phút'), 100);
    await tester.tap(findTab('Bớt 1 phút'));
    await tester.pump();
    expect(find.text('2 phút'), findsOneWidget);
    await tester.tap(find.text('Xong rồi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dừng sớm'));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteSavedScreen), findsOneWidget);
    expect(services.notes.notes.single.body, 'Mình đã ra ngoài 2 phút.');
  });

  testWidgets('lỗi tải kho thẻ: Error state + Thử lại', (tester) async {
    final services = TestServices();
    services.challenges.catalogError = const AppException(AppErrorKind.network);
    await pumpApp(tester, services: services);
    await openChallenges(tester);
    expect(find.text('Chưa tải được thẻ thử thách'), findsWidgets);

    services.challenges.catalogError = null;
    await tester.tap(find.text('Thử lại').last);
    await tester.pumpAndSettle();
    expect(find.text('Dũng cảm cấp 1 thẻ 1'), findsOneWidget);
  });
}
