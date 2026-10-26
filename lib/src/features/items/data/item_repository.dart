import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/item.dart';

/// Data source for [Item]s.
abstract interface class ItemRepository {
  Future<List<Item>> fetchItems();
}

/// The repository used by the app.
///
/// Override this provider in tests or replace it with an HTTP-backed
/// implementation without touching the presentation layer.
final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => const InMemoryItemRepository(),
);

/// A deterministic, in-memory repository with simulated latency.
class InMemoryItemRepository implements ItemRepository {
  const InMemoryItemRepository({
    this.latency = const Duration(milliseconds: 400),
  });

  final Duration latency;

  @override
  Future<List<Item>> fetchItems() async {
    await Future<void>.delayed(latency);
    return List<Item>.unmodifiable(_items);
  }

  static const List<Item> _items = <Item>[
    Item(
      id: 'flutter-layouts',
      title: 'Flutter layouts',
      description:
          'Compose layouts with Row, Column, and Flex. Learn how constraints '
          'flow down the tree and how sizes flow back up.',
      category: 'Flutter',
      level: ItemLevel.beginner,
    ),
    Item(
      id: 'riverpod-state',
      title: 'Riverpod state',
      description:
          'Model asynchronous state with AsyncNotifier. Keep loading, data, '
          'and error states explicit instead of scattering booleans.',
      category: 'State management',
      level: ItemLevel.intermediate,
    ),
    Item(
      id: 'go-router-navigation',
      title: 'go_router navigation',
      description:
          'Declarative routing with deep links, path parameters, and a '
          'stateful shell that preserves each tab navigation stack.',
      category: 'Navigation',
      level: ItemLevel.intermediate,
    ),
    Item(
      id: 'widget-testing',
      title: 'Widget testing',
      description:
          'Write fast widget tests with WidgetTester, provider overrides, '
          'and deterministic fakes instead of relying on the network.',
      category: 'Testing',
      level: ItemLevel.intermediate,
    ),
    Item(
      id: 'dart-async',
      title: 'Dart async',
      description:
          'Work with futures, streams, and structured concurrency. Know when '
          'to await, when to unawait, and how to surface failures.',
      category: 'Dart',
      level: ItemLevel.beginner,
    ),
    Item(
      id: 'release-shipping',
      title: 'Shipping releases',
      description:
          'Prepare Android, iOS, and web builds with versioning, CI checks, '
          'and signed artifacts that are reproducible from a clean checkout.',
      category: 'Delivery',
      level: ItemLevel.advanced,
    ),
  ];
}
