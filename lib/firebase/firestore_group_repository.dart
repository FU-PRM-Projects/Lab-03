import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/first_group.dart';
import '../models/image_ref.dart';
import '../models/note.dart';
import '../services/app_exception.dart';
import '../services/group_repository.dart';
import 'firestore_errors.dart';

/// [GroupRepository] trên Firestore, `users/{uid}/groups/{groupId}`.
///
/// Giống nốt, lệnh ghi xong ngay trên máy rồi tự đồng bộ (deviation D-08).
class FirestoreGroupRepository implements GroupRepository {
  FirestoreGroupRepository({
    required this.currentUid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String? Function() currentUid;
  final FirebaseFirestore _firestore;

  static const Duration _syncWait = Duration(seconds: 2);

  CollectionReference<Map<String, Object?>> _groups() {
    final uid = currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    return _firestore.collection('users').doc(uid).collection('groups');
  }

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  static FirstGroup? _toGroup(DocumentSnapshot<Map<String, Object?>> doc) {
    final data = doc.data();
    final idea = GroupIdea.fromId(data?['idea'] as String?);
    final name = data?['name'];
    if (data == null || idea == null || name is! String) return null;
    return FirstGroup(
      id: doc.id,
      name: name,
      idea: idea,
      source: GroupSource.fromId(data['source'] as String?),
      noteCount: data['noteCount'] as int? ?? 0,
      firstNoteId: data['firstNoteId'] as String?,
      firstNoteTitle: data['firstNoteTitle'] as String?,
      firstAt: _date(data['firstAt']),
      lastAt: _date(data['lastAt']),
      createdAt: _date(data['createdAt']),
      image: ImageRef.fromMap(data['image']),
    );
  }

  static Map<String, Object?> _base(FirstGroup group) => <String, Object?>{
    'name': group.name,
    'idea': group.idea.id,
    'source': group.source.id,
    'image': ?group.image?.toMap(),
  };

  static Future<void> _write(Future<void> write) async {
    try {
      await write.timeout(_syncWait);
    } on TimeoutException {
      write.ignore();
    }
  }

  Future<T> _guard<T>(Future<T> Function() task) async {
    try {
      return await task();
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  @override
  Stream<List<FirstGroup>> watchAll() {
    final Stream<QuerySnapshot<Map<String, Object?>>> snapshots;
    try {
      snapshots = _groups().snapshots();
    } on AppException catch (e, stack) {
      return Stream<List<FirstGroup>>.error(e, stack);
    }
    return snapshots
        .map(
          (snapshot) =>
              snapshot.docs.map(_toGroup).nonNulls.toList()..sort(_byRecent),
        )
        .transform(
          StreamTransformer<List<FirstGroup>, List<FirstGroup>>.fromHandlers(
            handleError: (error, stack, sink) => sink.addError(
              error is FirebaseException ? firestoreException(error) : error,
              stack,
            ),
          ),
        );
  }

  static int _byRecent(FirstGroup a, FirstGroup b) {
    final ta = a.lastAt ?? a.createdAt ?? DateTime(0);
    final tb = b.lastAt ?? b.createdAt ?? DateTime(0);
    return tb.compareTo(ta);
  }

  @override
  Future<FirstGroup?> get(String id) =>
      _guard(() async => _toGroup(await _groups().doc(id).get()));

  @override
  Future<void> create(FirstGroup group) => _guard(
    () => _write(
      _groups().doc(group.id).set(<String, Object?>{
        ..._base(group),
        'noteCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    ),
  );

  @override
  Future<void> recordNote(FirstGroup group, Note note) => _guard(
    () => _write(
      _groups().doc(group.id).set(<String, Object?>{
        ..._base(group),
        if (group.createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
        'noteCount': FieldValue.increment(1),
        'lastAt': Timestamp.fromDate(note.createdAt),
        if (note.isFirst) ...<String, Object?>{
          'firstNoteId': note.id,
          'firstNoteTitle': note.title,
          'firstAt': Timestamp.fromDate(note.createdAt),
        },
      }, SetOptions(merge: true)),
    ),
  );

  @override
  Future<void> rename(String id, String name) => _guard(
    () => _write(_groups().doc(id).update(<String, Object?>{'name': name})),
  );

  @override
  Future<void> delete(String id) =>
      _guard(() => _write(_groups().doc(id).delete()));
}
