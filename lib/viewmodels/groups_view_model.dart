import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/first_group.dart';
import '../models/image_ref.dart';
import '../services/group_repository.dart';
import 'auth_view_model.dart';
import 'error_messages.dart';
import 'group_deleter.dart';
import 'view_state.dart';

/// Kệ "Nhóm lần đầu" (S05) và trang "Xem tất cả".
class GroupShelfData {
  const GroupShelfData({required this.groups, required this.suggestions});

  /// Nhóm đã có nốt, lần ghi gần nhất trước.
  final List<FirstGroup> groups;

  /// Nhóm hệ thống (hoặc nhóm vừa tạo) chưa có nốt nào: thẻ viền đứt.
  final List<FirstGroup> suggestions;

  /// Mọi nhóm, đã có nốt trước rồi tới gợi ý.
  List<FirstGroup> get all => <FirstGroup>[...groups, ...suggestions];
}

/// Kết quả kiểm tra tên ở sheet "Tạo nhóm lần đầu".
sealed class GroupNameCheck {
  const GroupNameCheck();
}

/// Tên rỗng: nút chính tắt.
final class GroupNameEmpty extends GroupNameCheck {
  const GroupNameEmpty();
}

final class GroupNameTooLong extends GroupNameCheck {
  const GroupNameTooLong();
}

/// Trùng tên một nhóm có sẵn (bỏ dấu, không phân biệt hoa thường).
final class GroupNameTaken extends GroupNameCheck {
  const GroupNameTaken(this.group);

  final FirstGroup group;
}

final class GroupNameOk extends GroupNameCheck {
  const GroupNameOk();
}

final groupsViewModelProvider =
    NotifierProvider<GroupsViewModel, ViewState<GroupShelfData>>(
      GroupsViewModel.new,
    );

/// ViewModel của kệ nhóm lần đầu: gộp nhóm đã lưu với 8 nhóm hệ thống.
class GroupsViewModel extends Notifier<ViewState<GroupShelfData>> {
  GroupRepository get _groups => ref.read(groupRepositoryProvider);

  List<FirstGroup>? _saved;

  @override
  ViewState<GroupShelfData> build() {
    ref.watch(authUserProvider.select((user) => user.value?.uid));
    _saved = null;
    // Nhóm chờ xoá / hoàn tác: dựng lại kệ từ dữ liệu đã có.
    ref.listen(groupDeleterProvider, (_, _) => _emit());
    final sub = _groups.watchAll().listen(
      (saved) {
        _saved = saved;
        _emit();
      },
      onError: (Object error) {
        if (state is! Data<GroupShelfData>) {
          state = ErrorMessages.failure(error);
        }
      },
    );
    ref.onDispose(sub.cancel);
    return const Loading<GroupShelfData>();
  }

  void _emit() {
    final saved = _saved;
    if (saved == null) return;
    final pendingId = ref.read(groupDeleterProvider)?.id;
    state = Data<GroupShelfData>(
      _shelf(saved.where((g) => g.id != pendingId).toList(), pendingId),
    );
  }

  static GroupShelfData _shelf(List<FirstGroup> saved, String? hidden) {
    final savedIds = <String>{...saved.map((g) => g.id), ?hidden};
    return GroupShelfData(
      groups: saved.where((g) => g.noteCount > 0).toList(),
      suggestions: <FirstGroup>[
        ...saved.where((g) => g.noteCount == 0),
        ...FirstGroups.system.where((g) => !savedIds.contains(g.id)),
      ],
    );
  }

  /// Mọi nhóm đang biết (đã lưu và gợi ý), để kiểm tra trùng tên.
  List<FirstGroup> get _known => switch (state) {
    Data<GroupShelfData>(:final value) => value.all,
    _ => FirstGroups.system,
  };

  GroupNameCheck check(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const GroupNameEmpty();
    if (trimmed.length > FirstGroups.nameMaxLength) {
      return const GroupNameTooLong();
    }
    final key = FirstGroups.nameKey(trimmed);
    for (final group in _known) {
      if (FirstGroups.nameKey(group.name) == key) return GroupNameTaken(group);
    }
    return const GroupNameOk();
  }

  /// Tạo nhóm người dùng đặt tên. Trả nhóm vừa tạo, hoặc nhóm trùng tên có
  /// sẵn (không tạo thêm).
  Future<FirstGroup> create(
    String name,
    GroupIdea idea, {
    ImageRef? image,
  }) async {
    switch (check(name)) {
      case GroupNameTaken(:final group):
        return group;
      case GroupNameEmpty() || GroupNameTooLong():
        throw ArgumentError.value(name, 'name');
      case GroupNameOk():
        break;
    }
    final trimmed = name.trim();
    final slug = FirstGroups.slug(trimmed);
    final group = FirstGroup(
      id: slug.isEmpty ? 'nhom-${trimmed.hashCode.abs()}' : slug,
      name: trimmed,
      idea: idea,
      source: GroupSource.user,
      image: image,
    );
    await _groups.create(group);
    return group;
  }
}
