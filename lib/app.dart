import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'router/app_router.dart';
import 'services/nudge_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';
import 'viewmodels/awake_nudge_sync.dart';

/// Widget gốc của Nốt.
class NotApp extends ConsumerStatefulWidget {
  const NotApp({this.font = plainFont, super.key});

  /// Font gắn vào theme; `main.dart` truyền Be Vietnam Pro.
  final FontBuilder font;

  @override
  ConsumerState<NotApp> createState() => _NotAppState();
}

class _NotAppState extends ConsumerState<NotApp> {
  StreamSubscription<String>? _opened;

  @override
  void initState() {
    super.initState();
    // Chạm vào lời nhắc "Giờ tỉnh": mở S09 chồng lên màn đang xem. Thông báo
    // mở app thì `go`: router giữ đích qua splash / đăng nhập (flow P7).
    final nudges = ref.read(nudgeServiceProvider);
    _opened = nudges.openedRoutes.listen((route) {
      if (mounted) unawaited(ref.read(appRouterProvider).push(route));
    });
    unawaited(
      nudges.launchRoute().then((route) {
        if (route != null && mounted) ref.read(appRouterProvider).go(route);
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_opened?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(awakeNudgeSyncProvider);
    return MaterialApp.router(
      title: 'Nốt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(font: widget.font),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('vi'),
      supportedLocales: const <Locale>[Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
