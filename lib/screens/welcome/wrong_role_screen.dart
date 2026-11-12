import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../viewmodels/auth_view_model.dart';
import '../../widgets/mascot.dart';
import '../../widgets/state_views.dart';

/// Tài khoản `staff` / `admin` đăng nhập vào app mobile.
///
/// App chỉ dành cho người dùng (`user`); việc của staff / admin nằm ở web
/// admin (đề Final mục 6: "each client rejects accounts of the wrong role
/// with a clear message"). Đăng xuất xong, router đưa về S01 (xem
/// `router/auth_redirect.dart`).
class WrongRoleScreen extends ConsumerWidget {
  const WrongRoleScreen({super.key});

  /// Địa chỉ web admin, hiện trong câu báo.
  static const String webAdminUrl = 'prm393-not-lab3.web.app/admin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          mascot: MascotState.lac,
          title: 'Tài khoản này dành cho web admin',
          message:
              'Bạn đang đăng nhập bằng tài khoản staff / admin. App Nốt chỉ '
              'dành cho người dùng; việc quản lý kho thẻ, duyệt thẻ và gửi '
              'thông báo làm ở $webAdminUrl. Đăng xuất rồi đăng nhập bằng '
              'tài khoản người dùng nhé.',
          actionLabel: 'Đăng xuất',
          onAction: auth.isBusy
              ? null
              : () => ref.read(authViewModelProvider.notifier).signOut(),
        ),
      ),
    );
  }
}
