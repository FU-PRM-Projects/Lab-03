import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase/device_services.dart';
import 'firebase/firebase_auth_service.dart';
import 'firebase/firebase_bootstrap.dart';
import 'firebase/firestore_challenge_repository.dart';
import 'firebase/firestore_note_repository.dart';
import 'firebase/firestore_self_control.dart';
import 'firebase/firestore_user_repository.dart';
import 'firebase/prefs_draft_store.dart';
import 'firebase/report_impl.dart';
import 'services/auth_service.dart';
import 'services/challenge_repository.dart';
import 'services/draft_store.dart';
import 'services/note_repository.dart';
import 'services/report_services.dart';
import 'services/self_control_services.dart';
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
  final auth = FirebaseAuthService(
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
  );
  String? uid() => auth.currentUser?.uid;

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(FirestoreUserRepository()),
        noteRepositoryProvider.overrideWithValue(
          FirestoreNoteRepository(currentUid: uid),
        ),
        draftStoreProvider.overrideWithValue(PrefsDraftStore()),
        reportServiceProvider.overrideWithValue(const PdfReportService()),
        storageServiceProvider.overrideWithValue(
          FirebaseStorageService(currentUid: uid),
        ),
        challengeRepositoryProvider.overrideWithValue(
          FirestoreChallengeRepository(currentUid: uid),
        ),
        habitRepositoryProvider.overrideWithValue(
          FirestoreHabitRepository(currentUid: uid),
        ),
        settingsRepositoryProvider.overrideWithValue(
          FirestoreSettingsRepository(currentUid: uid),
        ),
        localAuthServiceProvider.overrideWithValue(DeviceLocalAuthService()),
        screenGuardProvider.overrideWithValue(const MethodChannelScreenGuard()),
      ],
      child: NotApp(
        font: (style) => GoogleFonts.beVietnamPro(textStyle: style),
      ),
    ),
  );
}
