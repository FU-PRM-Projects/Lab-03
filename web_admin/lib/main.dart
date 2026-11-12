import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:not_core/not_core.dart';

import 'app.dart';
import 'config.dart';
import 'firebase/app_check.dart';
import 'firebase/firebase_admin_services.dart';
import 'firebase_options.dart';
import 'services/admin_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  await activateAppCheck();
  if (useFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  final remoteConfig = await FirebaseAdminRemoteConfig.load();

  runApp(
    ProviderScope(
      retry: noRetry,
      overrides: [
        adminAuthProvider.overrideWithValue(FirebaseAdminAuth()),
        adminAnalyticsProvider.overrideWithValue(FirebaseAdminAnalytics()),
        adminRemoteConfigProvider.overrideWithValue(remoteConfig),
        userDirectoryProvider.overrideWithValue(FirestoreUserDirectory()),
        catalogRepositoryProvider.overrideWithValue(
          FirestoreCatalogRepository(),
        ),
        submissionRepositoryProvider.overrideWithValue(
          FirestoreSubmissionRepository(),
        ),
        announcementRepositoryProvider.overrideWithValue(
          FirestoreAnnouncementRepository(),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          FirestoreDashboardRepository(),
        ),
      ],
      child: AdminApp(
        font: (style) => GoogleFonts.beVietnamPro(textStyle: style),
      ),
    ),
  );
}
