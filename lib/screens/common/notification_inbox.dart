import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/community_view_model.dart';
import '../../widgets/app_dialog.dart';

/// Mở hộp thư (chuông ở các tab và dòng FCM trong Cài đặt).
///
/// Hộp thư có hai phần: tin từ Nốt (thông báo staff gửi trên web admin và
/// tin riêng khi thẻ được duyệt, đọc từ Firestore theo thời gian thực) và
/// thông báo đẩy FCM đã nhận. Chưa hỏi quyền thông báo thì hỏi trước; đã tắt
/// thì gợi ý mở cài đặt của máy, nhưng vẫn mở hộp thư vì tin từ Nốt không cần
/// quyền thông báo.
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
      message:
          'Bạn đã tắt thông báo đẩy. Mở cài đặt của máy để bật lại; tin trong '
          'hộp thư vẫn xem được.',
      confirmLabel: 'Mở cài đặt',
      cancelLabel: 'Xem hộp thư',
    );
    if (open ?? false) {
      await service.openSystemSettings();
      return;
    }
  }
  ref.invalidate(inboxProvider);
  if (!context.mounted) return;
  await ref
      .read(analyticsServiceProvider)
      .logEvent(AnalyticsEvents.inboxOpened);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    // Mở trên navigator gốc: khay rộng hết chiều ngang màn hình và nằm trên
    // thanh tab nổi, như các khay khác.
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const NotificationInboxSheet(),
  );
  // Đã xem: tắt chấm chưa đọc.
  await ref.read(communityActionsProvider).markInboxRead();
}

/// Tin từ Nốt (mới nhất trước), rồi các thông báo FCM đã nhận.
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
    final community = ref.watch(communityInboxProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget entry({
      required String title,
      required String body,
      required String meta,
      bool unread = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: Semantics(
        label: unread ? 'Tin mới' : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (unread)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpace.s6,
                  right: AppSpace.s8,
                ),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: theme.colorScheme.primary,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleMedium),
                  if (body.isNotEmpty) Text(body),
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Khay co theo bề ngang nội dung nếu không ép: kéo giãn hết màn hình.
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
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
                Text('Hộp thư', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpace.s12),
                // Danh sách dài hơn chiều cao khay thì cuộn, không tràn.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Từ Nốt', style: theme.textTheme.labelLarge),
                        const SizedBox(height: AppSpace.s8),
                        ...switch (community) {
                          AsyncData(:final value) when value.isEmpty =>
                            const <Widget>[
                              Text('Chưa có tin nào từ Nốt.'),
                              SizedBox(height: AppSpace.s12),
                            ],
                          AsyncData(:final value) => <Widget>[
                            for (final item in value.take(20))
                              entry(
                                title: item.title,
                                body: item.body,
                                meta:
                                    '${item.personal ? 'Tin riêng' : 'Thông báo'}'
                                    ' · ${item.at == null ? 'Vừa xong' : ViDateFormat.time(item.at!)}',
                                unread: item.unread,
                              ),
                          ],
                          AsyncError() => const <Widget>[
                            Text(
                              'Chưa tải được tin từ Nốt. Kiểm tra mạng rồi mở '
                              'lại hộp thư.',
                            ),
                            SizedBox(height: AppSpace.s12),
                          ],
                          _ => const <Widget>[
                            Text('Đang tải…'),
                            SizedBox(height: AppSpace.s12),
                          ],
                        },
                        const SizedBox(height: AppSpace.s8),
                        Text(
                          'Thông báo đẩy đã nhận',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpace.s8),
                        ...switch (inbox) {
                          AsyncData(:final value) when value.isEmpty =>
                            const <Widget>[Text('Chưa có thông báo nào.')],
                          AsyncData(:final value) => <Widget>[
                            for (final item in value.take(6))
                              entry(
                                title: item.title.isEmpty
                                    ? '(không có tiêu đề)'
                                    : item.title,
                                body: item.body,
                                meta:
                                    '${_origin(item.origin)} · ${ViDateFormat.time(item.receivedAt)}',
                              ),
                          ],
                          _ => const <Widget>[Text('Đang tải…')],
                        },
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
