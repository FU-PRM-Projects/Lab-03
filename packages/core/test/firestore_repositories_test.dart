import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_core/not_core.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreSubmissionRepository submissions;

  const card = Challenge(
    id: 'my-card',
    topic: ChallengeTopic.vanDong,
    level: 0,
    order: 0,
    title: 'Đi cầu thang thay thang máy',
    minutes: 5,
    tip: 'Từ tầng 3 trở xuống',
    mine: true,
  );

  setUp(() {
    db = FakeFirebaseFirestore();
    submissions = FirestoreSubmissionRepository(firestore: db);
  });

  test('submit ghi thẻ chờ duyệt của đúng người gửi', () async {
    final sent = await submissions.submit(uid: 'uma', card: card);
    final data =
        (await db.collection('challengeSubmissions').doc(sent.id).get())
            .data()!;
    expect(data['uid'], 'uma');
    expect(data['status'], 'pending');
    expect(data['customId'], 'my-card');
    expect(data['topic'], 'van_dong');
    final mine = await submissions.watchMine('uma').first;
    expect(mine.single.status, SubmissionStatus.pending);
  });

  test(
    'approve thêm thẻ vào kho, đánh dấu đã duyệt và để tin cho người gửi',
    () async {
      final sent = await submissions.submit(uid: 'uma', card: card);
      await submissions.approve(sent, reviewerUid: 'sam', level: 1, order: 6);

      final review =
          (await db.collection('challengeSubmissions').doc(sent.id).get())
              .data()!;
      expect(review['status'], 'approved');
      expect(review['reviewedBy'], 'sam');
      expect(review['challengeId'], 'cm-${sent.id}');

      final catalog = await FirestoreCatalogRepository(firestore: db)
          .watchAll()
          .first;
      final added = catalog.single;
      expect(added.challenge.title, card.title);
      expect(added.challenge.order, 6);
      expect(added.source, CardSource.community);
      expect(added.archived, isFalse);

      final inbox = await FirestoreInboxRepository(firestore: db)
          .watch('uma')
          .first;
      expect(inbox.single.kind, InboxKind.submissionApproved);
      expect(inbox.single.read, isFalse);
    },
  );

  test('reject cần lý do; có lý do thì người gửi nhận được lý do', () async {
    final sent = await submissions.submit(uid: 'uma', card: card);
    await expectLater(
      submissions.reject(sent, reviewerUid: 'sam', reason: '   '),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'reason-required'),
      ),
    );
    await submissions.reject(
      sent,
      reviewerUid: 'sam',
      reason: 'Trùng với thẻ có sẵn',
    );
    final mine = await submissions.watchMine('uma').first;
    expect(mine.single.status, SubmissionStatus.rejected);
    expect(mine.single.reason, 'Trùng với thẻ có sẵn');
    final inbox = await FirestoreInboxRepository(firestore: db)
        .watch('uma')
        .first;
    expect(inbox.single.body, contains('Trùng với thẻ có sẵn'));
  });

  test('lưu trữ rồi khôi phục thẻ, không xoá', () async {
    final catalog = FirestoreCatalogRepository(firestore: db);
    final id = await catalog.create(
      const CatalogDraft(
        topic: ChallengeTopic.dungCam,
        level: 1,
        order: 1,
        title: 'Hỏi giờ một người lạ',
        minutes: 2,
      ),
      staffUid: 'sam',
    );
    var cards = await catalog.watchAll().first;
    await catalog.setArchived(cards.single, true, staffUid: 'sam');
    cards = await catalog.watchAll().first;
    expect(cards.single.id, id);
    expect(cards.single.archived, isTrue);
    await catalog.setArchived(cards.single, false, staffUid: 'sam');
    expect((await catalog.watchAll().first).single.archived, isFalse);
  });

  test('vai trò lạ hoặc thiếu coi như user', () {
    expect(UserRole.fromId('admin'), UserRole.admin);
    expect(UserRole.fromId('owner'), UserRole.user);
    expect(UserRole.fromId(null).canUseAdmin, isFalse);
    expect(UserRole.staff.canUseAdmin, isTrue);
  });
}
