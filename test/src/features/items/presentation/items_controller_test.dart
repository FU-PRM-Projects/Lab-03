import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/src/features/items/data/item_repository.dart';
import 'package:lab03/src/features/items/presentation/items_controller.dart';

import '../../../../support/fake_item_repository.dart';
import '../../../../support/test_items.dart';

void main() {
  group('ItemsController', () {
    test('loads items from the repository', () async {
      final repository = FakeItemRepository();
      final container = ProviderContainer.test(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
      );

      final items = await container.read(itemsControllerProvider.future);

      expect(items, testItems);
      expect(repository.fetchCount, 1);
    });

    test('refresh re-fetches and exposes data again', () async {
      final repository = FakeItemRepository();
      final container = ProviderContainer.test(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
      );
      await container.read(itemsControllerProvider.future);

      container.read(itemsControllerProvider.notifier).refresh();
      await container.read(itemsControllerProvider.future);

      expect(repository.fetchCount, 2);
      expect(container.read(itemsControllerProvider).value, testItems);
    });

    test('surfaces repository failures', () async {
      final repository = FakeItemRepository(error: Exception('offline'));
      final container = ProviderContainer.test(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
      );

      await expectLater(
        container.read(itemsControllerProvider.future),
        throwsException,
      );
      expect(container.read(itemsControllerProvider).hasError, isTrue);
    });
  });
}
