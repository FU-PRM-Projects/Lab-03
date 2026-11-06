import 'package:material_ui/material_ui.dart';

import '../models/mood.dart';
import '../models/note_type.dart';

/// Figma Variables, collection **Color** (mode Light) của Lab 2.
///
/// Chỉ `theme/` được đọc các hằng này; widget đọc màu qua
/// `Theme.of(context).colorScheme` hoặc [AppColors.of].
abstract final class AppPalette {
  static const Color primary = Color(0xFF3D4FD6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDCE6FF);
  static const Color onPrimaryContainer = Color(0xFF2F3FB8);
  static const Color primaryDark = Color(0xFF2B399F);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFF6F7FB);
  static const Color surfaceVariant = Color(0xFFE7E9F3);
  static const Color surfaceContainer = Color(0xFFE7E9F3);
  static const Color outline = Color(0xFF7A8094);
  static const Color outlineVariant = Color(0xFFE3E5EE);
  static const Color switchOff = Color(0xFFC3C7D4);
  static const Color onSurface = Color(0xFF1B1D2A);
  static const Color onSurfaceVariant = Color(0xFF555B6E);
  static const Color onSurfaceMuted = Color(0xFF3A3F52);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFFA84F00);
  static const Color success = Color(0xFF187A4D);

  static const Color heat1 = Color(0xFFA9DCF5);
  static const Color heat2 = Color(0xFF7FD9B3);
  static const Color heat3 = Color(0xFFFFD24A);
  static const Color heat4 = Color(0xFFFF9A3D);
  static const Color heat5 = Color(0xFFF0524B);

  static const Color tintOrange = Color(0xFFFFEBD6);
  static const Color tintViolet = Color(0xFFECEBFC);
  static const Color tintGreen = Color(0xFFDDF5EA);
  static const Color tintBlue = Color(0xFFE3F3FB);
  static const Color tintRed = Color(0xFFFDE1DF);
  static const Color tintGray = Color(0xFFECEEF3);
  static const Color tintLavender = Color(0xFFEEF0FE);

  static const Color mono1 = Color(0xFFDFE3FD);
  static const Color mono2 = Color(0xFFC0C8F8);
  static const Color mono3 = Color(0xFF9EA9F3);
  static const Color mono4 = Color(0xFF7A88EA);
}

/// `ColorScheme` theo bảng 1.1 của `flutter-handoff.md`.
const ColorScheme appColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppPalette.primary,
  onPrimary: AppPalette.onPrimary,
  primaryContainer: AppPalette.primaryContainer,
  onPrimaryContainer: AppPalette.onPrimaryContainer,
  // Lab 2 không có màu secondary; dùng lại họ primary để component M3 mặc
  // định không lấy màu ngoài bảng token.
  secondary: AppPalette.primary,
  onSecondary: AppPalette.onPrimary,
  secondaryContainer: AppPalette.primaryContainer,
  onSecondaryContainer: AppPalette.onPrimaryContainer,
  error: AppPalette.error,
  onError: AppPalette.onPrimary,
  errorContainer: AppPalette.tintRed,
  onErrorContainer: AppPalette.error,
  surface: AppPalette.surface,
  onSurface: AppPalette.onSurface,
  onSurfaceVariant: AppPalette.onSurfaceVariant,
  surfaceContainerLowest: AppPalette.surface,
  surfaceContainerLow: AppPalette.surfaceCard,
  surfaceContainer: AppPalette.surfaceContainer,
  surfaceContainerHigh: AppPalette.surfaceVariant,
  surfaceContainerHighest: AppPalette.surfaceVariant,
  outline: AppPalette.outline,
  outlineVariant: AppPalette.outlineVariant,
  inverseSurface: AppPalette.onSurface,
  onInverseSurface: AppPalette.surface,
  inversePrimary: AppPalette.primaryContainer,
  shadow: AppPalette.onSurface,
  scrim: AppPalette.onSurface,
  // Lab 2 tách lớp bằng màu nền, không phủ màu primary lên bề mặt nổi.
  surfaceTint: Color(0x00000000),
);

/// Màu riêng của Nốt không có vai trò tương ứng trong `ColorScheme`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primaryDark,
    required this.onSurfaceMuted,
    required this.warning,
    required this.success,
    required this.switchOff,
    required this.streak,
    required this.streakContainer,
    required this.tintGray,
    required this.tintLavender,
    required this.moods,
    required this.noteTints,
    required this.chart,
  });

  static const AppColors light = AppColors(
    primaryDark: AppPalette.primaryDark,
    onSurfaceMuted: AppPalette.onSurfaceMuted,
    warning: AppPalette.warning,
    success: AppPalette.success,
    switchOff: AppPalette.switchOff,
    streak: AppPalette.heat4,
    streakContainer: AppPalette.tintOrange,
    tintGray: AppPalette.tintGray,
    tintLavender: AppPalette.tintLavender,
    moods: <Mood, Color>{
      Mood.vui: AppPalette.heat1,
      Mood.on: AppPalette.heat2,
      Mood.binhThuong: AppPalette.heat3,
      Mood.met: AppPalette.heat4,
      Mood.roi: AppPalette.heat5,
    },
    noteTints: <NoteType, Color>{
      NoteType.chienThang: AppPalette.tintOrange,
      NoteType.tuChu: AppPalette.tintViolet,
      NoteType.thuThach: AppPalette.tintGreen,
      NoteType.nhatKy: AppPalette.tintBlue,
    },
    chart: <Color>[
      AppPalette.mono1,
      AppPalette.mono2,
      AppPalette.mono3,
      AppPalette.mono4,
      AppPalette.primary,
    ],
  );

  final Color primaryDark;
  final Color onSurfaceMuted;
  final Color warning;
  final Color success;
  final Color switchOff;

  /// Ngọn lửa và vòng ngày đã ghi của chuỗi ngày.
  final Color streak;

  /// Nền thẻ chuỗi ngày.
  final Color streakContainer;

  /// Nền trạng thái lỗi và banner offline.
  final Color tintGray;

  /// Nền trạng thái rỗng.
  final Color tintLavender;

  /// `heat/1` … `heat/5`.
  final Map<Mood, Color> moods;

  /// `tint/orange`, `violet`, `green`, `blue`.
  final Map<NoteType, Color> noteTints;

  /// `mono/1` … `mono/5`, nhạt đến đậm.
  final List<Color> chart;

  Color mood(Mood mood) => moods[mood]!;

  Color noteTint(NoteType type) => noteTints[type]!;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? primaryDark,
    Color? onSurfaceMuted,
    Color? warning,
    Color? success,
    Color? switchOff,
    Color? streak,
    Color? streakContainer,
    Color? tintGray,
    Color? tintLavender,
    Map<Mood, Color>? moods,
    Map<NoteType, Color>? noteTints,
    List<Color>? chart,
  }) {
    return AppColors(
      primaryDark: primaryDark ?? this.primaryDark,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      switchOff: switchOff ?? this.switchOff,
      streak: streak ?? this.streak,
      streakContainer: streakContainer ?? this.streakContainer,
      tintGray: tintGray ?? this.tintGray,
      tintLavender: tintLavender ?? this.tintLavender,
      moods: moods ?? this.moods,
      noteTints: noteTints ?? this.noteTints,
      chart: chart ?? this.chart,
    );
  }

  // App chỉ có light theme (Lab 2 không có dark theme), nên không cần nội suy
  // giữa hai bộ màu.
  @override
  AppColors lerp(AppColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
