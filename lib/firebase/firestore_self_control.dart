import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/self_control.dart';
import '../services/app_exception.dart';
import '../services/self_control_services.dart';
import 'firestore_errors.dart';

/// Tài liệu riêng tư `users/{uid}/private/{name}` (thói quen, cài đặt).
class _PrivateDoc {
  _PrivateDoc(this._currentUid, this._firestore, this._name);

  final String? Function() _currentUid;
  final FirebaseFirestore _firestore;
  final String _name;

  DocumentReference<Map<String, Object?>> get ref {
    final uid = _currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc(_name);
  }

  Stream<T> watch<T>(T Function(Map<String, Object?> data) parse) {
    final Stream<DocumentSnapshot<Map<String, Object?>>> snapshots;
    try {
      snapshots = ref.snapshots();
    } on AppException catch (e, stack) {
      return Stream<T>.error(e, stack);
    }
    return snapshots
        .map((doc) => parse(doc.data() ?? const <String, Object?>{}))
        .transform(
          StreamTransformer<T, T>.fromHandlers(
            handleError: (error, stack, sink) => sink.addError(
              error is FirebaseException ? firestoreException(error) : error,
              stack,
            ),
          ),
        );
  }

  /// Ghi gộp; không chờ server quá 2 giây (offline vẫn ghi vào bộ nhớ đệm,
  /// giống `FirestoreNoteRepository`).
  Future<void> merge(Map<String, Object?> data) async {
    final write = ref.set(data, SetOptions(merge: true));
    try {
      await write.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      write.ignore();
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }
}

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : const <String>[];

/// [HabitRepository] trên `users/{uid}/private/habits`.
class FirestoreHabitRepository implements HabitRepository {
  FirestoreHabitRepository({
    required String? Function() currentUid,
    FirebaseFirestore? firestore,
  }) : _doc = _PrivateDoc(
         currentUid,
         firestore ?? FirebaseFirestore.instance,
         'habits',
       );

  final _PrivateDoc _doc;

  @override
  Stream<HabitList> watch() => _doc.watch(
    (data) => HabitList(
      selected: _strings(data['selected']).toSet(),
      custom: _strings(data['custom']),
    ),
  );

  @override
  Future<void> setSelected(String habit, {required bool selected}) =>
      _doc.merge(<String, Object?>{
        'selected': selected
            ? FieldValue.arrayUnion(<String>[habit])
            : FieldValue.arrayRemove(<String>[habit]),
      });

  @override
  Future<void> addCustom(String habit) => _doc.merge(<String, Object?>{
    'custom': FieldValue.arrayUnion(<String>[habit]),
    'selected': FieldValue.arrayUnion(<String>[habit]),
  });
}

/// [SettingsRepository] trên `users/{uid}/private/settings`.
class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository({
    required String? Function() currentUid,
    FirebaseFirestore? firestore,
  }) : _doc = _PrivateDoc(
         currentUid,
         firestore ?? FirebaseFirestore.instance,
         'settings',
       );

  final _PrivateDoc _doc;

  @override
  Stream<UserSettings> watch() {
    const defaults = UserSettings();
    return _doc.watch(
      (data) => UserSettings(
        eveningReminder:
            data['eveningReminder'] as int? ?? defaults.eveningReminder,
        awakeEnabled: data['awakeEnabled'] as bool? ?? defaults.awakeEnabled,
        awakeStart: data['awakeStart'] as int? ?? defaults.awakeStart,
        awakeEnd: data['awakeEnd'] as int? ?? defaults.awakeEnd,
        lockSelfControl:
            data['lockSelfControl'] as bool? ?? defaults.lockSelfControl,
        aiEnabled: data['aiEnabled'] as bool? ?? defaults.aiEnabled,
        hideNotificationContent:
            data['hideNotificationContent'] as bool? ??
            defaults.hideNotificationContent,
      ),
    );
  }

  @override
  Future<void> save(UserSettings settings) => _doc.merge(<String, Object?>{
    'eveningReminder': settings.eveningReminder,
    'awakeEnabled': settings.awakeEnabled,
    'awakeStart': settings.awakeStart,
    'awakeEnd': settings.awakeEnd,
    'lockSelfControl': settings.lockSelfControl,
    'aiEnabled': settings.aiEnabled,
    'hideNotificationContent': settings.hideNotificationContent,
  });
}
