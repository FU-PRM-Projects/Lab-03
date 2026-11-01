import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/screens/jar/jar_screen.dart';
import 'package:lab03/screens/note_composer/note_composer_screen.dart';
import 'package:lab03/screens/note_detail/note_detail_screen.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

/// Flow P4, P5, T1, T2: Hũ (S05) và Chi tiết nốt (S06).
void main() {
  TestServices withNotes(List<Note> notes) =>
      TestServices()..notes.notes.addAll(notes);

  final sample = <Note>[
    sampleNote('win', DateTime(2026, 10, 24, 20)),
    sampleNote(
      'self',
      DateTime(2026, 10, 23, 23),
      type: NoteType.tuChu,
      title: 'Dừng lướt TikTok lúc 0h15',
      mood: Mood.met,
    ),
    sampleNote(
      'journal',
      DateTime(2026, 10, 21),
      type: NoteType.nhatKy,
      title: 'Vì sao tuần này mình mệt',
      mood: null,
    ),
  ];

  Future<void> openJar(WidgetTester tester) async {
    await tester.tap(findTab('Hũ'));
    await tester.pumpAndSettle();
    expect(find.byType(JarScreen), findsOneWidget);
  }

  for (final size in <Size>[phone360, phone412]) {
    testWidgets('lưới tờ nốt ở ${size.width.toInt()} dp, mới nhất trước', (
      tester,
    ) async {
      await pumpApp(tester, size: size, services: withNotes(sample));
      await openJar(tester);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('nốt tháng 10'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Chiến thắng: Dọn bàn học, gửi email hỏi thầy, Hôm nay · Ổn',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Tự chủ: Dừng lướt TikTok lúc 0h15, Hôm qua · Mệt',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Nhật ký: Vì sao tuần này mình mệt, 21/10'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('hũ rỗng: "Ghi nốt đầu tiên" mở S03 (T1)', (tester) async {
    await pumpApp(tester);
    await openJar(tester);
    expect(find.text('Hũ còn trống'), findsOneWidget);
    await tester.tap(find.text('Ghi nốt đầu tiên'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteComposerScreen), findsOneWidget);
  });

  testWidgets('lỗi tải: "Chưa tải được hũ" + Thử lại (T2)', (tester) async {
    final services = TestServices();
    services.notes.watchError = const AppException(AppErrorKind.network);
    await pumpApp(tester, services: services);
    await openJar(tester);
    expect(find.text('Chưa tải được hũ'), findsWidgets);

    services.notes.watchError = null;
    await tester.tap(find.text('Thử lại').last);
    await tester.pumpAndSettle();
    expect(find.text('Hũ còn trống'), findsOneWidget);
  });

  testWidgets('chạm tờ nốt mở S06, sửa và lưu (P5)', (tester) async {
    final services = withNotes(sample);
    await pumpApp(tester, services: services);
    await openJar(tester);
    await tester.tap(find.text('Vì sao tuần này mình mệt'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteDetailScreen), findsOneWidget);
    expect(find.text('NHẬT KÝ · 21/10'), findsOneWidget);

    await tester.tap(findTab('Sửa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Ngủ ít quá.');
    await tester.pump();
    await tester.tap(find.text('Gợi ý'));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(findTab('Sửa'), findsOneWidget);
    final saved = services.notes.notes.firstWhere((n) => n.id == 'journal');
    expect(saved.body, startsWith('Ngủ ít quá.'));
    expect(saved.body, contains('Điều gì làm bạn thấy nhẹ hơn hôm nay?'));
  });

  testWidgets('Back khi đang sửa có thay đổi → "Bỏ thay đổi?"', (tester) async {
    final services = withNotes(sample);
    await pumpApp(tester, services: services);
    await openJar(tester);
    await tester.tap(find.text('Vì sao tuần này mình mệt'));
    await tester.pumpAndSettle();
    await tester.tap(findTab('Sửa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Tiêu đề mới');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi?'), findsOneWidget);
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.byType(JarScreen), findsOneWidget);
    expect(services.notes.notes.any((n) => n.title == 'Tiêu đề mới'), isFalse);
  });

  testWidgets('xoá: dialog → về Hũ, snackbar Hoàn tác trả nốt lại (P5)', (
    tester,
  ) async {
    final services = withNotes(sample);
    await pumpApp(tester, services: services);
    await openJar(tester);
    await tester.tap(find.text('Dừng lướt TikTok lúc 0h15'));
    await tester.pumpAndSettle();

    await tester.tap(findTab('Xoá'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá nốt này?'), findsOneWidget);
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();

    expect(find.byType(JarScreen), findsOneWidget);
    expect(find.text('Dừng lướt TikTok lúc 0h15'), findsNothing);
    expect(find.text('Đã xoá nốt · còn 5 giây'), findsOneWidget);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(find.text('Dừng lướt TikTok lúc 0h15'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(services.notes.deleted, isEmpty);
  });

  testWidgets('xoá rồi để hết 5 giây: nốt bị xoá thật', (tester) async {
    final services = withNotes(sample);
    await pumpApp(tester, services: services);
    await openJar(tester);
    await tester.tap(find.text('Dừng lướt TikTok lúc 0h15'));
    await tester.pumpAndSettle();
    await tester.tap(findTab('Xoá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(services.notes.deleted, <String>['self']);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('nốt tháng 10'), findsOneWidget);
  });
}
