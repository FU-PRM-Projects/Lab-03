import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:not_core/not_core.dart';

import '../services/admin_services.dart';

/// [AdminAuth] bằng Firebase Auth: Google Sign-In qua popup.
class FirebaseAdminAuth implements AdminAuth {
  FirebaseAdminAuth({FirebaseAuth? auth, this.preferRedirect = false})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Dùng chuyển trang thay cho popup (Emulator, trình duyệt nhúng). Popup bị
  /// chặn cũng tự chuyển sang cách này.
  final bool preferRedirect;

  static AdminUser? _map(User? user) => user == null
      ? null
      : AdminUser(
          uid: user.uid,
          displayName: user.displayName ?? '',
          email: user.email ?? '',
        );

  @override
  Stream<AdminUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AdminUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<void> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});
      if (preferRedirect) {
        await _auth.signInWithRedirect(provider);
        return;
      }
      try {
        await _auth.signInWithPopup(provider);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'popup-blocked' &&
            e.code != 'operation-not-supported-in-this-environment') {
          rethrow;
        }
        await _auth.signInWithRedirect(provider);
      }
    } on FirebaseAuthException catch (e) {
      throw AppException(switch (e.code) {
        'popup-closed-by-user' ||
        'cancelled-popup-request' ||
        'user-cancelled' => AppErrorKind.cancelled,
        'network-request-failed' => AppErrorKind.network,
        _ => AppErrorKind.unknown,
      }, code: e.code);
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AppException(
        e.code == 'network-request-failed'
            ? AppErrorKind.network
            : AppErrorKind.invalidInput,
        code: e.code,
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// [AdminAnalytics] bằng Firebase Analytics.
class FirebaseAdminAnalytics implements AdminAnalytics {
  FirebaseAdminAnalytics({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setUser(String? uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } on Object {
      // Analytics không được làm hỏng thao tác của staff.
    }
  }

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: <String, Object>{'client': 'web_admin', ...params},
      );
    } on Object {
      // Như trên.
    }
  }
}

/// [AdminRemoteConfig] bằng Firebase Remote Config; lỗi tải thì dùng mặc
/// định (khớp `firebase/remote-config-defaults.json`).
class FirebaseAdminRemoteConfig implements AdminRemoteConfig {
  FirebaseAdminRemoteConfig._(this._config);

  final FirebaseRemoteConfig? _config;

  static Future<FirebaseAdminRemoteConfig> load() async {
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.setDefaults(const <String, Object>{
        'challenge_submissions_enabled': true,
      });
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );
      await config.fetchAndActivate().timeout(const Duration(seconds: 8));
      return FirebaseAdminRemoteConfig._(config);
    } on Object {
      return FirebaseAdminRemoteConfig._(null);
    }
  }

  @override
  bool get submissionsEnabled =>
      _config?.getBool('challenge_submissions_enabled') ?? true;
}
