/// Route paths and names used across the app.
abstract final class AppRoutes {
  static const String items = '/items';
  static const String itemsName = 'items';

  /// Relative path of the item details route under [items].
  static const String itemDetails = ':id';
  static const String itemDetailsName = 'item-details';

  static const String settings = '/settings';
  static const String settingsName = 'settings';
}
