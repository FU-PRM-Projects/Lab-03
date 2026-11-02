import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discord_room.dart';
import '../models/first_group.dart';
import 'groups_view_model.dart';
import 'view_state.dart';

/// Một dòng ở S14: phòng và dòng phụ ("Nhóm Bắt chuyện · 4 nốt").
class DiscordRoomRow {
  const DiscordRoomRow({required this.room, required this.subtitle});

  final DiscordRoom room;
  final String subtitle;
}

/// S14 · Phòng trò chuyện: phòng của nhóm người dùng đã có nốt lên trước,
/// phòng còn lại là "Tụi Nốt gợi ý cho bạn"; rồi các phòng chung.
class DiscordRoomsData {
  const DiscordRoomsData({required this.groupRooms, required this.shared});

  final List<DiscordRoomRow> groupRooms;
  final List<DiscordRoomRow> shared;

  /// Xếp phòng nhóm theo [groups] của người dùng (đã có nốt, mới nhất trước).
  factory DiscordRoomsData.from(List<FirstGroup> groups) {
    final mine = <DiscordRoomRow>[
      for (final group in groups)
        if (group.noteCount > 0)
          if (DiscordRooms.forGroup(group.id) case final room?)
            DiscordRoomRow(
              room: room,
              subtitle: 'Nhóm ${group.name} · ${group.noteCount} nốt',
            ),
    ];
    final taken = <String>{for (final row in mine) row.room.key};
    return DiscordRoomsData(
      groupRooms: <DiscordRoomRow>[
        ...mine,
        for (final room in DiscordRooms.group)
          if (!taken.contains(room.key))
            DiscordRoomRow(room: room, subtitle: room.blurb),
      ],
      shared: <DiscordRoomRow>[
        for (final room in DiscordRooms.shared)
          DiscordRoomRow(room: room, subtitle: room.blurb),
      ],
    );
  }
}

/// Danh sách phòng của S14. Nhóm chưa tải được thì vẫn hiện đủ phòng, dòng
/// phụ dùng lời gợi ý: phòng nằm trên Discord, không phụ thuộc dữ liệu nhóm.
final discordRoomsProvider = Provider.autoDispose<DiscordRoomsData>((ref) {
  final shelf = ref.watch(groupsViewModelProvider);
  return DiscordRoomsData.from(switch (shelf) {
    Data<GroupShelfData>(:final value) => value.groups,
    _ => const <FirstGroup>[],
  });
});
