/// `announcements/{id}`: thông báo staff gửi từ web admin, mọi người dùng
/// đọc trong hộp thư của app.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.authorUid,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String authorUid;
  final DateTime? createdAt;
}

/// Giới hạn khớp firestore.rules.
abstract final class AnnouncementLimits {
  static const int titleMax = 80;
  static const int bodyMax = 1000;
}

/// Loại tin riêng trong `users/{uid}/inbox`.
enum InboxKind {
  submissionApproved(id: 'submission_approved'),
  submissionRejected(id: 'submission_rejected');

  const InboxKind({required this.id});

  final String id;

  static InboxKind? fromId(String? id) {
    for (final kind in values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

/// `users/{uid}/inbox/{id}`: tin riêng staff để lại khi duyệt thẻ.
class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.submissionId,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final InboxKind kind;
  final String title;
  final String body;
  final String? submissionId;
  final bool read;
  final DateTime? createdAt;
}
