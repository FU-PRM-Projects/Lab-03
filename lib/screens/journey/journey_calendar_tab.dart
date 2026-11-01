import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/mood.dart';
import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../utils/journey_stats.dart';
import '../../utils/vi_date_format.dart';
import '../../viewmodels/journey_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/mood_cells.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/pill_tabs.dart';
import '../../widgets/state_views.dart';

/// S11c · Lịch năng lượng (Tháng / Năm).
class JourneyCalendarTab extends StatelessWidget {
  const JourneyCalendarTab({
    required this.state,
    required this.viewModel,
    super.key,
  });

  final JourneyState state;
  final JourneyViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      // Lề 12 thay vì 16: 7 ô 48 dp vừa khít 360 dp mà không thu nhỏ vùng
      // chạm (deviation D-18).
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s12,
        AppSpace.s14,
        AppSpace.s12,
        AppSpace.tabContentBottom,
      ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.s2),
          child: Semantics(
            header: true,
            child: Text(
              'Lịch năng lượng',
              style: AppTextStyles.of(context).title17Bold
                  .copyWith(letterSpacing: -0.17),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        // Figma `Segmented`: khay surface-container bo 12, mục chọn nền trắng.
        PillTabs<bool>(
          items: const <(bool, String)>[(false, 'Tháng'), (true, 'Năm')],
          selected: state.yearMode,
          onSelected: viewModel.setYearMode,
          radius: AppRadius.r12,
          padding: 3,
          selectedColor: theme.colorScheme.surface,
        ),
        const SizedBox(height: AppSpace.s12),
        switch (state.data) {
          // T3: skeleton + mascot Đợi; quá 10 giây ViewModel chuyển sang lỗi.
          Loading<JourneyData>() ||
          Empty<JourneyData>() => const LoadingState.skeleton(
            message: 'Đang tải lịch năng lượng…',
            skeletonCount: 8,
          ),
          Failure<JourneyData>(:final message, :final offline) => ErrorState(
            title: 'Chưa tải được lịch',
            cause: message,
            kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
            onRetry: viewModel.retry,
          ),
          Data<JourneyData>(:final value) =>
            state.yearMode
                ? _YearView(data: value)
                : _MonthView(
                    data: value,
                    month:
                        state.month ??
                        DateTime(value.now.year, value.now.month),
                    onShift: viewModel.shiftMonth,
                  ),
        },
        const SizedBox(height: AppSpace.s12),
        const _Legend(),
      ],
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.data,
    required this.month,
    required this.onShift,
  });

  final JourneyData data;
  final DateTime month;
  final ValueChanged<int> onShift;

  void _openDay(BuildContext context, DateTime day) {
    final notes = data.notesOn(day);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            0,
            AppSpace.screen,
            AppSpace.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                ViDateFormat.dayHeader(day),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.s12),
              if (notes.isEmpty)
                Text(
                  'Ngày này chưa có nốt nào.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                )
              else
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s8),
                    child: SizedBox(
                      height: AppSize.noteCardHeight + AppSpace.s24,
                      child: NoteTile(
                        type: note.type,
                        title: note.title,
                        dateLabel: <String>[
                          ViDateFormat.time(note.createdAt),
                          ?note.mood?.label,
                        ].join(' · '),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          context.push(AppRoutes.noteDetail(note.id));
                        },
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = JourneyStats.monthGrid(month);
    final isCurrent =
        month.year == data.now.year && month.month == data.now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () => onShift(-1),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Tháng trước',
            ),
            Expanded(
              child: Text(
                'Tháng ${month.month}, ${month.year}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: isCurrent ? null : () => onShift(1),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Tháng sau',
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s8),
        // Ô 48 × 56 sát nhau; phần dư chia đều làm khoảng cách (handout S11).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (final label in ViDateFormat.weekdayShort)
              SizedBox(
                width: AppSize.moodDayCell.width,
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s12),
        for (var week = 0; week < days.length ~/ 7; week++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (final day in days.skip(week * 7).take(7))
                MoodDayCell(
                  day: day.day,
                  semanticDate: ViDateFormat.spoken(day),
                  mood: data.dayMoods[day],
                  inMonth: day.month == month.month,
                  today: DateUtils.isSameDay(day, data.now),
                  onTap: day.month == month.month && !day.isAfter(data.now)
                      ? () => _openDay(context, day)
                      : null,
                ),
            ],
          ),
      ],
    );
  }
}

/// Chế độ Năm: 12 cột (tháng) × 31 hàng (ngày) pixel tâm trạng.
class _YearView extends StatelessWidget {
  const _YearView({required this.data});

  final JourneyData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = data.now.year;
    final moods = data.dayMoods.entries.where((e) => e.key.year == year);
    final counts = <Mood, int>{};
    for (final entry in moods) {
      counts[entry.value] = (counts[entry.value] ?? 0) + 1;
    }
    final top = counts.entries.isEmpty
        ? null
        : counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    final summary = top == null
        ? 'Năm $year bạn chưa ghi tâm trạng ngày nào.'
        : 'Năm $year bạn ghi tâm trạng ${moods.length} ngày, '
              'nhiều nhất là ${top.label}.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: summary,
          excludeSemantics: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (var month = 1; month <= 12; month++)
                Column(
                  children: <Widget>[
                    Text('$month', style: theme.textTheme.labelSmall),
                    const SizedBox(height: AppSpace.s4),
                    for (var day = 1; day <= 31; day++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s2),
                        child: MoodPixel(
                          hasDay: DateTime(year, month, day).month == month,
                          mood: data.dayMoods[DateTime(year, month, day)],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        Text(summary, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Figma `legend`: "Vui ■■■■■ Rối · Ý nghĩa màu"; trình đọc màn hình nghe
/// đủ năm mức.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final caption = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Semantics(
      label:
          'Ý nghĩa màu: '
          '${Mood.values.map((m) => m.label).join(', ')}, từ vui tới rối',
      excludeSemantics: true,
      // Wrap: chữ lớn hoặc màn hẹp thì xuống dòng thay vì tràn.
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpace.s6,
        runSpacing: AppSpace.s6,
        children: <Widget>[
          Text('Vui', style: caption),
          for (final mood in Mood.values)
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: colors.mood(mood),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          Text('Rối', style: caption),
          Text(
            '· Ý nghĩa màu',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
