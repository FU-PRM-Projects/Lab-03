import 'challenge.dart';
import 'image_ref.dart';
import 'mood.dart';
import 'note_type.dart';

/// Một tờ nốt trong hũ, tài liệu `users/{uid}/notes/{id}`.
class Note {
  const Note({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.mood,
    this.body = '',
    this.pendingSync = false,
    this.challenge,
    this.groupId,
    this.isFirst = false,
    this.image,
  });

  final String id;
  final NoteType type;
  final String title;

  /// Nhật ký kèm theo; rỗng khi người dùng bỏ qua.
  final String body;
  final Mood? mood;

  /// Giờ trên máy lúc ghi. Dùng giờ máy thay cho giờ server để nốt ghi lúc
  /// offline vẫn có ngày và vẫn được truy vấn theo ngày.
  final DateTime createdAt;

  /// Mới ghi trên máy, chưa đồng bộ lên server (deviation D-08).
  final bool pendingSync;

  /// Kết quả thử thách, chỉ có ở nốt `thu_thach` ghi từ S08.
  final ChallengeResult? challenge;

  /// Nhóm lần đầu chứa nốt (`users/{uid}/groups/{groupId}`), nếu có.
  final String? groupId;

  /// Nốt đầu tiên của nhóm [groupId]: S04 hiện "Lần đầu tiên!".
  final bool isFirst;

  /// Ảnh đính kèm trên Cloudinary, nếu có.
  final ImageRef? image;

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.type == type &&
      other.title == title &&
      other.body == body &&
      other.mood == mood &&
      other.createdAt == createdAt &&
      other.pendingSync == pendingSync &&
      other.challenge == challenge &&
      other.groupId == groupId &&
      other.isFirst == isFirst &&
      other.image == image;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    body,
    mood,
    createdAt,
    pendingSync,
    challenge,
    groupId,
    isFirst,
    image,
  );
}

/// Nội dung một nốt chưa lưu: nháp S03 và dữ liệu gửi cho `NoteRepository`.
class NoteDraft {
  const NoteDraft({
    this.type = NoteType.chienThang,
    this.mood,
    this.title = '',
    this.body = '',
    this.challenge,
    this.groupId,
    this.isFirst = false,
    this.image,
  });

  final NoteType type;
  final Mood? mood;
  final String title;
  final String body;
  final ChallengeResult? challenge;

  /// Xếp nốt vào nhóm lần đầu này khi lưu.
  final String? groupId;
  final bool isFirst;

  /// Ảnh đã tải lên Cloudinary, gắn vào nốt khi lưu.
  final ImageRef? image;

  /// Có gì đáng giữ khi người dùng thoát giữa chừng.
  ///
  /// Ảnh đã đính cũng là dữ liệu người dùng đã bỏ công tải lên, nên tính cả
  /// [image]: nháp chỉ có ảnh vẫn phải hỏi "Giữ nháp?" thay vì bỏ lặng lẽ.
  bool get hasInput =>
      mood != null ||
      title.trim().isNotEmpty ||
      body.trim().isNotEmpty ||
      image != null;

  NoteDraft copyWith({
    NoteType? type,
    Mood? mood,
    String? title,
    String? body,
    ImageRef? image,
    bool clearImage = false,
  }) => NoteDraft(
    type: type ?? this.type,
    mood: mood ?? this.mood,
    title: title ?? this.title,
    body: body ?? this.body,
    challenge: challenge,
    groupId: groupId,
    isFirst: isFirst,
    image: clearImage ? null : (image ?? this.image),
  );

  @override
  bool operator ==(Object other) =>
      other is NoteDraft &&
      other.type == type &&
      other.mood == mood &&
      other.title == title &&
      other.body == body &&
      other.image == image;

  @override
  int get hashCode => Object.hash(type, mood, title, body, image);
}

/// Giới hạn độ dài do handout đặt (deviation D-02).
abstract final class NoteLimits {
  static const int title = 120;
  static const int body = 2000;
}
