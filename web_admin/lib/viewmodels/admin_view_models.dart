import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_core/not_core.dart';

import '../services/admin_services.dart';
import 'messages.dart';
import 'session_view_model.dart';

// ---------------------------------------------------------------- Catalog

/// Mọi thẻ của kho `challenges`, cập nhật theo thời gian thực.
final catalogProvider = StreamProvider<List<CatalogCard>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchAll(),
);

/// Bộ lọc của màn Quản lý thẻ.
class CatalogFilter {
  const CatalogFilter({this.query = '', this.topic, this.showArchived = false});

  final String query;
  final ChallengeTopic? topic;
  final bool showArchived;

  CatalogFilter copyWith({
    String? query,
    ChallengeTopic? Function()? topic,
    bool? showArchived,
  }) => CatalogFilter(
    query: query ?? this.query,
    topic: topic == null ? this.topic : topic(),
    showArchived: showArchived ?? this.showArchived,
  );

  bool matches(CatalogCard card) {
    if (card.archived && !showArchived) return false;
    if (topic != null && card.challenge.topic != topic) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final c = card.challenge;
    return c.title.toLowerCase().contains(q) ||
        c.tip.toLowerCase().contains(q) ||
        c.id.toLowerCase().contains(q);
  }
}

class CatalogFilterNotifier extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => const CatalogFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setTopic(ChallengeTopic? topic) =>
      state = state.copyWith(topic: () => topic);

  void setShowArchived(bool value) =>
      state = state.copyWith(showArchived: value);
}

final catalogFilterProvider =
    NotifierProvider<CatalogFilterNotifier, CatalogFilter>(
      CatalogFilterNotifier.new,
    );

/// Danh sách đã lọc; giữ trạng thái tải / lỗi của [catalogProvider].
final filteredCatalogProvider = Provider<AsyncValue<List<CatalogCard>>>((ref) {
  final filter = ref.watch(catalogFilterProvider);
  return ref
      .watch(catalogProvider)
      .whenData((cards) => cards.where(filter.matches).toList());
});

/// Thứ tự kế tiếp trong [topic] / [level] (thẻ mới xếp cuối cấp).
int nextOrder(List<CatalogCard> cards, ChallengeTopic topic, int level) {
  var max = 0;
  for (final card in cards) {
    final c = card.challenge;
    if (c.topic == topic && c.level == level && c.order > max) max = c.order;
  }
  return max + 1;
}

/// Thêm, sửa, lưu trữ thẻ. Trả về câu lỗi, hoặc `null` khi thành công.
class CatalogActions {
  CatalogActions(this._ref);

  final Ref _ref;

  Future<String?> save(CatalogDraft draft, {CatalogCard? existing}) async {
    try {
      final staff = requireStaff(_ref);
      final repo = _ref.read(catalogRepositoryProvider);
      if (existing == null) {
        await repo.create(draft, staffUid: staff.user.uid);
      } else {
        await repo.update(existing, draft, staffUid: staff.user.uid);
      }
      await _ref.read(adminAnalyticsProvider).log(
        'admin_card_saved',
        <String, Object>{
          'topic': draft.topic.id,
          'is_new': existing == null ? 1 : 0,
        },
      );
      return null;
    } on Object catch (e) {
      return errorMessage(e);
    }
  }

  Future<String?> setArchived(CatalogCard card, bool archived) async {
    try {
      final staff = requireStaff(_ref);
      await _ref
          .read(catalogRepositoryProvider)
          .setArchived(card, archived, staffUid: staff.user.uid);
      await _ref
          .read(adminAnalyticsProvider)
          .log(archived ? 'admin_card_archived' : 'admin_card_restored');
      return null;
    } on Object catch (e) {
      return errorMessage(e);
    }
  }
}

final catalogActionsProvider = Provider<CatalogActions>(CatalogActions.new);

// ----------------------------------------------------------------- Review

/// Hàng chờ theo trạng thái, cập nhật theo thời gian thực.
final submissionsProvider =
    StreamProvider.family<List<ChallengeSubmission>, SubmissionStatus>(
      (ref, status) =>
          ref.watch(submissionRepositoryProvider).watchByStatus(status),
    );

