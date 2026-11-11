/**
 * Four slides per Lab 3 technology:
 *   01 WHAT  · what it is
 *   02 WHY   · why we use it
 *   03 HOW   · how we set it up: screenshots of the Firebase Console (or Cloudinary, GitHub…)
 *   04 WHERE · where it is in the code: screenshots of the real code on GitHub (main)
 *
 * WHERE screenshots come from `scripts/capture-where.mjs`; the line numbers here must match it.
 * Text between `backticks` is shown as code.
 */

type Evidence = [path: string, caption: string];

/** One setup step: [screenshot under public/, what we did there]. */
export type SetupStep = [img: string, step: string];

/** One code location: [screenshot under public/, file, lines, what happens there]. */
export type CodeShot = [img: string, file: string, lines: string, does: string];

type Technology = {
  images: [Evidence];
  name: string;
  /** One-sentence answer to "What is it?". */
  what: string;
  /** What it gives the app. */
  points: string[];
  example: string;
  /** Why we use it: [reason, explanation]. */
  why: [string, string][];
  /** Why not something else: [alternative, why we did not pick it]. */
  alternatives: [string, string][];
  /** HOW: one sentence, then the setup steps with screenshots. */
  how: string;
  setupTitle: string;
  setup: SetupStep[];
  /** WHERE: code screenshots. */
  where: CodeShot[];
};

