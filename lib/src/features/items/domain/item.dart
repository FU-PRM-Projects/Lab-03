/// Difficulty level shown on an item.
enum ItemLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const ItemLevel(this.label);

  final String label;
}

/// A single learning item displayed by the app.
class Item {
  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final ItemLevel level;
}
