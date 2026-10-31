import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../common/screen_skeleton.dart';

/// S12 · Cài đặt (+ khu demo Firebase, deviation D-01).
///
/// Stage 3 có nhóm TÀI KHOẢN và Đăng xuất; Nhắc nhở, Quyền riêng tư và khu
/// demo Firebase làm ở Stage 4–5.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authUserProvider).value;
    final auth = ref.watch(authViewModelProvider);
    final viewModel = ref.read(authViewModelProvider.notifier);

    ref.listen(authViewModelProvider, (_, next) {
      if (next.source == AuthAction.signOut && next.message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message!)));
        viewModel.clearMessage();
      }
    });

    Future<void> confirmSignOut() async {
      final confirmed = await showAppDialog(
        context: context,
        title: 'Đăng xuất khỏi Nốt?',
        message: 'Dữ liệu đã đồng bộ vẫn còn khi bạn đăng nhập lại.',
        confirmLabel: 'Đăng xuất',
      );
      if (confirmed ?? false) await viewModel.signOut();
    }

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
        children: <Widget>[
          Text(
            'TÀI KHOẢN',
            style: AppTextStyles.of(context).overline
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Email'),
            subtitle: Text(
              user?.email ?? 'Không có email',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppButton(
            label: 'Đăng xuất',
            variant: AppButtonVariant.outlined,
            icon: Icons.logout,
            expand: true,
            loading: auth.busy == AuthAction.signOut,
            onPressed: auth.isBusy ? null : confirmSignOut,
          ),
          const SizedBox(height: AppSpace.s24),
        ],
      ),
    );
  }
}
