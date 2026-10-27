import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../common/screen_skeleton.dart';

/// S07 · Thử thách (tab 3).
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'Thử thách',
      body: ScreenSkeleton(
        code: 'S07',
        name: 'Thử thách',
        links: <SkeletonLink>[
          SkeletonLink(
            'Nhận thử thách (S08)',
            (context) => context.push(AppRoutes.challengeDetail('preview')),
          ),
        ],
      ),
    );
  }
}
