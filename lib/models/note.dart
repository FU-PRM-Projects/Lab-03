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

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.type == type &&
      other.title == title &&
      other.body == body &&
      other.mood == mood &&
      other.createdAt == createdAt &&
      other.pendingSync == pendingSync;

  @override
  int get hashCode =>
      Object.hash(id, type, title, body, mood, createdAt, pendingSync);
}

/// Nội dung một nốt chưa lưu: nháp S03 và dữ liệu gửi cho `NoteRepository`.
class NoteDraft {
  const NoteDraft({
    this.type = NoteType.chienThang,
    this.mood,
    this.title = '',
    this.body = '',
  });

  final NoteType type;
  final Mood? mood;
  final String title;
  final String body;

  /// Có gì đáng giữ khi người dùng thoát giữa chừng.
  bool get hasInput =>
      mood != null || title.trim().isNotEmpty || body.trim().isNotEmpty;

  NoteDraft copyWith({
    NoteType? type,
    Mood? mood,
    String? title,
    String? body,
  }) => NoteDraft(
    type: type ?? this.type,
    mood: mood ?? this.mood,
    title: title ?? this.title,
    body: body ?? this.body,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteDraft &&
      other.type == type &&
      other.mood == mood &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(type, mood, title, body);
}

/// Giới hạn độ dài do handout đặt (deviation D-02).
abstract final class NoteLimits {
  static const int title = 120;
  static const int body = 2000;
}
