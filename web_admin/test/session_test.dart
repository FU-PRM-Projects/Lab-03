import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_admin/services/admin_services.dart';
import 'package:not_admin/viewmodels/admin_view_models.dart';
import 'package:not_admin/viewmodels/session_view_model.dart';
import 'package:not_core/not_core.dart';

class _FakeAuth implements AdminAuth {
  final _changes = StreamController<AdminUser?>.broadcast();
  AdminUser? _user;

  void emit(AdminUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Stream<AdminUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  AdminUser? get currentUser => _user;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signOut() async => emit(null);
}

class _FakeDirectory implements UserDirectory {
  final Map<String, UserRole> roles = <String, UserRole>{};

  @override
  Future<void> ensureProfile(
    String uid, {
    required String displayName,
    String email = '',
  }) async => roles.putIfAbsent(uid, () => UserRole.user);

  @override
  Future<UserRole?> roleOf(String uid) async => roles[uid];

  @override
  Future<void> setRole(String uid, UserRole role) async => roles[uid] = role;

  @override
  Stream<List<UserSummary>> watchAll() => const Stream.empty();
}

class _NoAnalytics implements AdminAnalytics {
  final List<String> events = <String>[];

  @override
  Future<void> log(
    String name, [
    Map<String, Object> params = const {},
  ]) async => events.add(name);

  @override
  Future<void> setUser(String? uid) async {}
}

void main() {
  late _FakeAuth auth;
  late _FakeDirectory directory;
  late _NoAnalytics analytics;
  late ProviderContainer container;

  setUp(() {
    auth = _FakeAuth();
    directory = _FakeDirectory();
    analytics = _NoAnalytics();
    container = ProviderContainer(
      overrides: [
        adminAuthProvider.overrideWithValue(auth),
        userDirectoryProvider.overrideWithValue(directory),
        adminAnalyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<Session> session() async {
    container.listen(sessionProvider, (_, _) {});
    return container.read(sessionProvider.future);
  }

  test('chưa đăng nhập thì ở màn đăng nhập', () async {
    expect(await session(), isA<SignedOut>());
  });

  test('tài khoản người dùng app bị từ chối, có hồ sơ role = user', () async {
    auth.emit(const AdminUser(uid: 'uma', email: 'uma@example.test'));
    final result = await session();
    expect(result, isA<Rejected>());
    expect(directory.roles['uma'], UserRole.user);
    expect(analytics.events, contains('admin_access_denied'));
  });

  test('staff và admin vào được; chỉ admin là isAdmin', () async {
    directory.roles['sam'] = UserRole.staff;
    auth.emit(const AdminUser(uid: 'sam'));
    final staff = await session();
    expect(staff, isA<StaffSession>());
    expect((staff as StaffSession).isAdmin, isFalse);

    directory.roles['root'] = UserRole.admin;
    auth.emit(const AdminUser(uid: 'root'));
    await Future<void>.delayed(Duration.zero);
    final admin = await container.read(sessionProvider.future);
    expect((admin as StaffSession).isAdmin, isTrue);
  });

  test('thẻ mới xếp cuối cấp của đúng chủ đề', () {
    CatalogCard card(ChallengeTopic topic, int level, int order) => CatalogCard(
      challenge: Challenge(
        id: '$topic-$level-$order',
        topic: topic,
        level: level,
        order: order,
        title: 'x',
        minutes: 1,
      ),
    );
    final cards = <CatalogCard>[
      card(ChallengeTopic.vanDong, 1, 5),
      card(ChallengeTopic.vanDong, 2, 9),
      card(ChallengeTopic.dungCam, 1, 7),
    ];
    expect(nextOrder(cards, ChallengeTopic.vanDong, 1), 6);
    expect(nextOrder(cards, ChallengeTopic.vanDong, 3), 1);
  });

  test('bộ lọc kho thẻ: ẩn thẻ lưu trữ, tìm theo tên', () {
    const archived = CatalogCard(
      archived: true,
      challenge: Challenge(
        id: 'a',
        topic: ChallengeTopic.dungCam,
        level: 1,
        order: 1,
        title: 'Hỏi đường',
        minutes: 2,
      ),
    );
    expect(const CatalogFilter().matches(archived), isFalse);
    expect(const CatalogFilter(showArchived: true).matches(archived), isTrue);
    expect(
      const CatalogFilter(showArchived: true, query: 'đường').matches(archived),
      isTrue,
    );
    expect(
      const CatalogFilter(showArchived: true, query: 'bơi').matches(archived),
      isFalse,
    );
  });
}
