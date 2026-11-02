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
    expect(config.monthlyMilestone, InAppRemoteConfig.defaultMonthlyMilestone);
    expect(await config.refresh(), isFalse);
  });
}
