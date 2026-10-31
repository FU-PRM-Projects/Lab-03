/// Mục "Thói quen muốn bớt" ở S09 (`users/{uid}/private/habits`).
class HabitList {
  const HabitList({
    this.selected = const <String>{},
    this.custom = const <String>[],
  });

  /// Gợi ý sẵn (handout S09).
  static const List<String> suggestions = <String>[
    'Lướt mạng xã hội',
    'Video ngắn',
    'Game quá giờ',
    'Nội dung không lành mạnh',
  ];

  /// Độ dài tối đa một thói quen tự thêm (deviation D-02).
  static const int maxLength = 40;

  /// Số thói quen tự thêm tối đa, để danh sách gọn trên một màn.
  static const int maxCustom = 8;

  /// Những thói quen người dùng muốn bớt.
  final Set<String> selected;

  /// Thói quen người dùng tự thêm bằng "+ Thêm".
  final List<String> custom;

  /// Mọi chip hiện trên S09: gợi ý sẵn rồi tới thói quen tự thêm.
  List<String> get all => <String>[...suggestions, ...custom];
}

/// Cài đặt của người dùng (`users/{uid}/private/settings`). Giờ lưu bằng số
/// phút kể từ 0h để model không phụ thuộc Flutter.
class UserSettings {
  const UserSettings({
    this.awakeEnabled = true,
    this.awakeStart = 23 * 60,
    this.awakeEnd = 60,
    this.lockSelfControl = false,
  });

  /// "Giờ tỉnh": nhắc nhẹ trong khung giờ dễ lướt vô thức (mặc định 23:00 – 01:00).
  final bool awakeEnabled;
  final int awakeStart;
  final int awakeEnd;

  /// "Khoá phần Tự chủ" (S12): che mục thói quen ở S09 tới khi mở khoá.
  final bool lockSelfControl;

  UserSettings copyWith({
    bool? awakeEnabled,
    int? awakeStart,
    int? awakeEnd,
    bool? lockSelfControl,
  }) => UserSettings(
    awakeEnabled: awakeEnabled ?? this.awakeEnabled,
    awakeStart: awakeStart ?? this.awakeStart,
    awakeEnd: awakeEnd ?? this.awakeEnd,
    lockSelfControl: lockSelfControl ?? this.lockSelfControl,
  );

  @override
  bool operator ==(Object other) =>
      other is UserSettings &&
      other.awakeEnabled == awakeEnabled &&
      other.awakeStart == awakeStart &&
      other.awakeEnd == awakeEnd &&
      other.lockSelfControl == lockSelfControl;

  @override
  int get hashCode =>
      Object.hash(awakeEnabled, awakeStart, awakeEnd, lockSelfControl);
}
