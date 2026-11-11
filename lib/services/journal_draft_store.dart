import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trang nhật ký đang viết dở, lưu trên máy (flow P4): app bị tắt giữa chừng
/// thì lần mở Viết nhật ký sau hỏi "Tiếp tục bản nháp?".
///
/// Tách khỏi [DraftStore] (nháp S03) vì hai màn có nháp riêng: đang ghi một
/// chiến thắng dở không được ghi đè trang nhật ký dở, và ngược lại.
abstract interface class JournalDraftStore {
  /// Chữ đã viết; `null` khi không có nháp.
  Future<String?> load();

  Future<void> save(String text);

  Future<void> clear();
}

final journalDraftStoreProvider = Provider<JournalDraftStore>(
  (ref) =>
      throw UnimplementedError('journalDraftStoreProvider chưa được gắn'),
);
