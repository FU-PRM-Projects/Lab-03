import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/messaging_service.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../widgets/app_dialog.dart';

/// Mở hộp thư thông báo (chuông ở các tab và dòng FCM trong Cài đặt).
///
/// Chưa hỏi quyền thì hỏi trước; đã tắt thì dẫn tới cài đặt của máy.
Future<void> openNotificationInbox(BuildContext context, WidgetRef ref) async {
  final service = ref.read(messagingServiceProvider);
  var granted = await service.permission();
  if (granted == NotificationPermission.notAsked) {
    granted = await service.requestPermission();
    ref.invalidate(notificationPermissionProvider);
  }
  if (!context.mounted) return;
  if (granted == NotificationPermission.denied) {
    final open = await showAppDialog(
      context: context,
      title: 'Nốt cần quyền thông báo',
      message: 'Bạn đã tắt thông báo. Mở cài đặt của máy để bật lại.',
      confirmLabel: 'Mở cài đặt',
    );
    if (open ?? false) await service.openSystemSettings();
    return;
  }
  ref.invalidate(inboxProvider);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    // Mở trên navigator gốc: khay rộng hết chiều ngang màn hình và nằm trên
    // thanh tab nổi, như các khay khác.
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => const NotificationInboxSheet(),
  );
}

/// Các thông báo FCM đã nhận, mới nhất trước.
class NotificationInboxSheet extends ConsumerWidget {
  const NotificationInboxSheet({super.key});

  static String _origin(MessageOrigin origin) => switch (origin) {
    MessageOrigin.foreground => 'Đang mở app',
    MessageOrigin.background => 'Từ nền',
    MessageOrigin.terminated => 'App đã tắt',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);
    // Khay co theo bề ngang nội dung nếu không ép: kéo giãn hết màn hình.
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s20,
            0,
            AppSpace.s20,
            AppSpace.s20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Thông báo đã nhận',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.s12),
              // Danh sách dài hơn chiều cao khay thì cuộn, không tràn.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: switch (inbox) {
                      AsyncData(:final value) when value.isEmpty => <Widget>[
                        const Text('Chưa có thông báo nào.'),
                      ],
                      AsyncData(:final value) => <Widget>[
                        for (final item in value.take(6))
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpace.s12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.title.isEmpty
                                      ? '(không có tiêu đề)'
                                      : item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(item.body),
                                Text(
                                  '${_origin(item.origin)} · ${ViDateFormat.time(item.receivedAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                      _ => const <Widget>[Text('Đang tải…')],
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
