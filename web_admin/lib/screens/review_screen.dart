import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import '../services/admin_services.dart';
import '../viewmodels/admin_view_models.dart';
import '../viewmodels/messages.dart';
import '../widgets/admin_widgets.dart';

/// Màn 3 · Hàng chờ duyệt: duyệt hoặc từ chối (kèm lý do) thẻ người dùng
/// gửi từ app; app cập nhật ngay.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  SubmissionStatus _status = SubmissionStatus.pending;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(submissionsProvider(_status));
    final enabled = ref.watch(adminRemoteConfigProvider).submissionsEnabled;
    final scheme = Theme.of(context).colorScheme;

    return AdminPage(
      title: 'Hàng chờ duyệt',
      subtitle:
          'Thẻ người dùng tự thêm rồi gửi lên kho chung. Duyệt thì thẻ vào kho '
          'cho mọi người; từ chối cần ghi lý do. Người gửi nhận tin trong hộp '
          'thư của app.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!enabled) ...<Widget>[
            AdminCard(
              color: AppPalette.tintOrange,
              child: Text(
                'Remote Config `challenge_submissions_enabled` đang tắt: app '
                'không cho gửi thẻ mới. Thẻ đã gửi vẫn duyệt được.',
                style: TextStyle(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: AppSpace.s12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<SubmissionStatus>(
              showSelectedIcon: false,
              segments: <ButtonSegment<SubmissionStatus>>[
                for (final status in SubmissionStatus.values)
                  ButtonSegment(value: status, label: Text(status.label)),
              ],
              selected: <SubmissionStatus>{_status},
              onSelectionChanged: (value) =>
                  setState(() => _status = value.first),
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Expanded(
            child: switch (items) {
              AsyncData(:final value) when value.isEmpty => MessageView(
                mascot: 'xong',
                title: _status == SubmissionStatus.pending
                    ? 'Không còn thẻ nào chờ duyệt'
                    : 'Chưa có thẻ ${_status.label.toLowerCase()}',
                message: _status == SubmissionStatus.pending
                    ? 'Thẻ mới người dùng gửi sẽ hiện ở đây ngay khi có.'
                    : 'Thẻ đã xử lý sẽ hiện ở đây.',
              ),
              AsyncData(:final value) => ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpace.s24),
                itemCount: value.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpace.s12),
                itemBuilder: (_, i) => _SubmissionCard(submission: value[i]),
              ),
              AsyncError(:final error) => MessageView.error(
                message: errorMessage(error),
                onAction: () => ref.invalidate(submissionsProvider(_status)),
              ),
              _ => const LoadingView(message: 'Đang tải hàng chờ…'),
            },
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends ConsumerWidget {
  const _SubmissionCard({required this.submission});

  final ChallengeSubmission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = submission;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final (topicBg, topicFg) = topicColors(s.topic);
    final (statusBg, statusFg) = statusColors(s.status);

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AdminChip(s.topic.label, color: topicBg, textColor: topicFg),
              AdminChip(s.status.label, color: statusBg, textColor: statusFg),
              Text(
                'Gửi lúc ${formatDateTime(s.createdAt)}',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Text(s.title, style: text.titleMedium),
          const SizedBox(height: AppSpace.s4),
          Text(
            '${s.minutes} phút${s.tip.isEmpty ? '' : ' · Mẹo: ${s.tip}'}',
            style: text.bodyMedium,
          ),
          if (s.status == SubmissionStatus.rejected && s.reason.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s8),
            Text(
              'Lý do: ${s.reason}',
              style: text.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          if (s.status != SubmissionStatus.pending) ...<Widget>[
            const SizedBox(height: AppSpace.s8),
            Text(
              'Xử lý lúc ${formatDateTime(s.reviewedAt)}'
              '${s.challengeId == null ? '' : ' · thẻ ${s.challengeId}'}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (s.status == SubmissionStatus.pending) ...<Widget>[
            const SizedBox(height: AppSpace.s16),
            Wrap(
              spacing: AppSpace.s8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () => _approve(context, ref),
                  icon: const Icon(Icons.check),
                  label: const Text('Duyệt'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _reject(context, ref),
                  icon: const Icon(Icons.close),
                  label: const Text('Từ chối'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final level = await showDialog<int>(
      context: context,
      builder: (_) => _ApproveDialog(submission: submission),
    );
    if (level == null) return;
    final error = await ref
        .read(reviewActionsProvider)
        .approve(submission, level: level);
    if (!context.mounted) return;
    showMessage(
      context,
      error ?? 'Đã duyệt "${submission.title}". Thẻ đã vào kho chung.',
      error: error != null,
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectDialog(submission: submission),
    );
    if (reason == null) return;
    final error = await ref
        .read(reviewActionsProvider)
        .reject(submission, reason);
    if (!context.mounted) return;
    showMessage(
      context,
      error ?? 'Đã từ chối "${submission.title}" và báo cho người gửi.',
      error: error != null,
    );
  }
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog({required this.submission});

  final ChallengeSubmission submission;

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  int _level = 1;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Duyệt thẻ vào kho chung?'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '"${widget.submission.title}" sẽ hiện trong tab Thử thách của mọi '
            'người dùng, chủ đề ${widget.submission.topic.label}.',
          ),
          const SizedBox(height: AppSpace.s16),
          const Text('Xếp vào cấp'),
          const SizedBox(height: AppSpace.s8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<int>>[
              ButtonSegment(value: 1, label: Text('Cấp 1')),
              ButtonSegment(value: 2, label: Text('Cấp 2')),
              ButtonSegment(value: 3, label: Text('Cấp 3')),
            ],
            selected: <int>{_level},
            onSelectionChanged: (v) => setState(() => _level = v.first),
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Huỷ'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_level),
        child: const Text('Duyệt'),
      ),
    ],
  );
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.submission});

  final ChallengeSubmission submission;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();

  static const List<String> _quick = <String>[
    'Trùng với thẻ đã có trong kho',
    'Chưa đủ cụ thể để làm trong một lần',
    'Có thể không an toàn khi làm một mình',
  ];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Từ chối thẻ'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Người gửi sẽ thấy lý do này trong hộp thư của app, nên viết '
              'nhẹ nhàng và cụ thể.',
            ),
            const SizedBox(height: AppSpace.s12),
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: <Widget>[
                for (final reason in _quick)
                  ActionChip(
                    label: Text(reason),
                    onPressed: () => _reason.text = reason,
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.s12),
            TextFormField(
              controller: _reason,
              autofocus: true,
              maxLength: SubmissionLimits.reasonMax,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Lý do'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Cần ghi lý do' : null,
            ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Huỷ'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState?.validate() ?? false) {
            Navigator.of(context).pop(_reason.text.trim());
          }
        },
        child: const Text('Từ chối'),
      ),
    ],
  );
}
