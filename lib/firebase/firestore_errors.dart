import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/app_exception.dart';

/// Đổi lỗi Firestore sang [AppException].
AppException firestoreException(FirebaseException e) => AppException(
  switch (e.code) {
    'permission-denied' || 'unauthenticated' => AppErrorKind.permissionDenied,
    'unavailable' || 'deadline-exceeded' => AppErrorKind.network,
    'not-found' => AppErrorKind.notFound,
    'invalid-argument' => AppErrorKind.invalidInput,
    _ => AppErrorKind.unknown,
  },
  code: e.code,
  detail: e.message,
);
