import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../models/streak.dart';
import '../services/app_exception.dart';
import '../services/streak_share_service.dart';
import 'firestore_errors.dart';

/// [StreakShareService] trên Firestore + hộp chia sẻ của hệ thống.
///
/// Ảnh nằm ở `users/{uid}/sharedStreaks/{id}` dưới dạng base64, chỉ chủ tài
/// khoản đọc được (xem `firestore.rules`).
class FirebaseStreakShareService implements StreakShareService {
  FirebaseStreakShareService({
    required this.currentUid,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  /// Uid của người đang đăng nhập; `null` khi đã đăng xuất.
  final String? Function() currentUid;
  final FirebaseFirestore _db;

  @override
  Future<String> save({
    required StreakSummary streak,
    required Uint8List png,
    required DateTime createdAt,
  }) async {
    final uid = currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    final image = base64Encode(png);
    if (image.length > StreakShareLimits.maxBase64Length) {
      throw const AppException(
        AppErrorKind.invalidInput,
        code: 'image-too-large',
      );
    }
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('sharedStreaks')
          .add(<String, Object?>{
            'image': image,
            'streak': streak.current,
            'record': streak.record,
            'milestone': streak.isMilestone ? streak.current : 0,
            'createdAt': Timestamp.fromDate(createdAt.toUtc()),
          });
      return doc.id;
    } on FirebaseException catch (error) {
      throw firestoreException(error);
    }
  }

  @override
  Future<void> share({
    required Uint8List png,
    required String fileName,
    required String text,
    Rect? origin,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile.fromData(png, mimeType: 'image/png')],
          fileNameOverrides: <String>[fileName],
          text: text,
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        code: 'share',
        detail: '$error',
      );
    }
  }
}
