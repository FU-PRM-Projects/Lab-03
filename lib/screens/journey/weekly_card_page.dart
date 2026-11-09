import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/report.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../widgets/mascot.dart';

/// Thẻ tuần dạng story toàn màn (S11b).
class WeeklyCardPage extends ConsumerWidget {
  const WeeklyCardPage({required this.summary, super.key});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final range =
        '${ViDateFormat.shortDate(summary.weekStart)} – '
        '${ViDateFormat.shortDate(summary.weekEnd)}';

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
        ),
        title: const Text('Thẻ tuần'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSize.narrowContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpace.screen),
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          range,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s8),
                      Text(
                        '${summary.noteCount} nốt · '
                        '${summary.daysWithNotes}/7 ngày có ghi'
                        '${summary.energy == null ? '' : ' · năng lượng ${ViDateFormat.decimal(summary.energy!)}/5'}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpace.s16),
                      Row(
                        children: <Widget>[
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: Semantics(
                                label:
                                    '${ViDateFormat.weekdayShort[i]}: '
                                    '${summary.dayMoods[i]?.label ?? 'chưa ghi'}',
                                excludeSemantics: true,
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      height: AppSize.minTouch,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: AppSpace.s2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: summary.dayMoods[i] == null
                                            ? theme.colorScheme.surface
                                            : colors.mood(summary.dayMoods[i]!),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.r8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.s4),
                                    Text(
                                      ViDateFormat.weekdayShort[i],
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.s24),
                      Text(
                        'Chiến thắng nhỏ',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpace.s8),
                      if (summary.wins.isEmpty)
                        Text(
                          'Tuần sau ghi thêm vài chiến thắng nhé.',
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        for (final win in summary.wins)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.s4),
                            child: Text(
                              '✓ $win',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                      const SizedBox(height: AppSpace.s24),
                      const Center(child: Mascot(state: MascotState.xong)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
