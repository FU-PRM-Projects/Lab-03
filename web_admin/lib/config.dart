/// `--dart-define=USE_FIREBASE_EMULATOR=true` chạy với Emulator của
/// `firebase/` (cổng khớp `firebase.json`) và hiện đăng nhập email để test.
const bool useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
