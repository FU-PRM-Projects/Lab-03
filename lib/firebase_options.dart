// TẠM THỜI: cấu hình cho project giả `demo-prm393`, chỉ dùng được với
// Firebase Emulator (chạy app với --dart-define=USE_FIREBASE_EMULATOR=true).
//
// Khi đã có project Firebase thật, chạy `flutterfire configure` ở thư mục gốc:
// lệnh đó ghi đè file này bằng cấu hình thật và tạo
// android/app/google-services.json. Không cần sửa code nào khác.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-prm393',
    storageBucket: 'demo-prm393.appspot.com',
  );
}
