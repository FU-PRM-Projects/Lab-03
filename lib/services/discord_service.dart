import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discord_room.dart';
import 'remote_config_service.dart';

/// Thông tin tài khoản Discord đã liên kết (1-1) với tài khoản Nốt.
class DiscordLink {
  const DiscordLink({
    required this.discordId,
    required this.discordUsername,
    this.linkedAt,
  });

  final String discordId;
  final String discordUsername;
  final DateTime? linkedAt;

  @override
  bool operator ==(Object other) =>
      other is DiscordLink &&
      other.discordId == discordId &&
      other.discordUsername == discordUsername &&
      other.linkedAt == linkedAt;

  @override
  int get hashCode => Object.hash(discordId, discordUsername, linkedAt);
}

/// Mở phòng Discord bằng link, nhớ người dùng đã đọc quy tắc phòng chưa, và
/// quản lý liên kết 1-1 với tài khoản Discord qua mã từ bot DM (`connect`).
abstract interface class DiscordService {
  /// Mở [url] bằng app Discord (hoặc app mặc định của link); [inBrowser] mở
  /// bằng trình duyệt. `false` khi máy không mở được.
  Future<bool> open(String url, {bool inBrowser = false});

  /// Đã xem sheet "Trước khi vào phòng" (cờ `discord_rules_seen`).
  Future<bool> rulesSeen();

  Future<void> markRulesSeen();

  /// Theo dõi trạng thái liên kết Discord 1-1 của người dùng hiện tại.
  Stream<DiscordLink?> watchLink();

  /// Liên kết tài khoản Nốt hiện tại với tài khoản Discord qua mã 6 ký tự
  /// [code] do bot tạo từ lệnh `connect` trong DM.
  ///
  /// Đảm bảo ràng buộc 1-1: 1 tài khoản Nốt chỉ gắn với 1 tài khoản Discord.
  Future<DiscordLink> connectWithCode(String code);

  /// Huỷ liên kết tài khoản Discord hiện tại.
  Future<void> disconnect();
}

final discordServiceProvider = Provider<DiscordService>(
  (ref) => throw UnimplementedError('discordServiceProvider chưa được gắn'),
);

/// Trạng thái liên kết Discord hiện tại của người dùng.
final discordLinkProvider = StreamProvider.autoDispose<DiscordLink?>(
  (ref) => ref.watch(discordServiceProvider).watchLink(),
);

/// Link của [room]: link riêng trong `discord_channel_map`, không có thì link
/// mời vào server.
extension DiscordRoomLinks on RemoteConfigService {
  String linkFor(DiscordRoom room) =>
      discordChannels[room.key] ?? discordInviteUrl;
}
