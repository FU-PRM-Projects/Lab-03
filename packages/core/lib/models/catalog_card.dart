import 'challenge.dart';

/// Nguồn của một thẻ trong kho chung.
enum CardSource {
  seed(id: 'seed', label: 'Có sẵn'),
  staff(id: 'staff', label: 'Staff thêm'),
  community(id: 'community', label: 'Người dùng đề xuất');

  const CardSource({required this.id, required this.label});

  final String id;
  final String label;

  static CardSource fromId(String? id) {
    for (final source in values) {
      if (source.id == id) return source;
    }
    return seed;
  }
}

/// Giới hạn khớp `validChallenge` trong firestore.rules.
abstract final class CatalogLimits {
  static const int titleMax = 80;
  static const int tipMax = 120;
  static const int scriptMax = 300;
  static const int minutesMax = 600;
  static const int levelMax = 10;
  static const int orderMax = 999;
}

/// Một thẻ của kho `challenges` như staff thấy trên web admin: thêm trạng
/// lưu trữ, nguồn và lần sửa cuối. Thẻ lưu trữ ẩn trong app nhưng không bị
/// xoá, để nốt cũ trỏ tới thẻ vẫn mở được.
class CatalogCard {
  const CatalogCard({
    required this.challenge,
    this.archived = false,
    this.source = CardSource.seed,
    this.submissionId,
    this.updatedAt,
    this.updatedBy,
  });

  final Challenge challenge;
  final bool archived;
  final CardSource source;
  final String? submissionId;
  final DateTime? updatedAt;
  final String? updatedBy;

  String get id => challenge.id;
}

/// Dữ liệu staff nhập ở form thêm / sửa thẻ.
class CatalogDraft {
  const CatalogDraft({
    required this.topic,
    required this.level,
    required this.order,
    required this.title,
    required this.minutes,
    this.tip = '',
    this.script = '',
  });

  final ChallengeTopic topic;
  final int level;
  final int order;
  final String title;
  final int minutes;
  final String tip;
  final String script;
}
