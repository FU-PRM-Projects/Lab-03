import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/discord_service.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/discord_rooms_view_model.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/setting_row.dart';
import 'discord_connect_sheet.dart';
import 'discord_launcher.dart';

/// S14 · Phòng trò chuyện (Discord): Nốt chỉ mở link, không đọc tin nhắn.
class DiscordRoomsScreen extends ConsumerWidget {
  const DiscordRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(discordRoomsProvider);

    List<Widget> rows(List<DiscordRoomRow> list) => <Widget>[
      for (final row in list)
        SettingRow.value(
          title: row.room.name,
          subtitle: row.subtitle,
          value: 'Mở',
          onTap: () => openDiscordRoom(context, ref, row.room),
        ),
    ];

    return Scaffold(
      appBar: const AppTopBar(title: 'Phòng trò chuyện'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.contentMaxWidth,
            ),
            // Figma S14: lời giới thiệu, hai nhóm phòng; "Quy tắc phòng" dính
            // đáy (spacer co giãn), màn thấp thì cuộn.
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
                        Text(
                          'Nơi gặp người cũng đang tập. Phòng nằm trên '
                          'Discord, Nốt chỉ mở link và không đọc tin nhắn.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SettingGroup(
                          label: 'PHÒNG CỦA NHÓM BẠN',
                          children: rows(data.groupRooms),
                        ),
                        SettingGroup(
                          label: 'PHÒNG CHUNG',
                          children: rows(data.shared),
                        ),
                        SettingGroup(
                          label: 'BOT TRỢ LÝ (DM)',
                          children: <Widget>[
                            SettingRow.value(
                              title: 'Liên kết tài khoản Discord',
                              subtitle:
                                  ref
                                      .watch(discordLinkProvider)
                                      .value
                                      ?.discordUsername ??
                                  'Nhắn /connect cho bot trong DM để lấy mã',
                              value:
                                  ref.watch(discordLinkProvider).value != null
                                  ? 'Đã kết nối'
                                  : 'Nhập mã',
                              onTap: () => showDiscordConnectSheet(context),
                            ),
                          ],
                        ),
                        const Spacer(),
                        AppButton(
                          label: 'Quy tắc phòng',
                          variant: AppButtonVariant.outlined,
                          expand: true,
                          onPressed: () =>
                              showDiscordRulesSheet(context, asking: false),
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
