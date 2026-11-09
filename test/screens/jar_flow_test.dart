import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/app.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/screens/jar/jar_screen.dart';
import 'package:lab03/screens/note_composer/note_composer_screen.dart';
import 'package:lab03/screens/note_detail/note_detail_screen.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/viewmodels/note_wall_view_model.dart';
import 'package:lab03/widgets/note_card.dart';
import 'package:lab03/widgets/note_tile.dart';
import 'package:lab03/widgets/shake_jar.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

class _TestWall extends NoteWallViewModel {
  _TestWall(this.pins);

  final Map<String, DateTime> pins;

  @override
  Future<Map<String, DateTime>> build() async => pins;

  @override
  Future<void> release(String id, DateTime expires) async {
    state = AsyncData(Map.of(pins)..remove(id));
  }
}

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

  /// Cuộn lưới dọc của S05 (không phải kệ hay chip cuộn ngang) tới [finder].
  /// Về đầu S05 (tới kệ "Nhóm lần đầu") rồi cuộn xuống tới [finder], vì
  /// [finder] có thể đã bị cuộn qua. Không fling: kéo quá đầu sẽ làm mới hũ.
  Future<void> scrollJarTo(WidgetTester tester, Finder finder) async {
    final vertical = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Nhóm lần đầu'),
      -200,
      scrollable: vertical,
    );
    await tester.scrollUntilVisible(finder, 200, scrollable: vertical);
    await tester.pumpAndSettle();
  }

  Future<void> openJar(WidgetTester tester) async {
    await tester.tap(findTab('Hũ'));
    await tester.pumpAndSettle();
    expect(find.byType(JarScreen), findsOneWidget);
  }

  testWidgets('chạm hũ làm bật nốt để đọc lại', (tester) async {
    await pumpApp(tester, services: withNotes([sample.first]));
    await openJar(tester);

    await tester.tap(find.byType(ShakeJar));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Một nốt bật ra!'), findsOneWidget);

    await tester.tap(find.text('Chạm để đọc lại'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteDetailScreen), findsOneWidget);
  });

  testWidgets('nốt hết hạn rời tường và xuất hiện lại trong hũ', (
    tester,
  ) async {
    final services = withNotes([sample.first]);
    final expiry = services.clock.current.add(const Duration(days: 2));
    setScreenSize(tester, phone360);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...services.overrides,
          noteWallProvider.overrideWith(
            () => _TestWall({sample.first.id: expiry}),
          ),
        ],
        child: const NotApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('Tường nốt'), findsOneWidget);
    expect(find.text('Đang dán trên tường'), findsOneWidget);

    services.clock.current = expiry;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Tường nốt'), findsNothing);

    await openJar(tester);
    expect(find.text(sample.first.title), findsOneWidget);
  });

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
          'Chiến thắng: Dọn bàn học, gửi email hỏi thầy, Ổn',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Tự chủ: Dừng lướt TikTok lúc 0h15, Mệt'),
        findsOneWidget,
      );
      // Nhóm theo mốc thời gian, mỗi nhóm có số nốt.
      expect(find.bySemanticsLabel('Hôm nay, 1 nốt'), findsOneWidget);
      expect(find.bySemanticsLabel('Hôm qua, 1 nốt'), findsOneWidget);
      await scrollJarTo(tester, find.text('Vì sao tuần này mình mệt'));
      expect(find.bySemanticsLabel('Tuần này, 1 nốt'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Nhật ký: Vì sao tuần này mình mệt, 21/10'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('chip lọc loại và nút đổi sang danh sách gọn', (tester) async {
    await pumpApp(tester, services: withNotes(sample));
    await openJar(tester);
    await tester.ensureVisible(find.text('Tự chủ').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tự chủ'));
    await tester.pumpAndSettle();
    expect(find.text('Dừng lướt TikTok lúc 0h15'), findsOneWidget);
    expect(find.text('Dọn bàn học, gửi email hỏi thầy'), findsNothing);

    // Hàng chip cuộn ngang: đưa "Tất cả" vào khung trước khi chạm.
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tất cả'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
    await tester.pumpAndSettle();
    await tester.tap(findTab('Xem dạng danh sách'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteTile), findsNothing);
    await scrollJarTo(tester, find.text('Dừng lướt TikTok lúc 0h15'));
    expect(
      find.bySemanticsLabel('Dừng lướt TikTok lúc 0h15, Tự chủ · Mệt'),
      findsOneWidget,
    );
    await scrollJarTo(tester, find.text('Vì sao tuần này mình mệt'));
    expect(find.byType(NoteTile), findsNothing);
    expect(find.byType(NoteCard), findsWidgets);

    await tester.tap(findTab('Xem dạng lưới'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsNothing);
    expect(find.byType(NoteTile), findsWidgets);
  });

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
    await tapNote(tester, 'Vì sao tuần này mình mệt');
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
    await tapNote(tester, 'Vì sao tuần này mình mệt');
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
    await tapNote(tester, 'Dừng lướt TikTok lúc 0h15');
    await tester.pumpAndSettle();

    await tester.tap(findTab('Tuỳ chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá nốt'));
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
    await tapNote(tester, 'Dừng lướt TikTok lúc 0h15');
    await tester.pumpAndSettle();
    await tester.tap(findTab('Tuỳ chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá nốt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(services.notes.deleted, <String>['self']);
    // Về đầu hũ để thấy số đếm.
    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, 2000),
      2000,
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('nốt tháng 10'), findsOneWidget);
  });
}
