import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Cùng project Firebase với app mobile (`prm393-not-lab3`) và cùng web app
/// đã đăng ký bằng `flutterfire configure` (xem `lib/firebase_options.dart`
/// của app mobile). Web admin chỉ chạy trên web.
abstract final class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBBP1qUkoDEQT9sr04ErMfd1naRH7GmSwM',
    appId: '1:1069128102779:web:4f900912701ead247203de',
    messagingSenderId: '1069128102779',
    projectId: 'prm393-not-lab3',
    authDomain: 'prm393-not-lab3.firebaseapp.com',
    storageBucket: 'prm393-not-lab3.firebasestorage.app',
    measurementId: 'G-FT7L9V6M2Q',
  );
}
