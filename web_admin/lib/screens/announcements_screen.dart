import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import '../viewmodels/admin_view_models.dart';
import '../viewmodels/messages.dart';
import '../widgets/admin_widgets.dart';

/// Form thông báo: ghi vào `announcements`, hiện ngay trong hộp thư của app.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await ref
        .read(announcementActionsProvider)
        .post(title: _title.text, body: _body.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
    });
    if (error == null) {
      _title.clear();
      _body.clear();
      _form.currentState?.reset();
      showMessage(context, 'Đã gửi thông báo tới hộp thư của app.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(announcementsProvider);
    final text = Theme.of(context).textTheme;

    final form = AdminCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Thông báo mới', style: text.titleMedium),
            const SizedBox(height: AppSpace.s12),
            TextFormField(
              controller: _title,
              maxLength: AnnouncementLimits.titleMax,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Nhập tiêu đề' : null,
            ),
            TextFormField(
              controller: _body,
              maxLength: AnnouncementLimits.bodyMax,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Nhập nội dung' : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send),
                label: Text(_sending ? 'Đang gửi…' : 'Gửi tới mọi người dùng'),
              ),
            ),
          ],
        ),
      ),
    );

    final history = switch (list) {
      AsyncData(:final value) when value.isEmpty => const MessageView(
        title: 'Chưa có thông báo nào',
        message: 'Thông báo đầu tiên bạn gửi sẽ hiện ở đây và trong app.',
      ),
      AsyncData(:final value) => ListView.separated(
        padding: const EdgeInsets.only(bottom: AppSpace.s24),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s8),
        itemBuilder: (_, i) => _AnnouncementRow(item: value[i]),
      ),
      AsyncError(:final error) => MessageView.error(
        message: errorMessage(error),
        onAction: () => ref.invalidate(announcementsProvider),
      ),
      _ => const LoadingView(message: 'Đang tải thông báo…'),
    };

    return AdminPage(
      title: 'Thông báo',
      subtitle:
          'Gửi tin tới hộp thư của mọi người dùng app, theo thời gian thực.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 440, child: SingleChildScrollView(child: form)),
                const SizedBox(width: AppSpace.s24),
                Expanded(child: history),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              form,
              const SizedBox(height: AppSpace.s16),
              Expanded(child: history),
            ],
          );
        },
      ),
    );
  }
}

class _AnnouncementRow extends ConsumerWidget {
  const _AnnouncementRow({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: text.titleSmall),
                const SizedBox(height: AppSpace.s4),
                Text(item.body, style: text.bodyMedium),
                const SizedBox(height: AppSpace.s8),
                Text(
                  formatDateTime(item.createdAt),
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xoá thông báo',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xoá thông báo?'),
                  content: Text(
                    '"${item.title}" sẽ biến mất khỏi hộp thư của mọi người '
                    'dùng.',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Huỷ'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Xoá'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              final error = await ref
                  .read(announcementActionsProvider)
                  .delete(item.id);
              if (context.mounted) {
                showMessage(
                  context,
                  error ?? 'Đã xoá thông báo.',
                  error: error != null,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
