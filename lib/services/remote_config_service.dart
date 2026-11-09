import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_service.dart';

/// Tham số Remote Config mà màn hình dùng.
///
/// Stage 4 dùng [InAppRemoteConfig] (giá trị mặc định trong app). Stage 5 gắn
/// bản Firebase: tải, kích hoạt và lắng nghe thay đổi từ Console.
abstract interface class RemoteConfigService {
  /// 6 chip "Hoặc chọn nhanh" ở S03b (`quick_win_chips`).
  List<String> get quickWinChips;

  /// Hiện kệ "Nhóm lần đầu" ở hũ S05 (`groups_enabled`).
  bool get groupsEnabled;

  /// Cho người dùng tự thêm thẻ thử thách ở S07 (`custom_challenges_enabled`).
  bool get customChallengesEnabled;

  /// Cho gửi thẻ tự thêm lên kho chung để staff duyệt
  /// (`challenge_submissions_enabled`, luồng liên vai trò của Final).
  bool get challengeSubmissionsEnabled;

  /// Bật phòng Discord (`discord_enabled`): tắt thì ẩn S14, dòng phòng ở
  /// S05e, lối vào ở S12 và thẻ thử thách cấp 3 trên Discord.
  bool get discordEnabled;

  /// Link mời vào server (`discord_invite_url`); phòng chưa có link riêng
  /// thì mở link này.
  String get discordInviteUrl;

  /// Link từng phòng theo mã phòng (`discord_channel_map`, JSON).
  Map<String, String> get discordChannels;

  /// Câu chào có sẵn ở S08d khi Tụi Nốt AI nghỉ (`discord_greetings`).
  List<String> get discordGreetings;

  /// Hiện nhóm "Khu demo Firebase" ở S12 (`firebase_demo_enabled`).
  bool get firebaseDemoEnabled;

  /// Tham số Nốt AI (`ai_*`).
  AiConfig get ai;

  /// Tải lại cấu hình từ Console; `true` khi có giá trị mới được kích hoạt.
  Future<bool> refresh();
}

/// Giá trị mặc định trong app, cũng là giá trị khi tải cấu hình thất bại.
class InAppRemoteConfig implements RemoteConfigService {
  const InAppRemoteConfig();

  static const List<String> defaultQuickWinChips = <String>[
    'Dọn phòng',
    'Giúp ai đó',
    'Đi bộ',
    'Ăn đủ bữa',
    'Ngủ trước 12h',
    'Xong 1 việc khó',
  ];

  /// Link mẫu: đổi bằng Remote Config khi nhóm có server thật.
  static const String defaultDiscordInviteUrl = 'https://discord.gg/not-demo';

  static const List<String> defaultDiscordGreetings = <String>[
    'Chào mọi người! Mình mới vào, mong được làm quen.',
    'Hi cả phòng, mình đang tập bắt chuyện.',
  ];

  @override
  List<String> get quickWinChips => defaultQuickWinChips;

  @override
  bool get groupsEnabled => true;

  @override
  bool get customChallengesEnabled => true;

  @override
  bool get challengeSubmissionsEnabled => true;

  @override
  bool get discordEnabled => true;

  @override
  String get discordInviteUrl => defaultDiscordInviteUrl;

  @override
  Map<String, String> get discordChannels => const <String, String>{};

  @override
  List<String> get discordGreetings => defaultDiscordGreetings;

  @override
  bool get firebaseDemoEnabled => true;

  @override
  AiConfig get ai => const AiConfig();

  @override
  Future<bool> refresh() async => false;
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => const InAppRemoteConfig(),
);

/// Tăng sau mỗi lần [RemoteConfigService.refresh] có giá trị mới, để màn đang
/// mở đọc lại cấu hình.
class RemoteConfigRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final remoteConfigRevisionProvider =
    NotifierProvider<RemoteConfigRevision, int>(RemoteConfigRevision.new);
