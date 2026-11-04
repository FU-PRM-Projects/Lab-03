import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/firebase/firebase_remote_config_service.dart';
import 'package:lab03/services/remote_config_service.dart';

/// Remote Config trả giá trị hỏng hoặc rỗng (mất mạng, chưa publish, JSON sai
/// trên Console): app phải giữ giá trị mặc định thay vì hỏng màn hình.
void main() {
  const chips = InAppRemoteConfig.defaultQuickWinChips;

  test('JSON hợp lệ: dùng giá trị từ Console', () {
    expect(parseStringList('["Uống nước","Đi bộ"]', chips), <String>[
      'Uống nước',
      'Đi bộ',
    ]);
  });

  test('JSON hỏng, rỗng hoặc sai kiểu: giữ mặc định', () {
    expect(parseStringList('không phải json', chips), chips);
    expect(parseStringList('', chips), chips);
    expect(parseStringList('[]', chips), chips);
    expect(parseStringList('{"a":1}', chips), chips);
    expect(parseStringList('[1,2]', chips), chips);
  });

  test('bảng link phòng: bỏ mục sai kiểu, hỏng thì giữ mặc định', () {
    expect(
      parseStringMap('{"chao":"https://x","y":1}', const {}),
      <String, String>{'chao': 'https://x'},
    );
    expect(
      parseStringMap('???', const <String, String>{'a': 'b'}),
      <String, String>{'a': 'b'},
    );
  });

  test('InAppRemoteConfig là giá trị khi tải thất bại', () async {
    const config = InAppRemoteConfig();
    expect(config.quickWinChips, chips);
    // Mặc định khi tải thất bại: mọi cờ tính năng đều bật.
    expect(config.customChallengesEnabled, isTrue);
    expect(config.groupsEnabled, isTrue);
    expect(config.firebaseDemoEnabled, isTrue);
    expect(await config.refresh(), isFalse);
  });

  test('firebase/remote-config-defaults.json khớp InAppRemoteConfig', () {
    final file = File('firebase/remote-config-defaults.json');
    final values = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, String>();
    const config = InAppRemoteConfig();
    expect(values, <String, String>{
      'quick_win_chips': jsonEncode(config.quickWinChips),
      'groups_enabled': '${config.groupsEnabled}',
      'custom_challenges_enabled': '${config.customChallengesEnabled}',
      'discord_enabled': '${config.discordEnabled}',
      'discord_invite_url': config.discordInviteUrl,
      'discord_channel_map': jsonEncode(config.discordChannels),
      'discord_greetings': jsonEncode(config.discordGreetings),
      'firebase_demo_enabled': '${config.firebaseDemoEnabled}',
    });
  });
}
