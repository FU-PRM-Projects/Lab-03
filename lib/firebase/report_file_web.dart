import 'dart:typed_data';

/// Web không có hệ thống file: file chỉ nằm trong bộ nhớ và được tải xuống
/// khi người dùng bấm chia sẻ.
Future<String?> writeReportFile(Uint8List bytes, String fileName) async => null;
