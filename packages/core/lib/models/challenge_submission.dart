import 'challenge.dart';

/// Trạng thái thẻ người dùng gửi lên kho chung. Chỉ đi một chiều:
/// pending → approved | rejected (firestore.rules).
enum SubmissionStatus {
  pending(id: 'pending', label: 'Chờ duyệt'),
  approved(id: 'approved', label: 'Đã duyệt'),
  rejected(id: 'rejected', label: 'Từ chối');

  const SubmissionStatus({required this.id, required this.label});

  final String id;
  final String label;

  static SubmissionStatus fromId(String? id) {
    for (final status in values) {
      if (status.id == id) return status;
    }
    return pending;
  }
}

/// Giới hạn khớp firestore.rules.
abstract final class SubmissionLimits {
  static const int titleMax = 80;
  static const int tipMax = 120;
  static const int reasonMax = 200;
  static const int minutesMax = 600;
}

/// `challengeSubmissions/{id}`: thẻ người dùng đề xuất cho kho chung (luồng
/// liên vai trò của Final Assignment). Staff duyệt thì thẻ thành
/// `challenges/{challengeId}` cho mọi người.
class ChallengeSubmission {
  const ChallengeSubmission({
    required this.id,
    required this.uid,
    required this.topic,
    required this.title,
    required this.minutes,
    required this.status,
    this.tip = '',
    this.customId,
    this.reason = '',
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.challengeId,
  });

  final String id;

  /// Người gửi.
  final String uid;
  final ChallengeTopic topic;
  final String title;
  final int minutes;
  final String tip;

  /// Id thẻ tự thêm (`users/{uid}/customChallenges/{customId}`) đã gửi.
  final String? customId;
  final SubmissionStatus status;

  /// Lý do của staff; bắt buộc khi từ chối.
  final String reason;

  /// `null` khi lệnh ghi còn chờ server (offline).
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  /// Thẻ trong kho chung, khi đã duyệt.
  final String? challengeId;
}
