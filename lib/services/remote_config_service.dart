import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tham số Remote Config mà màn hình dùng.
///
/// Stage 4 dùng [InAppRemoteConfig] (giá trị mặc định trong app). Stage 5 gắn
/// bản Firebase: tải, kích hoạt và lắng nghe thay đổi từ Console.
abstract interface class RemoteConfigService {
  /// 6 chip "Hoặc chọn nhanh" ở S03b (`quick_win_chips`).
  List<String> get quickWinChips;

  /// Số nốt của mốc tháng ở S04 (`monthly_milestone`).
  int get monthlyMilestone;

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

  static const int defaultMonthlyMilestone = 25;

  /// Link mẫu: đổi bằng Remote Config khi nhóm có server thật.
  static const String defaultDiscordInviteUrl = 'https://discord.gg/not-demo';

  static const List<String> defaultDiscordGreetings = <String>[
    'Chào mọi người! Mình mới vào, mong được làm quen.',
    'Hi cả phòng, mình đang tập bắt chuyện.',
  ];

  @override
  List<String> get quickWinChips => defaultQuickWinChips;

  @override
  int get monthlyMilestone => defaultMonthlyMilestone;

  @override
  bool get discordEnabled => true;

  @override
  String get discordInviteUrl => defaultDiscordInviteUrl;

  @override
  Map<String, String> get discordChannels => const <String, String>{};

  @override
  List<String> get discordGreetings => defaultDiscordGreetings;
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => const InAppRemoteConfig(),
);
