import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../screens/breathing/breathing_screen.dart';
import '../screens/challenge_detail/challenge_detail_screen.dart';
import '../screens/challenge_detail/greeting_screen.dart';
import '../screens/challenges/challenges_screen.dart';
import '../screens/common/screen_skeleton.dart';
import '../screens/dev/component_gallery_screen.dart';
import '../screens/discord/discord_rooms_screen.dart';
import '../screens/groups/group_detail_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/jar/jar_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../screens/journey/journey_screen.dart';
import '../screens/note_composer/note_composer_screen.dart';
import '../screens/note_detail/note_detail_screen.dart';
import '../screens/note_saved/note_saved_screen.dart';
import '../screens/self_control/self_control_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/today/today_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../services/analytics_service.dart';
import '../services/crash_reporter.dart';
import '../services/messaging_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/state_views.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'auth_redirect.dart';

/// Router của app. Màn lồng gắn vào navigator gốc nên che thanh tab.
///
/// Chuyển hướng theo đăng nhập ở [authRedirect]; router chạy lại `redirect`
/// mỗi khi [authUserProvider] đổi, không dựng lại GoRouter.
final appRouterProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final authChanged = ValueNotifier<int>(0);
  ref
    ..listen(authUserProvider, (_, next) {
      authChanged.value++;
      // user ID (uid, không email/tên) cho Analytics và Crashlytics; kể cả khi
      // phiên đăng nhập được khôi phục lúc mở app.
      final uid = next.value?.uid;
      unawaited(ref.read(analyticsServiceProvider).setUserId(uid));
      unawaited(ref.read(crashReporterProvider).setUser(uid));
    })
    ..onDispose(authChanged.dispose);
  var lastScreen = '';

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.today,
    refreshListenable: authChanged,
    redirect: (context, state) =>
        authRedirect(ref.read(authUserProvider), state.uri),
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.today),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) =>
            WelcomeScreen(next: state.uri.queryParameters['next']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.today,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.jar,
                builder: (context, state) => const JarScreen(),
                routes: <RouteBase>[
                  // Trước `:noteId` để `/jar/groups` không bị hiểu là một nốt.
                  GoRoute(
                    path: 'groups',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => const GroupsScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: ':groupId',
                        parentNavigatorKey: rootKey,
                        builder: (context, state) => GroupDetailScreen(
                          groupId: state.pathParameters['groupId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':noteId',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => NoteDetailScreen(
                      noteId: state.pathParameters['noteId']!,
                      edit: state.uri.queryParameters['edit'] == '1',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.challenges,
                builder: (context, state) => const ChallengesScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => ChallengeDetailScreen(
                      challengeId: state.pathParameters['id']!,
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'greeting',
                        parentNavigatorKey: rootKey,
                        builder: (context, state) => GreetingScreen(
                          challengeId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.journey,
                builder: (context, state) => JourneyScreen(
                  tab: JourneyTab.fromId(state.uri.queryParameters['tab']),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.noteNew,
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: NoteComposerScreen(
            step: (int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 1)
                .clamp(1, 3),
            groupId: state.uri.queryParameters['group'],
          ),
        ),
      ),
      GoRoute(
        path: '/note/saved/:id',
        builder: (context, state) =>
            NoteSavedScreen(noteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.rooms,
        builder: (context, state) => const DiscordRoomsScreen(),
      ),
      GoRoute(
        path: AppRoutes.journal,
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: AppRoutes.selfControl,
        builder: (context, state) => const SelfControlScreen(),
      ),
      GoRoute(
        path: AppRoutes.breathe,
        builder: (context, state) => const BreathingScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      if (!kReleaseMode)
        GoRoute(
          path: AppRoutes.componentGallery,
          builder: (context, state) => const ComponentGalleryScreen(),
        ),
    ],
    errorBuilder: (context, state) => NestedScaffold(
      title: 'Không tìm thấy',
      body: ErrorState(
        title: 'Không tìm thấy trang này',
        cause: 'Đường dẫn ${state.uri} không có trong Nốt.',
        retryLabel: 'Về Hôm nay',
        onRetry: () => context.go(AppRoutes.today),
      ),
    ),
  );

  // screen_view theo mẫu route mỗi khi màn đổi.
  void logScreen() {
    // fullPath giữ mẫu route (`/note/saved/:id`), không lộ id cụ thể.
    final path = router.routerDelegate.currentConfiguration.fullPath;
    if (path.isEmpty || path == lastScreen) return;
    lastScreen = path;
    unawaited(ref.read(analyticsServiceProvider).logScreen(path));
    // Khoá chẩn đoán: màn đang mở khi có lỗi.
    unawaited(ref.read(crashReporterProvider).setKey('screen', path));
  }

  router.routerDelegate.addListener(logScreen);

  // Chạm thông báo FCM: mở đúng màn (chỉ khi đã đăng nhập, nếu không thì để
  // authRedirect đưa về Welcome).
  final messaging = ref.read(messagingServiceProvider);
  final routeSub = messaging.openedRoutes.listen(router.go);
  final pending = messaging.takePendingRoute();
  if (pending != null) router.go(pending);

  ref.onDispose(() {
    unawaited(routeSub.cancel());
    router.routerDelegate.removeListener(logScreen);
    router.dispose();
  });
  return router;
});
