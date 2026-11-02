import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discord_room.dart';
import 'remote_config_service.dart';

/// Mở phòng Discord bằng link (không bot, không đọc tin nhắn) và nhớ người
/// dùng đã đọc quy tắc phòng chưa.
abstract interface class DiscordService {
  /// Mở [url] bằng app Discord (hoặc app mặc định của link); [inBrowser] mở
  /// bằng trình duyệt. `false` khi máy không mở được.
  Future<bool> open(String url, {bool inBrowser = false});

  /// Đã xem sheet "Trước khi vào phòng" (cờ `discord_rules_seen`).
  Future<bool> rulesSeen();

  Future<void> markRulesSeen();
}

final discordServiceProvider = Provider<DiscordService>(
  (ref) => throw UnimplementedError('discordServiceProvider chưa được gắn'),
);

/// Link của [room]: link riêng trong `discord_channel_map`, không có thì link
/// mời vào server.
extension DiscordRoomLinks on RemoteConfigService {
  String linkFor(DiscordRoom room) =>
      discordChannels[room.key] ?? discordInviteUrl;
}
