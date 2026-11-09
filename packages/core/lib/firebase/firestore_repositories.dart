import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/catalog_card.dart';
import '../models/challenge.dart';
import '../models/challenge_submission.dart';
import '../models/inbox.dart';
import '../models/user_role.dart';
import '../services/app_exception.dart';
import '../services/repositories.dart';
import 'firestore_errors.dart';

/// Dữ liệu một tài liệu Firestore.
typedef JsonMap = Map<String, Object?>;

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;

/// Đổi lỗi Firebase trong stream sang [AppException].
Stream<T> _mapErrors<T>(Stream<T> source) => source.transform(
  StreamTransformer<T, T>.fromHandlers(
    handleError: (error, stack, sink) => sink.addError(
      error is FirebaseException ? firestoreException(error) : error,
      stack,
    ),
  ),
);

Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on FirebaseException catch (e) {
    throw firestoreException(e);
  }
}

String _clip(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max - 1)}…';

/// [SubmissionRepository] trên Firestore.
class FirestoreSubmissionRepository implements SubmissionRepository {
  FirestoreSubmissionRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<JsonMap> get _col =>
      _db.collection('challengeSubmissions');

  static ChallengeSubmission? fromDoc(DocumentSnapshot<JsonMap> doc) {
    final data = doc.data();
    final topic = ChallengeTopic.fromId(data?['topic'] as String?);
    final title = data?['title'];
    final uid = data?['uid'];
    if (data == null || topic == null || title is! String || uid is! String) {
      return null;
    }
    return ChallengeSubmission(
      id: doc.id,
      uid: uid,
      topic: topic,
      title: title,
      minutes: data['minutes'] as int? ?? 1,
      tip: data['tip'] as String? ?? '',
      customId: data['customId'] as String?,
      status: SubmissionStatus.fromId(data['status'] as String?),
      reason: data['reason'] as String? ?? '',
      createdAt: _date(data['createdAt']),
      reviewedAt: _date(data['reviewedAt']),
      reviewedBy: data['reviewedBy'] as String?,
      challengeId: data['challengeId'] as String?,
    );
  }

  @override
  Future<ChallengeSubmission> submit({
    required String uid,
    required Challenge card,
  }) => _guard(() async {
    final doc = _col.doc();
    final write = doc.set(<String, Object?>{
      'uid': uid,
      'topic': card.topic.id,
      'title': card.title,
      'minutes': card.minutes,
      if (card.tip.isNotEmpty) 'tip': card.tip,
      if (card.mine) 'customId': card.id,
      'status': SubmissionStatus.pending.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      await write.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // Offline: Firestore giữ lệnh ghi và gửi khi có mạng.
      write.ignore();
    }
    return ChallengeSubmission(
      id: doc.id,
      uid: uid,
      topic: card.topic,
      title: card.title,
      minutes: card.minutes,
      tip: card.tip,
      customId: card.mine ? card.id : null,
      status: SubmissionStatus.pending,
    );
  });

  List<ChallengeSubmission> _list(QuerySnapshot<JsonMap> snapshot) =>
      snapshot.docs.map(fromDoc).nonNulls.toList();

  @override
  Stream<List<ChallengeSubmission>> watchMine(String uid) => _mapErrors(
    _col
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_list),
  );

  @override
  Future<void> withdraw(String id) => _guard(() => _col.doc(id).delete());

  @override
  Stream<List<ChallengeSubmission>> watchByStatus(SubmissionStatus status) =>
      _mapErrors(
        _col
            .where('status', isEqualTo: status.id)
            .orderBy('createdAt', descending: true)
            .limit(200)
            .snapshots()
            .map(_list),
      );

