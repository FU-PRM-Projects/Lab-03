import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../common/screen_skeleton.dart';

/// S12 · Cài đặt (+ khu demo Firebase, deviation D-01).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NestedScaffold(
      title: 'Cài đặt',
      body: ScreenSkeleton(
        code: 'S12',
        name: 'Cài đặt',
        links: <SkeletonLink>[
          if (!kReleaseMode)
            SkeletonLink(
              'Thư viện component (dev)',
              (context) => context.push(AppRoutes.componentGallery),
            ),
        ],
      ),
    );
  }
}
