import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';

/// Composition root. Stage 3 khởi tạo Firebase ở đây và gắn hiện thực của
/// từng service vào `ProviderScope(overrides: …)`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: NotApp(
        font: (style) => GoogleFonts.beVietnamPro(textStyle: style),
      ),
    ),
  );
}
