import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/screens/dev/component_gallery_screen.dart';
import 'package:lab03/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

/// Checklist accessibility của Lab 2 trên toàn bộ thư viện component, ở hai
/// bề rộng 360 dp và 412 dp.
void main() {
  for (final width in <double>[phone360.width, phone412.width]) {
    testWidgets('component ở $width dp: không tràn, vùng chạm ≥ 48, contrast', (
      tester,
    ) async {
      // Đủ cao để mọi component được dựng cùng lúc.
      setScreenSize(tester, Size(width, 4200));
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const _NoAnimations();
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const ComponentGalleryScreen(),
        ),
      );
      // Nút Loading quay mãi nên không dùng pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }
}

class _NoAnimations implements AccessibilityFeatures {
  const _NoAnimations();

  @override
  bool get disableAnimations => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}
