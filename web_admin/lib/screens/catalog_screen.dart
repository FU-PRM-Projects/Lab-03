import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import '../viewmodels/admin_view_models.dart';
import '../viewmodels/messages.dart';
import '../widgets/admin_widgets.dart';

/// Màn 2 · Quản lý kho thẻ: tìm, lọc, thêm, sửa, lưu trữ thẻ mà app đọc.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(filteredCatalogProvider);
    final filter = ref.watch(catalogFilterProvider);
    final filters = ref.read(catalogFilterProvider.notifier);

    return AdminPage(
      title: 'Kho thẻ thử thách',
      subtitle:
          'Thẻ ở đây hiện trong tab Thử thách của app. Lưu trữ để ẩn thẻ; thẻ '
          'không bị xoá để nốt cũ vẫn mở được.',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () => showCardForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm thẻ'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppSpace.s12,
            runSpacing: AppSpace.s12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 320,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Tìm theo tên, mẹo hoặc mã thẻ',
                    isDense: true,
                  ),
                  onChanged: filters.setQuery,
                ),
              ),
              SegmentedButton<ChallengeTopic?>(
                showSelectedIcon: false,
                segments: <ButtonSegment<ChallengeTopic?>>[
                  const ButtonSegment(value: null, label: Text('Tất cả')),
                  for (final topic in ChallengeTopic.values)
                    ButtonSegment(value: topic, label: Text(topic.label)),
                ],
                selected: <ChallengeTopic?>{filter.topic},
                onSelectionChanged: (value) => filters.setTopic(value.first),
              ),
              FilterChip(
                label: const Text('Hiện thẻ đã lưu trữ'),
                selected: filter.showArchived,
                onSelected: filters.setShowArchived,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          Expanded(
            child: switch (cards) {
              AsyncData(:final value) when value.isEmpty => MessageView(
                title: filter.query.isEmpty && filter.topic == null
                    ? 'Kho thẻ đang trống'
                    : 'Không có thẻ khớp bộ lọc',
                message: filter.query.isEmpty && filter.topic == null
                    ? 'Thêm thẻ đầu tiên, hoặc nạp kho có sẵn bằng '
                          '`npm run seed`.'
                    : 'Thử từ khoá khác hoặc bỏ bộ lọc chủ đề.',
                actionLabel: 'Thêm thẻ',
                onAction: () => showCardForm(context),
              ),
              AsyncData(:final value) => _CardList(cards: value),
              AsyncError(:final error) => MessageView.error(
                message: errorMessage(error),
                onAction: () => ref.invalidate(catalogProvider),
              ),
              _ => const LoadingView(message: 'Đang tải kho thẻ…'),
            },
          ),
        ],
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.cards});

  final List<CatalogCard> cards;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.only(bottom: AppSpace.s24),
    itemCount: cards.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s8),
    itemBuilder: (context, i) => _CardRow(card: cards[i]),
  );
}

class _CardRow extends ConsumerWidget {
  const _CardRow({required this.card});

  final CatalogCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = card.challenge;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final (topicBg, topicFg) = topicColors(c.topic);

    Future<void> toggleArchive() async {
      final error = await ref
          .read(catalogActionsProvider)
          .setArchived(card, !card.archived);
      if (!context.mounted) return;
      showMessage(
        context,
        error ??
            (card.archived
                ? 'Đã khôi phục "${c.title}".'
                : 'Đã lưu trữ "${c.title}". App sẽ không hiện thẻ này nữa.'),
        error: error != null,
      );
    }

