import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../viewmodels/groups_view_model.dart';
import '../../viewmodels/view_state.dart';
import '../../widgets/group_card.dart';
import '../../widgets/state_views.dart';
import '../common/screen_skeleton.dart';
import 'group_shelf.dart';

/// "Xem tất cả" nhóm lần đầu: mọi nhóm đã có nốt, 8 nhóm hệ thống còn là gợi
/// ý và thẻ "Tạo nhóm mới".
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupsViewModelProvider);

    return NestedScaffold(
      title: 'Nhóm lần đầu',
      body: switch (state) {
        Loading<GroupShelfData>() || Empty<GroupShelfData>() =>
          const LoadingState.spinner(message: 'Đang mở các nhóm…'),
        Failure<GroupShelfData>(:final message, :final offline) => Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: ErrorState(
            title: 'Chưa tải được nhóm',
            cause: message,
            kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
            onRetry: () => ref.invalidate(groupsViewModelProvider),
          ),
        ),
        Data<GroupShelfData>(:final value) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.s16,
            AppSpace.screen,
            AppSpace.s24,
          ),
          child: Wrap(
            spacing: AppSpace.s12,
            runSpacing: AppSpace.s12,
            children: <Widget>[
              for (final group in value.all)
                GroupCard(
                  group: group,
                  onTap: () => context.push(AppRoutes.groupDetail(group.id)),
                ),
              GroupCard.create(onTap: () => createGroupAndOpen(context)),
            ],
          ),
        ),
      },
    );
  }
}
