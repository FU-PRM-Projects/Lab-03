import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../common/screen_skeleton.dart';

/// S03 · Ghi nốt (3 bước: tâm trạng → chiến thắng → vài dòng).
class NoteComposerScreen extends StatelessWidget {
  const NoteComposerScreen({this.step = 1, super.key});

  /// Bước 1–3 (`?step=`).
  final int step;

  @override
  Widget build(BuildContext context) {
    return NestedScaffold(
      title: 'Ghi nốt',
      body: ScreenSkeleton(
        code: 'S03',
        name: 'Ghi nốt · bước $step/3',
        links: <SkeletonLink>[
          // S04 thay route S03 (go, không push) theo handout mục 3.
          SkeletonLink(
            'Lưu vào hũ (tạm)',
            (context) => context.go(AppRoutes.noteSaved('preview')),
          ),
        ],
      ),
    );
  }
}
