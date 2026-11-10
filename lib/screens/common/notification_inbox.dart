import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/clock.dart';
import '../../services/messaging_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/community_view_model.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/mascot.dart';

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
///
/// Mỗi tin là một thẻ có biểu tượng theo loại (thẻ được duyệt, bị từ chối,
/// thông báo chung, thông báo đẩy); tin chưa đọc có nền nhấn và chấm xanh.
class NotificationInboxSheet extends ConsumerWidget {
  const NotificationInboxSheet({super.key});

  static String _origin(MessageOrigin origin) => switch (origin) {
    MessageOrigin.foreground => 'Đang mở app',
    MessageOrigin.background => 'Từ nền',
    MessageOrigin.terminated => 'App đã tắt',
  };

  static String _when(DateTime? at, DateTime now) => at == null
      ? 'Vừa xong'
      : '${ViDateFormat.relativeDay(at, now)} · ${ViDateFormat.time(at)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);
    final community = ref.watch(communityInboxProvider);
    final now = ref.watch(clockProvider).now();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);
    final unreadCount = switch (community) {
      AsyncData(:final value) => value.where((e) => e.unread).length,
      _ => 0,
    };

    _EntryStyle styleOf(InboxEntryKind kind) => switch (kind) {
      InboxEntryKind.approved => _EntryStyle(
        Icons.check_circle_rounded,
        colors.success,
        colors.success.withValues(alpha: 0.12),
      ),
      InboxEntryKind.rejected => _EntryStyle(
        Icons.undo_rounded,
        scheme.error,
        scheme.errorContainer,
      ),
      InboxEntryKind.announcement => _EntryStyle(
        Icons.campaign_rounded,
        scheme.primary,
        scheme.primaryContainer,
      ),
    };

    final pushStyle = _EntryStyle(
      Icons.notifications_rounded,
      scheme.onSurfaceVariant,
      scheme.surfaceContainerHigh,
    );

    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Hộp thư',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      _Pill(
                        label: '$unreadCount tin mới',
                        foreground: scheme.onPrimaryContainer,
                        background: scheme.primaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.s16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const _SectionLabel('Từ Nốt'),
                        ...switch (community) {
                          AsyncData(:final value) when value.isEmpty =>
                            const <Widget>[
                              _EmptyNote(
                                mascot: MascotState.thongTha,
                                text:
                                    'Chưa có tin nào. Khi thẻ bạn gửi được '
                                    'duyệt hoặc Nốt có thông báo mới, tin sẽ '
                                    'hiện ở đây.',
                              ),
                            ],
                          AsyncData(:final value) => <Widget>[
                            for (final item in value.take(20))
                              _InboxCard(
                                style: styleOf(item.kind),
                                title: item.title,
                                body: item.body,
                                meta:
                                    '${item.personal ? 'Tin riêng' : 'Thông báo chung'}'
                                    ' · ${_when(item.at, now)}',
                                unread: item.unread,
                              ),
                          ],
                          AsyncError() => const <Widget>[
                            _EmptyNote(
                              mascot: MascotState.lac,
                              text:
                                  'Chưa tải được tin từ Nốt. Kiểm tra mạng rồi '
                                  'mở lại hộp thư.',
                            ),
                          ],
                          _ => const <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpace.s16,
                              ),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                        },
                        const SizedBox(height: AppSpace.s12),
                        const _SectionLabel('Thông báo đẩy đã nhận'),
                        ...switch (inbox) {
                          AsyncData(:final value) when value.isEmpty =>
                            <Widget>[
                              Text(
                                'Chưa có thông báo đẩy nào.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          AsyncData(:final value) => <Widget>[
                            for (final item in value.take(6))
                              _InboxCard(
                                style: pushStyle,
                                title: item.title.isEmpty
                                    ? '(không có tiêu đề)'
                                    : item.title,
                                body: item.body,
                                meta:
                                    '${_origin(item.origin)} · ${_when(item.receivedAt, now)}',
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

class _EntryStyle {
  const _EntryStyle(this.icon, this.foreground, this.background);

  final IconData icon;
  final Color foreground;
  final Color background;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s8),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.r12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s10,
        vertical: AppSpace.s4,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground),
      ),
    ),
  );
}

/// Một tin: biểu tượng theo loại, tiêu đề, nội dung, nguồn và giờ.
class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.style,
    required this.title,
    required this.body,
    required this.meta,
    this.unread = false,
  });

  final _EntryStyle style;
  final String title;
  final String body;
  final String meta;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s8),
      child: Semantics(
        container: true,
        label: unread ? 'Tin mới' : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: unread
                ? scheme.primaryContainer.withValues(alpha: 0.45)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(
              color: unread
                  ? scheme.primary.withValues(alpha: 0.25)
                  : scheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: style.background,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Icon(style.icon, color: style.foreground, size: 22),
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: unread ? FontWeight.w700 : null,
                        ),
                      ),
                      if (body.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpace.s2),
                        Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: AppSpace.s6),
                      Text(
                        meta,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpace.s8,
                      top: AppSpace.s4,
                    ),
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: scheme.primary,
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

/// Trạng thái trống / lỗi có Tụi Nốt.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.mascot, required this.text});

  final MascotState mascot;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s8),
      child: Row(
        children: <Widget>[
          Mascot(state: mascot, size: 56),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
