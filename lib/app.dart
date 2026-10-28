import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

/// Widget gốc của Nốt.
class NotApp extends ConsumerWidget {
  const NotApp({this.font = plainFont, super.key});

  /// Font gắn vào theme; `main.dart` truyền Be Vietnam Pro.
  final FontBuilder font;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Nốt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(font: font),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('vi'),
      supportedLocales: const <Locale>[Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
