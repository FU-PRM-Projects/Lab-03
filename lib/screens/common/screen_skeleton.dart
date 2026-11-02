import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_routes.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/add_note_fab.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import 'note_kind_sheet.dart';

/// Một lối đi tới màn khác, dùng khi màn còn ở dạng khung.
class SkeletonLink {
  const SkeletonLink(this.label, this.onTap);

  final String label;
  final void Function(BuildContext context) onTap;
}

/// Nội dung tạm của một màn ở Stage 2: mã màn, tên Lab 2 và các lối đi theo
/// bảng điều hướng. Stage 4 thay bằng nội dung thật của từng màn.
class ScreenSkeleton extends StatelessWidget {
  const ScreenSkeleton({
    required this.code,
    required this.name,
    this.links = const <SkeletonLink>[],
    this.children = const <Widget>[],
    super.key,
  });

  final String code;
  final String name;
  final List<SkeletonLink> links;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.s8,
        AppSpace.screen,
        AppSpace.tabContentBottom,
      ),
      children: <Widget>[
        Text('$code · $name', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpace.s4),
        Text(
          'Màn khung · nội dung dựng ở Stage 4',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        ...children,
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s8),
            child: AppButton(
              label: link.label,
              onPressed: () => link.onTap(context),
              variant: AppButtonVariant.outlined,
              expand: true,
            ),
          ),
      ],
    );
  }
}

/// Khung chung của 4 màn tab: hàng đầu (tiêu đề + chuông + avatar), nội dung,
/// và nút nổi + khi [showAddNote].
class TabScaffold extends StatelessWidget {
  const TabScaffold({
    required this.title,
    required this.body,
    this.showAddNote = true,
    super.key,
  });

  final String title;
  final Widget body;
  final bool showAddNote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabHeader(
              title: title,
              onNotifications: () => context.push(AppRoutes.settings),
              onProfile: () => context.push(AppRoutes.settings),
            ),
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: showAddNote
          ? AddNoteFab(onPressed: () => openNoteKindSheet(context))
          : null,
    );
  }
}

/// Khung chung của màn lồng: App bar có nút Back.
class NestedScaffold extends StatelessWidget {
  const NestedScaffold({
    required this.title,
    required this.body,
    this.actions,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: title, actions: actions),
      body: SafeArea(top: false, child: body),
    );
  }
}
