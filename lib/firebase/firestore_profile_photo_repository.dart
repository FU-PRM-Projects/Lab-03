import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/image_ref.dart';
import '../services/app_exception.dart';
import '../services/profile_photo_repository.dart';
import 'firestore_errors.dart';

/// [ProfilePhotoRepository] trên Firestore: trường `photo` của `users/{uid}`
/// (`{url, publicId}`). firestore.rules chỉ cho chủ tài khoản sửa đúng trường
/// này và chỉ nhận URL của `res.cloudinary.com`.
class FirestoreProfilePhotoRepository implements ProfilePhotoRepository {
  FirestoreProfilePhotoRepository({
    required this.currentUid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String? Function() currentUid;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, Object?>> _doc() {
    final uid = currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    return _firestore.collection('users').doc(uid);
  }

  @override
  Stream<ImageRef?> watch() {
    final Stream<DocumentSnapshot<Map<String, Object?>>> snapshots;
    try {
      snapshots = _doc().snapshots();
    } on AppException catch (e, stack) {
      return Stream<ImageRef?>.error(e, stack);
    }
    return snapshots
        .map((snapshot) => ImageRef.fromMap(snapshot.data()?['photo']))
        .transform(
          StreamTransformer<ImageRef?, ImageRef?>.fromHandlers(
            handleError: (error, stack, sink) => sink.addError(
              error is FirebaseException ? firestoreException(error) : error,
              stack,
            ),
          ),
        );
  }

  @override
  Future<void> save(ImageRef? photo) async {
    try {
      await _doc().update(<String, Object?>{
        'photo': photo == null ? FieldValue.delete() : photo.toMap(),
      });
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }
}
