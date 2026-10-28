/// Đường dẫn route theo bảng điều hướng của `flutter-handoff.md` mục 3.
abstract final class AppRoutes {
  static const String welcome = '/welcome';
  static const String today = '/today';
  static const String noteNew = '/note/new';
  static const String jar = '/jar';
  static const String challenges = '/challenges';
  static const String selfControl = '/self-control';
  static const String breathe = '/breathe';
  static const String journey = '/journey';
  static const String settings = '/settings';

  /// Thư viện component để đối chiếu với Figma (không có ở bản release).
  static const String componentGallery = '/dev/components';

  /// Đường dẫn của 4 tab, theo thứ tự trên thanh tab.
  static const List<String> tabs = <String>[today, jar, challenges, journey];

  /// S03 ở bước [step] (1–3).
  static String newNote({int step = 1}) => '$noteNew?step=$step';

  /// S04 cho nốt [id] vừa lưu.
  static String noteSaved(String id) => '/note/saved/$id';

  /// S06.
  static String noteDetail(String id) => '$jar/$id';

  /// S08.
  static String challengeDetail(String id) => '$challenges/$id';

  /// S11 ở tab con [tab]: `path`, `stats` hoặc `calendar`.
  static String journeyTab(String tab) => '$journey?tab=$tab';
}
