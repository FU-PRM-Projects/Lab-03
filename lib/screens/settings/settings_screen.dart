import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/self_control.dart';
import '../../router/app_routes.dart';
import '../../services/crash_reporter.dart';
import '../../services/remote_config_service.dart';
import '../../theme/app_tokens.dart';
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
        SettingGroup(
          label: 'NHẮC NHỞ',
          children: <Widget>[
            SettingRow.value(
              title: 'Nhắc ghi nốt buổi tối',
              value: ViDateFormat.clock(value.eveningReminder),
              onTap: () => pickReminder(value),
            ),
            // Figma: dòng "Giờ tỉnh" hiện luôn khung giờ đang đặt.
            SettingRow.toggle(
              title: 'Giờ tỉnh',
              subtitle:
                  '${ViDateFormat.clock(value.awakeStart)} – '
                  '${ViDateFormat.clock(value.awakeEnd)}',
              value: value.awakeEnabled,
              onChanged: viewModel.setAwakeEnabled,
            ),
            SettingRow.value(
              title: 'Đổi khung giờ tỉnh',
              value: '',
              onTap: () => pickAwake(value),
            ),
          ],
        ),
        SettingGroup(
          label: 'QUYỀN RIÊNG TƯ',
          children: <Widget>[
            SettingRow.toggle(
              title: 'Nốt AI sắp xếp giúp',
              subtitle: 'Không gửi tên, email, ảnh',
              value: value.aiEnabled,
              onChanged: viewModel.setAiEnabled,
            ),
            SettingRow.toggle(
              title: 'Khoá phần Tự chủ',
              value: value.lockSelfControl,
              onChanged: state.authenticating
                  ? null
                  : viewModel.setLockSelfControl,
            ),
            SettingRow.toggle(
              title: 'Ẩn nội dung thông báo',
              value: value.hideNotificationContent,
              onChanged: viewModel.setHideNotificationContent,
            ),
          ],
        ),
      ],
    };

    return NestedScaffold(
      title: 'Cài đặt',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSize.contentMaxWidth),
          // Figma S12: nhóm cách nhau 16, nút Đăng xuất (Outlined, icon
          // Logout 20) dưới cùng.
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.s16,
              AppSpace.screen,
              AppSpace.s24,
            ),
            children: <Widget>[
              for (final section in settingsSection) ...<Widget>[
                section,
                const SizedBox(height: AppSpace.s16),
              ],
              // Spec "Kết nối Discord": S12 là một lối vào S14.
              if (ref.watch(remoteConfigServiceProvider).discordEnabled) ...[
                SettingGroup(
                  label: 'CỘNG ĐỒNG',
                  children: <Widget>[
                    SettingRow.value(
                      title: 'Phòng trò chuyện',
                      subtitle: 'Gặp người cũng đang tập, trên Discord',
                      value: '',
                      onTap: () => context.push(AppRoutes.rooms),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s16),
              ],
              SettingGroup(
                label: 'TÀI KHOẢN',
                children: <Widget>[
                  // Email dài: 1 dòng rồi "…" (handout S12).
                  SettingRow.value(
                    title: 'Email',
                    value: user?.email ?? 'Không có email',
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s16),
              // Khu demo Firebase (Lab 3 mục 3, deviation D-01).
              SettingGroup(
                label: 'KHU DEMO FIREBASE',
                children: <Widget>[
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
                  if (!kReleaseMode)
                    SettingRow.value(
                      title: 'Thử crash (dev)',
                      subtitle: 'Gửi một lỗi thử lên Crashlytics',
                      value: '',
                      onTap: () async {
                        final message = await ref
                            .read(crashReporterProvider)
                            .testCrash();
                        snack(message);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s24),
              AppButton(
                label: 'Đăng xuất',
                variant: AppButtonVariant.outlined,
                iconAsset: 'assets/icons/logout.svg',
                expand: true,
                loading: auth.busy == AuthAction.signOut,
                onPressed: auth.isBusy ? null : confirmSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
