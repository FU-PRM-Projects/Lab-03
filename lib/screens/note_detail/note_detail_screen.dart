import 'package:material_ui/material_ui.dart';

import '../common/screen_skeleton.dart';

/// S06 · Chi tiết nốt (xem / sửa / xoá).
class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return const NestedScaffold(
      title: 'Chi tiết nốt',
      body: ScreenSkeleton(code: 'S06', name: 'Chi tiết nốt'),
    );
  }
}
