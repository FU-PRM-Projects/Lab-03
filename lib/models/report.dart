import 'dart:typed_data';

import 'mood.dart';

/// Nội dung Thẻ tuần (S11b), cũng là nội dung file PDF lưu trên máy.
class WeeklySummary {
  const WeeklySummary({
    required this.weekStart,
    required this.noteCount,
    required this.daysWithNotes,
    required this.dayMoods,
    required this.wins,
    required this.balance,
    this.energy,
  });

  /// Thứ Hai đầu tuần.
  final DateTime weekStart;
  final int noteCount;

  /// "Mục tiêu tuần 5/7".
  final int daysWithNotes;

  /// Tâm trạng 7 ngày, chỉ số 0 = Thứ Hai; `null` là chưa ghi.
  final List<Mood?> dayMoods;

  /// Tối đa 3 chiến thắng mới nhất trong tuần.
  final List<String> wins;

  /// Số nốt theo nhãn "Cân bằng 5 điều tốt" (theo thứ tự hiển thị).
  final Map<String, int> balance;

  /// Năng lượng trung bình 1–5; `null` khi không có tâm trạng nào.
  final double? energy;

  DateTime get weekEnd =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

  /// Số tuần ISO 8601, dùng trong tên file và id metadata (`2026-W43`).
  String get isoWeek {
    final thursday = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 3,
    );
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart = DateTime(
      firstThursday.year,
      1,
      4 - (firstThursday.weekday - 1),
    );
    final week = thursday.difference(firstWeekStart).inDays ~/ 7 + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  String get fileName => 'weekly-$isoWeek.pdf';
}

/// File PDF đã lưu trên máy. [path] là đường dẫn trong thư mục tài liệu của
/// app; trên web không có hệ thống file nên `null` và chỉ giữ [bytes].
class SavedReport {
  const SavedReport({required this.fileName, required this.bytes, this.path});

  final String fileName;
  final Uint8List bytes;
  final String? path;

  int get sizeBytes => bytes.length;
}

/// Metadata của lần lưu Thẻ tuần gần nhất, ở
/// `users/{uid}/reports/{isoWeek}`. File nằm trên máy, Firestore chỉ giữ
/// thông tin để biết tuần nào đã lưu (Final Assignment, mục 4).
class ReportRecord {
  const ReportRecord({
    required this.isoWeek,
    required this.fileName,
    required this.sizeBytes,
    required this.noteCount,
    this.savedAt,
  });

  final String isoWeek;
  final String fileName;
  final int sizeBytes;
  final int noteCount;

  /// Giờ máy chủ; `null` khi bản ghi còn chờ đồng bộ.
  final DateTime? savedAt;
}
