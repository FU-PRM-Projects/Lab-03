/// `--dart-define=USE_FIREBASE_EMULATOR=true` chạy với Emulator của
/// `firebase/` (cổng khớp `firebase.json`) và hiện đăng nhập email để test.
const bool useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

/// Site key reCAPTCHA v3 của App Check
/// (`--dart-define=RECAPTCHA_SITE_KEY=...`). Site key là khoá công khai (nằm
/// trong trang), không phải bí mật. Trống thì web admin chạy không App Check.
const String recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

/// Debug token App Check khi chạy trên máy
/// (`--dart-define=APP_CHECK_DEBUG_TOKEN=...`), đã đăng ký ở Firebase Console →
/// App Check → Apps → web app → Manage debug tokens. Có token thì dùng thay
/// reCAPTCHA (localhost không qua được reCAPTCHA khi Console bật Enforce).
const String appCheckDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
);
