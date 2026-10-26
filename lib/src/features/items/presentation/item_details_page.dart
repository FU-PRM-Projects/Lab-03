import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/item.dart';
import 'items_controller.dart';

/// Detail screen for a single [Item], addressed by [itemId].
class ItemDetailsPage extends ConsumerWidget {
  const ItemDetailsPage({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsControllerProvider);
    final items = itemsAsync.value;

    final Widget body;
    if (itemsAsync.hasError && items == null) {
      body = ErrorView(
        message: 'Could not load this item.',
        onRetry: () => ref.invalidate(itemsControllerProvider),
      );
    } else if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final item = _findItem(items, itemId);
      body = item == null
          ? ErrorView(
              message: 'Item "$itemId" was not found.',
              icon: Icons.search_off,
              onRetry: () => context.go(AppRoutes.items),
              retryLabel: 'Back to items',
            )
          : _ItemDetails(item: item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Item details')),
      body: body,
    );
  }

  static Item? _findItem(List<Item> items, String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(item.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Chip(label: Text(item.category)),
            Chip(label: Text(item.level.label)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          item.description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 32),
        FilledButton.tonalIcon(
          onPressed: () => context.go(AppRoutes.items),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to items'),
        ),
      ],
    );
  }
}
