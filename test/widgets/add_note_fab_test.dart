import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/widgets/add_note_fab.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

/// Crashlytics ghi lỗi "multiple heroes that share the same tag" (13 sự kiện):
/// các tab của `StatefulShellRoute.indexedStack` cùng nằm trong một route và
/// mỗi tab có một nút + dùng heroTag mặc định chung. Nút này không cần Hero.
void main() {
  testWidgets('AddNoteFab không tham gia Hero', (tester) async {
    await pumpThemed(
      tester,
      Scaffold(floatingActionButton: AddNoteFab(onPressed: () {})),
    );

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.heroTag, isNull);
  });
}
