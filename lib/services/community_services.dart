import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_core/not_core.dart';

/// Phần "cộng đồng" của Final Assignment trên app: gửi thẻ lên kho chung,
/// hộp thư thông báo và tin riêng từ web admin. Hiện thực Firestore nằm ở
/// `package:not_core`; `main.dart` gắn chúng. Mặc định là bản rỗng để test
/// không cần Firebase.

final submissionRepositoryProvider = Provider<SubmissionRepository>(
  (ref) => const _NoCommunity(),
);

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => const _NoCommunity(),
);

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => const _NoCommunity(),
);

/// Không có backend: không có tin, gửi thẻ thì báo lỗi mạng.
class _NoCommunity
    implements SubmissionRepository, AnnouncementRepository, InboxRepository {
  const _NoCommunity();

  static const AppException _offline = AppException(
    AppErrorKind.network,
    code: 'no-backend',
  );

  @override
  Future<ChallengeSubmission> submit({
    required String uid,
    required Challenge card,
  }) => Future<ChallengeSubmission>.error(_offline);

  @override
  Stream<List<ChallengeSubmission>> watchMine(String uid) =>
      Stream<List<ChallengeSubmission>>.value(const <ChallengeSubmission>[]);

  @override
  Future<void> withdraw(String id) => Future<void>.error(_offline);

  @override
  Stream<List<ChallengeSubmission>> watchByStatus(SubmissionStatus status) =>
      Stream<List<ChallengeSubmission>>.value(const <ChallengeSubmission>[]);

  @override
  Future<void> approve(
    ChallengeSubmission submission, {
    required String reviewerUid,
    required int level,
    required int order,
  }) => Future<void>.error(_offline);

  @override
  Future<void> reject(
    ChallengeSubmission submission, {
    required String reviewerUid,
    required String reason,
  }) => Future<void>.error(_offline);

  @override
  Stream<List<Announcement>> watchLatest({int limit = 30}) =>
      Stream<List<Announcement>>.value(const <Announcement>[]);

  @override
  Future<void> post({
    required String title,
    required String body,
    required String authorUid,
  }) => Future<void>.error(_offline);

  @override
  Future<void> delete(String id) => Future<void>.error(_offline);

  @override
  Stream<List<InboxMessage>> watch(String uid) =>
      Stream<List<InboxMessage>>.value(const <InboxMessage>[]);

  @override
  Future<void> markRead(String uid, String id) async {}
}
