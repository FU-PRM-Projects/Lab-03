import 'package:material_ui/material_ui.dart';

import '../models/note_type.dart';
import '../theme/app_colors.dart';

/// Icon Material đi kèm nhãn chữ của mỗi loại nốt.
extension NoteTypeIcon on NoteType {
  IconData get icon => switch (this) {
    NoteType.chienThang => Icons.emoji_events_outlined,
    NoteType.tuChu => Icons.pan_tool_outlined,
    NoteType.thuThach => Icons.flag_outlined,
    NoteType.nhatKy => Icons.menu_book_outlined,
  };
}

/// Icon 14 dp và màu nhãn loại trên `Note/Tờ nốt` (Final UI).
extension NoteTypeTag on NoteType {
  String get tagIconAsset => switch (this) {
    NoteType.chienThang => 'assets/icons/check.svg',
    NoteType.tuChu => 'assets/icons/clock.svg',
    NoteType.thuThach => 'assets/icons/phase.svg',
    NoteType.nhatKy => 'assets/icons/pencil.svg',
  };

  Color tagColor(ColorScheme scheme, AppColors colors) => switch (this) {
    NoteType.chienThang => colors.warning,
    NoteType.tuChu => scheme.primary,
    NoteType.thuThach => colors.success,
    NoteType.nhatKy => scheme.onPrimaryContainer,
  };
}
