/// Loại nốt trong hũ (Lab 2, DESIGN.md mục 3.3). [id] là giá trị lưu trong
/// Firestore.
enum NoteType {
  chienThang(id: 'chien_thang', label: 'Chiến thắng'),
  tuChu(id: 'tu_chu', label: 'Tự chủ'),
  thuThach(id: 'thu_thach', label: 'Thử thách'),
  nhatKy(id: 'nhat_ky', label: 'Nhật ký');

  const NoteType({required this.id, required this.label});

  final String id;
  final String label;

  static NoteType? fromId(String? id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }
}
