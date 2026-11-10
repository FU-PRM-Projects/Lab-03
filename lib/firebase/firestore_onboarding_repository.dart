import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/onboarding.dart';
import '../services/app_exception.dart';
import '../services/onboarding_services.dart';
import 'firestore_errors.dart';

/// [OnboardingRepository] trên `users/{uid}/private/onboarding`; cấp bắt đầu
/// ghi vào `users/{uid}/challengeProgress/{topic}`.
class FirestoreOnboardingRepository implements OnboardingRepository {
  FirestoreOnboardingRepository({
    required this.currentUid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String? Function() currentUid;
  final FirebaseFirestore _firestore;

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

  DocumentReference<Map<String, Object?>> _doc() =>
      _user().collection('private').doc('onboarding');

  @override
  Stream<bool> watchDone() {
    final Stream<DocumentSnapshot<Map<String, Object?>>> snapshots;
    try {
      snapshots = _doc().snapshots();
    } on AppException catch (e, stack) {
      return Stream<bool>.error(e, stack);
    }
    return snapshots
        .map((doc) => doc.data()?['done'] == true)
        .transform(
          StreamTransformer<bool, bool>.fromHandlers(
            handleError: (error, stack, sink) => sink.addError(
              error is FirebaseException ? firestoreException(error) : error,
              stack,
            ),
          ),
        );
  }

  @override
  Future<OnboardingAnswers?> load() async {
    try {
      final data = (await _doc().get()).data();
      if (data == null) return null;
      List<Object?> list(String key) =>
          data[key] is List ? data[key]! as List<Object?> : const <Object?>[];
      return OnboardingAnswers(
        stranger: StrangerLevel.fromValue(data['strangerLevel']),
        habits: list('habits').whereType<String>().toSet(),
        move: MoveHabit.fromId(data['move']),
        freeSlot: FreeSlot.fromId(data['freeSlot']),
        goals: list('goals').map(OnboardingGoal.fromId).nonNulls.toSet(),
      );
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  @override
  Future<void> finish(OnboardingAnswers answers, StarterPlan? plan) async {
    try {
      final batch = _firestore.batch()
        ..set(_doc(), <String, Object?>{
          'strangerLevel': answers.stranger?.value,
          'habits': answers.habits.toList(),
          'move': answers.move?.id,
          'freeSlot': answers.freeSlot?.id,
          'goals': answers.goals.map((g) => g.id).toList(),
          if (plan != null) 'profileLabel': plan.profileLabel,
          if (plan != null) 'planSource': plan.fromAi ? 'ai' : 'rules',
          // `done` thay vì chỉ dựa vào `completedAt`: khi offline,
          // serverTimestamp còn null trong bộ nhớ đệm.
          'done': true,
          'completedAt': FieldValue.serverTimestamp(),
        });
      if (plan != null) {
        // Chỉ đổi giờ nhắc, giữ nguyên các cài đặt khác.
        batch.set(
          _user().collection('private').doc('settings'),
          <String, Object?>{'eveningReminder': plan.remindMinutes},
          SetOptions(merge: true),
        );
        for (final MapEntry(key: topic, value: level)
            in plan.startLevels.entries) {
          final ref = _user().collection('challengeProgress').doc(topic.id);
          final current = (await ref.get()).data()?['level'] as int? ?? 1;
          // Chỉ nâng cấp, không kéo người đã leo cao xuống lại.
          if (level > current) {
            batch.set(ref, <String, Object?>{
              'level': level,
            }, SetOptions(merge: true));
          }
        }
      }
      final write = batch.commit();
      try {
        await write.timeout(const Duration(seconds: 3));
      } on TimeoutException {
        // Offline: Firestore giữ lệnh ghi và gửi khi có mạng.
        write.ignore();
      }
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }
}
