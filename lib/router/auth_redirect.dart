import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:not_core/models/user_role.dart';

import '../models/app_user.dart';
import 'app_routes.dart';

/// Quy tắc chuyển hướng theo đăng nhập (Lab 3 mục 6, handout mục 3).
///
/// - Chưa biết trạng thái đăng nhập → `/splash?next=<đích>`.
/// - Chưa đăng nhập → `/welcome?next=<đích>`.
/// - Đã đăng nhập, chưa biết vai trò → `/splash?next=<đích>`.
/// - Đã đăng nhập bằng tài khoản `staff` / `admin` → `/wrong-role` (app chỉ
///   dành cho `user`; đề Final mục 6).
/// - Đã đăng nhập mà ở `/welcome`, `/splash` hoặc `/wrong-role` → `next` hoặc
///   `/today`.
String? authRedirect(
  AsyncValue<AppUser?> auth,
  Uri uri, {
  AsyncValue<UserRole> role = const AsyncData<UserRole>(UserRole.user),
}) {
  final path = uri.path;
  final onSplash = path == AppRoutes.splash;
  final onWelcome = path == AppRoutes.welcome;
  final onWrongRole = path == AppRoutes.wrongRole;

  // Giữ đích ban đầu (ví dụ mở từ thông báo, flow P7) qua các bước chuyển.
  final next = onSplash || onWelcome || onWrongRole
      ? safeNext(uri.queryParameters['next'])
      : safeNext(uri.toString());

  if (!auth.hasValue && !auth.hasError) {
    return onSplash ? null : _withNext(AppRoutes.splash, next);
  }

  final signedIn = auth.hasValue && auth.value != null;
  if (!signedIn) {
    return onWelcome ? null : _withNext(AppRoutes.welcome, next);
  }
  if (role.isLoading || !role.hasValue) {
    // Đang đọc vai trò (kể cả khi vừa đổi tài khoản và còn giá trị cũ): chờ
    // ở splash để không lộ màn của app cho tài khoản staff / admin. Lỗi đọc
    // đã được coi như `user` ở accountRoleProvider.
    return onSplash ? null : _withNext(AppRoutes.splash, next);
  }
  if (role.requireValue.canUseAdmin) {
    return onWrongRole ? null : AppRoutes.wrongRole;
  }
  if (onSplash || onWelcome || onWrongRole) return next ?? AppRoutes.today;
  return null;
}

/// Chỉ nhận đường dẫn nội bộ của app, bỏ các trang đăng nhập.
String? safeNext(String? next) {
  if (next == null || !next.startsWith('/') || next.startsWith('//')) {
    return null;
  }
  final path = Uri.parse(next).path;
  if (path == AppRoutes.welcome ||
      path == AppRoutes.splash ||
      path == AppRoutes.wrongRole ||
      path == '/') {
    return null;
  }
  return next;
}

String _withNext(String route, String? next) => next == null
    ? route
    : Uri(
        path: route,
        queryParameters: <String, String>{'next': next},
      ).toString();
