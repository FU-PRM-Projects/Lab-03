import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/admin_shell.dart';
import 'screens/announcements_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/review_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/users_screen.dart';
import 'viewmodels/session_view_model.dart';

abstract final class AdminRoutes {
  static const String signIn = '/sign-in';
  static const String dashboard = '/dashboard';
  static const String catalog = '/catalog';
  static const String review = '/review';
  static const String announcements = '/announcements';
  static const String users = '/users';
}

/// Chưa đăng nhập, đang kiểm tra hoặc sai vai trò thì ở màn đăng nhập; staff
/// không vào được `/users` (chỉ admin).
final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AdminRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider).value;
      final atSignIn = state.matchedLocation == AdminRoutes.signIn;
      if (session is! StaffSession) return atSignIn ? null : AdminRoutes.signIn;
      if (atSignIn) return AdminRoutes.dashboard;
      if (state.matchedLocation == AdminRoutes.users && !session.isAdmin) {
        return AdminRoutes.dashboard;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AdminRoutes.signIn,
        builder: (_, _) => const SignInScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AdminRoutes.dashboard,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AdminRoutes.catalog,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: CatalogScreen()),
          ),
          GoRoute(
            path: AdminRoutes.review,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: ReviewScreen()),
          ),
          GoRoute(
            path: AdminRoutes.announcements,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: AnnouncementsScreen()),
          ),
          GoRoute(
            path: AdminRoutes.users,
            pageBuilder: (_, _) => const NoTransitionPage(child: UsersScreen()),
          ),
        ],
      ),
    ],
  );
});
