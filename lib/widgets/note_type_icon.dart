import 'package:material_ui/material_ui.dart';

import '../models/note_type.dart';

/// Icon Material đi kèm nhãn chữ của mỗi loại nốt.
extension NoteTypeIcon on NoteType {
  IconData get icon => switch (this) {
    NoteType.chienThang => Icons.emoji_events_outlined,
    NoteType.tuChu => Icons.pan_tool_outlined,
    NoteType.thuThach => Icons.flag_outlined,
    NoteType.nhatKy => Icons.menu_book_outlined,
  };
}
