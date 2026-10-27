import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../common/screen_skeleton.dart';

/// S04 · Nốt đã vào hũ.
class NoteSavedScreen extends StatelessWidget {
  const NoteSavedScreen({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    // Back và "Về Hôm nay" đều về S02 (handout mục 3).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.today);
      },
      child: Scaffold(
        body: SafeArea(
          child: ScreenSkeleton(
            code: 'S04',
            name: 'Nốt đã vào hũ',
            links: <SkeletonLink>[
              SkeletonLink(
                'Về Hôm nay',
                (context) => context.go(AppRoutes.today),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
