/// Ý của Nốt mà một nhóm lần đầu thuộc về (chip "Thuộc ý nào của Nốt?").
enum GroupIdea {
  chienThang('chien_thang', 'Chiến thắng nhỏ'),
  nhatKy('nhat_ky', 'Nhật ký'),
  tuChu('tu_chu', 'Tự chủ'),
  nguoiLa('nguoi_la', 'Người lạ'),
  vanDong('van_dong', 'Vận động');

  const GroupIdea(this.id, this.label);

  final String id;
  final String label;

  static GroupIdea? fromId(String? id) {
    for (final idea in values) {
      if (idea.id == id) return idea;
    }
    return null;
  }
}

/// Nhóm do ai đặt: hệ thống gợi ý sẵn, người dùng tự tạo, hay Nốt AI gợi ý.
enum GroupSource {
  system('system'),
  user('user'),
  aiSuggested('ai_suggested');

  const GroupSource(this.id);

  final String id;

  static GroupSource fromId(String? id) => values.firstWhere(
    (source) => source.id == id,
    orElse: () => GroupSource.user,
  );
}

/// Một nhóm "lần đầu" (`users/{uid}/groups/{id}`): gom các nốt làm cùng một
/// việc mới, đánh dấu lần đầu và các mốc Lần 3, Lần 10.
class FirstGroup {
  const FirstGroup({
    required this.id,
    required this.name,
    required this.idea,
    required this.source,
    this.noteCount = 0,
    this.firstNoteId,
    this.firstNoteTitle,
    this.firstAt,
    this.lastAt,
    this.createdAt,
  });

  final String id;

  /// 1–24 ký tự.
  final String name;
  final GroupIdea idea;
  final GroupSource source;
  final int noteCount;

  /// Nốt "Lần đầu tiên!" của nhóm.
  final String? firstNoteId;
  final String? firstNoteTitle;
  final DateTime? firstAt;

  /// Lần ghi gần nhất, để xếp kệ: nhóm mới làm lên trước.
  final DateTime? lastAt;

  /// `null` khi nhóm hệ thống chưa được dùng (chỉ là gợi ý trên kệ).
  final DateTime? createdAt;

  /// Nhóm gợi ý chưa có nốt nào: thẻ viền đứt trên kệ.
  bool get isSuggestion => noteCount == 0;

  FirstGroup copyWith({String? name}) => FirstGroup(
    id: id,
    name: name ?? this.name,
    idea: idea,
    source: source,
    noteCount: noteCount,
    firstNoteId: firstNoteId,
    firstNoteTitle: firstNoteTitle,
    firstAt: firstAt,
    lastAt: lastAt,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is FirstGroup &&
      other.id == id &&
      other.name == name &&
      other.idea == idea &&
      other.source == source &&
      other.noteCount == noteCount &&
      other.firstNoteId == firstNoteId &&
      other.firstNoteTitle == firstNoteTitle &&
      other.firstAt == firstAt &&
      other.lastAt == lastAt &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    idea,
    source,
    noteCount,
    firstNoteId,
    firstNoteTitle,
    firstAt,
    lastAt,
    createdAt,
  );
}

/// Quy tắc nhóm lần đầu (Figma `Spec · Nhóm lần đầu`).
abstract final class FirstGroups {
  static const int nameMaxLength = 24;

  /// Mốc của nhóm: Lần đầu → Lần 3 → Lần 10.
  static const List<int> milestones = <int>[1, 3, 10];

  /// 8 nhóm hệ thống, hiện làm gợi ý trên kệ cho tới khi có nốt đầu tiên.
  static const List<FirstGroup> system = <FirstGroup>[
    FirstGroup(
      id: 'bat-chuyen',
      name: 'Bắt chuyện',
      idea: GroupIdea.nguoiLa,
      source: GroupSource.system,
    ),
    FirstGroup(
      id: 'hoi-thay-co',
      name: 'Hỏi thầy cô',
      idea: GroupIdea.nguoiLa,
      source: GroupSource.system,
    ),
    FirstGroup(
      id: 'len-tieng-trong-nhom',
      name: 'Lên tiếng trong nhóm',
      idea: GroupIdea.chienThang,
      source: GroupSource.system,
    ),
    FirstGroup(
      id: 'van-dong-mot-minh',
      name: 'Vận động một mình',
      idea: GroupIdea.vanDong,
      source: GroupSource.system,
    ),
    FirstGroup(
      id: 'dung-luot-dem',
      name: 'Dừng lướt đêm',
      idea: GroupIdea.tuChu,
      source: GroupSource.system,
    ),
    FirstGroup(
      id: 'ngu-truoc-1h',
      name: 'Ngủ trước 1h',
      idea: GroupIdea.tuChu,
      source: GroupSource.system,
    ),
    FirstGroup(
      id: 'viet-nhat-ky-dai',
      name: 'Viết nhật ký dài',
      idea: GroupIdea.nhatKy,
      source: GroupSource.system,
    ),
    FirstGroup(
      id: 'tu-di-noi-moi',
      name: 'Tự đi nơi mới',
      idea: GroupIdea.vanDong,
      source: GroupSource.system,
    ),
  ];

  static FirstGroup? systemById(String id) {
    for (final group in system) {
      if (group.id == id) return group;
    }
    return null;
  }

  /// Mốc kế tiếp sau [count] lần (Lần 3, Lần 10), `null` khi đã qua Lần 10.
  static int? nextMilestone(int count) {
    for (final m in milestones) {
      if (count < m) return m;
    }
    return null;
  }

  /// Nhãn của mốc [m]: "Lần đầu", "Lần 3", "Lần 10".
  static String milestoneLabel(int m) => m == 1 ? 'Lần đầu' : 'Lần $m';

  /// Khoá so trùng tên: bỏ dấu, không phân biệt hoa thường, gộp khoảng trắng.
  static String nameKey(String name) =>
      _stripMarks(name.trim().toLowerCase()).replaceAll(RegExp(r'\s+'), ' ');

  /// Id ổn định từ tên (dùng cho nhóm người dùng tạo): "Đi chợ một mình" →
  /// `di-cho-mot-minh`.
  static String slug(String name) =>
      nameKey(name)
          .replaceAll(RegExp('[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');

  static const String _from =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const String _to =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

  static String _stripMarks(String text) {
    final out = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final i = _from.indexOf(char);
      out.write(i < 0 ? char : _to[i]);
    }
    return out.toString();
  }
}
