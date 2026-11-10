import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';

/// Dựng file PDF từ dữ liệu người dùng đang xem.
abstract interface class ReportService {
  /// PDF Thẻ tuần. Lỗi là `AppException`.
  Future<Uint8List> weeklyCard(WeeklySummary summary);
}

/// Lưu file trên máy và mở hộp chia sẻ của hệ thống. Final Assignment để
/// Cloud Storage ngoài phạm vi, nên file không rời máy trừ khi người dùng tự
/// chia sẻ.
abstract interface class ReportFileStore {
  /// Ghi [bytes] vào thư mục tài liệu của app (`reports/[fileName]`), ghi đè
  /// bản cũ của cùng tuần. Lỗi là `AppException`.
  Future<SavedReport> save(Uint8List bytes, String fileName);

  /// Mở hộp chia sẻ với file đã lưu. Lỗi là `AppException`.
  Future<void> share(SavedReport report);
}

/// Metadata của các lần lưu ở `users/{uid}/reports/{isoWeek}`.
abstract interface class ReportRepository {
  /// Ghi (hoặc ghi đè) metadata của tuần. Lỗi là `AppException`.
  Future<void> record(ReportRecord record);

  /// Lần lưu của tuần [isoWeek]; `null` khi chưa lưu lần nào.
  Stream<ReportRecord?> watchWeek(String isoWeek);
}

final reportServiceProvider = Provider<ReportService>(
  (ref) => throw UnimplementedError('reportServiceProvider chưa được gắn'),
);

final reportFileStoreProvider = Provider<ReportFileStore>(
  (ref) => throw UnimplementedError('reportFileStoreProvider chưa được gắn'),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => throw UnimplementedError('reportRepositoryProvider chưa được gắn'),
);
