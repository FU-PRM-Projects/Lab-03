/// Một phòng trên server Discord của Nốt (S14). [key] là mã trong Remote
/// Config `discord_channel_map`.
class DiscordRoom {
  const DiscordRoom({
    required this.key,
    required this.name,
    required this.blurb,
    this.groupId,
  });

  final String key;

  /// Tên hiện trên app: "#lan-dau-bat-chuyen", "Voice tối thứ Sáu".
  final String name;

  /// Dòng phụ khi không gắn với nhóm của người dùng.
  final String blurb;

  /// Nhóm lần đầu của hệ thống có phòng này; `null` với phòng chung.
  final String? groupId;
}

/// Các phòng cố định (spec "Kết nối Discord"): mỗi nhóm hệ thống chính có một
/// phòng, cộng phòng chung. Nhóm người dùng tự tạo không có phòng.
abstract final class DiscordRooms {
  /// Phòng chung của thử thách cấp 3 "Chào 1 câu ở phòng chung".
  static const String chaoHoi = 'chao_hoi';

  static const List<DiscordRoom> group = <DiscordRoom>[
    DiscordRoom(
      key: 'bat_chuyen',
      name: '#lan-dau-bat-chuyen',
      blurb: 'Tụi Nốt gợi ý cho bạn',
      groupId: 'bat-chuyen',
    ),
    DiscordRoom(
      key: 'hoi_thay_co',
      name: '#hoi-thay-co',
      blurb: 'Tụi Nốt gợi ý cho bạn',
      groupId: 'hoi-thay-co',
    ),
    DiscordRoom(
      key: 'dung_luot_dem',
      name: '#dung-luot-dem',
      blurb: 'Tụi Nốt gợi ý cho bạn',
      groupId: 'dung-luot-dem',
    ),
  ];

  static const List<DiscordRoom> shared = <DiscordRoom>[
    DiscordRoom(
      key: chaoHoi,
      name: '#chao-hoi',
      blurb: 'Ai mới vào cũng chào 1 câu ở đây',
    ),
    DiscordRoom(
      key: 'voice_thu_sau',
      name: 'Voice tối thứ Sáu',
      blurb: '21h · nghe là chính, nói khi sẵn sàng',
    ),
  ];

  static DiscordRoom? forGroup(String groupId) {
    for (final room in group) {
      if (room.groupId == groupId) return room;
    }
    return null;
  }

  static DiscordRoom? byKey(String key) {
    for (final room in <DiscordRoom>[...group, ...shared]) {
      if (room.key == key) return room;
    }
    return null;
  }
}
