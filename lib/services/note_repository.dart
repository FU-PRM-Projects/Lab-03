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

  /// [limit] nốt mới nhất (trang đầu của S05), phát lại như [watchSince].
  Stream<List<Note>> watchRecent({int limit = 30});

  /// Tối đa [limit] nốt tạo trước [before] (mặc định: mọi nốt), mới nhất trước.
  Future<List<Note>> list({DateTime? before, int limit = 30});

  /// Số nốt tạo trong khoảng [[start], [end]).
  Future<int> countBetween(DateTime start, DateTime end);

  /// Ném `AppException(notFound)` khi không có nốt [id].
  Future<Note> get(String id);

  /// Lưu [draft] với giờ tạo [createdAt]; trả nốt vừa lưu.
  Future<Note> add(NoteDraft draft, {required DateTime createdAt});

  /// Sửa tiêu đề và nhật ký của nốt [id] (S06); trả nốt sau khi sửa.
  Future<Note> update(String id, {required String title, required String body});

  /// Xoá hẳn nốt [id]. Hoàn tác 5 giây do ViewModel giữ trước khi gọi.
  Future<void> delete(String id);

  /// Tối đa [limit] nốt của nhóm lần đầu [groupId], mới nhất trước (S05e).
  Future<List<Note>> listByGroup(String groupId, {int limit = 30});

  /// Gỡ mọi nốt khỏi nhóm [groupId] (nhóm vừa bị xoá); nốt vẫn ở trong hũ.
  Future<void> ungroup(String groupId);

  /// Gắn nhãn dán mốc của tháng chứa [month] vào hũ (S04).
  Future<void> saveMonthSticker(DateTime month);

  /// Các tháng đã có nhãn dán, dạng `yyyy-MM`, mới nhất trước.
  Future<List<String>> listStickers();
}

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => throw UnimplementedError('noteRepositoryProvider chưa được gắn'),
);
