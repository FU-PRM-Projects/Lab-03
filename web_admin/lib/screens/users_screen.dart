import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import '../viewmodels/admin_view_models.dart';
import '../viewmodels/messages.dart';
import '../viewmodels/session_view_model.dart';
import '../widgets/admin_widgets.dart';

/// Người dùng (chỉ admin): xem danh sách và đổi vai trò. Không đổi được vai
/// trò của chính mình (firestore.rules).
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final session = ref.watch(sessionProvider).value;
    final me = session is StaffSession ? session.user.uid : null;

    return AdminPage(
      title: 'Người dùng',
      subtitle:
          'Chỉ admin đổi vai trò. Staff vào được web admin; người dùng '
          'chỉ dùng app.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 320,
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm theo tên, email hoặc uid',
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Expanded(
            child: switch (users) {
              AsyncData(:final value) => () {
                final shown = value
                    .where(
                      (u) =>
                          _query.isEmpty ||
                          u.displayName.toLowerCase().contains(_query) ||
                          u.email.toLowerCase().contains(_query) ||
                          u.uid.toLowerCase().contains(_query),
                    )
                    .toList();
                if (shown.isEmpty) {
                  return const MessageView(
                    title: 'Không có người dùng khớp',
                    message: 'Thử từ khoá khác.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: AppSpace.s24),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.s8),
                  itemBuilder: (_, i) =>
                      _UserRow(user: shown[i], isMe: shown[i].uid == me),
                );
              }(),
              AsyncError(:final error) => MessageView.error(
                message: errorMessage(error),
                onAction: () => ref.invalidate(usersProvider),
              ),
              _ => const LoadingView(message: 'Đang tải người dùng…'),
            },
          ),
        ],
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  const _UserRow({required this.user, required this.isMe});

  final UserSummary user;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final name = user.displayName.isEmpty ? '(chưa có tên)' : user.displayName;
    return AdminCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s16,
        vertical: AppSpace.s12,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(isMe ? '$name (bạn)' : name, style: text.titleSmall),
                Text(
                  user.email.isEmpty ? user.uid : '${user.email} · ${user.uid}',
                  style: text.bodySmall?.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s12),
          DropdownButton<UserRole>(
            value: user.role,
            onChanged: isMe
                ? null
                : (role) async {
                    if (role == null || role == user.role) return;
                    final error = await ref
                        .read(userActionsProvider)
                        .setRole(user, role);
                    if (context.mounted) {
                      showMessage(
                        context,
                        error ??
                            'Đã đổi vai trò của $name thành ${role.label}.',
                        error: error != null,
                      );
                    }
                  },
            items: <DropdownMenuItem<UserRole>>[
              for (final role in UserRole.values)
                DropdownMenuItem(value: role, child: Text(role.label)),
            ],
          ),
        ],
      ),
    );
  }
}
