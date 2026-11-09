import '../models/catalog_card.dart';
import '../models/challenge.dart';
import '../models/challenge_submission.dart';
import '../models/inbox.dart';
import '../models/user_role.dart';

/// Hợp đồng dữ liệu dùng chung cho app mobile và web admin. Hiện thực
/// Firestore ở `package:not_core/firebase/`; test dùng bản giả. Mọi lỗi là
/// `AppException`.

/// `challengeSubmissions`: người dùng gửi thẻ, staff duyệt (luồng liên vai
/// trò).
abstract interface class SubmissionRepository {
  /// Gửi thẻ tự thêm [card] của [uid] lên kho chung, trạng thái chờ duyệt.
  Future<ChallengeSubmission> submit({
    required String uid,
    required Challenge card,
  });

  /// Thẻ [uid] đã gửi, mới nhất trước; cập nhật ngay khi staff duyệt.
  Stream<List<ChallengeSubmission>> watchMine(String uid);

  /// Rút lại thẻ còn chờ duyệt.
  Future<void> withdraw(String id);

  /// Hàng chờ của staff theo [status], mới nhất trước.
  Stream<List<ChallengeSubmission>> watchByStatus(SubmissionStatus status);

  /// Duyệt: thêm thẻ vào kho chung ở [level] / [order], đánh dấu đã duyệt và
  /// để lại tin trong hộp thư người gửi, trong một batch.
  Future<void> approve(
    ChallengeSubmission submission, {
    required String reviewerUid,
    required int level,
    required int order,
  });

  /// Từ chối với [reason] (bắt buộc) và để lại tin trong hộp thư người gửi.
  Future<void> reject(
    ChallengeSubmission submission, {
    required String reviewerUid,
    required String reason,
  });
}

/// Kho `challenges` phía staff.
abstract interface class CatalogRepository {
  /// Mọi thẻ, kể cả thẻ lưu trữ, sắp theo chủ đề, cấp, thứ tự.
  Stream<List<CatalogCard>> watchAll();

  Future<String> create(CatalogDraft draft, {required String staffUid});

  Future<void> update(
    CatalogCard card,
    CatalogDraft draft, {
    required String staffUid,
  });

  /// Lưu trữ hoặc khôi phục; không xoá thẻ.
  Future<void> setArchived(
    CatalogCard card,
    bool archived, {
    required String staffUid,
  });
}

/// `announcements`.
abstract interface class AnnouncementRepository {
  Stream<List<Announcement>> watchLatest({int limit = 30});

  Future<void> post({
    required String title,
    required String body,
    required String authorUid,
  });

  Future<void> delete(String id);
}

/// `users/{uid}/inbox`.
abstract interface class InboxRepository {
  Stream<List<InboxMessage>> watch(String uid);

  Future<void> markRead(String uid, String id);
}

/// `users`: vai trò và danh sách người dùng cho web admin.
abstract interface class UserDirectory {
  /// Vai trò của [uid]; `null` khi chưa có hồ sơ.
  Future<UserRole?> roleOf(String uid);

  /// Tạo hồ sơ `role = user` khi đăng nhập lần đầu (rules chỉ cho vai trò
  /// này); đã có thì giữ nguyên.
  Future<void> ensureProfile(
    String uid, {
    required String displayName,
    String email = '',
  });

  Stream<List<UserSummary>> watchAll();

  /// Chỉ admin; không đổi được vai trò của chính mình.
  Future<void> setRole(String uid, UserRole role);
}

/// Số liệu dashboard, đếm bằng truy vấn tổng hợp `count()`.
class DashboardStats {
  const DashboardStats({
    required this.users,
    required this.staff,
    required this.cards,
    required this.archivedCards,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.announcements,
    required this.cardsByTopic,
  });

  final int users;
  final int staff;
  final int cards;
  final int archivedCards;
  final int pending;
  final int approved;
  final int rejected;
  final int announcements;
  final Map<ChallengeTopic, int> cardsByTopic;

  int get activeCards => cards - archivedCards;
  int get reviewed => approved + rejected;
}

abstract interface class DashboardRepository {
  Future<DashboardStats> load();
}
