import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:not_core/models/user_role.dart';

import '../models/app_user.dart';
import '../services/user_repository.dart';
import 'firestore_errors.dart';

/// [UserRepository] trên Firestore, collection `users/{uid}`.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> ensureProfile(AppUser user) async {
    final doc = _firestore.collection('users').doc(user.uid);
    try {
      final snapshot = await doc.get();
      if (snapshot.exists) return;
      // `role` phải là `user`: firestore.rules chỉ cho tự tạo với vai trò này
      // và không cho tự sửa vai trò về sau.
      await doc.set(<String, Object?>{
        'role': 'user',
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  @override
  Future<UserRole?> roleOf(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      if (!snapshot.exists) return null;
      return UserRole.fromId(snapshot.data()?['role'] as String?);
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  @override
  Future<void> clearLocalData() async {
    // clearPersistence chỉ chạy khi Firestore đã dừng; instance tự khởi tạo
    // lại ở lần dùng kế tiếp.
    await _firestore.terminate();
    await _firestore.clearPersistence();
  }
}
