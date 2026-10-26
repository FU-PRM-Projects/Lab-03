import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/src/app/app.dart';

/// Pumps the real app with optional provider overrides.
Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const Lab03App()),
  );
}
