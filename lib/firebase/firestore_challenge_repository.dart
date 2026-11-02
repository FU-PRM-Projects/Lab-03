import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/challenge.dart';
import '../services/app_exception.dart';
import '../services/challenge_repository.dart';
import 'firestore_errors.dart';

/// [ChallengeRepository] trên Firestore. Kho thẻ đọc từ bộ nhớ đệm khi
/// offline (đã tải ít nhất một lần).
class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository({
    required this.currentUid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Uid của người đang đăng nhập; `null` khi đã đăng xuất.
  final String? Function() currentUid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> _progress() {
    final uid = currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('challengeProgress');
  }

  static Challenge? _toChallenge(DocumentSnapshot<Map<String, Object?>> doc) {
    final data = doc.data();
    final topic = ChallengeTopic.fromId(data?['topic'] as String?);
    final title = data?['title'];
    if (data == null || topic == null || title is! String) return null;
    return Challenge(
      id: doc.id,
      topic: topic,
      level: data['level'] as int? ?? 1,
      order: data['order'] as int? ?? 0,
      title: title,
      minutes: data['minutes'] as int? ?? 2,
      tip: data['tip'] as String? ?? '',
      script: data['script'] as String? ?? '',
      discordRoom: data['discordRoom'] as String?,
    );
  }

  @override
  Future<List<Challenge>> catalog() async {
    try {
      final snapshot = await _firestore.collection('challenges').get();
      return snapshot.docs.map(_toChallenge).nonNulls.toList()..sort(
        (a, b) => a.topic.index != b.topic.index
            ? a.topic.index.compareTo(b.topic.index)
            : a.level != b.level
            ? a.level.compareTo(b.level)
            : a.order.compareTo(b.order),
      );
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  @override
  Future<Challenge> get(String id) async {
    try {
      final challenge = _toChallenge(
        await _firestore.collection('challenges').doc(id).get(),
      );
      if (challenge == null) {
        throw AppException(
          AppErrorKind.notFound,
          code: 'challenge-not-found',
          detail: id,
        );
      }
      return challenge;
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  static ChallengeProgress _toProgress(Map<String, Object?>? data) =>
      ChallengeProgress(
        level: data?['level'] as int? ?? 1,
        completed: (data?['completed'] as List<Object?>? ?? const <Object?>[])
            .whereType<String>()
            .toSet(),
      );

  @override
  Future<ChallengeProgress> progressOf(ChallengeTopic topic) async {
    try {
      return _toProgress((await _progress().doc(topic.id).get()).data());
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  @override
  Stream<Map<ChallengeTopic, ChallengeProgress>> watchProgress() {
    final Stream<QuerySnapshot<Map<String, Object?>>> snapshots;
    try {
      snapshots = _progress().snapshots();
    } on AppException catch (e, stack) {
      return Stream<Map<ChallengeTopic, ChallengeProgress>>.error(e, stack);
    }
    return snapshots
        .map(
          (snapshot) => <ChallengeTopic, ChallengeProgress>{
            for (final doc in snapshot.docs)
              // Bỏ tài liệu có id không phải chủ đề đã biết.
              ?ChallengeTopic.fromId(doc.id): _toProgress(doc.data()),
          },
        )
        .transform(
          StreamTransformer<
            Map<ChallengeTopic, ChallengeProgress>,
            Map<ChallengeTopic, ChallengeProgress>
          >.fromHandlers(
            handleError: (error, stack, sink) => sink.addError(
              error is FirebaseException ? firestoreException(error) : error,
              stack,
            ),
          ),
        );
  }

  @override
  Future<void> complete(
    ChallengeTopic topic,
    String challengeId, {
    required int level,
  }) async {
    try {
      final write = _progress().doc(topic.id).set(<String, Object?>{
        'level': level,
        'completed': FieldValue.arrayUnion(<String>[challengeId]),
      }, SetOptions(merge: true));
      try {
        await write.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        // Offline: Firestore giữ lệnh ghi và gửi khi có mạng.
        write.ignore();
      }
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }
}
