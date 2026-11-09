import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';

/// Provider App Check cho web admin: debug token (chạy trên máy) được ưu tiên,
/// sau đó reCAPTCHA Enterprise (Console gọi là Fraud Defense; reCAPTCHA v3
/// "Classic" đã bị Firebase ngừng nhận). Không có cả hai thì `null`.
WebProvider? webAppCheckProvider({
  required String siteKey,
  required String debugToken,
}) {
  if (debugToken.isNotEmpty) return WebDebugProvider(debugToken: debugToken);
  if (siteKey.isNotEmpty) return ReCaptchaEnterpriseProvider(siteKey);
  return null;
}

/// Bật App Check cho Firestore, gọi ngay sau `Firebase.initializeApp`. Bỏ qua
/// khi chạy Emulator. Lỗi khi bật không chặn web admin: Console chưa bật
/// Enforce thì request không token vẫn qua, bật rồi thì Firestore trả
/// permission-denied và màn hình hiện trạng thái lỗi như mọi lỗi khác.
Future<void> activateAppCheck() async {
  if (useFirebaseEmulator) return;
  final provider = webAppCheckProvider(
    siteKey: recaptchaSiteKey,
    debugToken: appCheckDebugToken,
  );
  if (provider == null) {
    debugPrint('[app-check] chưa có RECAPTCHA_SITE_KEY, bỏ qua App Check');
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(providerWeb: provider);
  } on Object catch (error) {
    debugPrint('[app-check] chưa bật được: $error');
  }
}
