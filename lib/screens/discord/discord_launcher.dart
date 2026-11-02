import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/discord_room.dart';
import '../../services/discord_service.dart';
import '../../services/remote_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/mascot.dart';

/// Mở [room] trên Discord (S14, S05e, S08). Lần đầu hiện S14b "Trước khi vào
/// phòng"; mở thất bại thì hỏi "Mở bằng web" hoặc "Sao chép". Trả `true` khi
/// đã rời app sang Discord hoặc trình duyệt.
Future<bool> openDiscordRoom(
  BuildContext context,
  WidgetRef ref,
  DiscordRoom room,
) async {
  final discord = ref.read(discordServiceProvider);
  final url = ref.read(remoteConfigServiceProvider).linkFor(room);

  if (!await discord.rulesSeen()) {
    if (!context.mounted) return false;
    final agreed = await showDiscordRulesSheet(context, asking: true);
    if (!agreed) return false;
    await discord.markRulesSeen();
  }

  if (await discord.open(url)) return true;
  if (!context.mounted) return false;
  final web = await showAppDialog(
    context: context,
    title: 'Chưa mở được Discord',
    message:
        'Máy chưa cài Discord hoặc link vừa đổi. Bạn có thể mở bằng trình '
        'duyệt.',
    confirmLabel: 'Mở bằng web',
    cancelLabel: 'Sao chép',
  );
  if (web == null) return false;
  if (web) {
    if (await discord.open(url, inBrowser: true)) return true;
    if (!context.mounted) return false;
  }
  await Clipboard.setData(ClipboardData(text: url));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Đã sao chép link phòng')));
  }
  return false;
}

/// S14b · "Trước khi vào phòng". [asking] là lần đầu mở phòng (hai nút "Mình
/// hiểu, mở Discord" / "Để sau"); `false` là xem lại từ "Quy tắc phòng".
/// Trả `true` khi người dùng đồng ý mở.
Future<bool> showDiscordRulesSheet(
  BuildContext context, {
  required bool asking,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RulesSheet(asking: asking),
    ) ??
    false;

class _RulesSheet extends StatelessWidget {
  const _RulesSheet({required this.asking});

  final bool asking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = AppColors.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s20,
          0,
          AppSpace.s20,
          AppSpace.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s16,
          children: <Widget>[
            const Center(child: Mascot(state: MascotState.thongTha, size: 72)),
            Semantics(
              header: true,
              child: Text(
                'Trước khi vào phòng',
                style: theme.textTheme.titleLarge?.copyWith(
                  letterSpacing: -0.44,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const _RuleRow(
              icon: 'assets/icons/check.svg',
              tint: AppPalette.tintGreen,
              label: 'Bạn sẽ rời Nốt',
              text: 'Mở Discord. Nốt không đọc tin nhắn ở đó.',
            ),
            _RuleRow(
              icon: 'assets/icons/close.svg',
              tint: scheme.errorContainer,
              label: 'Giữ ẩn danh',
              text: 'Không dùng tên thật, trường, số điện thoại',
            ),
            _RuleRow(
              icon: 'assets/icons/pencil.svg',
              tint: colors.tintLavender,
              label: 'Bạn quyết',
              text: 'Chặn, báo cáo hoặc rời phòng lúc nào cũng được',
            ),
            if (asking) ...<Widget>[
              AppButton(
                label: 'Mình hiểu, mở Discord',
                expand: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              AppButton(
                label: 'Để sau',
                variant: AppButtonVariant.text,
                expand: true,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ] else
              AppButton(
                label: 'Mình hiểu',
                expand: true,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            Text(
              'Discord yêu cầu từ 13 tuổi trở lên',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Một dòng quy tắc: vòng 36 nền tint với icon 20, nhãn Label/13 SemiBold
/// và câu Body/16 SemiBold.
class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.text,
  });

  final String icon;
  final Color tint;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MergeSemantics(
      child: Row(
        spacing: AppSpace.s12,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              icon,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(scheme.onSurface, BlendMode.srcIn),
              excludeFromSemantics: true,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
