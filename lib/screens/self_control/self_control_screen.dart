import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../common/screen_skeleton.dart';

/// S09 · Tự chủ.
class SelfControlScreen extends StatelessWidget {
  const SelfControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NestedScaffold(
      title: 'Tự chủ',
      body: ScreenSkeleton(
        code: 'S09',
        name: 'Tự chủ',
        links: <SkeletonLink>[
          SkeletonLink(
            'Khó dừng? Thở 90 giây',
            (context) => context.push(AppRoutes.breathe),
          ),
        ],
      ),
    );
  }
}
