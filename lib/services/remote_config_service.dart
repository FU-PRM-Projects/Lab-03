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

  @override
  List<String> get quickWinChips => defaultQuickWinChips;

  @override
  int get monthlyMilestone => defaultMonthlyMilestone;
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => const InAppRemoteConfig(),
);
