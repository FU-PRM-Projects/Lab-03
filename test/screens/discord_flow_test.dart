import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/app.dart';
import 'package:lab03/models/challenge.dart';
import 'package:lab03/models/first_group.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/router/app_routes.dart';
import 'package:lab03/screens/challenge_detail/challenge_detail_screen.dart';
import 'package:lab03/screens/challenge_detail/greeting_screen.dart';
import 'package:lab03/screens/discord/discord_rooms_screen.dart';
import 'package:lab03/screens/note_saved/note_saved_screen.dart';
import 'package:lab03/services/remote_config_service.dart';
import 'package:lab03/viewmodels/challenges_view_model.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

class _NoDiscord extends InAppRemoteConfig {
  const _NoDiscord();

  @override
  bool get discordEnabled => false;
}

const String _invite = InAppRemoteConfig.defaultDiscordInviteUrl;

const Challenge _chaoHoi = Challenge(
  id: 'dc-3-1',
  topic: ChallengeTopic.dungCam,
  level: 3,
  order: 1,
  title: 'Chào 1 câu ở phòng chung',
  minutes: 2,
  tip: 'Dùng biệt danh, không cần tên thật.',
  script: 'Chào mọi người, mình đang tập bắt chuyện!',
  discordRoom: 'chao_hoi',
);

