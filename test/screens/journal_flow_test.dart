import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/screens/journal/journal_screen.dart';
import 'package:lab03/screens/note_saved/note_saved_screen.dart';
import 'package:lab03/screens/today/today_screen.dart';
import 'package:lab03/viewmodels/journal_view_model.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

/// Viết nhật ký: S02 "Ghi nốt" → chọn Viết nhật ký → viết → chọn câu → S04.
void main() {
  Future<void> openJournal(WidgetTester tester) async {
    await tester.tap(find.text('Ghi nốt'));
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay bạn muốn ghi gì?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Viết nhật ký')));
    await tester.pumpAndSettle();
    expect(find.byType(JournalScreen), findsOneWidget);
  }

  group('JournalViewModel.sentences', () {
    test('tách theo dấu câu và dòng, bỏ câu hỏi gợi ý, bỏ trùng', () {
      expect(
        JournalViewModel.sentences(
          'Mệt quá. Deadline thứ sáu!\nLúc đó mình nghĩ gì?\n'
          'Thật ra mình chưa hỏi ai cả\nMệt quá.',
        ),
        <String>[
          'Mệt quá.',
          'Deadline thứ sáu!',
          'Thật ra mình chưa hỏi ai cả',
        ],
      );
    });

    test('câu dài quá tiêu đề thì cắt ở ranh giới từ', () {
      final long = List<String>.filled(40, 'chữ').join(' ');
      final title = JournalViewModel.sentences(long).single;
      expect(title.length, lessThanOrEqualTo(NoteLimits.title));
      expect(title, endsWith('…'));
      expect(title, isNot(contains('ch…')));
    });
  });

  testWidgets('viết, chèn câu hỏi gợi ý, chọn câu rõ nhất rồi lưu', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await openJournal(tester);
    expect(
      find.text('Viết ra những suy nghĩ trong tâm trí bạn'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField),
      'Bị nhóm trưởng nhắc trước lớp.',
    );
    await tester.pump();
    await tester.tap(find.text('Bí rồi? Hỏi mình đi'));
    await tester.pump();
    await tester.tap(find.text('Lúc đó mình nghĩ gì?'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.controller!.text,
      'Bị nhóm trưởng nhắc trước lớp.\nLúc đó mình nghĩ gì?\n',
    );

    await tester.enterText(
      find.byType(TextField),
      '${field.controller!.text}Thật ra mình chưa hỏi ai cả.',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Xong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(find.text('Điều rõ ràng nhất là gì?'), findsOneWidget);
    expect(find.text('Lúc đó mình nghĩ gì?'), findsNothing);

    await tester.tap(find.text('Thật ra mình chưa hỏi ai cả.'));
    await tester.pump();
    await tester.ensureVisible(find.text('Lưu vào hũ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu vào hũ'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteSavedScreen), findsOneWidget);
    final note = services.notes.notes.single;
    expect(note.type, NoteType.nhatKy);
    expect(note.title, 'Thật ra mình chưa hỏi ai cả.');
    expect(note.body, contains('Bị nhóm trưởng nhắc trước lớp.'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chưa viết gì thì không bấm Xong được, Đóng về luôn', (
    tester,
  ) async {
    await pumpApp(tester);
    await openJournal(tester);
    final done = tester.widget<FilledButton>(
      find.ancestor(of: find.text('Xong'), matching: find.byType(FilledButton)),
    );
    expect(done.onPressed, isNull);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('đóng khi đã viết: hỏi "Bỏ trang đang viết?"', (tester) async {
    final services = await pumpApp(tester);
    await openJournal(tester);
    await tester.enterText(find.byType(TextField), 'Hôm nay rối quá.');
    await tester.pump();

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ trang đang viết?'), findsOneWidget);
    await tester.tap(find.text('Viết tiếp'));
    await tester.pumpAndSettle();
    expect(find.byType(JournalScreen), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(services.notes.notes, isEmpty);
    expect(services.journalDrafts.text, isNull);
  });

  group('nháp khi app bị tắt giữa chừng (flow P4)', () {
    testWidgets('đang gõ thì nháp được lưu trên máy', (tester) async {
      final services = await pumpApp(tester);
      await openJournal(tester);
      await tester.enterText(find.byType(TextField), 'Hôm nay rối quá.');
      await tester.pump(const Duration(seconds: 1));
      expect(services.journalDrafts.text, 'Hôm nay rối quá.');
    });

    testWidgets('mở lại: "Tiếp tục bản nháp?" → Viết tiếp điền lại chữ', (
      tester,
    ) async {
      final services = TestServices();
      services.journalDrafts.text = 'Trang viết dở hôm qua.';
      await pumpApp(tester, services: services);
      await openJournal(tester);

      expect(find.text('Tiếp tục bản nháp?'), findsOneWidget);
      await tester.tap(find.text('Viết tiếp'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Trang viết dở hôm qua.');
      expect(services.journalDrafts.text, 'Trang viết dở hôm qua.');
    });

    testWidgets('Bắt đầu trang mới: ô trống, nháp cũ bị xoá', (tester) async {
      final services = TestServices();
      services.journalDrafts.text = 'Trang viết dở hôm qua.';
      await pumpApp(tester, services: services);
      await openJournal(tester);

      await tester.tap(find.text('Bắt đầu trang mới'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(services.journalDrafts.text, isNull);
    });

    testWidgets('không có nháp thì không hỏi', (tester) async {
      await pumpApp(tester);
      await openJournal(tester);
      expect(find.text('Tiếp tục bản nháp?'), findsNothing);
    });

    testWidgets('lưu thành nốt thì nháp bị xoá', (tester) async {
      final services = TestServices();
      services.journalDrafts.text = 'Mình đã hỏi thầy.';
      await pumpApp(tester, services: services);
      await openJournal(tester);
      await tester.tap(find.text('Viết tiếp'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Xong'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lưu vào hũ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu vào hũ'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteSavedScreen), findsOneWidget);
      expect(services.notes.notes.single.title, 'Mình đã hỏi thầy.');
      expect(services.journalDrafts.text, isNull);
    });
  });
}
