import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/image_ref.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/widgets/app_network_image.dart';
import 'package:lab03/widgets/note_card.dart';
import 'package:lab03/widgets/note_tile.dart';

import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

const _photo = ImageRef(
  url: 'https://res.cloudinary.com/demo/image/upload/moment.jpg',
  publicId: 'notes/moment',
);

/// Mọi chỗ xem lại nốt phải hiện ảnh khoảnh khắc đã lưu kèm nốt.
void main() {
  group('NoteTile', () {
    testWidgets('nốt có ảnh: hiện ảnh nhỏ và báo "có ảnh" cho TalkBack', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const SizedBox(
          width: 158,
          height: 137,
          child: NoteTile(
            type: NoteType.chienThang,
            title: 'Dọn bàn học',
            dateLabel: '24/10',
            image: _photo,
          ),
        ),
      );

      expect(find.byType(AppNetworkImage), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Dọn bàn học.*có ảnh')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('nốt không ảnh: không có khung ảnh', (tester) async {
      await pumpThemed(
        tester,
        const SizedBox(
          width: 158,
          height: 137,
          child: NoteTile(
            type: NoteType.chienThang,
            title: 'Dọn bàn học',
            dateLabel: '24/10',
          ),
        ),
      );

      expect(find.byType(AppNetworkImage), findsNothing);
      expect(find.bySemanticsLabel(RegExp('có ảnh')), findsNothing);
    });

    testWidgets('ô thấp 96 dp (lịch Hành trình) có ảnh vẫn không tràn', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const SizedBox(
          width: 158,
          height: 96,
          child: NoteTile(
            type: NoteType.chienThang,
            title: 'Một chiến thắng nhỏ',
            dateLabel: '20:00 · Ổn',
            image: _photo,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('NoteCard', () {
    testWidgets('nốt có ảnh: ảnh thay biểu tượng loại nốt', (tester) async {
      await pumpThemed(
        tester,
        const NoteCard(
          type: NoteType.chienThang,
          title: 'Dọn bàn học',
          meta: 'Chiến thắng · 24/10',
          image: _photo,
        ),
      );

      expect(find.byType(AppNetworkImage), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Dọn bàn học.*có ảnh')),
        findsOneWidget,
      );
    });

    testWidgets('nốt không ảnh: vẫn hiện biểu tượng loại nốt', (tester) async {
      await pumpThemed(
        tester,
        const NoteCard(
          type: NoteType.chienThang,
          title: 'Dọn bàn học',
          meta: 'Chiến thắng · 24/10',
        ),
      );

      expect(find.byType(AppNetworkImage), findsNothing);
    });
  });
}
