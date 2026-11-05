import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chụp [boundaryKey] thành PNG. Tách khỏi UI để test thay bằng ảnh giả.
typedef StreakImageRenderer = Future<Uint8List> Function(
  GlobalKey boundaryKey, {
  double pixelRatio,
});

final streakImageRendererProvider = Provider<StreakImageRenderer>(
  (ref) => renderStreakCardImage,
);

/// Chụp `RepaintBoundary` đang hiển thị (thẻ xem trước ở S04b) thành PNG.
///
/// [pixelRatio] 3 cho ảnh nét trên máy thật; nơi gọi có thể giảm xuống khi
/// ảnh vượt giới hạn document của Firestore.
Future<Uint8List> renderStreakCardImage(
  GlobalKey boundaryKey, {
  double pixelRatio = 3,
}) async {
  final object = boundaryKey.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) {
    throw StateError('Không tìm thấy khung ảnh chuỗi.');
  }
  final image = await object.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Không tạo được ảnh PNG.');
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
