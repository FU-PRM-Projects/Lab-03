import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'firebase/crash_handlers.dart';
import 'firebase/device_discord_service.dart';
import 'firebase/device_services.dart';
import 'firebase/firebase_analytics_service.dart';
import 'firebase/firebase_auth_service.dart';
import 'firebase/firebase_bootstrap.dart';
import 'firebase/firebase_crash_reporter.dart';
import 'firebase/firebase_messaging_service.dart';
import 'firebase/firebase_remote_config_service.dart';
import 'firebase/firestore_challenge_repository.dart';
import 'firebase/firestore_group_repository.dart';
import 'firebase/firestore_note_repository.dart';
import 'firebase/firestore_self_control.dart';
import 'firebase/firestore_user_repository.dart';
import 'firebase/local_nudge_service.dart';
import 'firebase/prefs_draft_store.dart';
import 'firebase/report_impl.dart';
import 'firebase/streak_share_impl.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/challenge_repository.dart';
import 'services/crash_reporter.dart';
import 'services/discord_service.dart';
import 'services/draft_store.dart';
import 'services/group_repository.dart';
import 'services/messaging_service.dart';
import 'services/note_repository.dart';
import 'services/nudge_service.dart';
import 'services/remote_config_service.dart';
import 'services/report_services.dart';
import 'services/self_control_services.dart';
import 'services/streak_share_service.dart';
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
  // Crashlytics không có emulator và không hỗ trợ web; chỉ gắn khi chạy
  // Android/iOS với project thật.
  const crashEnabled = !useFirebaseEmulator && !kIsWeb;
  installCrashHandlers(enabled: crashEnabled);
  final messaging = FirebaseMessagingService();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    unawaited(messaging.start());
  }
  final auth = FirebaseAuthService(
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
  );
  String? uid() => auth.currentUser?.uid;
  // Remote Config không có emulator: dùng project thật, lỗi thì về mặc định.
  final remoteConfig = await FirebaseRemoteConfigService.create();

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        messagingServiceProvider.overrideWithValue(messaging),
        analyticsServiceProvider.overrideWithValue(
          useFirebaseEmulator
              ? const DebugAnalyticsService()
              : FirebaseAnalyticsService(),
        ),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
        userRepositoryProvider.overrideWithValue(FirestoreUserRepository()),
        noteRepositoryProvider.overrideWithValue(
          FirestoreNoteRepository(currentUid: uid),
        ),
        groupRepositoryProvider.overrideWithValue(
          FirestoreGroupRepository(currentUid: uid),
        ),
        draftStoreProvider.overrideWithValue(PrefsDraftStore()),
        reportServiceProvider.overrideWithValue(const PdfReportService()),
        streakShareServiceProvider.overrideWithValue(
          FirebaseStreakShareService(currentUid: uid),
        ),
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
        nudgeServiceProvider.overrideWithValue(LocalNudgeService()),
        discordServiceProvider.overrideWithValue(const DeviceDiscordService()),
        crashReporterProvider.overrideWithValue(
          crashEnabled
              ? const FirebaseCrashReporter()
              : const NoopCrashReporter(),
        ),
      ],
      child: NotApp(
        font: (style) => GoogleFonts.beVietnamPro(textStyle: style),
      ),
    ),
  );
}
