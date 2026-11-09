import 'package:material_ui/material_ui.dart';

/// Gắn font vào một kiểu chữ. App thật truyền Be Vietnam Pro của
/// `google_fonts`; test dùng [plainFont] để không gọi mạng.
typedef FontBuilder = TextStyle Function(TextStyle style);

TextStyle plainFont(TextStyle style) => style;

/// Text Styles của Lab 2 theo bảng 1.2 của `flutter-handoff.md`.
abstract final class AppTypography {
  static TextTheme textTheme({
    required Color color,
    FontBuilder font = plainFont,
  }) {
    TextStyle style(double size, FontWeight weight, double height) => font(
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
        letterSpacing: 0,
      ),
    );

    return TextTheme(
      displayLarge: style(44, FontWeight.w700, 1.25),
      // Display/44 Bold
      displayMedium: style(44, FontWeight.w700, 1.25),
      // Display/36 Bold
      displaySmall: style(36, FontWeight.w700, 1.25),
      headlineLarge: style(28, FontWeight.w700, 1.25),
      // Headline/28 Bold
      headlineMedium: style(28, FontWeight.w700, 1.25),
      // Title/24 Bold
      headlineSmall: style(24, FontWeight.w700, 1.25),
      // Headline/22 Bold
      titleLarge: style(22, FontWeight.w700, 1.25),
      // Title/18 Bold
      titleMedium: style(18, FontWeight.w700, 1.4),
      // Title/17 SemiBold
      titleSmall: style(17, FontWeight.w600, 1.4),
      // Body/16 Regular
      bodyLarge: style(16, FontWeight.w400, 1.4),
      // Body/15 Regular
      bodyMedium: style(15, FontWeight.w400, 1.4),
      // Label/14 Regular
      bodySmall: style(14, FontWeight.w400, 1.4),
      // Label/14 SemiBold (chữ trên nút)
      labelLarge: style(14, FontWeight.w600, 1.4),
      // Label/13 SemiBold
      labelMedium: style(13, FontWeight.w600, 1.4),
      // Caption/12 SemiBold (nhãn tab)
      labelSmall: style(12, FontWeight.w600, 1.4),
    );
  }

  static AppTextStyles extraStyles({
    required Color color,
    FontBuilder font = plainFont,
  }) {
    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      double letterSpacing = 0,
    }) => font(
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );

    return AppTextStyles(
      title20: style(20, FontWeight.w700, 1.25),
      title17Bold: style(17, FontWeight.w700, 1.4),
      body17: style(17, FontWeight.w400, 1.4),
      overline: style(12, FontWeight.w700, 1.4, letterSpacing: 0.5),
    );
  }
}

/// Bốn kiểu chữ Lab 2 không có chỗ trong `TextTheme` của Material 3.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.title20,
    required this.title17Bold,
    required this.body17,
    required this.overline,
  });

  /// `Title/20 Bold`: tiêu đề khối.
  final TextStyle title20;

  /// `Title/17 Bold`: tiêu đề tờ nốt nhấn mạnh.
  final TextStyle title17Bold;

  /// `Body/17 Regular`: nội dung nhật ký dài.
  final TextStyle body17;

  /// `Overline/12 Bold`: "BƯỚC 1/3", "DŨNG CẢM · 2 PHÚT" (viết hoa).
  final TextStyle overline;

  static AppTextStyles of(BuildContext context) =>
      Theme.of(context).extension<AppTextStyles>()!;

  @override
  AppTextStyles copyWith({
    TextStyle? title20,
    TextStyle? title17Bold,
    TextStyle? body17,
    TextStyle? overline,
  }) {
    return AppTextStyles(
      title20: title20 ?? this.title20,
      title17Bold: title17Bold ?? this.title17Bold,
      body17: body17 ?? this.body17,
      overline: overline ?? this.overline,
    );
  }

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) {
    if (other == null) return this;
    return AppTextStyles(
      title20: TextStyle.lerp(title20, other.title20, t)!,
      title17Bold: TextStyle.lerp(title17Bold, other.title17Bold, t)!,
      body17: TextStyle.lerp(body17, other.body17, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
    );
  }
}
