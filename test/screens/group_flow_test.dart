import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/app.dart';
import 'package:lab03/models/first_group.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/router/app_routes.dart';
import 'package:lab03/screens/groups/group_detail_screen.dart';
import 'package:lab03/screens/jar/jar_screen.dart';
import 'package:lab03/screens/note_saved/note_saved_screen.dart';
import 'package:lab03/services/remote_config_service.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

/// Flow G1 Nhóm lần đầu: kệ ở S05, sheet tạo nhóm, S05e, S04 "Lần đầu tiên!".
void main() {
  /// Hũ có một nốt để S05 hiện lưới (hũ rỗng là Empty state, không có kệ).
  TestServices withNote() =>
      TestServices()
        ..notes.notes.add(sampleNote('seed', DateTime(2026, 10, 22)));

  Future<void> openJar(WidgetTester tester) async {
    await tester.tap(findTab('Hũ'));
    await tester.pumpAndSettle();
    expect(find.byType(JarScreen), findsOneWidget);
  }

  Future<void> openGroup(WidgetTester tester, String id) async {
    unawaited(routerOf(tester).push(AppRoutes.groupDetail(id)));
    await tester.pumpAndSettle();
    expect(find.byType(GroupDetailScreen), findsOneWidget);
  }

  testWidgets('groups_enabled tắt: ẩn kệ Nhóm lần đầu ở hũ', (tester) async {
    final services = withNote();
    setScreenSize(tester, phone360);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...services.overrides,
          remoteConfigServiceProvider.overrideWithValue(const _NoGroups()),
        ],
        child: const NotApp(),
      ),
    );
    await tester.pumpAndSettle();
    await openJar(tester);
    expect(find.text('Nhóm lần đầu'), findsNothing);
    expect(find.text('Xem tất cả'), findsNothing);
  });

  for (final size in <Size>[phone360, phone412]) {
    testWidgets('kệ ở ${size.width.toInt()} dp: gợi ý hệ thống và Tạo mới', (
      tester,
    ) async {
      await pumpApp(tester, size: size, services: withNote());
      await openJar(tester);
      expect(find.text('Nhóm lần đầu'), findsOneWidget);
      expect(find.text('Xem tất cả'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Bắt chuyện, Tụi Nốt gợi ý'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Hỏi thầy cô, Tụi Nốt gợi ý'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('nhóm đã có nốt lên đầu kệ, kèm số nốt và ngày lần đầu', (
    tester,
  ) async {
    final services = withNote();
    services.groups.groups['bat-chuyen'] = FirstGroup(
      id: 'bat-chuyen',
      name: 'Bắt chuyện',
      idea: GroupIdea.nguoiLa,
      source: GroupSource.system,
      noteCount: 4,
      firstAt: DateTime(2026, 10, 12),
      lastAt: DateTime(2026, 10, 23),
      createdAt: DateTime(2026, 10, 12),
    );
    await pumpApp(tester, services: services);
    await openJar(tester);
    expect(
      find.bySemanticsLabel('Bắt chuyện, 4 nốt · lần đầu 12/10'),
      findsOneWidget,
    );
  });

  testWidgets('tạo nhóm: tên trùng → mở nhóm đó; tên mới → tạo và mở S05e', (
    tester,
  ) async {
    final services = await pumpApp(tester, services: withNote());
    await openJar(tester);
    await tester.drag(find.text('Bắt chuyện'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo nhóm mới'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo nhóm lần đầu'), findsOneWidget);

    await tester.enterText(findField('Lần đầu…'), 'bat chuyen');
    await tester.pump();
    expect(
      find.text('Đã có nhóm “Bắt chuyện”. Mở nhóm đó nhé?'),
      findsOneWidget,
    );
    expect(find.text('Mở “Bắt chuyện”'), findsOneWidget);

    await tester.enterText(findField('Lần đầu…'), 'Đi xe buýt một mình');
    await tester.pump();
    await tester.tap(find.text('Vận động'));
    await tester.pump();
    await tester.tap(find.text('Tạo nhóm'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupDetailScreen), findsOneWidget);
    expect(find.text('Đi xe buýt một mình'), findsOneWidget);
    expect(find.text('Ghi lần đầu'), findsOneWidget);
    final created = services.groups.groups['di-xe-buyt-mot-minh']!;
    expect(created.idea, GroupIdea.vanDong);
    expect(created.source, GroupSource.user);
  });

  testWidgets(
    'G1: Ghi lần đầu từ S05e → S04 "Lần đầu tiên!" → Xem nhóm có mốc Lần đầu',
    (tester) async {
      final services = await pumpApp(tester);
      await openGroup(tester, 'bat-chuyen');
      expect(find.text('CHƯA CÓ LẦN ĐẦU'), findsOneWidget);
      expect(find.bySemanticsLabel('Mốc Lần đầu, chưa mở'), findsOneWidget);

      await tester.tap(find.text('Ghi lần đầu'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Tâm trạng ${Mood.on.label}'));
      await tester.pump();
      await tester.tap(find.text('Tiếp'));
      await tester.pumpAndSettle();
      expect(find.text('Lần đầu cho nhóm “Bắt chuyện”'), findsOneWidget);
      await tester.enterText(
        findField('Chiến thắng nhỏ'),
        'Hỏi đường một chị ở tiệm sách',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Bỏ qua phần kể thêm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ qua phần kể thêm'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteSavedScreen), findsOneWidget);
      expect(find.text('Lần đầu tiên!'), findsOneWidget);
      expect(find.text('Nhóm “Bắt chuyện” có thêm một nấc.'), findsOneWidget);
      expect(find.text('Hôm nay · Lần đầu'), findsOneWidget);
      expect(find.text('Bắt chuyện · tới mốc Lần 3'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final note = services.notes.notes.single;
      expect(note.groupId, 'bat-chuyen');
      expect(note.isFirst, isTrue);
      final group = services.groups.groups['bat-chuyen']!;
      expect(group.noteCount, 1);
      expect(group.firstNoteId, note.id);

      await tester.tap(find.text('Xem nhóm Bắt chuyện'));
      await tester.pumpAndSettle();
      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.text('LẦN ĐẦU · 24/10'), findsOneWidget);
      expect(find.bySemanticsLabel('Mốc Lần đầu, đã mở'), findsOneWidget);
      expect(find.text('Thử lần nữa'), findsOneWidget);
    },
  );

  testWidgets('lần thứ hai vào nhóm: S04 bình thường, nốt không là lần đầu', (
    tester,
  ) async {
    final services = TestServices();
    services.groups.groups['bat-chuyen'] = FirstGroups.systemById(
      'bat-chuyen',
    )!;
    await services.groups.recordNote(
      FirstGroups.systemById('bat-chuyen')!,
      sampleNote('n0', DateTime(2026, 10, 20)),
    );
    await pumpApp(tester, services: services);
    await openGroup(tester, 'bat-chuyen');
    await tester.tap(find.text('Thử lần nữa'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tâm trạng ${Mood.vui.label}'));
    await tester.pump();
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    await tester.enterText(
      findField('Chiến thắng nhỏ'),
      'Hỏi giờ chị bán nước',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Bỏ qua phần kể thêm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ qua phần kể thêm'));
    await tester.pumpAndSettle();

    expect(find.text('Đã vào hũ!'), findsOneWidget);
    expect(services.notes.notes.single.isFirst, isFalse);
    expect(services.groups.groups['bat-chuyen']!.noteCount, 2);
  });

  testWidgets('xoá nhóm: về Hũ, hết 5 giây thì xoá và nốt rời nhóm', (
    tester,
  ) async {
    final services = TestServices();
    final group = FirstGroups.systemById('bat-chuyen')!;
    await services.groups.create(group);
    await pumpApp(tester, services: services);
    await openGroup(tester, 'bat-chuyen');

    await tester.tap(findTab('Tuỳ chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá nhóm'));
    await tester.pumpAndSettle();
    expect(find.byType(JarScreen), findsOneWidget);
    expect(
      find.text('Đã xoá nhóm “Bắt chuyện” · nốt vẫn ở trong hũ'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(services.groups.deleted, <String>['bat-chuyen']);
  });

  testWidgets('xoá nhóm rồi Hoàn tác: nhóm còn nguyên', (tester) async {
    final services = TestServices();
    await services.groups.create(FirstGroups.systemById('bat-chuyen')!);
    await pumpApp(tester, services: services);
    await openGroup(tester, 'bat-chuyen');

    await tester.tap(findTab('Tuỳ chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá nhóm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    expect(services.groups.deleted, isEmpty);
    expect(services.groups.groups, contains('bat-chuyen'));
  });
}

/// Remote Config tắt cờ nhóm lần đầu.
class _NoGroups extends InAppRemoteConfig {
  const _NoGroups();

  @override
  bool get groupsEnabled => false;
}
