import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/app_exception.dart';
import '../../services/discord_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';

/// Link cài Nốt Bot vào tài khoản Discord của người dùng (User Install).
const String kDiscordBotInstallUrl =
    'https://discord.com/oauth2/authorize'
    '?client_id=1568528720203878460&integration_type=1'
    '&scope=applications.commands';

/// Mở sheet liên kết (hoặc xem / ngắt liên kết) tài khoản Discord với Nốt.
///
/// Mỗi tài khoản Nốt chỉ liên kết với 1 tài khoản Discord duy nhất thông qua
/// mã 6 ký tự từ lệnh `/connect` (hoặc `!connect`) trong DM với bot.
Future<void> showDiscordConnectSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _DiscordConnectSheet(),
    );

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s12,
      children: <Widget>[
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _DiscordConnectSheet extends ConsumerStatefulWidget {
  const _DiscordConnectSheet();

  @override
  ConsumerState<_DiscordConnectSheet> createState() =>
      _DiscordConnectSheetState();
}

class _DiscordConnectSheetState extends ConsumerState<_DiscordConnectSheet> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  static String _errorMessage(Object error) {
    if (error is AppException) {
      return switch (error.code) {
        'invalid-code-format' => 'Mã kết nối gồm đúng 6 ký tự.',
        'code-not-found' => 'Mã không tồn tại hoặc đã được sử dụng. Nhắn /connect cho bot để lấy mã mới nhé.',
        'code-expired' => 'Mã đã hết hạn (quá 10 phút). Nhắn /connect cho bot để lấy mã mới nhé.',
        'account-already-linked' =>
          'Tài khoản Nốt này đã gắn với một tài khoản Discord.',
        'discord-already-linked' =>
          'Tài khoản Discord này đã được liên kết với một tài khoản Nốt khác.',
        _ when error.kind == AppErrorKind.network =>
          'Không có mạng. Kiểm tra Wi-Fi rồi thử lại.',
        _ => 'Chưa liên kết được. Kiểm tra lại mã rồi thử lại nhé.',
      };
    }
    return 'Chưa liên kết được. Thử lại sau ít phút nhé.';
  }

  Future<void> _openBotInstall() async {
    final opened = await ref
        .read(discordServiceProvider)
        .open(kDiscordBotInstallUrl);
    if (opened || !mounted) return;
    setState(() => _error = 'Không mở được Discord. Thử lại sau nhé.');
  }

  Future<void> _submit() async {
    final trimmed = _code.text.trim().toUpperCase();
    if (trimmed.length != 6) {
      setState(() => _error = 'Mã kết nối gồm đúng 6 ký tự.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final link = await ref
          .read(discordServiceProvider)
          .connectWithCode(trimmed);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Đã liên kết với Discord: ${link.discordUsername}'),
          ),
        );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _disconnect(DiscordLink link) async {
    final confirmed = await showAppDialog(
      context: context,
      title: 'Ngắt liên kết Discord?',
      message:
          'Tài khoản Nốt sẽ huỷ liên kết với ${link.discordUsername}. '
          'Bạn có thể dùng lệnh /connect để liên kết lại bất cứ lúc nào.',
      confirmLabel: 'Ngắt liên kết',
      kind: AppDialogKind.destructive,
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(discordServiceProvider).disconnect();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Đã ngắt liên kết Discord.')),
        );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _errorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = ref.watch(discordLinkProvider).value;

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
          child: link != null
              ? _buildLinkedView(theme, link)
              : _buildConnectForm(theme),
        ),
      ),
    );
  }

  Widget _buildLinkedView(ThemeData theme, DiscordLink link) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s16,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Đã liên kết Discord',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Text(
          'Tài khoản Nốt của bạn đang gắn 1-1 với tài khoản Discord:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpace.s16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s4,
            children: <Widget>[
              Text(
                link.discordUsername,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Discord ID: ${link.discordId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        AppButton(
          label: 'Ngắt liên kết',
          variant: AppButtonVariant.destructive,
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : () => _disconnect(link),
        ),
        AppButton(
          label: 'Đóng',
          variant: AppButtonVariant.text,
          expand: true,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildConnectForm(ThemeData theme) {
    final canSubmit = !_busy && _code.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s16,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Liên kết Discord',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Text(
          'Làm theo 3 bước để liên kết. Mỗi tài khoản Nốt chỉ liên kết với 1 '
          'tài khoản Discord duy nhất.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const _SetupStep(
          number: 1,
          text:
              'Thêm Nốt Bot vào tài khoản Discord của bạn (chỉ cần làm một '
              'lần). Bấm nút bên dưới, chọn "Thêm vào ứng dụng của tôi" rồi '
              '"Cho phép".',
        ),
        AppButton(
          label: 'Thêm Nốt Bot vào Discord',
          variant: AppButtonVariant.tonal,
          expand: true,
          onPressed: _openBotInstall,
        ),
        const _SetupStep(
          number: 2,
          text:
              'Mở tin nhắn riêng (DM) với Nốt Bot trên Discord và gửi lệnh '
              '/connect (hoặc !⁠connect) để nhận mã 6 ký tự.',
        ),
        const _SetupStep(
          number: 3,
          text: 'Nhập mã vào ô bên dưới. Mã có hiệu lực trong 10 phút.',
        ),
        AppTextField(
          label: 'Mã kết nối',
          hint: 'Ví dụ: A1B2C3',
          controller: _code,
          maxLength: 6,
          errorText: _error,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) {
            if (canSubmit) _submit();
          },
        ),
        AppButton(
          label: 'Kết nối',
          expand: true,
          loading: _busy,
          onPressed: canSubmit ? _submit : null,
        ),
        AppButton(
          label: 'Huỷ',
          variant: AppButtonVariant.text,
          expand: true,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
