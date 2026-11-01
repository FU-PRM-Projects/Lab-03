import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/first_group.dart';

void main() {
  group('FirstGroups.nameKey', () {
    test('bỏ dấu, không phân biệt hoa thường, gộp khoảng trắng', () {
      expect(FirstGroups.nameKey('  Bắt   Chuyện '), 'bat chuyen');
      expect(FirstGroups.nameKey('ĐI XE BUÝT'), 'di xe buyt');
      expect(
        FirstGroups.nameKey('Hỏi thầy cô'),
        FirstGroups.nameKey('hoi thay co'),
      );
    });
  });

  test('slug làm id ổn định từ tên', () {
    expect(FirstGroups.slug('Đi xe buýt một mình'), 'di-xe-buyt-mot-minh');
    expect(FirstGroups.slug('Ngủ trước 1h!'), 'ngu-truoc-1h');
  });

  test('mốc kế tiếp: Lần đầu → Lần 3 → Lần 10 → hết', () {
    expect(FirstGroups.nextMilestone(0), 1);
    expect(FirstGroups.nextMilestone(1), 3);
    expect(FirstGroups.nextMilestone(4), 10);
    expect(FirstGroups.nextMilestone(10), isNull);
    expect(FirstGroups.milestoneLabel(1), 'Lần đầu');
    expect(FirstGroups.milestoneLabel(3), 'Lần 3');
  });

  test('8 nhóm hệ thống có id riêng và tên trong giới hạn', () {
    expect(FirstGroups.system, hasLength(8));
    expect(FirstGroups.system.map((g) => g.id).toSet(), hasLength(8));
    for (final group in FirstGroups.system) {
      expect(group.name.length, lessThanOrEqualTo(FirstGroups.nameMaxLength));
      expect(group.source, GroupSource.system);
    }
  });
}