  @override
  Future<void> approve(
    ChallengeSubmission submission, {
    required String reviewerUid,
    required int level,
    required int order,
  }) => _guard(() async {
    final cardId = 'cm-${submission.id}';
    final batch = _db.batch()
      ..set(_db.collection('challenges').doc(cardId), <String, Object?>{
        'topic': submission.topic.id,
        'level': level,
        'order': order,
        'title': submission.title,
        'minutes': submission.minutes,
        if (submission.tip.isNotEmpty) 'tip': submission.tip,
        'status': 'active',
        'source': CardSource.community.id,
        'submissionId': submission.id,
        'updatedBy': reviewerUid,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_col.doc(submission.id), <String, Object?>{
        'status': SubmissionStatus.approved.id,
        'reason': '',
        'challengeId': cardId,
        'reviewedBy': reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      })
      ..set(_inbox(submission.uid).doc(), <String, Object?>{
        'kind': InboxKind.submissionApproved.id,
        'title': 'Thẻ của bạn đã vào kho chung',
        'body': _clip(
          '"${submission.title}" đã được duyệt. Mọi người giờ có thể nhận '
          'thẻ này ở tab Thử thách.',
          500,
        ),
        'submissionId': submission.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  });

  @override
  Future<void> reject(
    ChallengeSubmission submission, {
    required String reviewerUid,
    required String reason,
  }) => _guard(() async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        AppErrorKind.invalidInput,
        code: 'reason-required',
      );
    }
    final batch = _db.batch()
      ..update(_col.doc(submission.id), <String, Object?>{
        'status': SubmissionStatus.rejected.id,
        'reason': _clip(trimmed, SubmissionLimits.reasonMax),
        'reviewedBy': reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      })
      ..set(_inbox(submission.uid).doc(), <String, Object?>{
        'kind': InboxKind.submissionRejected.id,
        'title': 'Thẻ của bạn chưa được duyệt',
        'body': _clip('"${submission.title}": $trimmed', 500),
        'submissionId': submission.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  });

  CollectionReference<JsonMap> _inbox(String uid) =>
      _db.collection('users').doc(uid).collection('inbox');
}

/// [CatalogRepository] trên Firestore.
class FirestoreCatalogRepository implements CatalogRepository {
  FirestoreCatalogRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<JsonMap> get _col => _db.collection('challenges');

  static CatalogCard? fromDoc(DocumentSnapshot<JsonMap> doc) {
    final data = doc.data();
    final topic = ChallengeTopic.fromId(data?['topic'] as String?);
    final title = data?['title'];
    if (data == null || topic == null || title is! String) return null;
    return CatalogCard(
      challenge: Challenge(
        id: doc.id,
        topic: topic,
        level: data['level'] as int? ?? 1,
        order: data['order'] as int? ?? 0,
        title: title,
        minutes: data['minutes'] as int? ?? 2,
        tip: data['tip'] as String? ?? '',
        script: data['script'] as String? ?? '',
        discordRoom: data['discordRoom'] as String?,
      ),
      archived: data['status'] == 'archived',
      source: CardSource.fromId(data['source'] as String?),
      submissionId: data['submissionId'] as String?,
      updatedAt: _date(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  static int _compare(CatalogCard a, CatalogCard b) {
    final x = a.challenge;
    final y = b.challenge;
    if (x.topic.index != y.topic.index) {
      return x.topic.index.compareTo(y.topic.index);
    }
    if (x.level != y.level) return x.level.compareTo(y.level);
    return x.order.compareTo(y.order);
  }

  @override
  Stream<List<CatalogCard>> watchAll() => _mapErrors(
    _col.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(fromDoc).nonNulls.toList()..sort(_compare),
    ),
  );

  JsonMap _fields(CatalogDraft draft, String staffUid) => <String, Object?>{
    'topic': draft.topic.id,
    'level': draft.level,
    'order': draft.order,
    'title': draft.title.trim(),
    'minutes': draft.minutes,
    'tip': draft.tip.trim(),
    'script': draft.script.trim(),
    'updatedBy': staffUid,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Future<String> create(CatalogDraft draft, {required String staffUid}) =>
      _guard(() async {
        final doc = _col.doc();
        await doc.set(<String, Object?>{
          ..._fields(draft, staffUid),
          'status': 'active',
          'source': CardSource.staff.id,
        });
        return doc.id;
      });

  @override
  Future<void> update(
    CatalogCard card,
    CatalogDraft draft, {
    required String staffUid,
  }) => _guard(
    () => _col.doc(card.id).update(<String, Object?>{
      ..._fields(draft, staffUid),
      // Thẻ có sẵn từ seed có thể chưa có `status`; rules đòi đủ trường.
      'status': card.archived ? 'archived' : 'active',
    }),
  );

  @override
  Future<void> setArchived(
    CatalogCard card,
    bool archived, {
    required String staffUid,
  }) => _guard(
    () => _col.doc(card.id).update(<String, Object?>{
      'status': archived ? 'archived' : 'active',
      'updatedBy': staffUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );
}

/// [AnnouncementRepository] trên Firestore.
class FirestoreAnnouncementRepository implements AnnouncementRepository {
  FirestoreAnnouncementRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<JsonMap> get _col => _db.collection('announcements');

  static Announcement? fromDoc(DocumentSnapshot<JsonMap> doc) {
    final data = doc.data();
    final title = data?['title'];
    final body = data?['body'];
    if (data == null || title is! String || body is! String) return null;
    return Announcement(
      id: doc.id,
      title: title,
      body: body,
      authorUid: data['authorUid'] as String? ?? '',
      createdAt: _date(data['createdAt']),
    );
  }

  @override
  Stream<List<Announcement>> watchLatest({int limit = 30}) => _mapErrors(
    _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromDoc).nonNulls.toList()),
  );

  @override
  Future<void> post({
    required String title,
    required String body,
    required String authorUid,
  }) => _guard(
    () => _col.add(<String, Object?>{
      'title': title.trim(),
      'body': body.trim(),
      'authorUid': authorUid,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> delete(String id) => _guard(() => _col.doc(id).delete());
}

/// [InboxRepository] trên Firestore.
class FirestoreInboxRepository implements InboxRepository {
  FirestoreInboxRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<JsonMap> _col(String uid) =>
      _db.collection('users').doc(uid).collection('inbox');

  static InboxMessage? fromDoc(DocumentSnapshot<JsonMap> doc) {
    final data = doc.data();
    final kind = InboxKind.fromId(data?['kind'] as String?);
    final title = data?['title'];
    if (data == null || kind == null || title is! String) return null;
    return InboxMessage(
      id: doc.id,
      kind: kind,
      title: title,
      body: data['body'] as String? ?? '',
      submissionId: data['submissionId'] as String?,
      read: data['read'] == true,
      createdAt: _date(data['createdAt']),
    );
  }

  @override
  Stream<List<InboxMessage>> watch(String uid) => _mapErrors(
    _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(fromDoc).nonNulls.toList()),
  );

  @override
  Future<void> markRead(String uid, String id) =>
      _guard(() => _col(uid).doc(id).update(<String, Object?>{'read': true}));
}

/// [UserDirectory] trên Firestore.
class FirestoreUserDirectory implements UserDirectory {
  FirestoreUserDirectory({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<JsonMap> get _col => _db.collection('users');

  @override
  Future<UserRole?> roleOf(String uid) => _guard(() async {
    final snapshot = await _col.doc(uid).get();
    if (!snapshot.exists) return null;
    return UserRole.fromId(snapshot.data()?['role'] as String?);
  });

  @override
  Future<void> ensureProfile(
    String uid, {
    required String displayName,
    String email = '',
  }) => _guard(() async {
    final doc = _col.doc(uid);
    if ((await doc.get()).exists) return;
    await doc.set(<String, Object?>{
      'role': UserRole.user.id,
      'displayName': displayName,
      if (email.isNotEmpty) 'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Stream<List<UserSummary>> watchAll() => _mapErrors(
    _col
        .limit(500)
        .snapshots()
        .map(
          (snapshot) => <UserSummary>[
            for (final doc in snapshot.docs)
              UserSummary(
                uid: doc.id,
                role: UserRole.fromId(doc.data()['role'] as String?),
                displayName: doc.data()['displayName'] as String? ?? '',
                email: doc.data()['email'] as String? ?? '',
              ),
          ],
        ),
  );

  @override
  Future<void> setRole(String uid, UserRole role) =>
      _guard(() => _col.doc(uid).update(<String, Object?>{'role': role.id}));
}

/// [DashboardRepository]: mỗi con số là một truy vấn `count()` (không tải tài
/// liệu về máy).
class FirestoreDashboardRepository implements DashboardRepository {
  FirestoreDashboardRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<int> _count(Query<JsonMap> query) async =>
      (await query.count().get()).count ?? 0;

  @override
  Future<DashboardStats> load() => _guard(() async {
    final users = _db.collection('users');
    final cards = _db.collection('challenges');
    final submissions = _db.collection('challengeSubmissions');
    Query<JsonMap> status(String id) =>
        submissions.where('status', isEqualTo: id);
    final counts = await Future.wait(<Future<int>>[
      _count(users),
      _count(users.where('role', whereIn: <String>['staff', 'admin'])),
      _count(cards),
      _count(cards.where('status', isEqualTo: 'archived')),
      _count(status(SubmissionStatus.pending.id)),
      _count(status(SubmissionStatus.approved.id)),
      _count(status(SubmissionStatus.rejected.id)),
      _count(_db.collection('announcements')),
      for (final topic in ChallengeTopic.values)
        _count(cards.where('topic', isEqualTo: topic.id)),
    ]);
    return DashboardStats(
      users: counts[0],
      staff: counts[1],
      cards: counts[2],
      archivedCards: counts[3],
      pending: counts[4],
      approved: counts[5],
      rejected: counts[6],
      announcements: counts[7],
      cardsByTopic: <ChallengeTopic, int>{
        for (final (i, topic) in ChallengeTopic.values.indexed)
          topic: counts[8 + i],
      },
    );
  });
}
