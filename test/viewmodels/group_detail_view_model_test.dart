import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/services/analytics_events.dart';
import 'package:lab03/services/analytics_service.dart';
import 'package:lab03/services/group_repository.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/viewmodels/group_detail_view_model.dart';
import 'package:lab03/viewmodels/view_state.dart';

import '../support/fakes.dart';

/// S05e ghi `group_viewed` khi mở, để Analytics phủ đủ mọi loại màn chi tiết.
void main() {
  late FakeGroupRepository groups;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    groups = FakeGroupRepository();
    analytics = FakeAnalyticsService();
    container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(groups),
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> open(String id) async {
    container.listen(groupDetailViewModelProvider(id), (_, _) {});
    await pumpEventQueue();
  }

  test('mở nhóm: ghi group_viewed với loại nhóm, không có tên nhóm', () async {
    await open('bat-chuyen');

    expect(
      container.read(groupDetailViewModelProvider('bat-chuyen')),
      isA<Data<GroupDetail>>(),
    );
    final event = analytics.events.single;
    expect(event.name, AnalyticsEvents.groupViewed);
    expect(event.params, <String, Object>{
      AnalyticsParams.groupSource: 'system',
      AnalyticsParams.groupIdea: 'nguoi_la',
      AnalyticsParams.noteCount: 0,
    });
  });

  test('màn tải lại khi nhóm đổi nhưng chỉ ghi group_viewed một lần', () async {
    await open('bat-chuyen');
    final vm = container.read(
      groupDetailViewModelProvider('bat-chuyen').notifier,
    );

    expect(await vm.rename('Bắt chuyện ở lớp'), isNull);
    await pumpEventQueue();

    expect(
      analytics.events.where((e) => e.name == AnalyticsEvents.groupViewed),
      hasLength(1),
    );
  });

  test('nhóm không tồn tại: không ghi event', () async {
    await open('khong-co');
    expect(analytics.events, isEmpty);
  });
}
