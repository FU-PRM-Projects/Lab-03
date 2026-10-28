import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../common/screen_skeleton.dart';

/// Tab con của S11.
enum JourneyTab {
  path('path', 'Con đường'),
  stats('stats', 'Thống kê'),
  calendar('calendar', 'Lịch');

  const JourneyTab(this.id, this.label);

  final String id;
  final String label;

  static JourneyTab fromId(String? id) =>
      values.firstWhere((tab) => tab.id == id, orElse: () => JourneyTab.path);
}

/// S11 · Hành trình (tab 4): Con đường, Thống kê, Lịch.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({this.tab = JourneyTab.path, super.key});

  final JourneyTab tab;

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'Hành trình',
      body: ScreenSkeleton(
        code: 'S11',
        name: 'Hành trình · ${tab.label}',
        children: <Widget>[
          SegmentedButton<JourneyTab>(
            segments: <ButtonSegment<JourneyTab>>[
              for (final value in JourneyTab.values)
                ButtonSegment<JourneyTab>(
                  value: value,
                  label: Text(value.label),
                ),
            ],
            selected: <JourneyTab>{tab},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                context.go(AppRoutes.journeyTab(selection.single.id)),
          ),
        ],
      ),
    );
  }
}
