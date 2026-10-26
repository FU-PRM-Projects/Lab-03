import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/error_view.dart';
import '../../features/items/presentation/item_details_page.dart';
import '../../features/items/presentation/items_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import 'app_routes.dart';
import 'view/app_shell.dart';

/// The application router.
///
/// Keeping the router in a provider makes it easy to override in tests and
/// lets it be disposed with the surrounding [ProviderScope].
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.items,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.items,
                name: AppRoutes.itemsName,
                builder: (context, state) => const ItemsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: AppRoutes.itemDetails,
                    name: AppRoutes.itemDetailsName,
                    builder: (context, state) =>
                        ItemDetailsPage(itemId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                name: AppRoutes.settingsName,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        RouteErrorPage(location: state.uri.toString()),
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Shown when no route matches the requested location.
class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: ErrorView(
        message: 'No route matches "$location".',
        onRetry: () => context.go(AppRoutes.items),
        retryLabel: 'Go to items',
        icon: Icons.explore_off_outlined,
      ),
    );
  }
}
