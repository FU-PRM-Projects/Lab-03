import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/item.dart';
import 'items_controller.dart';

/// Lists all available items.
class ItemsPage extends ConsumerWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsControllerProvider);
    final items = itemsAsync.value;

    final Widget body;
    if (itemsAsync.hasError && items == null) {
      body = ErrorView(
        message: 'Could not load items.',
        onRetry: () => ref.invalidate(itemsControllerProvider),
      );
    } else if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: () async {
          ref.read(itemsControllerProvider.notifier).refresh();
          await ref.read(itemsControllerProvider.future);
        },
        child: _ItemList(items: items),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: <Widget>[
          IconButton(
            onPressed: () =>
                ref.read(itemsControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh items',
          ),
        ],
      ),
      body: body,
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 96),
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Center(child: Text('No items yet. Pull to refresh.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context)
                  .colorScheme
                  .onSecondaryContainer,
              child: Text(item.category.substring(0, 1)),
            ),
            title: Text(
              item.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${item.category} · ${item.level.label}'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(
              AppRoutes.itemDetailsName,
              pathParameters: <String, String>{'id': item.id},
            ),
          ),
        );
      },
    );
  }
}
