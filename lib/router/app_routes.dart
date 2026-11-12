/// Đường dẫn route theo bảng điều hướng của `flutter-handoff.md` mục 3.
abstract final class AppRoutes {
  /// Màn chờ trong lúc chưa biết trạng thái đăng nhập (không có trong Figma).
  static const String splash = '/splash';
  static const String welcome = '/welcome';

  /// Tài khoản `staff` / `admin` đăng nhập vào app: báo dùng web admin.
  static const String wrongRole = '/wrong-role';
  static const String today = '/today';
  static const String noteNew = '/note/new';

  /// S03b "Kể tự do" (Nốt AI sắp xếp giúp).
  static const String freeTell = '/note/free-tell';
  static const String jar = '/jar';
  static const String challenges = '/challenges';
  static const String selfControl = '/self-control';

  /// Viết nhật ký (nốt loại Nhật ký).
  static const String journal = '/journal';
  static const String breathe = '/breathe';
  static const String journey = '/journey';
  static const String settings = '/settings';
  static const String onboarding = '/onboarding';

  /// Thư viện component để đối chiếu với Figma (không có ở bản release).
  static const String componentGallery = '/dev/components';

  /// Đường dẫn của 4 tab, theo thứ tự trên thanh tab.
  static const List<String> tabs = <String>[today, jar, challenges, journey];

  /// S03 ở bước [step] (1–3); [groupId] xếp nốt vào nhóm lần đầu đó.
  static String newNote({int step = 1, String? groupId}) => groupId == null
      ? '$noteNew?step=$step'
      : '$noteNew?step=$step&group=${Uri.encodeQueryComponent(groupId)}';

  /// "Xem tất cả" nhóm lần đầu.
  static const String groups = '$jar/groups';

  /// S05e · Chi tiết nhóm.
  static String groupDetail(String id) => '$groups/$id';

  /// S04 cho nốt [id] vừa lưu.
  static String noteSaved(String id) => '/note/saved/$id';

  /// S06; [edit] mở sẵn chế độ sửa ("Viết thêm" ở S04).
  static String noteDetail(String id, {bool edit = false}) =>
      edit ? '$jar/$id?edit=1' : '$jar/$id';

  /// S08.
  static String challengeDetail(String id) => '$challenges/$id';

  /// S08d · Câu chào của bạn (thẻ thử thách trên Discord).
  static String challengeGreeting(String id) => '$challenges/$id/greeting';

  /// S14 · Phòng trò chuyện (Discord).
  static const String rooms = '/rooms';

  /// S11 ở tab con [tab]: `path`, `stats` hoặc `calendar`.
  static String journeyTab(String tab) => '$journey?tab=$tab';
}
