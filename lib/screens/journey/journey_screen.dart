import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/journey_view_model.dart';
import '../../widgets/app_dialog.dart';
import '../common/screen_skeleton.dart';
import 'journey_calendar_tab.dart';
import 'journey_path_tab.dart';
import 'journey_stats_tab.dart';

/// Tab con của S11.
enum JourneyTab {
  path('path', 'Con đường'),
  stats('stats', 'Thống kê'),
  calendar('calendar', 'Lịch');

  const JourneyTab(this.id, this.label);

  final String id;
  final String label;

  static JourneyTab fromId(String? id) =>
      values.firstWhere((tab) => tab.id == id, orElse: () => JourneyTab.path);
}

/// S11 · Hành trình (tab 4): Con đường, Thống kê, Lịch.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({this.tab = JourneyTab.path, super.key});

  final JourneyTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(journeyViewModelProvider);
    final viewModel = ref.read(journeyViewModelProvider.notifier);

    // P6: Mệt / Rối 5 ngày liền → gợi ý người để nói chuyện.
    ref.listen(journeyViewModelProvider.select((s) => s.supportVisible), (
      previous,
      visible,
    ) async {
      if (!visible || (previous ?? false)) return;
      await showAppDialog(
        context: context,
        title: 'Mấy hôm nay hơi nặng nề',
        message:
            'Bạn đã thấy mệt hoặc rối ${JourneyViewModel.lowDaysForSupport} '
            'ngày liền. Thử kể với một người bạn tin cậy, hoặc ghé phòng tư '
            'vấn tâm lý của trường. Nếu thấy không an toàn, gọi ngay 115.',
        confirmLabel: 'Mình hiểu rồi',
        cancelLabel: 'Để sau',
      );
      viewModel.dismissSupport();
    });

    return TabScaffold(
      title: 'Hành trình',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              0,
              AppSpace.screen,
              AppSpace.s8,
            ),
            child: SegmentedButton<JourneyTab>(
              segments: <ButtonSegment<JourneyTab>>[
                for (final value in JourneyTab.values)
                  ButtonSegment<JourneyTab>(
                    value: value,
                    label: Text(value.label),
                  ),
              ],
              selected: <JourneyTab>{tab},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  context.go(AppRoutes.journeyTab(selection.single.id)),
            ),
          ),
          Expanded(
            // Mỗi tab con giữ vị trí cuộn riêng (handout S11).
            child: switch (tab) {
              JourneyTab.path => JourneyPathTab(
                key: const PageStorageKey<String>('journey-path'),
                state: state.path,
                onRetry: viewModel.retry,
              ),
              JourneyTab.stats => JourneyStatsTab(
                key: const PageStorageKey<String>('journey-stats'),
                state: state,
                viewModel: viewModel,
              ),
              JourneyTab.calendar => JourneyCalendarTab(
                key: const PageStorageKey<String>('journey-calendar'),
                state: state,
                viewModel: viewModel,
              ),
            },
          ),
        ],
      ),
    );
  }
}
