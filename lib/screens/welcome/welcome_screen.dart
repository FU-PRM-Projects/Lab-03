import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../common/screen_skeleton.dart';

/// S01 · Chào mừng & Đăng nhập.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({this.next, super.key});

  /// Đích sau khi đăng nhập (`?next=`), ví dụ khi mở từ thông báo (P7).
  final String? next;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScreenSkeleton(
          code: 'S01',
          name: 'Chào mừng & Đăng nhập',
          links: <SkeletonLink>[
            // Tạm thời đi thẳng vào app; Stage 3 thay bằng Google Sign-In và
            // redirect theo trạng thái đăng nhập.
            SkeletonLink(
              'Vào app (tạm, chưa đăng nhập)',
              (context) => context.go(next ?? AppRoutes.today),
            ),
          ],
        ),
      ),
    );
  }
}
