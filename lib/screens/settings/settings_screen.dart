import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/self_control.dart';
import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/setting_row.dart';
import '../../widgets/state_views.dart';
import '../common/screen_skeleton.dart';

/// S12 · Cài đặt (+ khu demo Firebase, deviation D-01).
///
/// Stage 4: Nhắc nhở, Quyền riêng tư, Tài khoản, lối vào Xuất & tải lên PDF.
/// Stage 5 thêm vào khu demo: thông báo đã nhận, Remote Config, Crashlytics.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static TimeOfDay _time(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60 % 24, minute: minutes % 60);

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final viewModel = ref.read(settingsViewModelProvider.notifier);
    final auth = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);
    final user = ref.watch(authUserProvider).value;

    void snack(String message) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    ref
      ..listen(authViewModelProvider, (_, next) {
        if (next.source == AuthAction.signOut && next.message != null) {
          snack(next.message!);
          authViewModel.clearMessage();
        }
      })
      ..listen(settingsViewModelProvider, (previous, next) {
        if (next.message != null && previous?.message != next.message) {
          snack(next.message!);
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
      if (confirmed ?? false) await authViewModel.signOut();
    }

    Future<void> pickReminder(UserSettings settings) async {
      final time = await showTimePicker(
        context: context,
        initialTime: _time(settings.eveningReminder),
        helpText: 'NHẮC GHI NỐT BUỔI TỐI',
      );
      if (time != null) await viewModel.setEveningReminder(_minutes(time));
    }

    Future<void> pickAwake(UserSettings settings) async {
      final start = await showTimePicker(
        context: context,
        initialTime: _time(settings.awakeStart),
        helpText: 'GIỜ TỈNH BẮT ĐẦU',
      );
      if (start == null || !context.mounted) return;
      final end = await showTimePicker(
        context: context,
        initialTime: _time(settings.awakeEnd),
        helpText: 'GIỜ TỈNH KẾT THÚC',
      );
      if (end == null) return;
      await viewModel.setAwakeTimes(_minutes(start), _minutes(end));
    }

    final settingsSection = switch (state.settings) {
      Loading<UserSettings>() || Empty<UserSettings>() => <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.s24),
          child: LoadingState.spinner(message: 'Đang tải cài đặt…'),
        ),
      ],
      Failure<UserSettings>(:final message, :final offline) => <Widget>[
        ErrorState(
          title: 'Chưa tải được cài đặt',
          cause: message,
          kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
          onRetry: viewModel.retry,
        ),
      ],
      Data<UserSettings>(:final value) => <Widget>[
        const _Section('NHẮC NHỞ'),
        SettingRow.value(
          title: 'Nhắc ghi nốt buổi tối',
          value: ViDateFormat.clock(value.eveningReminder),
          onTap: () => pickReminder(value),
        ),
        SettingRow.toggle(
          title: 'Giờ tỉnh',
          subtitle: 'Nhắc nhẹ khi dễ lướt vô thức',
          value: value.awakeEnabled,
          onChanged: viewModel.setAwakeEnabled,
        ),
        SettingRow.value(
          title: 'Khung giờ tỉnh',
          value:
              '${ViDateFormat.clock(value.awakeStart)} – '
              '${ViDateFormat.clock(value.awakeEnd)}',
          onTap: () => pickAwake(value),
        ),
        const SizedBox(height: AppSpace.s16),
        const _Section('QUYỀN RIÊNG TƯ'),
        SettingRow.toggle(
          title: 'Nốt AI sắp xếp giúp',
          subtitle: 'Không gửi tên, email, ảnh',
          value: value.aiEnabled,
          onChanged: viewModel.setAiEnabled,
        ),
        SettingRow.toggle(
          title: 'Khoá phần Tự chủ',
          subtitle: 'Mở bằng vân tay hoặc mã máy',
          value: value.lockSelfControl,
          onChanged: state.authenticating ? null : viewModel.setLockSelfControl,
        ),
        SettingRow.toggle(
          title: 'Ẩn nội dung thông báo',
          subtitle: 'Màn khoá chỉ hiện "Nốt có lời nhắc"',
          value: value.hideNotificationContent,
          onChanged: viewModel.setHideNotificationContent,
        ),
      ],
    };

    return NestedScaffold(
      title: 'Cài đặt',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.s8,
              AppSpace.screen,
              AppSpace.s24,
            ),
            children: <Widget>[
              ...settingsSection,
              const SizedBox(height: AppSpace.s16),
              const _Section('TÀI KHOẢN'),
              // Email dài: 1 dòng rồi "…" (handout S12).
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: AppSize.settingRowMinHeight,
                title: const Text('Email'),
                subtitle: Text(
                  user?.email ?? 'Không có email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Đăng xuất',
                variant: AppButtonVariant.outlined,
                icon: Icons.logout,
                expand: true,
                loading: auth.busy == AuthAction.signOut,
                onPressed: auth.isBusy ? null : confirmSignOut,
              ),
              const SizedBox(height: AppSpace.s24),
              // Khu demo Firebase (Lab 3 mục 3, deviation D-01).
              const _Section('KHU DEMO FIREBASE'),
              SettingRow.value(
                title: 'Xuất & tải lên Thẻ tuần (PDF)',
                subtitle: 'Cloud Storage · reports/{uid}/',
                value: '',
                onTap: () => context.go(AppRoutes.journeyTab('stats')),
              ),
              if (!kReleaseMode)
                SettingRow.value(
                  title: 'Thư viện component (dev)',
                  value: '',
                  onTap: () => context.push(AppRoutes.componentGallery),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s4),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: AppTextStyles.of(context).overline
              .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
