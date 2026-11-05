import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/first_group.dart';
import '../models/note.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/group_repository.dart';
import '../services/note_repository.dart';
import 'error_messages.dart';
import 'view_state.dart';

/// Nội dung S05e · Chi tiết nhóm.
class GroupDetail {
  const GroupDetail({required this.group, required this.notes});

  final FirstGroup group;

  /// Nốt của nhóm, mới nhất trước.
  final List<Note> notes;

  int get count =>
      notes.length > group.noteCount ? notes.length : group.noteCount;

  /// Mốc đã mở (Lần đầu, Lần 3, Lần 10).
  bool reached(int milestone) => count >= milestone;

  /// "Hồi hộp trước khi làm: lần 1 là 5/5, lần 4 chỉ còn 2/5." khi mức hồi
  /// hộp đã giảm; `null` khi chưa đủ dữ liệu hoặc không giảm.
  String? get anxietyTrend {
    final rated = notes.reversed
        .where((n) => n.challenge?.anxietyBefore != null)
        .toList();
    if (rated.length < 2) return null;
    final first = rated.first.challenge!.anxietyBefore!;
    final last = rated.last.challenge!.anxietyBefore!;
    if (last >= first) return null;
    return 'Hồi hộp trước khi làm: lần 1 là $first/5, '
        'lần ${rated.length} chỉ còn $last/5.';
  }
}

final groupDetailViewModelProvider = NotifierProvider.autoDispose
    .family<GroupDetailViewModel, ViewState<GroupDetail>, String>(
      GroupDetailViewModel.new,
    );

/// ViewModel của S05e. Tham số là id nhóm (có thể là nhóm hệ thống chưa lưu).
class GroupDetailViewModel extends Notifier<ViewState<GroupDetail>> {
  GroupDetailViewModel(this.groupId);

  final String groupId;

  GroupRepository get _groups => ref.read(groupRepositoryProvider);
  NoteRepository get _notes => ref.read(noteRepositoryProvider);

  /// Màn tải lại mỗi khi danh sách nhóm đổi; chỉ ghi `group_viewed` một lần
  /// cho mỗi lần mở.
  bool _viewLogged = false;

  @override
  ViewState<GroupDetail> build() {
    final sub = _groups.watchAll().listen((_) => unawaited(_load()));
    ref.onDispose(sub.cancel);
    return const Loading<GroupDetail>();
  }

  Future<void> _load() async {
    try {
      final group =
          await _groups.get(groupId) ?? FirstGroups.systemById(groupId);
      if (group == null) {
        if (ref.mounted) state = const Empty<GroupDetail>();
        return;
      }
      final notes = await _notes.listByGroup(groupId);
      if (!ref.mounted) return;
      final detail = GroupDetail(group: group, notes: notes);
      state = Data<GroupDetail>(detail);
      if (!_viewLogged) {
        _viewLogged = true;
        // Chỉ loại nhóm và số nốt; không gửi tên nhóm (người dùng tự đặt).
        unawaited(
          ref.read(analyticsServiceProvider).track(
            AnalyticsEvents.groupViewed,
            <String, Object>{
              AnalyticsParams.groupSource: group.source.id,
              AnalyticsParams.groupIdea: group.idea.id,
              AnalyticsParams.noteCount: detail.count,
            },
          ),
        );
      }
    } on Object catch (error) {
      if (ref.mounted) state = ErrorMessages.failure(error);
    }
  }

  void retry() {
    state = const Loading<GroupDetail>();
    unawaited(_load());
  }

  /// Đổi tên; trả câu lỗi để hiện dưới ô, `null` khi xong.
  Future<String?> rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > FirstGroups.nameMaxLength) {
      return 'Tên nhóm dài 1–${FirstGroups.nameMaxLength} ký tự.';
    }
    final value = state;
    if (value is! Data<GroupDetail>) return null;
    try {
      final group = value.value.group;
      if (group.createdAt == null) {
        await _groups.create(group.copyWith(name: trimmed));
      } else {
        await _groups.rename(groupId, trimmed);
      }
      return null;
    } on Object catch (error) {
      return ErrorMessages.update(error);
    }
  }
}
