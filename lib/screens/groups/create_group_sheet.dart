import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/first_group.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/error_messages.dart';
import '../../viewmodels/groups_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/quick_win_chip.dart';

/// Sheet "Tạo nhóm lần đầu" (S05). Trả nhóm vừa tạo, hoặc nhóm trùng tên mà
/// người dùng chọn mở; `null` khi huỷ.
Future<FirstGroup?> showCreateGroupSheet(BuildContext context) =>
    showModalBottomSheet<FirstGroup>(
      context: context,
      // Mở từ kệ ở tab Hũ: nằm trên thanh tab nổi.
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const _CreateGroupSheet(),
    );

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _name = TextEditingController();
  GroupIdea _idea = GroupIdea.chienThang;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final group = await ref
          .read(groupsViewModelProvider.notifier)
          .create(_name.text, _idea);
      if (mounted) Navigator.of(context).pop(group);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ErrorMessages.save(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final check = ref.read(groupsViewModelProvider.notifier).check(_name.text);
    final (fieldError, primaryLabel) = switch (check) {
      GroupNameTaken(:final group) => (
        'Đã có nhóm “${group.name}”. Mở nhóm đó nhé?',
        'Mở “${group.name}”',
      ),
      GroupNameTooLong() => (
        'Tên nhóm tối đa ${FirstGroups.nameMaxLength} ký tự.',
        'Tạo nhóm',
      ),
      _ => (_error, 'Tạo nhóm'),
    };
    final canSubmit =
        !_saving && check is! GroupNameEmpty && check is! GroupNameTooLong;

    // Figma `Bottom sheet · Tạo nhóm lần đầu`: lề 16, các khối cách 16.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            0,
            AppSpace.screen,
            AppSpace.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s16,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  'Tạo nhóm lần đầu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              AppTextField(
                label: 'Lần đầu…',
                hint: 'Ví dụ: Đi xe buýt một mình',
                controller: _name,
                autofocus: true,
                errorText: fieldError,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) {
                  if (canSubmit) _submit();
                },
              ),
              Text('Thuộc ý nào của Nốt?', style: theme.textTheme.labelLarge),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: <Widget>[
                  for (final idea in GroupIdea.values)
                    QuickWinChip(
                      label: idea.label,
                      selected: _idea == idea,
                      onSelected: (_) => setState(() => _idea = idea),
                    ),
                ],
              ),
              AppButton(
                label: primaryLabel,
                expand: true,
                loading: _saving,
                onPressed: canSubmit ? _submit : null,
              ),
              AppButton(
                label: 'Huỷ',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
