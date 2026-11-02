import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/challenge.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/challenge_repository.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/viewmodels/challenge_detail_view_model.dart';
import 'package:lab03/viewmodels/challenges_view_model.dart';
import 'package:lab03/viewmodels/view_state.dart';

import '../support/fakes.dart';

/// Flow F3 (và P3 vận động): S07 chồng thẻ, S08 làm thử thách.
void main() {
  final catalog = sampleCatalog();
  Challenge card(String id) => catalog.firstWhere((c) => c.id == id);

  group('ChallengeDeck', () {
    test('thẻ chưa làm ở cấp hiện tại; Dũng cảm trước khi hôm qua ổn', () {
      final deck = ChallengeDeck.build(
        catalog: catalog,
        progress: <ChallengeTopic, ChallengeProgress>{
          ChallengeTopic.dungCam: const ChallengeProgress(
            completed: <String>{'dc-1-1'},
          ),
        },
        lowYesterday: false,
      );
      expect(deck.map((c) => c.challenge.id), <String>[
        'dc-1-2',
        'dc-1-3',
        'vd-1-1',
        'vd-1-2',
        'vd-1-3',
      ]);
      expect(deck.first.header, 'Dũng cảm · cấp 1');
      expect((deck.first.levelDone, deck.first.levelTotal), (1, 3));
    });

    test('hôm qua Mệt / Rối: Vận động lên trước', () {
      final deck = ChallengeDeck.build(
        catalog: catalog,
        progress: const <ChallengeTopic, ChallengeProgress>{},
        lowYesterday: true,
      );
      expect(deck.first.challenge.topic, ChallengeTopic.vanDong);
    });

    test('làm hết một cấp thì mở cấp sau; hết thẻ thì rỗng', () {
      final allLevel1 = <String>{'dc-1-1', 'dc-1-2', 'dc-1-3'};
      expect(
        ChallengeDeck.levelAfter(
          card('dc-1-3'),
          const ChallengeProgress(completed: <String>{'dc-1-1', 'dc-1-2'}),
          catalog,
        ),
        2,
      );
      final deck = ChallengeDeck.build(
        catalog: catalog,
        progress: <ChallengeTopic, ChallengeProgress>{
          ChallengeTopic.dungCam: ChallengeProgress(completed: allLevel1),
        },
        lowYesterday: false,
      );
      expect(deck.first.challenge.id, 'dc-2-1');

      final done = ChallengeDeck.build(
        catalog: catalog,
        progress: <ChallengeTopic, ChallengeProgress>{
          for (final topic in ChallengeTopic.values)
            topic: ChallengeProgress(
              level: 2,
              completed: catalog
                  .where((c) => c.topic == topic)
                  .map((c) => c.id)
                  .toSet(),
            ),
        },
        lowYesterday: false,
      );
      expect(done, isEmpty);
    });

    test('thẻ tự thêm: chưa làm hôm nay lên đầu, đã làm thì xuống cuối', () {
      const open = Challenge(
        id: 'my-1',
        topic: ChallengeTopic.dungCam,
        level: 0,
        order: 0,
        title: 'Nhắn lời cảm ơn',
        minutes: 2,
        mine: true,
      );
      const done = Challenge(
        id: 'my-2',
        topic: ChallengeTopic.vanDong,
        level: 0,
        order: 0,
        title: 'Đi bộ 10 phút',
        minutes: 10,
        mine: true,
      );
      final deck = ChallengeDeck.build(
        catalog: catalog,
        progress: const <ChallengeTopic, ChallengeProgress>{},
        lowYesterday: false,
        mine: <Challenge>[done, open],
        doneToday: <String>{'my-2'},
      );
      expect(deck.first.challenge.id, 'my-1');
      expect(deck.first.header, 'Của bạn · Dũng cảm');
      expect(deck.first.challenge.label, 'CỦA BẠN · DŨNG CẢM · 2 PHÚT');
      expect(deck.last.challenge.id, 'my-2');
      expect(deck.last.doneToday, isTrue);
      final withoutMine = ChallengeDeck.build(
        catalog: catalog,
        progress: const <ChallengeTopic, ChallengeProgress>{},
        lowYesterday: false,
      );
      expect(deck.length, withoutMine.length + 2);
    });

    test('thẻ dễ hơn: cấp thấp hơn cùng chủ đề, không có thì null', () {
      expect(ChallengeDeck.easierThan(card('dc-2-2'), catalog)?.level, 1);
      expect(ChallengeDeck.easierThan(card('dc-1-1'), catalog), isNull);
      // Cùng cấp 1: thẻ ít phút hơn.
      expect(ChallengeDeck.easierThan(card('vd-1-3'), catalog)?.id, 'vd-1-1');
    });
  });

  group('ViewModel', () {
    late FakeNoteRepository notes;
    late FakeChallengeRepository challenges;

    ProviderContainer makeContainer() {
      final c = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            FakeAuthService(signedIn: testUser),
          ),
          noteRepositoryProvider.overrideWithValue(notes),
          challengeRepositoryProvider.overrideWithValue(challenges),
          clockProvider.overrideWithValue(FixedClock()),
        ],
      );
      addTearDown(c.dispose);
      c.listen(challengesViewModelProvider, (_, _) {});
      return c;
    }

    List<DeckCard> deck(ProviderContainer c) =>
        (c.read(challengesViewModelProvider) as Data<List<DeckCard>>).value;

    setUp(() {
      notes = FakeNoteRepository();
      challenges = FakeChallengeRepository();
    });

    test('S07: hôm qua Rối thì thẻ đầu là Vận động', () async {
      notes.notes.add(
        sampleNote('y', DateTime(2026, 10, 23, 22), mood: Mood.roi),
      );
      final c = makeContainer();
      await pumpEventQueue();
      expect(deck(c).first.challenge.topic, ChallengeTopic.vanDong);
    });

    test('S07 thẻ tự thêm: lên đầu chồng; làm xong không đổi tiến độ cấp, '
        'xuống cuối và có dấu "đã làm hôm nay"', () async {
      final c = makeContainer();
      await pumpEventQueue();
      final added = await c
          .read(challengesViewModelProvider.notifier)
          .addMine(
            topic: ChallengeTopic.dungCam,
            title: '  Nhắn lời cảm ơn ',
            minutes: 2,
          );
      await pumpEventQueue();
      expect(added.mine, isTrue);
      expect(deck(c).first.challenge.id, added.id);
      expect(deck(c).first.challenge.title, 'Nhắn lời cảm ơn');

      c.listen(challengeDetailViewModelProvider(added.id), (_, _) {});
      await pumpEventQueue();
      await c
          .read(challengeDetailViewModelProvider(added.id).notifier)
          .save(ChallengeOutcome.smooth, '');
      await pumpEventQueue();

      final saved = notes.notes.single;
      expect(saved.challenge?.challengeId, added.id);
      expect(saved.challenge?.subtype, 'nguoi_la');
      expect(challenges.progress, isEmpty);
      expect(deck(c).last.challenge.id, added.id);
      expect(deck(c).last.doneToday, isTrue);
    });

    test('S07 thẻ tự thêm: tên trống hoặc quá dài bị từ chối, xoá thì mất '
        'khỏi chồng', () async {
      final c = makeContainer();
      await pumpEventQueue();
      final vm = c.read(challengesViewModelProvider.notifier);
      expect(
        () =>
            vm.addMine(topic: ChallengeTopic.dungCam, title: '  ', minutes: 2),
        throwsA(isA<AppException>()),
      );
      expect(
        () => vm.addMine(
          topic: ChallengeTopic.dungCam,
          title: 'a' * (CustomChallengeLimits.titleMax + 1),
          minutes: 2,
        ),
        throwsA(isA<AppException>()),
      );
      expect(challenges.mine, isEmpty);

      final added = await vm.addMine(
        topic: ChallengeTopic.vanDong,
        title: 'Giãn cơ 5 phút',
        minutes: 5,
      );
      await pumpEventQueue();
      expect(deck(c).any((d) => d.challenge.id == added.id), isTrue);
      await vm.deleteMine(added.id);
      await pumpEventQueue();
      expect(deck(c).any((d) => d.challenge.id == added.id), isFalse);
    });

    test('S07 thẻ tự thêm: đủ giới hạn thì không thêm nữa', () async {
      final c = makeContainer();
      await pumpEventQueue();
      final vm = c.read(challengesViewModelProvider.notifier);
      for (var i = 0; i < CustomChallengeLimits.count; i++) {
        await vm.addMine(
          topic: ChallengeTopic.dungCam,
          title: 'Việc nhỏ $i',
          minutes: 1,
        );
        await pumpEventQueue();
      }
      expect(
        () => vm.addMine(
          topic: ChallengeTopic.dungCam,
          title: 'Một việc nữa',
          minutes: 1,
        ),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'challenge-limit'),
        ),
      );
    });

    test('S07: lỗi tải kho thẻ → Error state', () async {
      challenges.catalogError = const AppException(AppErrorKind.network);
      final c = makeContainer();
      await pumpEventQueue();
      expect(
        c.read(challengesViewModelProvider),
        isA<Failure<List<DeckCard>>>(),
      );
    });

    Future<ProviderContainer> openDetail(String id) async {
      final c = makeContainer()
        ..listen(challengeDetailViewModelProvider(id), (_, _) {});
      await pumpEventQueue();
      return c;
    }

    test(
      'S08 Suôn sẻ: nốt thử thách có mức hồi hộp, thẻ được đánh dấu',
      () async {
        final c = await openDetail('dc-1-1');
        final vm = c.read(challengeDetailViewModelProvider('dc-1-1').notifier)
          ..setAnxiety(4);
        await vm.save(ChallengeOutcome.smooth, ' Nhẹ người ');
        await pumpEventQueue();

        final saved = notes.notes.single;
        expect(saved.type, NoteType.thuThach);
        expect(saved.title, 'Dũng cảm cấp 1 thẻ 1');
        expect(saved.body, 'Nhẹ người');
        expect(saved.challenge?.subtype, 'nguoi_la');
        expect(saved.challenge?.anxietyBefore, 4);
        expect(saved.challenge?.minutes, isNull);
        expect(challenges.progress[ChallengeTopic.dungCam]?.completed, <String>{
          'dc-1-1',
        });
        expect(
          c.read(challengeDetailViewModelProvider('dc-1-1')).savedNoteId,
          saved.id,
        );
        // S07 bỏ thẻ vừa làm khỏi chồng.
        expect(deck(c).any((d) => d.challenge.id == 'dc-1-1'), isFalse);
      },
    );

    test(
      'S08 Không như ý: ghi "Mình đã mở lời." và vẫn tính là đã làm',
      () async {
        final c = await openDetail('dc-1-2');
        await c
            .read(challengeDetailViewModelProvider('dc-1-2').notifier)
            .save(ChallengeOutcome.notAsHoped, '');
        expect(notes.notes.single.body, 'Mình đã mở lời.');
        expect(
          notes.notes.single.challenge?.outcome,
          ChallengeOutcome.notAsHoped,
        );
        expect(
          challenges.progress[ChallengeTopic.dungCam]?.completed,
          contains('dc-1-2'),
        );
      },
    );

    test('P3 vận động dừng sớm: lưu số phút thực tế', () async {
      final c = await openDetail('vd-1-3');
      final vm = c.read(challengeDetailViewModelProvider('vd-1-3').notifier);
      expect(
        c.read(challengeDetailViewModelProvider('vd-1-3')).minutes,
        card('vd-1-3').minutes,
      );
      vm.setMinutes(4);
      await vm.save(ChallengeOutcome.notAsHoped, '');
      expect(notes.notes.single.body, 'Mình đã ra ngoài 4 phút.');
      expect(notes.notes.single.challenge?.minutes, 4);
      expect(notes.notes.single.challenge?.subtype, 'van_dong');
    });

    test('làm thẻ cuối của cấp: lên cấp 2', () async {
      challenges.progress[ChallengeTopic.dungCam] = const ChallengeProgress(
        completed: <String>{'dc-1-1', 'dc-1-2'},
      );
      final c = await openDetail('dc-1-3');
      await c
          .read(challengeDetailViewModelProvider('dc-1-3').notifier)
          .save(ChallengeOutcome.smooth, '');
      await pumpEventQueue();
      expect(challenges.progress[ChallengeTopic.dungCam]?.level, 2);
      expect(deck(c).first.challenge.id, 'dc-2-1');
    });

    test(
      'Đổi thẻ dễ hơn: thẻ dễ hơn lên đầu S07; thẻ dễ nhất thì báo',
      () async {
        final c = await openDetail('dc-2-2');
        final vm = c.read(challengeDetailViewModelProvider('dc-2-2').notifier);
        expect(await vm.showEasier(), isTrue);
        expect(deck(c).first.easier, isTrue);
        expect(deck(c).first.challenge.level, 1);

        c.listen(challengeDetailViewModelProvider('dc-1-1'), (_, _) {});
        await pumpEventQueue();
        expect(
          await c
              .read(challengeDetailViewModelProvider('dc-1-1').notifier)
              .showEasier(),
          isFalse,
        );
      },
    );
  });
}
