import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/src/features/settings/presentation/theme_mode_controller.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ThemeModeController', () {
    test('defaults to system', () {
      final container = ProviderContainer.test();

      expect(container.read(themeModeControllerProvider), ThemeMode.system);
    });

    test('select updates the theme mode', () {
      final container = ProviderContainer.test();

      container
          .read(themeModeControllerProvider.notifier)
          .select(ThemeMode.dark);

      expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    });
  });
}