    return Opacity(
      opacity: card.archived ? 0.6 : 1,
      child: AdminCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s12,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 96,
              child: AdminChip(
                c.topic.label,
                color: topicBg,
                textColor: topicFg,
              ),
            ),
            SizedBox(
              width: 88,
              child: Text(
                'Cấp ${c.level} · #${c.order}',
                style: text.bodySmall,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(c.title, style: text.titleSmall),
                  if (c.tip.isNotEmpty)
                    Text(
                      c.tip,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Text('${c.minutes} phút', style: text.bodySmall),
            const SizedBox(width: AppSpace.s12),
            SizedBox(
              width: 150,
              child: Wrap(
                spacing: AppSpace.s4,
                runSpacing: AppSpace.s4,
                children: <Widget>[
                  if (card.source == CardSource.community)
                    AdminChip(
                      card.source.label,
                      color: AppPalette.tintOrange,
                      textColor: AppPalette.warning,
                    ),
                  if (card.archived)
                    AdminChip(
                      'Đã lưu trữ',
                      color: scheme.surfaceContainerHigh,
                      textColor: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sửa "${c.title}"',
              onPressed: () => showCardForm(context, existing: card),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: card.archived
                  ? 'Khôi phục "${c.title}"'
                  : 'Lưu trữ "${c.title}"',
              onPressed: toggleArchive,
              icon: Icon(
                card.archived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hộp thoại thêm / sửa thẻ.
Future<void> showCardForm(BuildContext context, {CatalogCard? existing}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _CardForm(existing: existing),
    );

class _CardForm extends ConsumerStatefulWidget {
  const _CardForm({this.existing});

  final CatalogCard? existing;

  @override
  ConsumerState<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends ConsumerState<_CardForm> {
  final _form = GlobalKey<FormState>();
  late final Challenge? _c = widget.existing?.challenge;
  late ChallengeTopic _topic = _c?.topic ?? ChallengeTopic.dungCam;
  late final _title = TextEditingController(text: _c?.title ?? '');
  late final _tip = TextEditingController(text: _c?.tip ?? '');
  late final _script = TextEditingController(text: _c?.script ?? '');
  late final _minutes = TextEditingController(text: '${_c?.minutes ?? 2}');
  late final _level = TextEditingController(text: '${_c?.level ?? 1}');
  late final _order = TextEditingController(
    text: _c == null ? '' : '${_c.order}',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _title,
      _tip,
      _script,
      _minutes,
      _level,
      _order,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _number(String? value, int min, int max, {bool optional = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && optional) return null;
    final n = int.tryParse(text);
    if (n == null || n < min || n > max) return 'Nhập số từ $min đến $max';
    return null;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final level = int.parse(_level.text.trim());
    final cards = ref.read(catalogProvider).value ?? const <CatalogCard>[];
    final order = _order.text.trim().isEmpty
        ? nextOrder(cards, _topic, level)
        : int.parse(_order.text.trim());
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref
        .read(catalogActionsProvider)
        .save(
          CatalogDraft(
            topic: _topic,
            level: level,
            order: order,
            title: _title.text,
            minutes: int.parse(_minutes.text.trim()),
            tip: _tip.text,
            script: _script.text,
          ),
          existing: widget.existing,
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      showMessage(
        context,
        widget.existing == null ? 'Đã thêm thẻ.' : 'Đã lưu thay đổi.',
      );
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      title: Text(widget.existing == null ? 'Thêm thẻ' : 'Sửa thẻ'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SegmentedButton<ChallengeTopic>(
                  segments: <ButtonSegment<ChallengeTopic>>[
                    for (final topic in ChallengeTopic.values)
                      ButtonSegment(value: topic, label: Text(topic.label)),
                  ],
                  selected: <ChallengeTopic>{_topic},
                  onSelectionChanged: (value) =>
                      setState(() => _topic = value.first),
                ),
                const SizedBox(height: AppSpace.s16),
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  maxLength: CatalogLimits.titleMax,
                  decoration: const InputDecoration(labelText: 'Tên thẻ'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Nhập tên thẻ' : null,
                ),
                TextFormField(
                  controller: _tip,
                  maxLength: CatalogLimits.tipMax,
                  decoration: const InputDecoration(
                    labelText: 'Mẹo ngắn (không bắt buộc)',
                  ),
                ),
                TextFormField(
                  controller: _script,
                  maxLength: CatalogLimits.scriptMax,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Câu mẫu để nói (không bắt buộc)',
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _minutes,
                        inputFormatters: digits,
                        decoration: const InputDecoration(labelText: 'Số phút'),
                        validator: (v) =>
                            _number(v, 1, CatalogLimits.minutesMax),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: TextFormField(
                        controller: _level,
                        inputFormatters: digits,
                        decoration: const InputDecoration(labelText: 'Cấp'),
                        validator: (v) => _number(v, 1, CatalogLimits.levelMax),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: TextFormField(
                        controller: _order,
                        inputFormatters: digits,
                        decoration: const InputDecoration(
                          labelText: 'Thứ tự',
                          helperText: 'Trống: xếp cuối cấp',
                        ),
                        validator: (v) => _number(
                          v,
                          0,
                          CatalogLimits.orderMax,
                          optional: true,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: AppSpace.s12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
        ),
      ],
    );
  }
}
