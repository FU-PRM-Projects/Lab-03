import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/challenge.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/challenges_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/quick_win_chip.dart';

/// Sheet "Điều tốt nhỏ của bạn": người dùng tự thêm một thẻ thử thách. Trả
/// thẻ vừa thêm, hoặc `null` khi huỷ.
Future<Challenge?> showCreateChallengeSheet(BuildContext context) =>
    showModalBottomSheet<Challenge>(
      context: context,
      // Mở từ tab Thử thách: nằm trên thanh tab nổi.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateChallengeSheet(),
    );

/// Gợi ý để người dùng không phải nghĩ từ trang giấy trắng: việc nhỏ, làm
/// được trong vài phút.
const List<({String title, ChallengeTopic topic, int minutes})> _suggestions =
    <({String title, ChallengeTopic topic, int minutes})>[
      (
        title: 'Nhắn lời cảm ơn một người',
        topic: ChallengeTopic.dungCam,
        minutes: 2,
      ),
      (title: 'Chào một người lạ', topic: ChallengeTopic.dungCam, minutes: 1),
      (
        title: 'Gọi hỏi thăm người thân',
        topic: ChallengeTopic.dungCam,
        minutes: 5,
      ),
      (title: 'Đi bộ 10 phút', topic: ChallengeTopic.vanDong, minutes: 10),
      (title: 'Giãn cơ 5 phút', topic: ChallengeTopic.vanDong, minutes: 5),
      (title: 'Dọn một góc nhỏ', topic: ChallengeTopic.vanDong, minutes: 5),
    ];

const List<int> _minuteChoices = <int>[1, 2, 5, 10, 15];

class _CreateChallengeSheet extends ConsumerStatefulWidget {
  const _CreateChallengeSheet();

  @override
  ConsumerState<_CreateChallengeSheet> createState() =>
      _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends ConsumerState<_CreateChallengeSheet> {
  final _title = TextEditingController();
  ChallengeTopic _topic = ChallengeTopic.dungCam;
  int _minutes = 2;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _pick(({String title, ChallengeTopic topic, int minutes}) suggestion) {
    setState(() {
      _title.text = suggestion.title;
      _topic = suggestion.topic;
      _minutes = suggestion.minutes;
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(challengesViewModelProvider.notifier)
          .addMine(topic: _topic, title: _title.text, minutes: _minutes);
      if (mounted) Navigator.of(context).pop(challenge);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ChallengesViewModel.addError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = _title.text.trim();
    final canSubmit = !_saving && trimmed.isNotEmpty;

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
                  'Một điều tốt nhỏ của bạn',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Text(
                'Nhỏ thôi cũng được. Mỗi ngày một việc, cộng dồn lại sẽ thành '
                'điều lớn.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppTextField(
                label: 'Hôm nay mình sẽ…',
                hint: 'Ví dụ: Nhắn lời cảm ơn một người bạn',
                controller: _title,
                maxLength: CustomChallengeLimits.titleMax,
                errorText: _error,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) {
                  if (canSubmit) _submit();
                },
              ),
              Text('Gợi ý nhỏ', style: theme.textTheme.labelLarge),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: <Widget>[
                  for (final suggestion in _suggestions)
                    QuickWinChip(
                      label: suggestion.title,
                      selected: _title.text == suggestion.title,
                      onSelected: (_) => _pick(suggestion),
                    ),
                ],
              ),
              Text('Thuộc ý nào của Nốt?', style: theme.textTheme.labelLarge),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: <Widget>[
                  for (final topic in ChallengeTopic.values)
                    QuickWinChip(
                      label: topic.label,
                      selected: _topic == topic,
                      onSelected: (_) => setState(() => _topic = topic),
                    ),
                ],
              ),
              Text('Mất khoảng bao lâu?', style: theme.textTheme.labelLarge),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: <Widget>[
                  for (final minutes in _minuteChoices)
                    QuickWinChip(
                      label: '$minutes phút',
                      selected: _minutes == minutes,
                      onSelected: (_) => setState(() => _minutes = minutes),
                    ),
                ],
              ),
              AppButton(
                label: 'Thêm vào thẻ của mình',
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
