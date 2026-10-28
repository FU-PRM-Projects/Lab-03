import 'package:material_ui/material_ui.dart';

/// Figma collection **Size** (`space/*`) và quy ước lề của Lab 2.
abstract final class AppSpace {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;

  /// Lề trái phải của màn hình.
  static const double screen = s16;

  /// Khoảng cách giữa các tờ nốt trong lưới.
  static const double grid = s12;

  /// Khoảng trống cuối nội dung màn tab để thanh tab nổi không che.
  static const double tabContentBottom = 96;
}

/// Bo góc (`radius/*` và các giá trị Lab 2 chưa có Variable, DESIGN.md 5.2).
abstract final class AppRadius {
  static const double r4 = 4;
  static const double r6 = 6;
  static const double r8 = 8;
  static const double r12 = 12;

  /// Tờ nốt.
  static const double note = 14;

  /// Thẻ nốt, ô tâm trạng, nút lớn.
  static const double card = 16;

  /// Thanh tab nổi.
  static const double nav = 32;

  /// Chip (tròn hẳn).
  static const double full = 999;
}

/// Effect Styles của Lab 2.
abstract final class AppElevation {
  /// `Elevation/0 Flat`: thẻ và tờ nốt tách bằng màu nền.
  static const double flat = 0;

  /// `Elevation/2 FAB`: blur 16, y 6, độ mờ 22%.
  static List<BoxShadow> fab(Color shadow) => <BoxShadow>[
    BoxShadow(
      color: shadow.withValues(alpha: 0.22),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Kích thước cố định của component (DESIGN.md mục 7, handoff mục 1.3).
abstract final class AppSize {
  /// Vùng chạm tối thiểu.
  static const double minTouch = 48;

  static const double buttonHeight = 48;
  static const double buttonMinWidth = 64;
  static const double appBarHeight = 48;
  static const double navBarHeight = 64;
  static const double navBarBottomGap = 12;
  static const double fab = 56;
  static const double shortcut = 56;
  static const double avatar = 40;
  static const double noteCardHeight = 72;
  static const double settingRowMinHeight = 56;
  static const Size moodOption = Size(96, 116);
  static const Size moodDayCell = Size(48, 56);
  static const double moodPixel = 10;

  /// Bề rộng nội dung tối đa của S03, S04, S10 trên màn rộng.
  static const double narrowContentMaxWidth = 480;

  /// Bề rộng nội dung tối đa của màn lồng còn lại trên màn rộng.
  static const double contentMaxWidth = 600;
}
