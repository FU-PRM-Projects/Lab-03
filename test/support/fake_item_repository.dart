import 'package:lab03/src/features/items/data/item_repository.dart';
import 'package:lab03/src/features/items/domain/item.dart';

import 'test_items.dart';

/// Configurable repository double for unit and widget tests.
class FakeItemRepository implements ItemRepository {
  FakeItemRepository({
    List<Item>? items,
    this.error,
    this.latency = Duration.zero,
  }) : items = items ?? testItems;

  final List<Item> items;
  final Object? error;
  final Duration latency;

  int fetchCount = 0;

  @override
  Future<List<Item>> fetchItems() async {
    fetchCount++;

    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }

    final failure = error;
    if (failure != null) {
      throw failure;
    }

    return items;
  }
}
