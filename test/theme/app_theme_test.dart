import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/theme/app_colors.dart';
import 'package:lab03/theme/app_theme.dart';
import 'package:lab03/theme/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// Tỉ lệ contrast WCAG 2.x giữa hai màu đặc.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final theme = AppTheme.light();
  final scheme = theme.colorScheme;
  final colors = theme.extension<AppColors>()!;
  final text = theme.textTheme;

  group('Màu (DESIGN.md mục 3)', () {
    test('ColorScheme lấy đúng Figma Variables', () {
      expect(scheme.primary, const Color(0xFF3D4FD6));
      expect(scheme.onPrimary, const Color(0xFFFFFFFF));
      expect(scheme.primaryContainer, const Color(0xFFDCE6FF));
      expect(scheme.onPrimaryContainer, const Color(0xFF2F3FB8));
      expect(scheme.surface, const Color(0xFFFFFFFF));
      expect(scheme.surfaceContainerLow, const Color(0xFFF6F7FB));
      expect(scheme.surfaceContainerHighest, const Color(0xFFE7E9F3));
      expect(scheme.onSurface, const Color(0xFF1B1D2A));
      expect(scheme.onSurfaceVariant, const Color(0xFF555B6E));
      expect(scheme.outline, const Color(0xFF7A8094));
      expect(scheme.outlineVariant, const Color(0xFFE3E5EE));
      expect(scheme.error, const Color(0xFFB3261E));
      expect(scheme.errorContainer, const Color(0xFFFDE1DF));
    });

    test('AppColors có đủ màu tâm trạng, loại nốt và biểu đồ', () {
      expect(colors.moods.keys, containsAll(Mood.values));
      expect(colors.noteTints.keys, containsAll(NoteType.values));
      expect(colors.chart, hasLength(5));
      expect(colors.mood(Mood.vui), const Color(0xFFA9DCF5));
      expect(colors.mood(Mood.roi), const Color(0xFFF0524B));
      expect(colors.noteTint(NoteType.chienThang), const Color(0xFFFFEBD6));
      expect(colors.success, const Color(0xFF187A4D));
      expect(colors.switchOff, const Color(0xFFC3C7D4));
    });

    test('các cặp chữ/nền trong DESIGN.md 3.4 đạt 4.5:1', () {
      final pairs = <String, (Color, Color)>{
        'on-surface / surface': (scheme.onSurface, scheme.surface),
        'on-surface-variant / surface-card': (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerLow,
        ),
        'on-primary / primary': (scheme.onPrimary, scheme.primary),
        'on-primary-container / primary-container': (
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        ),
        'success / surface': (colors.success, scheme.surface),
        'error / surface': (scheme.error, scheme.surface),
        'on-surface-muted / tint loại nốt': (
          colors.onSurfaceMuted,
          colors.noteTint(NoteType.chienThang),
        ),
        for (final mood in Mood.values)
          'on-surface / ${mood.label}': (scheme.onSurface, colors.mood(mood)),
      };

      for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: name);
      }
    });
  });

  group('Chữ (DESIGN.md mục 4)', () {
    test('cỡ, độ đậm và line height theo bảng handout 1.2', () {
      void check(TextStyle? style, double size, FontWeight weight) {
        expect(style?.fontSize, size);
        expect(style?.fontWeight, weight);
      }

      check(text.displayMedium, 44, FontWeight.w700);
      check(text.displaySmall, 36, FontWeight.w700);
      check(text.headlineMedium, 28, FontWeight.w700);
      check(text.headlineSmall, 24, FontWeight.w700);
      check(text.titleLarge, 22, FontWeight.w700);
      check(text.titleMedium, 18, FontWeight.w700);
      check(text.titleSmall, 17, FontWeight.w600);
      check(text.bodyLarge, 16, FontWeight.w400);
      check(text.bodyMedium, 15, FontWeight.w400);
      check(text.bodySmall, 14, FontWeight.w400);
      check(text.labelLarge, 14, FontWeight.w600);
      check(text.labelMedium, 13, FontWeight.w600);
      check(text.labelSmall, 12, FontWeight.w600);
      expect(text.bodyLarge?.height, 1.4);
      expect(text.headlineMedium?.height, 1.25);

      final extra = theme.extension<AppTextStyles>()!;
      expect(extra.overline.fontSize, 12);
      expect(extra.overline.letterSpacing, 0.5);
      expect(extra.body17.fontSize, 17);
    });

    test('mọi kiểu chữ nội dung (body*) từ 14 sp trở lên', () {
      for (final style in <TextStyle?>[
        text.bodyLarge,
        text.bodyMedium,
        text.bodySmall,
      ]) {
        expect(style!.fontSize, greaterThanOrEqualTo(14));
      }
    });

    test('fontBuilder được gắn vào mọi kiểu chữ', () {
      final themed = AppTheme.light(
        font: (style) => style.copyWith(fontFamily: 'Be Vietnam Pro'),
      );
      expect(themed.textTheme.bodyLarge?.fontFamily, 'Be Vietnam Pro');
      expect(themed.textTheme.displayMedium?.fontFamily, 'Be Vietnam Pro');
      expect(
        themed.extension<AppTextStyles>()!.overline.fontFamily,
        'Be Vietnam Pro',
      );
    });
  });

  group('Component theme (DESIGN.md mục 7)', () {
    test('nút cao 48, rộng tối thiểu 64', () {
      final styles = <ButtonStyle?>[
        theme.filledButtonTheme.style,
        theme.outlinedButtonTheme.style,
        theme.textButtonTheme.style,
      ];
      for (final style in styles) {
        expect(
          style!.minimumSize!.resolve(<WidgetState>{}),
          const Size(64, 48),
        );
      }
    });

    test('app bar 48, thanh tab 64, vùng chạm padded', () {
      expect(theme.appBarTheme.toolbarHeight, 48);
      expect(theme.navigationBarTheme.height, 64);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    test('công tắc tắt dùng màu switch-off', () {
      final track = theme.switchTheme.trackColor!;
      expect(track.resolve(<WidgetState>{}), colors.switchOff);
      expect(
        track.resolve(<WidgetState>{WidgetState.selected}),
        scheme.primary,
      );
    });
  });
}
