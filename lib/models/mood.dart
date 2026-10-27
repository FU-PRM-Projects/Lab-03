/// Tâm trạng người dùng chọn ở bước 1 của S03 (Lab 2, DESIGN.md mục 3.2).
///
/// [score] là thang năng lượng 1–5 của biểu đồ S11b. [id] là giá trị lưu
/// trong Firestore.
enum Mood {
  vui(id: 'vui', label: 'Vui', score: 5),
  on(id: 'on', label: 'Ổn', score: 4),
  binhThuong(id: 'binh_thuong', label: 'Bình thường', score: 3),
  met(id: 'met', label: 'Mệt', score: 2),
  roi(id: 'roi', label: 'Rối', score: 1);

  const Mood({required this.id, required this.label, required this.score});

  final String id;
  final String label;
  final int score;

  /// Mệt và Rối kích hoạt nhánh "ngày tệ" (F1, P6).
  bool get isLow => score <= 2;

  static Mood? fromId(String? id) {
    for (final mood in values) {
      if (mood.id == id) return mood;
    }
    return null;
  }
}
