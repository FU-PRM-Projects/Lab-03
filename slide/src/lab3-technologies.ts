type Location = [name: string, detail: string];

type Evidence = [path: string, caption: string];

type Technology = {
  images: [Evidence, [Evidence, Evidence], Evidence];
  name: string;
  what: string;
  example: string;
  why: [string, string];
  how: string;
  flow: [string, string, string];
  code: [Location, Location];
  service: Location;
};

export const technologies = {
  auth: {
    images: [
      ['app/welcome.png', 'Welcome offers two sign-in methods'],
      [['app/welcome.png', 'Signed out'], ['app/s02.png', 'Signed in']],
      ['code/redirect.png', 'Router redirects by session state'],
    ],
    name: 'Firebase Authentication',
    what: 'Verifies who is signing in and gives each account a user ID (UID).',
    example: 'In Nốt: Google or email sign-in on Welcome.',
    why: ['Keep each user\'s notes under their UID.', 'Open Today when the user signs in.'],
    flow: ['Sign in', 'Watch session', 'Open Today'],
    how: 'Sign in through Firebase Auth, observe the auth state, then send the signed-in user to Today.',
    code: [['lib/firebase/firebase_auth_service.dart', 'Google and email/password sign-in'], ['lib/router/auth_redirect.dart', 'Redirect between Welcome and Today']],
    service: ['Authentication › Sign-in method / Users', 'Enable Google and Email/Password. Inspect registered accounts and UIDs in Users.'],
  },
  firestore: {
    images: [
      ['evidence/firestore-challenges.png', 'Documents in Firestore'],
      [['app/artemis-offline.jpg', 'Saved locally while offline'], ['app/cld-note.png', 'Note shown in the app']],
      ['evidence/firestore-challenges.png', 'Firestore Database / Data'],
    ],
    name: 'Cloud Firestore',
    what: 'Stores data in documents and sends live updates.',
    example: 'In Nốt: private notes under users/{uid}/notes.',
    why: ['Update the Jar as notes change.', 'Restrict access to the note owner.'],
    flow: ['Save note', 'Watch snapshots', 'Refresh Jar'],
    how: 'Write a note document under the signed-in UID. Watch query snapshots and map them back to Dart Note objects.',
    code: [['lib/firebase/firestore_note_repository.dart', 'Write notes and subscribe to snapshots'], ['firebase/firestore.rules', 'Check ownership and note fields']],
    service: ['Firestore Database › Data / Rules', 'Inspect users/{uid}/notes in Data and the deployed access policy in Rules.'],
  },
  cloudinary: {
    images: [
      ['app/cld-note.png', 'Photo displayed in a saved note'],
      [['app/cld-uploading.png', 'Upload progress and cancel'], ['app/cld-attached.png', 'Photo attached to the note']],
      ['code/cld-upload.png', 'Cloudinary upload implementation'],
    ],
    name: 'Cloudinary',
    what: 'Stores photos and delivers them through an image CDN.',
    example: 'In Nốt: profile photos, note attachments and group covers.',
    why: ['Show progress and allow cancellation.', 'Keep only the image reference in Firestore.'],
    flow: ['Select photo', 'Upload to CDN', 'Save URL + ID'],
    how: 'Upload the image with an unsigned preset. Save the returned secure URL and public ID in Firestore.',
    code: [['lib/firebase/cloudinary_image_service.dart', 'Build the multipart upload and read its response'], ['firebase/firestore.rules', 'Validate the stored image reference']],
    service: ['Media Library / Firestore Database', 'Cloudinary stores the photo. Firebase stores its url and publicId.'],
  },
  fcm: {
    images: [
      ['app/fcm-foreground.png', 'Push received in the foreground'],
      [['app/fcm-inbox.png', 'Messages in the inbox'], ['app/fcm-route.png', 'Tap opens the Jar']],
      ['app/fcm-console.png', 'Test push from Firebase Console'],
    ],
    name: 'Firebase Cloud Messaging',
    what: 'Sends push notifications to a device.',
    example: 'In Nốt: tapping a test push can open the Jar.',
    why: ['Test remote pushes from Firebase.', 'Open the relevant screen from a notification.'],
    flow: ['Allow notifications', 'Receive push', 'Open route'],
    how: 'Request permission, receive the push, then resolve its route when the user taps. Handle foreground, background and cold-start delivery.',
    code: [['lib/firebase/firebase_messaging_service.dart', 'Receive messages and handle notification taps'], ['lib/services/messaging_service.dart', 'Accept routes on the allowlist']],
    service: ['Messaging › Send test message', 'Target the device token for a test push. The recurring evening reminder is scheduled on the device.'],
  },
  analytics: {
    images: [
      ['app/console-analytics.png', 'Events arriving in DebugView'],
      [['app/artemis-saved.jpg', 'Note saved in the app'], ['app/dv-params.png', 'Event parameters in DebugView']],
      ['app/dv-params.png', 'Inspect the event parameters'],
    ],
    name: 'Google Analytics for Firebase',
    what: 'Tracks events and their parameters.',
    example: 'In Nốt: note_saved records duration_ms.',
    why: ['Measure how long it takes to save a note.', 'Track feature use without collecting note text.'],
    flow: ['Save note', 'Log event', 'Check DebugView'],
    how: 'The composer records note_saved after saving. The analytics adapter forwards the event and parameters to Firebase.',
    code: [['lib/viewmodels/note_composer_view_model.dart', 'Track note_saved and duration_ms'], ['lib/firebase/firebase_analytics_service.dart', 'Forward events to logEvent']],
    service: ['Analytics › DebugView / Events', 'Verify a debug device sends note_saved and inspect its parameters.'],
  },
  crashlytics: {
    images: [
      ['app/console-crashlytics.png', 'Crashlytics issues dashboard'],
      [['app/crash-test.png', 'Crash test in the app'], ['app/console-crash-keys.png', 'Context attached to an issue']],
      ['app/console-crashlytics.png', 'Inspect reported issues in Firebase'],
    ],
    name: 'Firebase Crashlytics',
    what: 'Groups crashes and caught errors into issues.',
    example: 'In Nốt: a failed note save reports note_save.',
    why: ['See failures on real devices.', 'Find the cause with stack traces and custom keys.'],
    flow: ['Catch error', 'Report details', 'Inspect issue'],
    how: 'Register global error handlers. Report caught errors explicitly and use the Settings crash action to verify delivery.',
    code: [['lib/firebase/crash_handlers.dart', 'Capture uncaught Flutter and platform errors'], ['lib/firebase/firebase_crash_reporter.dart', 'Report non-fatals, keys and test crashes']],
    service: ['Crashlytics › Issues', 'Open an issue to inspect its stack trace, custom keys and event details.'],
  },
  'remote-config': {
    images: [
      ['app/console-remoteconfig.png', 'Feature flags in Firebase Console'],
      [['app/rc-jar-before.png', 'Groups shelf enabled'], ['app/rc-jar-after.png', 'Groups shelf disabled']],
      ['app/console-remoteconfig.png', 'Edit and publish feature flags'],
    ],
    name: 'Firebase Remote Config',
    what: 'Changes app settings from Firebase.',
    example: 'In Nốt: groups_enabled toggles the Jar’s groups shelf.',
    why: ['Toggle a feature without a new release.', 'Keep defaults if the app cannot fetch settings.'],
    flow: ['Set defaults', 'Fetch flags', 'Apply settings'],
    how: 'Load in-app defaults, call fetchAndActivate, then read the flag when rendering the feature.',
    code: [['lib/firebase/firebase_remote_config_service.dart', 'Fetch and activate parameters'], ['firebase/remoteconfig.template.json', 'Versioned parameter values']],
    service: ['Remote Config › Parameters', 'Change and publish groups_enabled, then let the app fetch the update.'],
  },
} satisfies Record<string, Technology>;
