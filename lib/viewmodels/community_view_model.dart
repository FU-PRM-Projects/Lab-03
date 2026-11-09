import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_core/not_core.dart';

import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/community_services.dart';
import 'auth_view_model.dart';

/// Thẻ người dùng đã gửi lên kho chung, cập nhật ngay khi staff duyệt trên
/// web admin (snapshot listener).
final mySubmissionsProvider = StreamProvider<List<ChallengeSubmission>>((ref) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) {
    return Stream<List<ChallengeSubmission>>.value(
      const <ChallengeSubmission>[],
    );
  }
  return ref.watch(submissionRepositoryProvider).watchMine(uid);
});

/// Lần gửi mới nhất của từng thẻ tự thêm, theo id thẻ.
final submissionByCardProvider = Provider<Map<String, ChallengeSubmission>>((
  ref,
) {
  final list = ref.watch(mySubmissionsProvider).value ?? const [];
  final byCard = <String, ChallengeSubmission>{};
  // Danh sách mới nhất trước: giữ lần đầu gặp.
  for (final submission in list) {
    final id = submission.customId;
    if (id != null) byCard.putIfAbsent(id, () => submission);
  }
  return byCard;
});

class CommunityActions {
  CommunityActions(this._ref);

  final Ref _ref;

  /// Gửi thẻ tự thêm [card] lên kho chung, trạng thái chờ duyệt.
  Future<void> submit(Challenge card) async {
    final uid = _ref.read(authUserProvider).value?.uid;
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    await _ref.read(submissionRepositoryProvider).submit(uid: uid, card: card);
    await _ref.read(analyticsServiceProvider).logEvent(
      AnalyticsEvents.challengeSubmitted,
      <String, Object>{'topic': card.topic.id},
    );
  }

  /// Rút lại thẻ còn chờ duyệt.
  Future<void> withdraw(ChallengeSubmission submission) =>
      _ref.read(submissionRepositoryProvider).withdraw(submission.id);

  /// Đánh dấu đã đọc mọi tin riêng (khi mở hộp thư). Lỗi thì bỏ qua: không
  /// ảnh hưởng việc xem hộp thư.
  Future<void> markInboxRead() async {
    final uid = _ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final repo = _ref.read(inboxRepositoryProvider);
    for (final message
        in _ref.read(personalInboxProvider).value ?? const <InboxMessage>[]) {
      if (message.read) continue;
      try {
        await repo.markRead(uid, message.id);
      } on Object {
        // Như trên.
      }
    }
  }
}

final communityActionsProvider = Provider<CommunityActions>(
  CommunityActions.new,
);

/// Một dòng trong hộp thư: thông báo chung của staff hoặc tin riêng.
class InboxEntry {
  const InboxEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.personal,
    this.at,
    this.unread = false,
  });

  final String id;
  final String title;
  final String body;

  /// Tin riêng (`users/{uid}/inbox`) chứ không phải thông báo chung.
  final bool personal;
  final DateTime? at;
  final bool unread;
}

final announcementsFeedProvider = StreamProvider<List<Announcement>>(
  (ref) => ref.watch(announcementRepositoryProvider).watchLatest(),
);

final personalInboxProvider = StreamProvider<List<InboxMessage>>((ref) {
  final uid = ref.watch(authUserProvider).value?.uid;
  if (uid == null) {
    return Stream<List<InboxMessage>>.value(const <InboxMessage>[]);
  }
  return ref.watch(inboxRepositoryProvider).watch(uid);
});

/// Thông báo chung và tin riêng gộp lại, mới nhất trước.
final communityInboxProvider = Provider<AsyncValue<List<InboxEntry>>>((ref) {
  final announcements = ref.watch(announcementsFeedProvider);
  final personal = ref.watch(personalInboxProvider);
  if (announcements is AsyncError) {
    return AsyncError(
      announcements.error!,
      announcements.stackTrace ?? StackTrace.current,
    );
  }
  if (personal is AsyncError) {
    return AsyncError(
      personal.error!,
      personal.stackTrace ?? StackTrace.current,
    );
  }
  final a = announcements.value;
  final p = personal.value;
  if (a == null || p == null) return const AsyncLoading();
  final entries =
      <InboxEntry>[
        for (final item in a)
          InboxEntry(
            id: 'a-${item.id}',
            title: item.title,
            body: item.body,
            personal: false,
            at: item.createdAt,
          ),
        for (final item in p)
          InboxEntry(
            id: item.id,
            title: item.title,
            body: item.body,
            personal: true,
            at: item.createdAt,
            unread: !item.read,
          ),
      ]..sort((x, y) {
        final ax = x.at;
        final ay = y.at;
        if (ax == null) return -1;
        if (ay == null) return 1;
        return ay.compareTo(ax);
      });
  return AsyncData(entries);
});

/// Số tin riêng chưa đọc (chấm đỏ trên chuông).
final unreadInboxCountProvider = Provider<int>(
  (ref) =>
      ref.watch(personalInboxProvider).value?.where((m) => !m.read).length ?? 0,
);
