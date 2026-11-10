import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../services/app_exception.dart';

/// Ghi [bytes] vào `<thư mục tài liệu của app>/reports/[fileName]` và trả về
/// đường dẫn. Thư mục riêng của app, không cần quyền bộ nhớ.
Future<String?> writeReportFile(Uint8List bytes, String fileName) async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}reports');
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } on FileSystemException catch (e) {
    // ENOSPC (28): hết bộ nhớ.
    final full = e.osError?.errorCode == 28;
    throw AppException(
      full ? AppErrorKind.unknown : AppErrorKind.permissionDenied,
      code: full ? 'storage-full' : 'file-write',
      detail: '$e',
    );
  } on Object catch (e) {
    throw AppException(AppErrorKind.unknown, code: 'file-write', detail: '$e');
  }
}
