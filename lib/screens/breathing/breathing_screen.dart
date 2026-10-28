import 'package:material_ui/material_ui.dart';

import '../common/screen_skeleton.dart';

/// S10 · Thở 90 giây. Mở thẳng, không chờ dữ liệu (tiêu chí < 2 giây).
class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NestedScaffold(
      title: 'Thở cùng Nốt',
      body: ScreenSkeleton(code: 'S10', name: 'Thở 90 giây'),
    );
  }
}
