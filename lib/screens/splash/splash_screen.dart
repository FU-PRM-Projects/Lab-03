import 'package:material_ui/material_ui.dart';

import '../../widgets/state_views.dart';

/// Màn chờ ngắn lúc mở app, trong khi Firebase cho biết đã đăng nhập chưa.
/// Không có trong Figma (deviation D-12).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingState.spinner());
  }
}