export const technologies = {
  riverpod: {
    images: [
      ['app/s02.png', 'S02 Today: drawn from the state of TodayViewModel'],
    ],
    name: 'Riverpod + MVVM',
    what: 'Riverpod is a Flutter library that keeps app state and services in providers; a widget watches a provider and rebuilds when it changes.',
    points: [
      '`Provider`: one service, typed by its interface',
      '`NotifierProvider`: one ViewModel and its `ViewState<T>`',
      '`ProviderScope(overrides:)`: Firebase in the app, fakes in tests',
    ],
    example: 'In Nốt: TodayScreen watches TodayViewModel, which reads NoteRepository.',
    why: [
      ['Screens never touch Firebase', 'View → ViewModel → service interface; only `lib/firebase/` imports the SDK.'],
      ['Tests without Firebase', 'Tests override the same providers with fakes.'],
      ['Every state is explicit', '`Loading | Empty | Failure | Data`, so each screen draws errors too.'],
    ],
    alternatives: [
      ['Only `setState`', 'Logic lives inside widgets, so it cannot be tested without the UI.'],
      ['Provider (package)', 'Reads need a `BuildContext`, and a missing provider fails only at run time.'],
      ['Bloc', 'An event class and a state class for every screen: more code for the same MVVM split.'],
    ],
    how: 'Riverpod needs no cloud setup: add the package, wrap the app in one ProviderScope that wires every Firebase implementation, and let tests wire fakes the same way.',
    setupTitle: 'Project setup',
    setup: [
      ['where/h-rp-pubspec.png', 'Add `flutter_riverpod` to pubspec.yaml'],
      ['where/w-rp-main.png', 'Wrap the app in `ProviderScope` and override each service'],
      ['where/h-rp-test.png', 'Tests override the same providers with fakes'],
    ],
    // One entry per numbered box of the MVVM diagram, in order 1–8 ("layer · what it does").
    where: [
      ['where/w-rp-screen.png', 'lib/screens/today/today_screen.dart', '41–45', 'screens/ · watches its ViewModel, switches on the state'],
      ['where/mv-widgets.png', 'lib/widgets/app_button.dart', '11–15', 'widgets/ · one shared component, variant as a parameter'],
      ['where/mv-theme.png', 'packages/core/lib/theme/app_tokens.dart', '4–10', 'theme/ · spacing tokens, no hard-coded numbers'],
      ['where/w-rp-vm.png', 'lib/viewmodels/today_view_model.dart', '55–62', 'ViewModel · `NotifierProvider` + `Notifier<ViewState>`'],
      ['where/mv-service.png', 'lib/services/note_repository.dart', '9–15', 'Service · the interface the ViewModel calls'],
      ['where/mv-impl.png', 'lib/firebase/firestore_note_repository.dart', '19–23', 'Implementation · implements it with Firestore'],
      ['where/mv-main.png', 'lib/main.dart', '107–109', 'main.dart · overrides the provider with the Firestore class'],
      ['where/mv-models.png', 'lib/models/note.dart', '7–14', 'models/ · plain Dart, shared by every layer'],
    ],
  },
  auth: {
    images: [
      ['app/welcome.png', 'Welcome offers two sign-in methods'],
    ],
    name: 'Firebase Authentication',
    what: 'Firebase Authentication is Google’s hosted sign-in service: it checks who the user is and gives each account a stable user ID (UID).',
    points: [
      'Providers: Google (`google_sign_in`) and email + password',
      '`authStateChanges()` streams signed in / signed out',
      'Failures return codes, e.g. `network-request-failed`',
    ],
    example: 'In Nốt: Google or email sign-in on Welcome.',
    why: [
      ['The UID is the key of all data', 'Notes live under `users/{uid}/…`; rules allow only that user.'],
      ['No passwords on our side', 'Google keeps the credentials; the app never stores one.'],
      ['Routing follows the session', 'Signed out → `/welcome`, signed in → `/today`.'],
    ],
    alternatives: [
      ['Our own login server', 'We would have to store and hash passwords and keep a server running.'],
      ['Supabase Auth / Auth0', 'A second vendor; Firestore rules only know Firebase users (`request.auth`).'],
      ['Google Sign-In alone', 'Gives a Google account, but no UID that Firestore rules can check.'],
    ],
    how: 'Enable the two providers, register the app’s SHA fingerprints so Google sign-in works on Android, then check that real accounts appear with their UID.',
    setupTitle: 'Firebase Console',
    setup: [
      ['console/auth-providers.png', 'Authentication › Sign-in method: enable Google and Email/Password'],
      ['console/auth-sha.png', 'Project settings › Android app: add the SHA-1 / SHA-256 fingerprints'],
      ['console/auth-users-crop.png', 'Authentication › Users: accounts and their UIDs'],
    ],
    where: [
      ['where/w-auth-google.png', 'lib/firebase/firebase_auth_service.dart', '47–58', 'Google ID token → Firebase credential'],
      ['where/w-auth-map.png', 'lib/firebase/firebase_auth_service.dart', '119–131', 'Error code → message kind'],
      ['where/w-auth-redirect.png', 'lib/router/auth_redirect.dart', '25–29', 'Signed out → Welcome, signed in → Today'],
      ['where/w-auth-signout.png', 'lib/viewmodels/auth_view_model.dart', '116–127', 'Sign-out clears local data and the FCM inbox'],
    ],
  },
  firestore: {
    images: [
      ['evidence/firestore-challenges.png', 'Documents in Firestore'],
    ],
    name: 'Cloud Firestore',
    what: 'Cloud Firestore is Firebase’s NoSQL document database: collections → documents → fields, with live updates and an offline cache.',
    points: [
      '`snapshots()` pushes every change to the app',
      'Writes wait on the device when offline, then sync',
      'Security Rules check each read and write on the server',
    ],
    example: 'In Nốt: private notes under users/{uid}/notes.',
    why: [
      ['The Jar updates by itself', 'Today and the Jar watch a stream; no manual refresh.'],
      ['Works offline', 'A note saved without Wi-Fi stays on the device (“Đã lưu trên máy”).'],
      ['Owner-only data', 'Rules: only the owner, only valid notes; tested on the Emulator.'],
    ],
    alternatives: [
      ['Realtime Database', 'One big JSON tree, and a query can sort or filter on only one field.'],
      ['SQLite on the phone', 'Data stays on one device: no sync, lost with the phone.'],
      ['Own REST API + SQL', 'We would host a server and write offline sync ourselves.'],
    ],
    how: 'Create the database, publish the rules from firebase/firestore.rules with `firebase deploy --only firestore`, and seed the shared challenge catalogue with `npm run seed`.',
    setupTitle: 'Firebase Console',
    setup: [
      ['console/fs-rules-published.png', 'Firestore › Rules: our rules published from the repo (history on the left)'],
      ['evidence/firestore-challenges.png', 'Firestore › Data: the seeded `challenges` collection'],
    ],
    where: [
      ['where/w-fs-add.png', 'lib/firebase/firestore_note_repository.dart', '180–192', 'Write a note with `doc.set`'],
      ['where/w-fs-write.png', 'lib/firebase/firestore_note_repository.dart', '87–95', 'Wait 2 s, else keep it on the device'],
      ['where/w-fs-watch.png', 'lib/firebase/firestore_note_repository.dart', '108–116', 'Live list from `snapshots()`'],
      ['where/w-fs-rules.png', 'firebase/firestore.rules', '156–159', 'Only the owner, only valid notes'],
    ],
  },
  cloudinary: {
    images: [
      ['app/cld-note.png', 'Photo displayed in a saved note'],
    ],
    name: 'Cloudinary',
    what: 'Cloudinary is a cloud service that stores photos and serves them from an image CDN; the app posts a photo and gets back a URL and an ID.',
    points: [
      'Unsigned upload preset: no API secret in the app',
      'Upload over HTTP (`dio`) with progress and cancel',
      'Photos served over HTTPS from `res.cloudinary.com`',
    ],
    example: 'In Nốt: profile photos, note attachments and group covers.',
    why: [
      ['Free plan with an image CDN', 'Photos load fast over HTTPS from `res.cloudinary.com` at no cost.'],
      ['Progress and cancel', 'The user sees the upload percentage and can stop it.'],
      ['Only a reference in Firestore', '`{url, publicId}`, checked by `validImage`.'],
    ],
    alternatives: [
      ['Firebase Storage', 'A new bucket needs the paid Blaze plan; our project is on Spark.'],
      ['Photo as base64 in Firestore', 'A document holds at most 1 MiB, and every read downloads the photo.'],
      ['Amazon S3', 'Uploads need a signed request, so the secret would need a backend.'],
    ],
    how: 'On Cloudinary, create an unsigned upload preset `PRM_Lab3` with type and size limits. The app gets the cloud name and preset through --dart-define, then uploads straight to Cloudinary.',
    setupTitle: 'Cloudinary',
    setup: [
      ['where/w-cld-main.png', 'Cloud name + unsigned preset `PRM_Lab3` passed to the app'],
      ['app/cld-uploading.png', 'Upload to Cloudinary with progress and cancel'],
      ['app/cld-note.png', 'Photo served back from `res.cloudinary.com`'],
    ],
    where: [
      ['where/w-cld-upload.png', 'lib/firebase/cloudinary_image_service.dart', '72–82', 'Unsigned preset, random id, upload with progress'],
      ['where/w-cld-response.png', 'lib/firebase/cloudinary_image_service.dart', '89–101', 'Read `secure_url` and `public_id`'],
      ['where/w-cld-rules.png', 'firebase/firestore.rules', '20–27', '`validImage`: only a Cloudinary link'],
      ['where/w-cld-main.png', 'lib/main.dart', '127–133', 'Cloud name and preset from --dart-define'],
    ],
  },
  fcm: {
    images: [
      ['app/fcm-foreground.png', 'Push received in the foreground'],
    ],
    name: 'Firebase Cloud Messaging',
    what: 'Firebase Cloud Messaging (FCM) is Google’s free push service: a message sent to a device token reaches the app whether it is open, in the background or closed.',
    points: [
      'Each install has a device token',
      'A message carries a `data` part, here `route`',
      'Android 13+ needs `POST_NOTIFICATIONS`',
    ],
    example: 'In Nốt: tapping a test push can open the Jar.',
    why: [
      ['The success criterion starts here', 'Log a win in under 30 s after tapping a notification.'],
      ['Open the right screen', '`data.route = /jar` opens the Jar; only allow-listed routes.'],
      ['All three app states', 'Foreground, background and terminated, as Lab 3 requires.'],
    ],
    alternatives: [
      ['OneSignal', 'Another SDK and account; on Android it delivers through FCM anyway.'],
      ['Local notifications only', 'Scheduled on the phone, cannot be sent from a server (we still use them for the evening reminder).'],
      ['Polling a server', 'The app would wake up again and again and drain the battery.'],
    ],
    how: 'Check that the Cloud Messaging API (V1) is on, then send a test message from the Console to the device token printed in the debug log, with data route=/jar.',
    setupTitle: 'Firebase Console',
    setup: [
      ['console/fcm-api.png', 'Project settings › Cloud Messaging: API (V1) enabled'],
      ['console/fcm-test-received.png', 'Messaging › Send test message to the device token: it arrives on the phone'],
    ],
    where: [
      ['where/w-fcm-main.png', 'lib/main.dart', '82–86', 'Background handler, start messaging'],
      ['where/w-fcm-start.png', 'lib/firebase/firebase_messaging_service.dart', '77–87', 'Foreground, background and terminated'],
      ['where/w-fcm-fg.png', 'lib/firebase/firebase_messaging_service.dart', '97–107', 'Foreground: local notification + route'],
      ['where/w-fcm-route.png', 'lib/router/app_router.dart', '234–237', 'Tapped route → open the screen'],
    ],
  },
  analytics: {
    images: [
      ['app/console-analytics.png', 'Events arriving in DebugView'],
    ],
    name: 'Google Analytics for Firebase',
    what: 'Google Analytics for Firebase records the events the app logs, each with parameters, and shows them in reports and live in DebugView.',
    points: [
      '`logEvent(name, parameters)` for custom events',
      '`setUserId(uid)` after sign-in',
      'DebugView shows a debug device within seconds',
    ],
    example: 'In Nốt: note_saved records duration_ms.',
    why: [
      ['Measure the 30-second goal', '`note_saved.duration_ms`: 7.7 s in our run.'],
      ['No personal data', 'No note text, titles, emails or names are logged.'],
      ['Never breaks a feature', '`track()` catches a failed log; the action still works.'],
    ],
    alternatives: [
      ['Mixpanel / Amplitude', 'Another SDK and account, with usage limits on the free plan.'],
      ['Events as Firestore documents', 'A write per event, and no reports or DebugView.'],
      ['No analytics', 'We could not check the 30-second goal.'],
    ],
    how: 'Analytics is linked when the project is created. Mark the emulator as a debug device with `adb shell setprop debug.firebase.analytics.app com.quanphungg.lab03`, use the app, and watch DebugView.',
    setupTitle: 'Firebase Console',
    setup: [
      ['app/console-analytics.png', 'Analytics › DebugView: events from the debug device'],
      ['app/dv-params.png', 'DebugView: open an event to check its parameters'],
    ],
    where: [
      ['where/w-an-track.png', 'lib/viewmodels/note_composer_view_model.dart', '253–264', '`note_saved` with `duration_ms`'],
      ['where/w-an-safe.png', 'lib/services/analytics_service.dart', '39–46', '`track()` never breaks the user’s action'],
      ['where/w-an-impl.png', 'lib/firebase/firebase_analytics_service.dart', '11–20', 'Forward to Firebase Analytics'],
      ['where/w-an-events.png', 'lib/services/analytics_events.dart', '5–13', 'Every event name in one place'],
    ],
  },
  crashlytics: {
    images: [
      ['app/console-crashlytics.png', 'Crashlytics issues dashboard'],
    ],
    name: 'Firebase Crashlytics',
    what: 'Firebase Crashlytics collects crashes and caught errors from real devices and groups them into issues with the stack trace, custom keys and user ID.',
    points: [
      'Fatal: uncaught errors, sent on the next launch',
      'Non-fatal: `recordError` for errors the app caught',
      'Context: user ID and custom keys',
    ],
    example: 'In Nốt: a failed note save reports note_save.',
    why: [
      ['Real devices, not the Emulator', 'The Emulator Suite has no Crashlytics.'],
      ['Caught errors still count', 'The user sees a message; we still get the report.'],
      ['It found a real bug', 'Two add-note buttons shared a Hero tag; fixed.'],
    ],
    alternatives: [
      ['Sentry', 'Another account and SDK, with a monthly error quota on the free plan.'],
      ['Only `print` / logcat', 'Works on our emulator, not on a user’s phone after release.'],
      ['Error rows in Firestore', 'No grouping and no stack trace view; a write per error.'],
    ],
    how: 'Add the Crashlytics Gradle plugin, send a test crash from Settings › “Thử crash (dev)” to activate the dashboard, then read non-fatals with their keys and user ID.',
    setupTitle: 'Firebase Console',
    setup: [
      ['console/crash-issues-crop.png', 'Crashlytics › Issues: the test crash and a real Hero error'],
      ['console/crash-nonfatal-crop.png', 'Issues: a non-fatal error the app reported'],
      ['app/console-crash-keys.png', 'Issue › Keys: `screen` and the user ID'],
    ],
    where: [
      ['where/w-cr-handlers.png', 'lib/firebase/crash_handlers.dart', '9–19', 'Uncaught errors → Crashlytics'],
      ['where/w-cr-reporter.png', 'lib/firebase/firebase_crash_reporter.dart', '9–20', 'Report a caught error (non-fatal)'],
      ['where/w-cr-nonfatal.png', 'lib/viewmodels/note_composer_view_model.dart', '276–281', 'A failed save → non-fatal `note_save`'],
      ['where/w-cr-main.png', 'lib/main.dart', '80–81', 'Only on the real project, not on web'],
    ],
  },
  'remote-config': {
    images: [
      ['app/console-remoteconfig.png', 'Feature flags in Firebase Console'],
    ],
    name: 'Firebase Remote Config',
    what: 'Firebase Remote Config is a set of key–value parameters on Firebase that the app fetches at run time, so values change from the Console without a new build.',
    points: [
      '`setDefaults`: in-app values for first launch and errors',
      '`fetchAndActivate`: download and apply server values',
      '`minimumFetchInterval`: how long values are cached',
    ],
    example: 'In Nốt: groups_enabled toggles the Jar’s groups shelf.',
    why: [
      ['Turn a feature off fast', 'Same APK before and after; only the Console value changed.'],
      ['Safe when it fails', 'Every flag defaults to on; a failed fetch keeps features.'],
      ['Values live in the repo', 'A template file, deployed with the Firebase CLI.'],
    ],
    alternatives: [
      ['Hard-coded flags', 'Every change needs a new build and a new install.'],
      ['A flags document in Firestore', 'No built-in defaults or cache; a read on every launch.'],
    ],
    how: 'Publish firebase/remoteconfig.template.json with `firebase deploy --only remoteconfig`, then flip a flag on the Console and reopen the app: no new build.',
    setupTitle: 'Firebase Console',
    setup: [
      ['app/console-remoteconfig.png', 'Remote Config: the feature flags'],
      ['app/rc-jar-after.png', 'Flag set to false → the groups shelf is gone'],
    ],
    where: [
      ['where/w-rc-defaults.png', 'lib/firebase/firebase_remote_config_service.dart', '53–58', 'In-app defaults: every flag on'],
      ['where/w-rc-fetch.png', 'lib/firebase/firebase_remote_config_service.dart', '75–87', 'Cache 1 h in release, then fetch'],
      ['where/w-rc-shelf.png', 'lib/screens/groups/group_shelf.dart', '33–36', '`groups_enabled` hides the shelf'],
      ['where/w-rc-challenges.png', 'lib/screens/challenges/challenges_screen.dart', '150–152', '`custom_challenges_enabled`'],
    ],
  },
  artemis: {
    images: [
      ['app/artemis-workspace.jpg', 'ARTEMIS Workspace: agent steps and run history'],
    ],
    name: 'ARTEMIS (AI E2E testing)',
    what: 'ARTEMIS is Google’s open-source AI agent that controls an Android device over ADB: it gets a goal in plain language, taps through the app and reports a value.',
    points: [
      'Local server + LLM (`deepseek-v4.1-flash` via OpenRouter)',
      'Our pytest suite sends goals and asserts on the answer',
      'Locked to the app package, so it stays in Nốt',
    ],
    example: 'In Nốt: “save a note” must end with the agent reporting SAVED.',
    why: [
      ['The real app end to end', 'Real build, real Firebase, Android 15 emulator.'],
      ['Also outside the app', 'Home button, notification shade, airplane mode.'],
      ['Three runs per case', '14 cases × 3 runs: 41 of 42 pass.'],
    ],
    alternatives: [
      ['Flutter `integration_test`', 'Stays inside our app: cannot press Home, open the shade or switch on airplane mode.'],
      ['Appium / Espresso scripts', 'Every tap is scripted by element ID, so a layout change breaks the test.'],
      ['Manual testing', 'Not repeatable 3 times per case with a recorded result.'],
    ],
    how: 'Put the OpenRouter key in tools/artemis/.env, start the ARTEMIS server next to the emulator, then run `uv run pytest --runs 3` in e2e_test/.',
    setupTitle: 'ARTEMIS Workspace',
    setup: [
      ['console/artemis-running-crop.jpg', 'Server running: agent steps live, run history'],
      ['app/artemis-saved.jpg', 'T02: the agent saved a note and reported SAVED'],
    ],
    where: [
      ['where/w-ar-ask.png', 'e2e_test/conftest.py', '138–147', 'Send a goal, lock the app, read the answer'],
      ['where/w-ar-t02.png', 'e2e_test/test_main_flows.py', '39–48', 'T02: save a note → SAVED'],
      ['where/w-ar-t06.png', 'e2e_test/test_main_flows.py', '76–86', 'T06: airplane mode over adb'],
      ['where/w-ar-model.png', 'tools/artemis/config/artemis.jsonc', '9–12', 'Model: deepseek-v4.1-flash'],
    ],
  },
  coderabbit: {
    images: [
      ['review/proof-review.png', 'CodeRabbit review on PR #38'],
    ],
    name: 'CodeRabbit (AI code review)',
    what: 'CodeRabbit is an AI code review app for GitHub: it reads each pull request and leaves inline comments with a severity, a category and a suggested fix.',
    points: [
      'Runs on every PR and on each new push',
      'Inline comments on the exact lines',
      'Severity (Major / Minor) and kind (security, correctness…)',
    ],
    example: 'In Nốt: 52 findings on PRs #28, #29 and #38.',
    why: [
      ['A second reviewer every time', 'A small team cannot review every line twice.'],
      ['It found real bugs', 'The FCM inbox survived sign-out (privacy).'],
      ['We still judge each one', '51 right, 1 wrong; each fix is its own commit.'],
    ],
    alternatives: [
      ['Human review only', 'Four students cannot read every line of every PR twice.'],
      ['`flutter analyze` only', 'Finds lint and type errors, not logic bugs like the inbox leak; CI still runs it.'],
    ],
    how: 'Install the CodeRabbit app on the repository. It reviews each PR; we write a verdict for every finding in docs/code-review.md and fix the real ones in separate commits.',
    setupTitle: 'GitHub',
    setup: [
      ['review/proof-review.png', 'PR #38: CodeRabbit review and inline comments'],
      ['review/proof-verdicts.png', 'docs/code-review.md: our verdict per finding'],
      ['review/proof-commit-736453a.png', 'Fix commit naming its finding'],
    ],
    where: [
      ['where/w-cb-inbox.png', 'lib/viewmodels/auth_view_model.dart', '123–127', 'Fixed `736453a`: clear the inbox on sign-out'],
      ['where/w-cb-payload.png', 'lib/firebase/firebase_messaging_service.dart', '101–107', 'Fixed `5e13651`: payload carries the route'],
      ['where/w-cb-rejected.png', 'lib/screens/challenges/create_challenge_sheet.dart', '97–98', 'Rejected: `canSubmit` already checks `_saving`'],
    ],
  },
} satisfies Record<string, Technology>;
