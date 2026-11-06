import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/streak.dart';

/// Giới hạn của ảnh chia sẻ.
///
/// Firestore cho tối đa 1 MiB mỗi document; base64 phình thêm khoảng 4/3 nên
/// giữ PNG dưới 600 KB để còn chỗ cho các trường mô tả.
abstract final class StreakShareLimits {
  static const int maxPngBytes = 600000;
  static const int maxBase64Length = 850000;
}

/// Lưu ảnh chuỗi vào Firestore rồi mở hộp chia sẻ của hệ thống.
abstract interface class StreakShareService {
  /// Ghi ảnh PNG vào `users/{uid}/sharedStreaks/{id}` dưới dạng base64.
  /// Trả id document vừa tạo.
  Future<String> save({
    required StreakSummary streak,
    required Uint8List png,
    required DateTime createdAt,
  });

  /// Mở hộp chia sẻ hệ thống với [png] và [text].
  Future<void> share({
    required Uint8List png,
    required String fileName,
    required String text,
    Rect? origin,
  });
}

final streakShareServiceProvider = Provider<StreakShareService>(
  (ref) => throw UnimplementedError('streakShareServiceProvider chưa được gắn'),
);
