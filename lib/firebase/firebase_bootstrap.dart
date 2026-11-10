import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;

import '../firebase_options.dart';

/// Bật bằng `--dart-define=USE_FIREBASE_EMULATOR=true` để chạy với Emulator
/// của `firebase/` thay vì project thật.
const bool useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

/// Máy chạy Emulator. Trên web app chạy ngay trên máy tính nên dùng
/// `localhost`; Android emulator phải đi qua `10.0.2.2`; điện thoại thật dùng
/// IP LAN của máy tính (`--dart-define=FIREBASE_EMULATOR_HOST=<IP>`).
const String firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: kIsWeb ? 'localhost' : '10.0.2.2',
);

/// Khởi tạo Firebase trước `runApp`.
Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!useFirebaseEmulator) await _activateAppCheck();

  if (useFirebaseEmulator) {
    // Cổng khớp với `firebase.json`.
    await FirebaseAuth.instance.useAuthEmulator(firebaseEmulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(firebaseEmulatorHost, 8080);
  }
}

/// Site key reCAPTCHA Enterprise (Fraud Defense) cho App Check trên web
/// (`--dart-define=RECAPTCHA_SITE_KEY=...`); trống thì web chưa có App Check.
const String recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

/// App Check cho Firestore và Firebase AI Logic (Final Assignment). Bản debug
/// dùng debug provider: token in ra logcat, dán vào Firebase Console → App
/// Check → app Android → Manage debug tokens. Bản release dùng Play
/// Integrity. Lỗi khi bật không chặn app (Console chưa bật Enforce thì
/// request không token vẫn qua).
Future<void> _activateAppCheck() async {
  if (kIsWeb && recaptchaSiteKey.isEmpty) return;
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerWeb: kIsWeb
          ? ReCaptchaEnterpriseProvider(recaptchaSiteKey)
          : null,
    );
  } on Object catch (error) {
    debugPrint('[app-check] chưa bật được: $error');
  }
}
