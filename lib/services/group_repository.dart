import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/first_group.dart';
import '../models/note.dart';

/// Nhóm lần đầu của người dùng đang đăng nhập (`users/{uid}/groups`).
///
/// Nhóm hệ thống chỉ được lưu khi có nốt đầu tiên; trước đó chúng là gợi ý
/// trong `FirstGroups.system`. Mọi lỗi được ném dưới dạng `AppException`.
abstract interface class GroupRepository {
  /// Các nhóm đã lưu, lần ghi gần nhất trước.
  Stream<List<FirstGroup>> watchAll();

  /// Nhóm đã lưu [id], `null` khi chưa có.
  Future<FirstGroup?> get(String id);

  /// Lưu nhóm mới [group] (chưa có nốt).
  Future<void> create(FirstGroup group);

  /// Tính [note] vào nhóm [group] (tạo nhóm nếu chưa lưu): tăng số nốt, nhớ
  /// lần ghi gần nhất và, khi `note.isFirst`, nốt lần đầu.
  Future<void> recordNote(FirstGroup group, Note note);

  Future<void> rename(String id, String name);

  /// Xoá nhóm; các nốt được ViewModel gỡ khỏi nhóm sau khi hết Hoàn tác.
  Future<void> delete(String id);
}

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => throw UnimplementedError('groupRepositoryProvider chưa được gắn'),
);
