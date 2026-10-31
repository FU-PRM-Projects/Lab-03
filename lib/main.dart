import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase/firebase_auth_service.dart';
import 'firebase/firebase_bootstrap.dart';
import 'firebase/firestore_user_repository.dart';
import 'services/auth_service.dart';
import 'services/user_repository.dart';

/// Web client ID (OAuth) cho Google Sign-In; để trống thì plugin đọc từ
/// google-services.json.
const String _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
);

/// Composition root: khởi tạo Firebase và gắn hiện thực Firebase vào từng
/// service. Test gắn bản fake theo cùng cách.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(
          FirebaseAuthService(
            serverClientId: _googleServerClientId.isEmpty
                ? null
                : _googleServerClientId,
          ),
        ),
        userRepositoryProvider.overrideWithValue(FirestoreUserRepository()),
      ],
      child: NotApp(
        font: (style) => GoogleFonts.beVietnamPro(textStyle: style),
      ),
    ),
  );
}
