import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/src/features/items/data/item_repository.dart';
import 'package:lab03/src/features/items/presentation/item_details_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_item_repository.dart';
import '../../support/pump_app.dart';

void main() {
  group('Lab03App', () {
    testWidgets('shows a loader, then the item list', (tester) async {
      await pumpApp(
        tester,
        overrides: [
          itemRepositoryProvider.overrideWithValue(FakeItemRepository()),
        ],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Alpha item'), findsOneWidget);
      expect(find.text('Beta item'), findsOneWidget);
    });

    testWidgets('opens item details from a list item', (tester) async {
      await pumpApp(
        tester,
        overrides: [
          itemRepositoryProvider.overrideWithValue(FakeItemRepository()),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alpha item'));
      await tester.pumpAndSettle();

      expect(find.byType(ItemDetailsPage), findsOneWidget);
      expect(find.text('First test item description.'), findsOneWidget);
    });

    testWidgets('switches tabs and changes the theme mode', (tester) async {
      await pumpApp(
        tester,
        overrides: [
          itemRepositoryProvider.overrideWithValue(FakeItemRepository()),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    });

    testWidgets('shows a retry action when loading fails', (tester) async {
      await pumpApp(
        tester,
        overrides: [
          itemRepositoryProvider.overrideWithValue(
            FakeItemRepository(error: Exception('offline')),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load items.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
