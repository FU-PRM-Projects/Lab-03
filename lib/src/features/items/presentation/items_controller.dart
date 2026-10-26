import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/item_repository.dart';
import '../domain/item.dart';

/// Loads the item list and exposes an explicit refresh action.
///
/// Automatic retries are disabled so failures surface immediately and can be
/// retried deliberately by the user.
final itemsControllerProvider =
    AsyncNotifierProvider<ItemsController, List<Item>>(
      ItemsController.new,
      retry: (retryCount, error) => null,
    );

/// Async state holder for the item list.
class ItemsController extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() {
    return ref.watch(itemRepositoryProvider).fetchItems();
  }

  /// Re-fetches items while Riverpod keeps the previous data visible.
  ///
  /// Invalidate the provider instead of setting [state] manually so Riverpod
  /// can retain the previous data during the rebuild. Listeners can await the
  /// provider's `future` when they need to know the refresh has finished.
  void refresh() {
    ref.invalidateSelf();
  }
}
