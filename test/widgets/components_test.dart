import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/widgets/app_button.dart';
import 'package:lab03/widgets/app_dialog.dart';
import 'package:lab03/widgets/mood_cells.dart';
import 'package:lab03/widgets/mood_option.dart';
import 'package:lab03/widgets/note_tile.dart';
import 'package:lab03/widgets/quick_win_chip.dart';
import 'package:lab03/widgets/setting_row.dart';
import 'package:lab03/widgets/state_views.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pump.dart';

void main() {
  group('AppButton', () {
    testWidgets('Loading giữ nguyên bề rộng và chặn chạm', (tester) async {
      var taps = 0;
      Widget button({required bool loading}) => AppButton(
        key: const Key('save'),
        label: 'Lưu vào hũ',
        loading: loading,
        onPressed: () => taps++,
      );

      await pumpThemed(tester, button(loading: false));
      final idleWidth = tester.getSize(find.byKey(const Key('save'))).width;

      await pumpThemed(tester, button(loading: true));
      expect(tester.getSize(find.byKey(const Key('save'))).width, idleWidth);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byKey(const Key('save')));
      expect(taps, 0);
      expect(
        tester.getSemantics(find.byKey(const Key('save'))),
        matchesSemantics(
          label: 'Lưu vào hũ, đang xử lý',
          isButton: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('Disabled khi onPressed null, cao 48', (tester) async {
      await pumpThemed(
        tester,
        const AppButton(key: Key('next'), label: 'Tiếp', onPressed: null),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(
        tester.getSize(find.byKey(const Key('next'))).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('Destructive dùng màu error', (tester) async {
      await pumpThemed(
        tester,
        AppButton(
          label: 'Xoá',
          variant: AppButtonVariant.destructive,
          onPressed: () {},
        ),
      );
      final context = tester.element(find.text('Xoá'));
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(
        style.backgroundColor!.resolve(<WidgetState>{}),
        Theme.of(context).colorScheme.error,
      );
    });
  });

  testWidgets('MoodOption: 96 × 116, báo đã chọn cho trình đọc màn hình', (
    tester,
  ) async {
    Mood? tapped;
    await pumpThemed(
      tester,
      MoodOption(mood: Mood.on, selected: true, onTap: () => tapped = Mood.on),
    );

    expect(tester.getSize(find.byType(MoodOption)), const Size(96, 116));
    expect(find.text('Ổn'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(MoodOption)),
      matchesSemantics(
        label: 'Tâm trạng Ổn',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(MoodOption));
    expect(tapped, Mood.on);
  });

  testWidgets('QuickWinChip cao tối thiểu 48', (tester) async {
    await pumpThemed(
      tester,
      QuickWinChip(label: 'Đi bộ', selected: false, onSelected: (_) {}),
    );
    expect(
      tester.getSize(find.byType(QuickWinChip)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('NoteTile luôn có nhãn loại bằng chữ', (tester) async {
    await pumpThemed(
      tester,
      const SizedBox(
        width: 160,
        child: NoteTile(
          type: NoteType.tuChu,
          title: 'Dừng lướt TikTok lúc 0h15',
          dateLabel: 'Hôm qua',
        ),
      ),
    );
    expect(find.text('Tự chủ'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(NoteTile)),
      matchesSemantics(label: 'Tự chủ: Dừng lướt TikTok lúc 0h15, Hôm qua'),
    );
  });

  testWidgets('MoodDayCell đọc ngày và tâm trạng, ô chưa ghi nói rõ', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MoodDayCell(
            key: Key('d24'),
            day: 24,
            semanticDate: '24 tháng 10',
            mood: Mood.on,
          ),
          MoodDayCell(key: Key('d25'), day: 25, semanticDate: '25 tháng 10'),
        ],
      ),
    );
    expect(tester.getSize(find.byKey(const Key('d24'))), const Size(48, 56));
    expect(
      tester.getSemantics(find.byKey(const Key('d24'))),
      matchesSemantics(label: '24 tháng 10, Ổn'),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('d25'))),
      matchesSemantics(label: '25 tháng 10, chưa ghi'),
    );
  });

  testWidgets('ErrorState có nút Thử lại gọi lại tải dữ liệu', (tester) async {
    var retries = 0;
    await pumpThemed(
      tester,
      ErrorState(
        title: 'Chưa tải được hũ',
        cause: 'Kiểm tra Wi-Fi rồi thử lại.',
        kind: ErrorKind.offline,
        onRetry: () => retries++,
      ),
    );
    await tester.tap(find.text('Thử lại'));
    expect(retries, 1);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('EmptyState hiện lời mời và một nút', (tester) async {
    var created = false;
    await pumpThemed(
      tester,
      EmptyState(
        title: 'Hũ còn trống',
        message: 'Ghi chiến thắng đầu tiên nhé.',
        actionLabel: 'Ghi nốt đầu tiên',
        onAction: () => created = true,
      ),
    );
    await tester.tap(find.text('Ghi nốt đầu tiên'));
    expect(created, isTrue);
  });

  testWidgets('SettingRow.toggle đổi giá trị', (tester) async {
    bool? value;
    await pumpThemed(
      tester,
      SettingRow.toggle(
        title: 'Ẩn nội dung thông báo',
        value: false,
        onChanged: (v) => value = v,
      ),
    );
    await tester.tap(find.byType(Switch));
    expect(value, isTrue);
  });

  group('showAppDialog', () {
    Future<bool?> open(WidgetTester tester, String tapLabel) async {
      bool? result;
      await pumpThemed(
        tester,
        Builder(
          builder: (context) => AppButton(
            label: 'Mở',
            onPressed: () async {
              result = await showAppDialog(
                context: context,
                title: 'Xoá nốt này?',
                message: 'Bạn có 5 giây để hoàn tác.',
                confirmLabel: 'Xoá',
                kind: AppDialogKind.destructive,
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá nốt này?'), findsOneWidget);
      await tester.tap(find.text(tapLabel));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('nút chính trả về true', (tester) async {
      expect(await open(tester, 'Xoá'), isTrue);
    });

    testWidgets('nút phụ trả về false', (tester) async {
      expect(await open(tester, 'Huỷ'), isFalse);
    });
  });
}
