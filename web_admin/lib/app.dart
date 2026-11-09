import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import 'router.dart';

/// Widget gốc của web admin; cùng theme Lab 2 với app (`package:not_core`).
class AdminApp extends ConsumerWidget {
  const AdminApp({this.font = plainFont, super.key});

  final FontBuilder font;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Nốt · Web admin',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(font: font),
    themeMode: ThemeMode.light,
    routerConfig: ref.watch(adminRouterProvider),
    locale: const Locale('vi'),
    supportedLocales: const <Locale>[Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
  );
}
