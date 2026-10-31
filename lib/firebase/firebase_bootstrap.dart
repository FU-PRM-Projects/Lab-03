import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Bật bằng `--dart-define=USE_FIREBASE_EMULATOR=true` để chạy với Emulator
/// của `firebase/` thay vì project thật.
const bool useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

/// Máy chạy Emulator. `10.0.2.2` là máy tính khi app chạy trên Android
/// emulator; điện thoại thật dùng IP LAN của máy tính.
const String firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

/// Khởi tạo Firebase trước `runApp`.
Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useFirebaseEmulator) {
    // Cổng khớp với `firebase.json`.
    await FirebaseAuth.instance.useAuthEmulator(firebaseEmulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(firebaseEmulatorHost, 8080);
  }
}
