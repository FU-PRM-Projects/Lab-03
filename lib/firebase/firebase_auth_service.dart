import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../services/app_exception.dart';
import '../services/auth_service.dart';

/// [AuthService] bằng Firebase Authentication + Google Sign-In.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    this.serverClientId,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  /// Web client ID (OAuth) để Google trả idToken. Để `null` thì plugin đọc
  /// `default_web_client_id` từ google-services.json.
  final String? serverClientId;

  Future<void>? _googleInit;

  static AppUser? _toAppUser(User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
        );

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await (_googleInit ??= _google.initialize(
        serverClientId: serverClientId,
      ));
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AppException(
          AppErrorKind.unknown,
          code: 'missing-id-token',
          detail: 'Google không trả idToken; kiểm tra SHA-1 và web client ID.',
        );
      }
      final result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return _toAppUser(result.user)!;
    } on GoogleSignInException catch (e) {
      throw AppException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AppErrorKind.cancelled
            : AppErrorKind.unknown,
        code: e.code.name,
        detail: e.description,
      );
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAppUser(result.user)!;
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<AppUser> registerWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAppUser(result.user)!;
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Đăng xuất Google để lần sau hộp chọn tài khoản hiện lại.
      if (_googleInit != null) await _google.signOut();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  static AppException _map(FirebaseAuthException e) {
    final kind = switch (e.code) {
      'network-request-failed' || 'too-many-requests' => AppErrorKind.network,
      'invalid-credential' ||
      'invalid-email' ||
      'wrong-password' ||
      'user-not-found' ||
      'email-already-in-use' ||
      'weak-password' ||
      'user-disabled' => AppErrorKind.invalidInput,
      _ => AppErrorKind.unknown,
    };
    return AppException(kind, code: e.code, detail: e.message);
  }
}
