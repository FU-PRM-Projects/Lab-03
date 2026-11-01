import 'package:material_ui/material_ui.dart';

import '../../models/mood.dart';
import '../../models/note_type.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/mascot.dart';
import '../../widgets/milestone_sticker.dart';
import '../../widgets/mood_cells.dart';
import '../../widgets/mood_option.dart';
import '../../widgets/note_card.dart';
import '../../widgets/note_tile.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/quick_win_chip.dart';
import '../../widgets/setting_row.dart';
import '../../widgets/shortcut_button.dart';
import '../../widgets/state_views.dart';
import '../common/screen_skeleton.dart';

/// Thư viện component để đối chiếu với Figma page `05 Components`.
///
/// Chỉ đăng ký route ở bản không phải release; chữ mẫu lấy từ `screen-spec.md` mục 2 và
/// không phải dữ liệu của app.
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  // State cục bộ của một màn demo, không chia sẻ với màn khác.
  Mood _mood = Mood.on;
  String _chip = 'Đi bộ';
  bool _switch = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.s12),
          ...children,
        ],
      ),
    );

    return NestedScaffold(
      title: 'Component',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: <Widget>[
          section('Button', <Widget>[
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: <Widget>[
                AppButton(label: 'Ghi nốt', onPressed: () {}),
                AppButton(
                  label: 'Thở 90 giây',
                  onPressed: () {},
                  variant: AppButtonVariant.tonal,
                ),
                AppButton(
                  label: 'Đăng xuất',
                  onPressed: () {},
                  variant: AppButtonVariant.outlined,
                ),
                AppButton(
                  label: 'Bỏ qua',
                  onPressed: () {},
                  variant: AppButtonVariant.text,
                ),
                AppButton(
                  label: 'Xoá',
                  onPressed: () {},
                  variant: AppButtonVariant.destructive,
                ),
                const AppButton(label: 'Tiếp', onPressed: null),
                AppButton(label: 'Lưu vào hũ', onPressed: () {}, loading: true),
              ],
            ),
          ]),
          section('Text field', <Widget>[
            const AppTextField(label: 'Chiến thắng nhỏ', maxLength: 120),
            const SizedBox(height: AppSpace.s12),
            const AppTextField(
              label: 'Email',
              errorText: 'Email chưa đúng dạng, ví dụ ten@gmail.com.',
            ),
            const SizedBox(height: AppSpace.s12),
            const AppTextField(label: 'Không dùng được', enabled: false),
          ]),
          section('MoodOption', <Widget>[
            Wrap(
              spacing: AppSpace.s12,
              runSpacing: AppSpace.s12,
              children: <Widget>[
                for (final mood in Mood.values)
                  MoodOption(
                    mood: mood,
                    selected: mood == _mood,
                    onTap: () => setState(() => _mood = mood),
                  ),
              ],
            ),
          ]),
          section('Chip/Chiến thắng nhanh', <Widget>[
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: <Widget>[
                for (final label in const <String>[
                  'Dọn phòng',
                  'Đi bộ',
                  'Ngủ trước 12h',
                ])
                  QuickWinChip(
                    label: label,
                    selected: label == _chip,
                    onSelected: (_) => setState(() => _chip = label),
                  ),
              ],
            ),
          ]),
          section('Note/Tờ nốt', <Widget>[
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpace.grid,
              crossAxisSpacing: AppSpace.grid,
              childAspectRatio: 158 / 137,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                NoteTile(
                  type: NoteType.chienThang,
                  title: 'Dọn bàn học, gửi email hỏi thầy',
                  dateLabel: 'Hôm nay · Ổn',
                  onTap: () {},
                ),
                NoteTile(
                  type: NoteType.tuChu,
                  title: 'Dừng lướt TikTok lúc 0h15',
                  dateLabel: 'Hôm qua',
                  onTap: () {},
                ),
                NoteTile(
                  type: NoteType.thuThach,
                  title: 'Hỏi thầy Nam về đề tài',
                  dateLabel: 'T5',
                  onTap: () {},
                ),
                NoteTile(
                  type: NoteType.nhatKy,
                  title: 'Vì sao tuần này mình mệt',
                  dateLabel: 'T4',
                  onTap: () {},
                ),
              ],
            ),
          ]),
          section('Card/Nốt', <Widget>[
            NoteCard(
              type: NoteType.chienThang,
              title: 'Đi bộ 20 phút sau giờ học',
              meta: 'Chiến thắng · 22/10',
              onTap: () {},
            ),
          ]),
          section('Cell/Ngày năng lượng · Pixel năm', <Widget>[
            Wrap(
              spacing: AppSpace.s4,
              runSpacing: AppSpace.s4,
              children: <Widget>[
                for (final (index, mood) in Mood.values.indexed)
                  MoodDayCell(
                    day: 20 + index,
                    semanticDate: '${20 + index} tháng 10',
                    mood: mood,
                  ),
                const MoodDayCell(day: 25, semanticDate: '25 tháng 10'),
                const MoodDayCell(
                  day: 1,
                  semanticDate: '1 tháng 11',
                  inMonth: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s8),
            Wrap(
              spacing: AppSpace.s2,
              children: <Widget>[
                for (final mood in Mood.values) MoodPixel(mood: mood),
                const MoodPixel(),
              ],
            ),
          ]),
          section('Sticker/Mốc · Lối tắt · Mascot', <Widget>[
            Wrap(
              spacing: AppSpace.s12,
              runSpacing: AppSpace.s12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const MilestoneSticker(label: 'Th9', unlocked: true),
                const MilestoneSticker(label: 'Th10', unlocked: false),
                ShortcutButton(
                  iconAsset: 'assets/icons/clock.svg',
                  label: 'Dừng lại',
                  onTap: () {},
                ),
                for (final state in MascotState.values)
                  Mascot(state: state, size: 48, semanticLabel: state.label),
              ],
            ),
          ]),
          section('SettingRow · Switch', <Widget>[
            SettingRow.value(
              title: 'Nhắc ghi nốt buổi tối',
              value: '21:30',
              onTap: () {},
            ),
            SettingRow.toggle(
              title: 'Khoá phần Tự chủ',
              subtitle: 'Mở bằng vân tay hoặc mã PIN',
              value: _switch,
              onChanged: (value) => setState(() => _switch = value),
            ),
          ]),
          section('Banner · Dialog', <Widget>[
            const OfflineBanner(),
            const SizedBox(height: AppSpace.s12),
            AppButton(
              label: 'Mở dialog xoá',
              variant: AppButtonVariant.outlined,
              onPressed: () => showAppDialog(
                context: context,
                title: 'Xoá nốt này?',
                message: 'Bạn có 5 giây để hoàn tác.',
                confirmLabel: 'Xoá',
                kind: AppDialogKind.destructive,
              ),
            ),
          ]),
          section('Loading · Empty · Error', <Widget>[
            const LoadingState.skeleton(
              message: 'Đang tải lịch năng lượng…',
              skeletonCount: 2,
            ),
            const SizedBox(height: AppSpace.s16),
            EmptyState(
              title: 'Hũ còn trống',
              message: 'Ghi chiến thắng đầu tiên nhé.',
              actionLabel: 'Ghi nốt đầu tiên',
              onAction: () {},
            ),
            const SizedBox(height: AppSpace.s16),
            ErrorState(
              title: 'Chưa tải được hũ',
              cause: 'Kiểm tra Wi-Fi rồi thử lại.',
              kind: ErrorKind.offline,
              onRetry: () {},
            ),
          ]),
        ],
      ),
    );
  }
}
