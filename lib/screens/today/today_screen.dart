import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../utils/vi_date_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/shortcut_button.dart';
import '../common/screen_skeleton.dart';

/// S02 · Hôm nay (tab 1).
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      // Stage 4: ngày lấy từ TodayViewModel (Clock) thay vì DateTime.now().
      title: ViDateFormat.dayHeader(DateTime.now()),
      showAddNote: false,
      body: ScreenSkeleton(
        code: 'S02',
        name: 'Hôm nay',
        children: <Widget>[
          AppButton(
            label: 'Ghi nốt',
            icon: Icons.add,
            expand: true,
            onPressed: () => context.push(AppRoutes.newNote()),
          ),
          const SizedBox(height: AppSpace.s16),
          // Ba lối tắt chia đều chiều ngang; nhãn xuống dòng khi chật.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ShortcutButton(
                  icon: Icons.pan_tool_outlined,
                  label: 'Dừng lại',
                  onTap: () => context.push(AppRoutes.selfControl),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: ShortcutButton(
                  icon: Icons.air,
                  label: 'Thở 90 giây',
                  onTap: () => context.push(AppRoutes.breathe),
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: ShortcutButton(
                  icon: Icons.flag_outlined,
                  label: 'Thử thách',
                  onTap: () => context.go(AppRoutes.challenges),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
