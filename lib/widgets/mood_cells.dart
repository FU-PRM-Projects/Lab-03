import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/mood.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Component `Cell/Ngày năng lượng` (Final UI): ô 48 × 56, bên trong là tờ
/// nốt 42 × 50 (bo 12, góc trên phải 3) tô màu tâm trạng `heat/1…5`, số ngày
/// và khuôn mặt theo tâm trạng, nên không chỉ báo bằng màu. Hôm nay có viền
/// on-surface 3.
class MoodDayCell extends StatelessWidget {
  const MoodDayCell({
    required this.day,
    required this.semanticDate,
    this.mood,
    this.inMonth = true,
    this.today = false,
    this.onTap,
    super.key,
  });

  final int day;

  /// Ngày đọc cho trình đọc màn hình, ví dụ "24 tháng 10".
  final String semanticDate;
  final Mood? mood;
  final bool inMonth;
  final bool today;
  final VoidCallback? onTap;

  static const BorderRadius _noteRadius = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.r12),
    topRight: Radius.circular(3),
    bottomLeft: Radius.circular(AppRadius.r12),
    bottomRight: Radius.circular(AppRadius.r12),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    final Color background = !inMonth
        ? const Color(0x00000000)
        : mood == null
        ? scheme.surfaceContainerHighest
        : colors.mood(mood!);

    return Semantics(
      button: onTap != null,
      label:
          '$semanticDate, ${mood?.label ?? 'chưa ghi'}'
          '${today ? ', hôm nay' : ''}',
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox.fromSize(
        size: AppSize.moodDayCell,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: _noteRadius,
              side: today
                  ? BorderSide(color: scheme.onSurface, width: 3)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const RoundedRectangleBorder(
                borderRadius: _noteRadius,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpace.s4,
                children: <Widget>[
                  Text(
                    '$day',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: inMonth
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (inMonth && mood != null)
                    SvgPicture.asset(
                      mood!.faceAsset,
                      width: 20,
                      height: 10,
                      excludeFromSemantics: true,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Khuôn mặt nhỏ trong ô lịch (Vui và Ổn dùng chung mặt cười).
extension MoodFace on Mood {
  String get faceAsset => switch (this) {
    Mood.vui || Mood.on => 'assets/faces/face-vui.svg',
    Mood.binhThuong => 'assets/faces/face-binh-thuong.svg',
    Mood.met => 'assets/faces/face-met.svg',
    Mood.roi => 'assets/faces/face-roi.svg',
  };
}

/// Component `Cell/Pixel năm`: ô nhỏ chế độ Năm, chỉ trang trí (có chú giải
/// chữ đi kèm).
class MoodPixel extends StatelessWidget {
  const MoodPixel({this.mood, this.hasDay = true, super.key});

  final Mood? mood;

  /// `false` cho ô không có ngày (ví dụ 30/2).
  final bool hasDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSize.moodPixel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: !hasDay
                ? const Color(0x00000000)
                : mood == null
                ? scheme.surfaceContainerHighest
                : AppColors.of(context).mood(mood!),
            borderRadius: BorderRadius.circular(AppRadius.r4 / 2),
          ),
        ),
      ),
    );
  }
}
