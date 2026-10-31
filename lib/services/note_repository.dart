import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';

/// Các nốt của người dùng đang đăng nhập (`users/{uid}/notes`).
///
/// Mọi lỗi được ném dưới dạng `AppException`. Ghi khi mất mạng vẫn thành công:
/// nốt nằm trên máy với `pendingSync = true` và tự đồng bộ sau.
abstract interface class NoteRepository {
  /// Các nốt tạo từ [since] trở đi, mới nhất trước. Phát lại khi có nốt mới
  /// hoặc khi một nốt đồng bộ xong.
  Stream<List<Note>> watchSince(DateTime since);

  /// Tối đa [limit] nốt tạo trước [before] (mặc định: mọi nốt), mới nhất trước.
  Future<List<Note>> list({DateTime? before, int limit = 30});

  /// Số nốt tạo trong khoảng [[start], [end]).
  Future<int> countBetween(DateTime start, DateTime end);

  /// Ném `AppException(notFound)` khi không có nốt [id].
  Future<Note> get(String id);

  /// Lưu [draft] với giờ tạo [createdAt]; trả nốt vừa lưu.
  Future<Note> add(NoteDraft draft, {required DateTime createdAt});

  /// Gắn nhãn dán mốc của tháng chứa [month] vào hũ (S04).
  Future<void> saveMonthSticker(DateTime month);
}

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => throw UnimplementedError('noteRepositoryProvider chưa được gắn'),
);
