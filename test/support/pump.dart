import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/app.dart';
import 'package:lab03/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Khung thiết kế Lab 2 và khung kiểm tra thêm.
const Size phone360 = Size(360, 800);
const Size phone412 = Size(412, 915);

/// Đặt kích thước màn hình (dp) cho test và trả lại sau test.
void setScreenSize(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Bơm cả app (router, theme) với các override service tuỳ chọn.
Future<void> pumpApp(
  WidgetTester tester, {
  Size size = phone360,
  List<Override> overrides = const <Override>[],
}) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const NotApp()),
  );
  await tester.pumpAndSettle();
}

/// Bơm một widget trong theme Lab 2.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Size size = phone360,
}) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
