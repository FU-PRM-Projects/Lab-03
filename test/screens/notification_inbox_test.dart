import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/screens/common/notification_inbox.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/messaging_service.dart';
import 'package:lab03/theme/app_theme.dart';
import 'package:lab03/viewmodels/community_view_model.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fakes.dart';
import '../support/pump.dart';

/// Hộp thư: mỗi tin có biểu tượng theo loại, tin chưa đọc được đếm, giờ đọc
/// theo ngày tương đối.
void main() {
  Future<void> pumpSheet(
    WidgetTester tester,
    AsyncValue<List<InboxEntry>> community,
  ) async {
    setScreenSize(tester, phone360);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityInboxProvider.overrideWithValue(community),
          inboxProvider.overrideWith(
            (ref) async => const <ReceivedNotification>[],
          ),
          clockProvider.overrideWithValue(FixedClock()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: NotificationInboxSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tin được duyệt, bị từ chối, thông báo chung có biểu tượng riêng',
    (tester) async {
      await pumpSheet(
        tester,
        AsyncData(<InboxEntry>[
          InboxEntry(
            id: 'm1',
            title: 'Thẻ của bạn đã vào kho chung',
            body: '"Đi bộ 10 phút" đã được duyệt.',
            personal: true,
            kind: InboxEntryKind.approved,
            at: DateTime(2026, 10, 24, 10, 15),
            unread: true,
          ),
          InboxEntry(
            id: 'm2',
            title: 'Thẻ chưa được duyệt',
            body: 'Lý do: trùng thẻ có sẵn.',
            personal: true,
            kind: InboxEntryKind.rejected,
            at: DateTime(2026, 10, 23, 9),
          ),
          InboxEntry(
            id: 'a-1',
            title: 'Thẻ mới tuần này',
            body: 'Có 3 thẻ vận động mới.',
            personal: false,
            at: DateTime(2026, 10, 20, 8),
          ),
        ]),
      );

      expect(find.text('1 tin mới'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
      expect(find.text('Tin riêng · Hôm nay · 10:15'), findsOneWidget);
      expect(find.text('Tin riêng · Hôm qua · 09:00'), findsOneWidget);
      expect(find.text('Thông báo chung · 20/10 · 08:00'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Tin mới')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('chưa có tin: Tụi Nốt và lời giải thích, không đếm tin mới', (
    tester,
  ) async {
    await pumpSheet(tester, const AsyncData(<InboxEntry>[]));
    expect(find.textContaining('Chưa có tin nào.'), findsOneWidget);
    expect(find.textContaining('tin mới'), findsNothing);
    expect(find.text('Chưa có thông báo đẩy nào.'), findsOneWidget);
  });
}
