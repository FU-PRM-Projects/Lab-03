import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_core/not_core.dart';

/// Người đang đăng nhập web admin.
class AdminUser {
  const AdminUser({required this.uid, this.displayName = '', this.email = ''});

  final String uid;
  final String displayName;
  final String email;
}

/// Đăng nhập Google cho web admin. Lỗi là [AppException].
abstract interface class AdminAuth {
  Stream<AdminUser?> authStateChanges();

  AdminUser? get currentUser;

  Future<void> signInWithGoogle();

  /// Chỉ dùng với Emulator (test cục bộ, ARTEMIS); bản thật chỉ có Google.
  Future<void> signInWithEmail(String email, String password);

  Future<void> signOut();
}

/// Sự kiện Analytics của web admin (không có dữ liệu cá nhân trong tham số).
abstract interface class AdminAnalytics {
  Future<void> setUser(String? uid);

  Future<void> log(String name, [Map<String, Object> params = const {}]);
}

/// Cờ Remote Config web admin đọc.
abstract interface class AdminRemoteConfig {
  /// Cùng cờ với app: app có đang cho người dùng gửi thẻ lên kho chung không.
  bool get submissionsEnabled;
}

Never _unbound(String name) =>
    throw UnimplementedError('$name chưa được gắn trong main.dart');

final adminAuthProvider = Provider<AdminAuth>((ref) => _unbound('adminAuth'));
final adminAnalyticsProvider = Provider<AdminAnalytics>(
  (ref) => _unbound('adminAnalytics'),
);
final adminRemoteConfigProvider = Provider<AdminRemoteConfig>(
  (ref) => _unbound('adminRemoteConfig'),
);
final userDirectoryProvider = Provider<UserDirectory>(
  (ref) => _unbound('userDirectory'),
);
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => _unbound('catalogRepository'),
);
final submissionRepositoryProvider = Provider<SubmissionRepository>(
  (ref) => _unbound('submissionRepository'),
);
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => _unbound('announcementRepository'),
);
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => _unbound('dashboardRepository'),
);
