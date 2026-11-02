import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/challenge.dart';
import '../models/mood.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../services/app_exception.dart';
import '../services/note_repository.dart';
import 'firestore_errors.dart';

/// [NoteRepository] trên Firestore, `users/{uid}/notes` và
/// `users/{uid}/stickers`.
///
/// Dựa vào bộ nhớ đệm offline của Firestore (deviation D-08): lệnh ghi xong
/// ngay trên máy, rồi tự gửi lên server khi có mạng.
class FirestoreNoteRepository implements NoteRepository {
  FirestoreNoteRepository({
    required this.currentUid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Uid của người đang đăng nhập; `null` khi đã đăng xuất.
  final String? Function() currentUid;
  final FirebaseFirestore _firestore;

  /// Chờ server xác nhận lệnh ghi tối đa chừng này; quá thời gian thì coi như
  /// đang offline và để Firestore tự đồng bộ sau.
  static const Duration _syncWait = Duration(seconds: 2);

  DocumentReference<Map<String, Object?>> _user() {
    final uid = currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, Object?>> _notes() =>
      _user().collection('notes');

  static Note? _toNote(DocumentSnapshot<Map<String, Object?>> doc) {
    final data = doc.data();
    final type = NoteType.fromId(data?['type'] as String?);
    final createdAt = data?['createdAt'];
    if (data == null || type == null || createdAt is! Timestamp) return null;
    return Note(
      id: doc.id,
      type: type,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      mood: Mood.fromId(data['mood'] as String?),
      createdAt: createdAt.toDate(),
      pendingSync: doc.metadata.hasPendingWrites,
      challenge: _toChallenge(data),
      groupId: data['groupId'] as String?,
      isFirst: data['isFirst'] == true,
    );
  }

  static ChallengeResult? _toChallenge(Map<String, Object?> data) {
    final id = data['challengeId'];
    final subtype = data['subtype'];
    final outcome = ChallengeOutcome.fromId(data['outcome'] as String?);
    if (id is! String || subtype is! String || outcome == null) return null;
    return ChallengeResult(
      challengeId: id,
      subtype: subtype,
      outcome: outcome,
      anxietyBefore: data['anxietyBefore'] as int?,
      anxietyAfter: data['anxietyAfter'] as int?,
      minutes: data['minutes'] as int?,
    );
  }

  static List<Note> _toNotes(QuerySnapshot<Map<String, Object?>> snapshot) =>
      snapshot.docs.map(_toNote).nonNulls.toList();

  /// Gửi lệnh ghi và chờ server tối đa [_syncWait]. Trả `true` khi lệnh ghi
  /// còn nằm trên máy.
  static Future<bool> _write(Future<void> write) async {
    try {
      await write.timeout(_syncWait);
      return false;
    } on TimeoutException {
      // Firestore vẫn giữ lệnh ghi và gửi lại khi có mạng.
      write.ignore();
      return true;
    }
  }

  Future<T> _guard<T>(Future<T> Function() task) async {
    try {
      return await task();
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  /// Theo dõi [query] (gồm cả thay đổi `hasPendingWrites`), đổi lỗi SDK
  /// sang `AppException`.
  Stream<List<Note>> _watch(Query<Map<String, Object?>> Function() query) {
    final Stream<QuerySnapshot<Map<String, Object?>>> snapshots;
    try {
      snapshots = query().snapshots(includeMetadataChanges: true);
    } on AppException catch (e, stack) {
      return Stream<List<Note>>.error(e, stack);
    }
    return snapshots
        .map(_toNotes)
        .transform(
          StreamTransformer<List<Note>, List<Note>>.fromHandlers(
            handleError: (error, stack, sink) => sink.addError(
              error is FirebaseException ? firestoreException(error) : error,
              stack,
            ),
          ),
        );
  }

  @override
  Stream<List<Note>> watchSince(DateTime since) => _watch(
    () => _notes()
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true),
  );

  @override
  Stream<List<Note>> watchRecent({int limit = 30}) => _watch(
    () => _notes().orderBy('createdAt', descending: true).limit(limit),
  );

  @override
  Future<List<Note>> list({DateTime? before, int limit = 30}) =>
      _guard(() async {
        Query<Map<String, Object?>> query = _notes().orderBy(
          'createdAt',
          descending: true,
        );
        if (before != null) {
          query = query.where(
            'createdAt',
            isLessThan: Timestamp.fromDate(before),
          );
        }
        return _toNotes(await query.limit(limit).get());
      });

  @override
  Future<int> countBetween(DateTime start, DateTime end) => _guard(() async {
    // Đếm bằng truy vấn thường thay vì count(): count() cần server, còn truy
    // vấn thường đọc được từ bộ nhớ đệm khi offline.
    final snapshot = await _notes()
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();
    return snapshot.size;
  });

  @override
  Future<Note> get(String id) => _guard(() async {
    final note = _toNote(await _notes().doc(id).get());
    if (note == null) {
      throw AppException(
        AppErrorKind.notFound,
        code: 'note-not-found',
        detail: id,
      );
    }
    return note;
  });

  @override
  Future<Note> add(NoteDraft draft, {required DateTime createdAt}) =>
      _guard(() async {
        final doc = _notes().doc();
        final body = draft.body.trim();
        final pending = await _write(
          doc.set(<String, Object?>{
            'type': draft.type.id,
            'title': draft.title.trim(),
            'body': ?(body.isEmpty ? null : body),
            'mood': ?draft.mood?.id,
            'createdAt': Timestamp.fromDate(createdAt),
            'groupId': ?draft.groupId,
            if (draft.groupId != null && draft.isFirst) 'isFirst': true,
            if (draft.challenge case final c?) ...<String, Object?>{
              'challengeId': c.challengeId,
              'subtype': c.subtype,
              'outcome': c.outcome.id,
              'anxietyBefore': ?c.anxietyBefore,
              'anxietyAfter': ?c.anxietyAfter,
              'minutes': ?c.minutes,
            },
          }),
        );
        return Note(
          id: doc.id,
          type: draft.type,
          title: draft.title.trim(),
          body: body,
          mood: draft.mood,
          createdAt: createdAt,
          pendingSync: pending,
          challenge: draft.challenge,
          groupId: draft.groupId,
          isFirst: draft.groupId != null && draft.isFirst,
        );
      });

  @override
  Future<Note> update(
    String id, {
    required String title,
    required String body,
  }) => _guard(() async {
    final doc = _notes().doc(id);
    final before = await get(id);
    final trimmed = body.trim();
    final pending = await _write(
      doc.update(<String, Object?>{
        'title': title.trim(),
        'body': trimmed.isEmpty ? FieldValue.delete() : trimmed,
      }),
    );
    return Note(
      id: id,
      type: before.type,
      title: title.trim(),
      body: trimmed,
      mood: before.mood,
      createdAt: before.createdAt,
      pendingSync: pending,
      challenge: before.challenge,
      groupId: before.groupId,
      isFirst: before.isFirst,
    );
  });

  @override
  Future<void> delete(String id) =>
      _guard(() async => _write(_notes().doc(id).delete()));

  @override
  Future<List<Note>> listByGroup(String groupId, {int limit = 30}) =>
      _guard(() async {
        final snapshot = await _notes()
            .where('groupId', isEqualTo: groupId)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        return _toNotes(snapshot);
      });

  @override
  Future<void> ungroup(String groupId) => _guard(() async {
    final snapshot = await _notes().where('groupId', isEqualTo: groupId).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, <String, Object?>{
        'groupId': FieldValue.delete(),
        'isFirst': FieldValue.delete(),
      });
    }
    await _write(batch.commit());
  });

  @override
  Future<void> saveMonthSticker(DateTime month) => _guard(() async {
    final id = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    await _write(
      _user().collection('stickers').doc(id).set(<String, Object?>{
        'month': id,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  });

  @override
  Future<List<String>> listStickers() => _guard(() async {
    final snapshot = await _user().collection('stickers').get();
    return snapshot.docs.map((doc) => doc.id).toList()
      ..sort((a, b) => b.compareTo(a));
  });
}
