import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../common/screen_skeleton.dart';

/// S05 · Hũ & Nhật ký (tab 2).
class JarScreen extends StatelessWidget {
  const JarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'Hũ của bạn',
      body: ScreenSkeleton(
        code: 'S05',
        name: 'Hũ & Nhật ký',
        links: <SkeletonLink>[
          SkeletonLink(
            'Mở một nốt (S06)',
            (context) => context.push(AppRoutes.noteDetail('preview')),
          ),
        ],
      ),
    );
  }
}
