import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';

/// Dựng file từ dữ liệu người dùng đang xem và mở hộp chia sẻ của hệ thống.
abstract interface class ReportService {
  /// PDF Thẻ tuần. Lỗi (ví dụ chưa tải được font khi offline) là
  /// `AppException`.
  Future<Uint8List> weeklyCard(WeeklySummary summary);

  Future<void> share(Uint8List bytes, String fileName);
}

/// Cloud Storage, chỉ ghi vào thư mục của người dùng đang đăng nhập.
abstract interface class StorageService {
  /// Tải [bytes] lên `reports/{uid}/[fileName]`. Phát tiến độ, bước cuối có
  /// `url`. Lỗi là `AppException`.
  Stream<UploadProgress> uploadReport(String fileName, Uint8List bytes);
}

final reportServiceProvider = Provider<ReportService>(
  (ref) => throw UnimplementedError('reportServiceProvider chưa được gắn'),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('storageServiceProvider chưa được gắn'),
);
