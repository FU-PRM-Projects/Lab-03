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

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
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
        titleTextStyle: text.headlineSmall,
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
          foregroundColor: scheme.onPrimaryContainer,
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
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s14,
        ),
        labelStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
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
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainerHighest,
        labelStyle: text.bodyMedium,
        secondaryLabelStyle: text.bodyMedium?.copyWith(color: scheme.onPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s10,
        ),
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
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: AppElevation.flat,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
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
}