/// Kết nối Discord (D1, D2): S12 → S14 → S14b → Discord; S08 cấp 3 → S08d →
/// Discord → S08 "Bạn vừa ghé phòng chung" → S04.
void main() {
  late List<String> clipboard;

  setUp(() {
    clipboard = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add(
              (call.arguments as Map<Object?, Object?>)['text']! as String,
            );
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> openRooms(WidgetTester tester) async {
    routerOf(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Phòng trò chuyện'), 100);
    await tester.tap(find.text('Phòng trò chuyện'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscordRoomsScreen), findsOneWidget);
  }

  test('discord_enabled tắt: bỏ thẻ làm trên Discord khỏi kho', () {
    final catalog = <Challenge>[...sampleCatalog(), _chaoHoi];
    expect(
      ChallengeDeck.available(catalog, discord: false),
      isNot(contains(_chaoHoi)),
    );
    expect(ChallengeDeck.available(catalog, discord: true), contains(_chaoHoi));
    expect(_chaoHoi.label, 'DŨNG CẢM · CẤP 3 · DISCORD');
  });

  testWidgets('S14: phòng của nhóm đã có nốt lên trước, kèm số nốt', (
    tester,
  ) async {
    final services = TestServices();
    services.groups.groups['hoi-thay-co'] = const FirstGroup(
      id: 'hoi-thay-co',
      name: 'Hỏi thầy cô',
      idea: GroupIdea.nguoiLa,
      source: GroupSource.system,
      noteCount: 2,
    );
    await pumpApp(tester, services: services);
    await openRooms(tester);

    expect(find.text('PHÒNG CỦA NHÓM BẠN'), findsOneWidget);
    expect(find.text('Nhóm Hỏi thầy cô · 2 nốt'), findsOneWidget);
    expect(find.text('#lan-dau-bat-chuyen'), findsOneWidget);
    expect(find.text('#chao-hoi'), findsOneWidget);
    expect(find.text('Voice tối thứ Sáu'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('#hoi-thay-co')).dy,
      lessThan(tester.getTopLeft(find.text('#lan-dau-bat-chuyen')).dy),
    );
  });

  testWidgets('lần đầu mở phòng: S14b rồi mới mở Discord; lần sau mở luôn', (
    tester,
  ) async {
    final services = await pumpApp(tester);
    await openRooms(tester);

    await tester.tap(find.text('#chao-hoi'));
    await tester.pumpAndSettle();
    expect(find.text('Trước khi vào phòng'), findsOneWidget);
    expect(find.text('Discord yêu cầu từ 13 tuổi trở lên'), findsOneWidget);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(services.discord.opened, isEmpty);
    expect(services.discord.seen, isFalse);

    await tester.tap(find.text('#chao-hoi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mình hiểu, mở Discord'));
    await tester.pumpAndSettle();
    expect(services.discord.opened, <String>[_invite]);
    expect(services.discord.seen, isTrue);

    await tester.tap(find.text('#chao-hoi'));
    await tester.pumpAndSettle();
    expect(find.text('Trước khi vào phòng'), findsNothing);
    expect(services.discord.opened, hasLength(2));
  });

  testWidgets('không mở được Discord: "Mở bằng web" hoặc "Sao chép"', (
    tester,
  ) async {
    final services = TestServices();
    services.discord
      ..seen = true
      ..appWorks = false;
    await pumpApp(tester, services: services);
    await openRooms(tester);

    await tester.tap(find.text('#chao-hoi'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa mở được Discord'), findsOneWidget);
    await tester.tap(find.text('Mở bằng web'));
    await tester.pumpAndSettle();
    expect(services.discord.opened, <String>['$_invite (web)']);

    await tester.tap(find.text('#chao-hoi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sao chép'));
    await tester.pumpAndSettle();
    expect(clipboard, <String>[_invite]);
    expect(find.text('Đã sao chép link phòng'), findsOneWidget);
  });

  testWidgets('discord_enabled tắt: không có lối vào ở Cài đặt', (
    tester,
  ) async {
    final services = TestServices();
    setScreenSize(tester, phone360);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...services.overrides,
          remoteConfigServiceProvider.overrideWithValue(const _NoDiscord()),
        ],
        child: const NotApp(),
      ),
    );
    await tester.pumpAndSettle();
    routerOf(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();
    expect(find.text('Phòng trò chuyện'), findsNothing);
  });

  testWidgets(
    'thẻ cấp 3: Mở #chao-hoi → câu chào → Discord → quay lại → ghi nốt',
    (tester) async {
      final services = TestServices();
      services.discord.seen = true;
      services.challenges.cards.add(_chaoHoi);
      await pumpApp(tester, services: services);
      routerOf(tester).go(AppRoutes.challengeDetail(_chaoHoi.id));
      await tester.pumpAndSettle();
      expect(find.byType(ChallengeDetailScreen), findsOneWidget);
      expect(find.text('DŨNG CẢM · CẤP 3 · DISCORD'), findsOneWidget);
      expect(find.text('Xong rồi'), findsNothing);
      await tester.tap(find.text('4'));
      await tester.pump();

      await tester.tap(find.text('Mở #chao-hoi'));
      await tester.pumpAndSettle();
      expect(find.byType(GreetingScreen), findsOneWidget);
      expect(find.text('Tụi Nốt đang nghỉ một chút'), findsOneWidget);
      await tester.tap(find.text('Hi cả phòng, mình đang tập bắt chuyện.'));
      await tester.pump();

      await tester.ensureVisible(find.text('Sao chép và mở #chao-hoi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sao chép và mở #chao-hoi'));
      await tester.pumpAndSettle();
      expect(clipboard, <String>['Hi cả phòng, mình đang tập bắt chuyện.']);
      expect(services.discord.opened, <String>[_invite]);

      // Người dùng rời app sang Discord rồi quay lại.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Bạn vừa ghé phòng chung'), findsOneWidget);
      expect(find.text('Sau đó bạn thấy sao?'), findsOneWidget);
      await tester.tap(find.text('2'));
      await tester.pump();

      await tester.ensureVisible(find.text('Mình đã chào, ghi nốt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mình đã chào, ghi nốt'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteSavedScreen), findsOneWidget);
      final note = services.notes.notes.single;
      expect(note.type, NoteType.thuThach);
      expect(note.body, 'Mình đã chào ở phòng chung.');
      expect(note.challenge?.outcome, ChallengeOutcome.smooth);
      expect(note.challenge?.anxietyBefore, 4);
      expect(note.challenge?.anxietyAfter, 2);
    },
  );

  testWidgets('thẻ cấp 3: "Để mai" quay lại, không ghi gì', (tester) async {
    final services = TestServices();
    services.challenges.cards.add(_chaoHoi);
    await pumpApp(tester, services: services);
    routerOf(tester).go(AppRoutes.challenges);
    await tester.pumpAndSettle();
    unawaited(routerOf(tester).push(AppRoutes.challengeDetail(_chaoHoi.id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Để mai'));
    await tester.pumpAndSettle();
    expect(find.byType(ChallengeDetailScreen), findsNothing);
    expect(services.notes.notes, isEmpty);
  });

  testWidgets(
    'liên kết Discord bằng mã 6 ký tự từ bot DM (ràng buộc 1-1) và ngắt kết nối',
    (tester) async {
      final services = await pumpApp(tester);
      routerOf(tester).go(AppRoutes.settings);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Liên kết Discord'), 100);
      await tester.ensureVisible(find.text('Liên kết Discord'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Liên kết Discord'));
      await tester.pumpAndSettle();

      // Nhập mã sai -> báo lỗi
      await tester.enterText(findField('Mã kết nối'), 'WRONG1');
      await tester.pump();
      await tester.tap(find.text('Kết nối'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Mã không tồn tại hoặc đã được sử dụng'),
        findsOneWidget,
      );

      // Nhập mã đúng ABC123 -> liên kết thành công 1-1
      await tester.enterText(findField('Mã kết nối'), 'abc123');
      await tester.pump();
      await tester.tap(find.text('Kết nối'));
      await tester.pumpAndSettle();

      expect(services.discord.link?.discordId, '123456789012345678');
      expect(
        find.text('Đã liên kết với Discord: Minh (@minh_discord)'),
        findsOneWidget,
      );
      expect(find.text('Minh (@minh_discord)'), findsOneWidget);
      expect(find.text('Đã kết nối'), findsOneWidget);

      // Mở lại sheet -> hiện thông tin đã liên kết và cho phép ngắt liên kết
      await tester.tap(find.text('Liên kết Discord'));
      await tester.pumpAndSettle();
      expect(find.text('Đã liên kết Discord'), findsOneWidget);
      expect(find.text('Discord ID: 123456789012345678'), findsOneWidget);

      await tester.tap(find.text('Ngắt liên kết'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngắt liên kết').last);
      await tester.pumpAndSettle();

      expect(services.discord.link, isNull);
      expect(find.text('Đã ngắt liên kết Discord.'), findsOneWidget);
    },
  );
}
