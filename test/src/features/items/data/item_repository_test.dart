import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/src/features/items/data/item_repository.dart';

void main() {
  group('InMemoryItemRepository', () {
    test('returns a non-empty, unmodifiable list with unique ids', () async {
      const repository = InMemoryItemRepository(latency: Duration.zero);

      final items = await repository.fetchItems();

      expect(items, isNotEmpty);
      expect(items.map((item) => item.id).toSet(), hasLength(items.length));
      expect(() => items.add(items.first), throwsUnsupportedError);
    });
  });
}
