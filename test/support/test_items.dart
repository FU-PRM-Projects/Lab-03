import 'package:lab03/src/features/items/domain/item.dart';

/// Small, deterministic fixtures shared by tests.
const List<Item> testItems = <Item>[
  Item(
    id: 'alpha',
    title: 'Alpha item',
    description: 'First test item description.',
    category: 'Testing',
    level: ItemLevel.beginner,
  ),
  Item(
    id: 'beta',
    title: 'Beta item',
    description: 'Second test item description.',
    category: 'Testing',
    level: ItemLevel.advanced,
  ),
];
