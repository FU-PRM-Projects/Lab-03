import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/screens/note_composer/note_composer_screen.dart';
import 'package:lab03/screens/note_saved/note_saved_screen.dart';
import 'package:lab03/screens/today/today_screen.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

/// Flow F1 Ghi nốt buổi tối trên cả app, gồm nhánh thay thế và nhánh lỗi.
void main() {
  Future<void> openComposer(WidgetTester tester) async {
    await tester.tap(find.text('Ghi nốt'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteComposerScreen), findsOneWidget);
  }

  Future<void> pickMoodAndContinue(WidgetTester tester, Mood mood) async {
    await tester.tap(find.bySemanticsLabel('Tâm trạng ${mood.label}'));
    await tester.pump();
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
  }

  for (final size in <Size>[phone360, phone412]) {
    testWidgets(
      'happy path ở ${size.width.toInt()} dp: đủ 3 bước, S04 rồi hũ có nốt',
      (tester) async {
        final services = await pumpApp(tester, size: size);
        expect(find.text('Thứ Bảy, 24/10'), findsOneWidget);
        await openComposer(tester);
        expect(find.text('Bước 1/3'), findsOneWidget);

        await pickMoodAndContinue(tester, Mood.vui);
        expect(find.text('Bước 2/3'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Dọn bàn học');
        await tester.pump();
        await tester.tap(find.text('Tiếp'));
        await tester.pumpAndSettle();

        expect(find.text('Viết thêm vài dòng?'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Nhẹ hơn hôm qua.');
        await tester.pump();
        await tester.tap(find.text('Lưu vào hũ'));
        await tester.pumpAndSettle();

        expect(find.byType(NoteSavedScreen), findsOneWidget);
        expect(find.text('Đã vào hũ!'), findsOneWidget);
        expect(find.text('Nốt thứ 1 tháng này.'), findsOneWidget);
        expect(find.text('Mốc tháng 10 · 1/25 nốt'), findsOneWidget);
        expect(tester.takeException(), isNull);

        final saved = services.notes.notes.single;
        expect(saved.title, 'Dọn bàn học');
        expect(saved.body, 'Nhẹ hơn hôm qua.');

        await tester.tap(find.text('Về Hôm nay'));
        await tester.pumpAndSettle();
        expect(find.byType(TodayScreen), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Hũ chiến thắng, 1 nốt tháng này')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('Back ở bước 2 → "Giữ nốt đang ghi?" → Giữ nháp', (tester) async {
    final services = await pumpApp(tester);
    await openComposer(tester);
    await pickMoodAndContinue(tester, Mood.on);
    await tester.enterText(find.byType(TextField), 'Đi bộ 20 phút');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Giữ nốt đang ghi?'), findsOneWidget);
    await tester.tap(find.text('Giữ nháp'));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(services.drafts.draft?.title, 'Đi bộ 20 phút');
    expect(find.text('Tiếp tục ghi nốt'), findsOneWidget);

    // Mở lại: nháp được điền sẵn.
    await tester.tap(find.text('Tiếp tục ghi nốt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('Đi bộ 20 phút'), findsOneWidget);
  });

  testWidgets('Back ở bước 2 → Bỏ: xoá nháp, về S02', (tester) async {
    final services = await pumpApp(tester);
    services.drafts.draft = const NoteDraft(mood: Mood.on, title: 'cũ');
    await openComposer(tester);
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(services.drafts.draft, isNull);
  });

  testWidgets('ngày Rối: gợi ý sơ cứu 5-4-3-2-1', (tester) async {
    await pumpApp(tester);
    await openComposer(tester);
    await tester.tap(find.bySemanticsLabel('Tâm trạng Rối'));
    await tester.pump();
    expect(find.text('Ngày rối: 1 chip là đủ.'), findsOneWidget);
    expect(find.text('Sơ cứu 1 phút: 5-4-3-2-1'), findsOneWidget);
    expect(find.text('Làm cùng Nốt'), findsOneWidget);
  });

  testWidgets('mất mạng: vẫn tới S04 với banner Offline', (tester) async {
    final services = await pumpApp(tester);
    services.notes.offline = true;
    await openComposer(tester);
    await pickMoodAndContinue(tester, Mood.binhThuong);
    await tester.tap(find.text('Ăn đủ bữa'));
    await tester.pump();
    await tester.tap(find.text('Bỏ qua nhật ký'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteSavedScreen), findsOneWidget);
    expect(find.text('Offline · đã lưu trên máy'), findsOneWidget);
    await tester.tap(find.text('Về Hôm nay'));
    await tester.pumpAndSettle();
    expect(find.text('Offline · đã lưu trên máy'), findsOneWidget);
  });

  testWidgets('lỗi lưu: SnackBar, ở lại S03 với nội dung cũ', (tester) async {
    final services = await pumpApp(tester);
    await openComposer(tester);
    await pickMoodAndContinue(tester, Mood.on);
    await tester.enterText(find.byType(TextField), 'Đi bộ');
    await tester.pump();
    services.notes.nextError = const AppException(
      AppErrorKind.permissionDenied,
    );
    await tester.tap(find.text('Bỏ qua nhật ký'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteComposerScreen), findsOneWidget);
    expect(find.textContaining('Chưa lưu được'), findsOneWidget);
    expect(services.notes.notes, isEmpty);
    expect(services.drafts.draft?.title, 'Đi bộ');
  });

  testWidgets('S02: hôm qua Mệt thì hiện một nốt cũ (P6)', (tester) async {
    final services = TestServices();
    services.notes.notes.addAll(<Note>[
      sampleNote('old', DateTime(2026, 10, 2), title: 'Hỏi thầy Nam về đề tài'),
      sampleNote('y', DateTime(2026, 10, 23, 22), mood: Mood.met),
    ]);
    await pumpApp(tester, services: services);
    expect(find.text('Hôm qua hơi mệt. Nhớ lại lần này nhé:'), findsOneWidget);
    expect(find.text('Hỏi thầy Nam về đề tài'), findsOneWidget);
  });
}
