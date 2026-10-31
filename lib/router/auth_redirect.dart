import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'app_routes.dart';

/// Quy tắc chuyển hướng theo đăng nhập (Lab 3 mục 6, handout mục 3).
///
/// - Chưa biết trạng thái đăng nhập → `/splash?next=<đích>`.
/// - Chưa đăng nhập → `/welcome?next=<đích>`.
/// - Đã đăng nhập mà ở `/welcome` hoặc `/splash` → `next` hoặc `/today`.
String? authRedirect(AsyncValue<AppUser?> auth, Uri uri) {
  final path = uri.path;
  final onSplash = path == AppRoutes.splash;
  final onWelcome = path == AppRoutes.welcome;

  // Giữ đích ban đầu (ví dụ mở từ thông báo, flow P7) qua các bước chuyển.
  final next = onSplash || onWelcome
      ? safeNext(uri.queryParameters['next'])
      : safeNext(uri.toString());

  if (!auth.hasValue && !auth.hasError) {
    return onSplash ? null : _withNext(AppRoutes.splash, next);
  }

  final signedIn = auth.hasValue && auth.value != null;
  if (!signedIn) {
    return onWelcome ? null : _withNext(AppRoutes.welcome, next);
  }
  if (onSplash || onWelcome) return next ?? AppRoutes.today;
  return null;
}

/// Chỉ nhận đường dẫn nội bộ của app, bỏ các trang đăng nhập.
String? safeNext(String? next) {
  if (next == null || !next.startsWith('/') || next.startsWith('//')) {
    return null;
  }
  final path = Uri.parse(next).path;
  if (path == AppRoutes.welcome || path == AppRoutes.splash || path == '/') {
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
