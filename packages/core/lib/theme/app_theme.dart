import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// `ThemeData` dựng từ token Lab 2. App chỉ có light theme (DESIGN.md mục 11).
abstract final class AppTheme {
  static ThemeData light({FontBuilder font = plainFont}) {
    const scheme = appColorScheme;
    const colors = AppColors.light;
    final text = AppTypography.textTheme(color: scheme.onSurface, font: font);

    // Final UI: mọi nút dùng `radius/8`, nhãn Body/16 SemiBold.
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.r8),
    );
    final buttonText = text.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    const buttonMinSize = Size(AppSize.buttonMinWidth, AppSize.buttonHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpace.s24);

    // Final UI `Text field`: nền surface-card, viền outline 1.5, bo 6.
    OutlineInputBorder inputBorder(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r6),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        AppTypography.extraStyles(color: scheme.onSurface, font: font),
      ],
      appBarTheme: AppBarThemeData(
        toolbarHeight: AppSize.appBarHeight,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: AppElevation.flat,
        scrolledUnderElevation: AppElevation.flat,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 20,
          letterSpacing: -0.4,
        ),
      ),
      // Icon/Back, Icon/Close 24 dp nét 2 của Figma.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => _icon(context, 'back'),
        closeButtonIconBuilder: (context) => _icon(context, 'close'),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: scheme.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSize.minTouch),
          foregroundColor: scheme.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const CircleBorder(),
        sizeConstraints: const BoxConstraints.tightFor(
          width: AppSize.fab,
          height: AppSize.fab,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: AppElevation.flat,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s14,
          vertical: AppSpace.s14,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
        ),
        counterStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: scheme.error,
        ),
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        disabledBorder: inputBorder(scheme.outlineVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSize.navBarHeight,
        elevation: AppElevation.flat,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      // Final UI `Chip/Chiến thắng nhanh`: nền surface-card, viền
      // outline-variant, nhãn Label/14 Medium, lề 14 × 10.
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: scheme.primary)
              : BorderSide(color: scheme.outlineVariant),
        ),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainerHighest,
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.onPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s14,
          vertical: AppSpace.s10,
        ),
        labelPadding: EdgeInsets.zero,
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : colors.switchOff,
        ),
        thumbColor: WidgetStateProperty.all(scheme.onPrimary),
        trackOutlineColor: WidgetStateProperty.all(const Color(0x00000000)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(AppSize.minTouch, AppSize.minTouch),
          textStyle: text.labelLarge,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      // Final UI `Dialog`: nền surface-card, bo 12, rộng 304 trên màn 360,
      // tiêu đề Title/20 Bold, nội dung Body/15; scrim on-surface 40%.
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        elevation: 6,
        shadowColor: scheme.shadow,
        barrierColor: scheme.onSurface.withValues(alpha: 0.4),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 20,
          letterSpacing: -0.4,
        ),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: AppSize.settingRowMinHeight,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static Widget _icon(BuildContext context, String name) => SvgPicture.asset(
    'assets/icons/$name.svg',
    package: 'not_core',
    width: 24,
    height: 24,
    colorFilter: ColorFilter.mode(
      IconTheme.of(context).color ?? appColorScheme.onSurface,
      BlendMode.srcIn,
    ),
  );
}
