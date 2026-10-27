import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/utils/vi_date_format.dart';

void main() {
  group('Mood', () {
    test('thang năng lượng S11b: Vui = 5 … Rối = 1', () {
      expect(Mood.values.map((m) => m.score), <int>[5, 4, 3, 2, 1]);
    });

    test('Mệt và Rối là ngày tệ', () {
      expect(Mood.values.where((m) => m.isLow), <Mood>[Mood.met, Mood.roi]);
    });

    test('đọc lại từ id Firestore', () {
      for (final mood in Mood.values) {
        expect(Mood.fromId(mood.id), mood);
      }
      expect(Mood.fromId('khong_co'), isNull);
    });
  });

  test('NoteType đọc lại từ id Firestore', () {
    for (final type in NoteType.values) {
      expect(NoteType.fromId(type.id), type);
    }
    expect(NoteType.fromId(null), isNull);
  });

  group('ViDateFormat', () {
    final saturday = DateTime(2026, 10, 24, 21, 5);

    test('tiêu đề S02 dạng "Thứ Bảy, 24/10"', () {
      expect(ViDateFormat.dayHeader(saturday), 'Thứ Bảy, 24/10');
      expect(ViDateFormat.dayHeader(DateTime(2026, 10, 25)), 'Chủ Nhật, 25/10');
    });

    test('giờ 24 giờ và ngày đọc cho trình đọc màn hình', () {
      expect(ViDateFormat.time(saturday), '21:05');
      expect(ViDateFormat.shortDate(DateTime(2026, 3, 9)), '09/03');
      expect(ViDateFormat.spoken(saturday), '24 tháng 10');
    });
  });
}
