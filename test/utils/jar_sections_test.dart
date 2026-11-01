import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/utils/jar_sections.dart';

import '../support/fakes.dart';

void main() {
  // Thứ Bảy 24/10/2026; tuần bắt đầu Thứ Hai 19/10.
  final now = DateTime(2026, 10, 24, 21, 30);

  test('gom theo Hôm nay, Hôm qua, Tuần này, Tuần trước rồi từng tháng', () {
    final notes = <DateTime>[
      DateTime(2026, 10, 24, 8),
      DateTime(2026, 10, 23, 22),
      DateTime(2026, 10, 20, 9),
      DateTime(2026, 10, 15, 9),
      DateTime(2026, 10, 2, 9),
      DateTime(2026, 9, 28, 9),
      DateTime(2025, 12, 31, 9),
    ].indexed.map((e) => sampleNote('n${e.$1}', e.$2)).toList();

    final sections = JarSections.group(notes, now);
    expect(sections.map((s) => s.title), <String>[
      'Hôm nay',
      'Hôm qua',
      'Tuần này',
      'Tuần trước',
      'Tháng 10',
      'Tháng 9',
      'Tháng 12, 2025',
    ]);
    expect(sections.map((s) => s.notes.length), <int>[1, 1, 1, 1, 1, 1, 1]);
    expect(sections[0].showsDay, isFalse);
    expect(sections[1].showsDay, isFalse);
    expect(sections[2].showsDay, isTrue);
  });

  test('bỏ nhóm rỗng; hôm qua thuộc tuần trước vẫn là "Hôm qua"', () {
    final monday = DateTime(2026, 10, 19, 10);
    final sections = JarSections.group(
      <DateTime>[
        DateTime(2026, 10, 18, 9),
        DateTime(2026, 10, 12, 9),
      ].indexed.map((e) => sampleNote('n${e.$1}', e.$2)).toList(),
      monday,
    );
    expect(sections.map((s) => s.title), <String>['Hôm qua', 'Tuần trước']);
  });
}
