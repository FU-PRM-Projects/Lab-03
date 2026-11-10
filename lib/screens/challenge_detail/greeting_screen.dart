import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/discord_room.dart';
import '../../services/ai_service.dart';
import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/remote_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/challenge_detail_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/mascot.dart';
import '../discord/discord_launcher.dart';

/// S08d · Câu chào của bạn: chọn hoặc sửa một câu chào, sao chép rồi mở phòng
/// Discord. Quay lại app sau khi mở thì trả `true` cho S08 ("Bạn vừa ghé
/// phòng chung"). Tụi Nốt AI viết 3 câu chào theo thẻ và phòng; AI tắt
/// hoặc lỗi thì dùng câu có sẵn trong Remote Config (biến thể "AI nghỉ").
class GreetingScreen extends ConsumerStatefulWidget {
  const GreetingScreen({required this.challengeId, super.key});

  final String challengeId;

  @override
  ConsumerState<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends ConsumerState<GreetingScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  late List<String> _greetings;

  /// `null`: chưa hỏi; `true`: đang viết; `false`: đã xong (AI hoặc nghỉ).
  bool? _aiLoading;
  bool _fromAi = false;
  late final AppLifecycleListener _lifecycle;
  int? _selected;
  bool _awaitingReturn = false;

  @override
  void initState() {
    super.initState();
    _greetings = ref.read(remoteConfigServiceProvider).discordGreetings;
    if (_greetings.isNotEmpty) {
      _selected = 0;
      _text.text = _greetings.first;
    }
    // Đã mở Discord: người dùng quay lại app thì về S08.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_awaitingReturn && mounted) context.pop(true);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Nhờ Tụi Nốt AI viết câu chào khi đã biết thẻ (một lần).
  Future<void> _askAi(String challengeTitle, String room) async {
    final ai = ref.read(aiServiceProvider);
    if (!ai.config.enabled) {
      _aiLoading = false;
      return;
    }
    setState(() => _aiLoading = true);
    try {
      final lines = await ai.greetings(
        challengeTitle: challengeTitle,
        room: room,
      );
      if (!mounted) return;
      setState(() {
        // Người dùng đang sửa câu riêng thì giữ nguyên ô nhập.
        final keepOwn = _selected == null && _text.text.trim().isNotEmpty;
        _greetings = lines;
        _fromAi = true;
        _aiLoading = false;
        if (!keepOwn) {
          _selected = 0;
          _text.text = lines.first;
        }
      });
    } on AiException {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _pick(int index) => setState(() {
    _selected = index;
    _text.text = _greetings[index];
  });

  void _writeOwn() {
    setState(() => _selected = null);
    _text.clear();
    _focus.requestFocus();
  }

  Future<void> _copyAndOpen(DiscordRoom room) async {
    final text = _text.text.trim();
    await Clipboard.setData(ClipboardData(text: text));
    if (_fromAi) {
      unawaited(
        ref.read(analyticsServiceProvider).logEvent(
          AnalyticsEvents.aiResultAccepted,
          <String, Object>{
            'feature': AiFeature.greeting.id,
            'item_count': 1,
            'edited_count': _greetings.contains(text) ? 0 : 1,
          },
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Đã sao chép câu chào · đang mở Discord')),
      );
    final opened = await openDiscordRoom(context, ref, room);
    if (opened && mounted) setState(() => _awaitingReturn = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final challenge = ref
        .watch(challengeDetailViewModelProvider(widget.challengeId))
        .loaded;
    final room =
        DiscordRooms.byKey(challenge?.discordRoom ?? DiscordRooms.chaoHoi) ??
        DiscordRooms.shared.first;
    final canSend = _text.text.trim().isNotEmpty;
    if (challenge != null && _aiLoading == null) {
      _aiLoading = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _askAi(challenge.title, room.name),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Câu chào của bạn'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.narrowContentMaxWidth,
            ),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      AppSpace.s16,
                      AppSpace.screen,
                      AppSpace.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpace.s16,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: Text(
                            'Chọn một câu chào',
                            style: theme.textTheme.titleLarge?.copyWith(
                              letterSpacing: -0.44,
                            ),
                          ),
                        ),
                        if (_aiLoading ?? false)
                          const _Writing()
                        else if (_fromAi)
                          const _AiLabel()
                        else
                          const _Resting(),
                        if (_greetings.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpace.s8,
                            children: <Widget>[
                              for (final (i, line) in _greetings.indexed)
                                _GreetingTile(
                                  text: line,
                                  selected: _selected == i,
                                  onTap: () => _pick(i),
                                ),
                            ],
                          ),
                        AppTextField(
                          label: 'Câu bạn sẽ gửi',
                          controller: _text,
                          focusNode: _focus,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: 200,
                          onChanged: (_) => setState(() => _selected = null),
                        ),
                        Text(
                          'Bạn tự dán câu này lên Discord. Nốt không gửi gì '
                          'thay bạn.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        AppButton(
                          label: 'Sao chép và mở ${room.name}',
                          expand: true,
                          onPressed: canSend ? () => _copyAndOpen(room) : null,
                        ),
                        AppButton(
                          label: 'Tự viết câu khác',
                          variant: AppButtonVariant.text,
                          expand: true,
                          onPressed: _writeOwn,
                        ),
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

/// Figma `banner AI nghỉ`: nền tint cam, mascot Ngủ 44, hai dòng chữ.
class _Resting extends StatelessWidget {
  const _Resting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppPalette.tintOrange,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            spacing: AppSpace.s12,
            children: <Widget>[
              const Mascot(state: MascotState.ngu, size: 49.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.s2,
                  children: <Widget>[
                    Text(
                      'Tụi Nốt đang nghỉ một chút',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Đây là câu chào có sẵn. Bạn vẫn sửa được.',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một câu chào: đang chọn thì nền primary-container, viền primary 2.
class _GreetingTile extends StatelessWidget {
  const _GreetingTile({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ),
      ),
    );
  }
}

/// Đang chờ Tụi Nốt AI viết câu chào.
class _Writing extends StatelessWidget {
  const _Writing();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      children: <Widget>[
        const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Text(
            'Tụi Nốt đang viết câu chào cho bạn…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

/// Nhãn "Gợi ý từ Nốt AI" phía trên các câu do AI viết.
class _AiLabel extends StatelessWidget {
  const _AiLabel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
        const SizedBox(width: AppSpace.s8),
        Expanded(
          child: Text(
            'Tụi Nốt AI viết giúp · sửa thoải mái trước khi gửi',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.primary),
          ),
        ),
      ],
    );
  }
}