class ReviewActions {
  ReviewActions(this._ref);

  final Ref _ref;

  Future<String?> approve(
    ChallengeSubmission submission, {
    required int level,
  }) async {
    try {
      final staff = requireStaff(_ref);
      // Đọc kho thẻ thẳng từ repository để thẻ mới xếp cuối cấp. Không dùng
      // `catalogProvider.future`: khi staff chưa mở màn Kho thẻ, provider
      // không có ai lắng nghe nên Riverpod tạm dừng nó, future không bao giờ
      // xong và lần duyệt hết giờ sau 10 giây ("Có lỗi xảy ra").
      final cards = await _ref
          .read(catalogRepositoryProvider)
          .watchAll()
          .first
          .timeout(const Duration(seconds: 10));
      await _ref
          .read(submissionRepositoryProvider)
          .approve(
            submission,
            reviewerUid: staff.user.uid,
            level: level,
            order: nextOrder(cards, submission.topic, level),
          );
      await _ref.read(adminAnalyticsProvider).log(
        'admin_submission_reviewed',
        <String, Object>{'result': SubmissionStatus.approved.id},
      );
      return null;
    } on Object catch (e) {
      return errorMessage(e);
    }
  }

  Future<String?> reject(ChallengeSubmission submission, String reason) async {
    try {
      final staff = requireStaff(_ref);
      await _ref
          .read(submissionRepositoryProvider)
          .reject(submission, reviewerUid: staff.user.uid, reason: reason);
      await _ref.read(adminAnalyticsProvider).log(
        'admin_submission_reviewed',
        <String, Object>{'result': SubmissionStatus.rejected.id},
      );
      return null;
    } on Object catch (e) {
      return errorMessage(e);
    }
  }
}

final reviewActionsProvider = Provider<ReviewActions>(ReviewActions.new);

// -------------------------------------------------------------- Dashboard

/// Truy vấn `count()` cần máy chủ: mất mạng thì Firestore chờ mãi, màn Tổng
/// quan quay vòng không dứt. Quá thời gian này thì báo lỗi để staff thử lại.
const Duration dashboardTimeout = Duration(seconds: 15);

final dashboardProvider = FutureProvider<DashboardStats>(
  (ref) =>
      ref.watch(dashboardRepositoryProvider).load().timeout(dashboardTimeout),
);

// ---------------------------------------------------------- Announcements

final announcementsProvider = StreamProvider<List<Announcement>>(
  (ref) => ref.watch(announcementRepositoryProvider).watchLatest(),
);

class AnnouncementActions {
  AnnouncementActions(this._ref);

  final Ref _ref;

  Future<String?> post({required String title, required String body}) async {
    try {
      final staff = requireStaff(_ref);
      await _ref
          .read(announcementRepositoryProvider)
          .post(title: title, body: body, authorUid: staff.user.uid);
      await _ref.read(adminAnalyticsProvider).log('admin_announcement_posted');
      return null;
    } on Object catch (e) {
      return errorMessage(e);
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _ref.read(announcementRepositoryProvider).delete(id);
      return null;
    } on Object catch (e) {
      return errorMessage(e);
    }
  }
}

final announcementActionsProvider = Provider<AnnouncementActions>(
  AnnouncementActions.new,
);

// ------------------------------------------------------------------ Users

final usersProvider = StreamProvider<List<UserSummary>>(
  (ref) => ref.watch(userDirectoryProvider).watchAll(),
);

class UserActions {
  UserActions(this._ref);

  final Ref _ref;

  Future<String?> setRole(UserSummary user, UserRole role) async {
    try {
      await _ref.read(userDirectoryProvider).setRole(user.uid, role);
      await _ref.read(adminAnalyticsProvider).log(
        'admin_role_changed',
        <String, Object>{'role': role.id},
      );
      return null;
    } on Object catch (e) {
      return errorMessage(e);
    }
  }
}

final userActionsProvider = Provider<UserActions>(UserActions.new);
