import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/firebase/report_impl.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/report.dart';

/// Dựng PDF Thẻ tuần thật (gói `pdf` + font đóng gói), không cần mạng.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF Thẻ tuần có font tiếng Việt đóng gói, chạy offline', () async {
    final bytes = await const PdfReportService().weeklyCard(
      WeeklySummary(
        weekStart: DateTime(2026, 11, 9),
        noteCount: 5,
        daysWithNotes: 4,
        dayMoods: <Mood?>[Mood.vui, null, Mood.on, Mood.met, null, null, null],
        wins: const <String>['Đi bộ 20 phút', 'Chào người lạ ở thang máy'],
        balance: const <String, int>{'Vận động': 2, 'Kết nối': 1},
        energy: 3.5,
      ),
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
    final text = latin1.decode(bytes);
    expect(text, contains('BeVietnamPro'));
    expect(text, contains('/MediaBox'));
  });
}
