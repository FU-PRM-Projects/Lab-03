import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_info.dart';
import '../../items/presentation/items_controller.dart';
import 'theme_mode_controller.dart';

/// App preferences and diagnostic actions.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('System'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Dark'),
              ),
            ],
            selected: <ThemeMode>{themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(themeModeControllerProvider.notifier)
                .select(selection.single),
          ),
          const SizedBox(height: 24),
          Text('Data', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Refresh cached items'),
              subtitle: const Text(
                'Re-fetch the item list from the repository.',
              ),
              onTap: () {
                ref.invalidate(itemsControllerProvider);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Items refreshed.')),
                  );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('About', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text(AppInfo.name),
                  subtitle: Text('Version ${AppInfo.version}'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.flutter_dash),
                  title: Text('Built with Flutter'),
                  subtitle: Text('Riverpod · go_router · Material 3'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
