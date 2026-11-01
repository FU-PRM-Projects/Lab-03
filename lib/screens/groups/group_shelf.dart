import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/first_group.dart';
import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/groups_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/group_card.dart';
import 'create_group_sheet.dart';

/// Mở sheet tạo nhóm rồi tới S05e của nhóm vừa tạo (hoặc nhóm trùng tên).
Future<void> createGroupAndOpen(BuildContext context) async {
  final group = await showCreateGroupSheet(context);
  if (group != null && context.mounted) {
    await context.push(AppRoutes.groupDetail(group.id));
  }
}

/// Figma `kệ · Nhóm lần đầu` trên S05: tiêu đề + "Xem tất cả", rồi một hàng
/// thẻ cuộn ngang (nhóm có nốt, tối đa 2 gợi ý, "Tạo nhóm mới").
class GroupShelf extends ConsumerWidget {
  const GroupShelf({super.key});

  /// Số thẻ gợi ý hiện trên kệ; "Xem tất cả" có đủ 8 nhóm hệ thống.
  static const int _suggestionsOnShelf = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupsViewModelProvider);
    final theme = Theme.of(context);
    // Kệ chỉ là phần thêm của S05: chưa tải được thì vẫn có thẻ gợi ý.
    final shelf = switch (state) {
      Data<GroupShelfData>(:final value) => value,
      _ => const GroupShelfData(
        groups: <FirstGroup>[],
        suggestions: FirstGroups.system,
      ),
    };
    final cards = <FirstGroup>[
      ...shelf.groups,
      ...shelf.suggestions.take(_suggestionsOnShelf),
    ];
    // Thẻ cao theo cỡ chữ (lề, icon, thanh mốc cố định; tên 1 dòng, dòng phụ
    // tối đa 2 dòng): chữ phóng to thì kệ cao theo.
    final height = 98 + MediaQuery.textScalerOf(context).scale(58);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Nhóm lần đầu',
                  style: AppTextStyles.of(context).title17Bold.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.17,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.groups),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
                minimumSize: const Size(AppSize.minTouch, AppSize.minTouch),
                textStyle: theme.textTheme.labelLarge,
              ),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => i < cards.length
                ? GroupCard(
                    group: cards[i],
                    onTap: () =>
                        context.push(AppRoutes.groupDetail(cards[i].id)),
                  )
                : GroupCard.create(onTap: () => createGroupAndOpen(context)),
          ),
        ),
      ],
    );
  }
}
