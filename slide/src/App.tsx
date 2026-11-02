import type { ReactNode } from 'react';
import { Deck, Slide } from '@revealjs/react';
import RevealNotes from 'reveal.js/plugin/notes';

import 'reveal.js/reveal.css';
import './slides.css';

/** Slot for a real screenshot. Replace with <img> once evidence exists; never fill in assumed results. */
function Shot({ label }: { label: string }) {
  return <div className="shot">{label}</div>;
}

/** Figma frame next to the real app screen, with a few short notes on what differs. */
function Compare({ screen, diffs }: { screen: string; diffs: string[] }) {
  const base = import.meta.env.BASE_URL;
  const file = screen.toLowerCase();
  return (
    <div className="compare">
      <figure>
        <img src={`${base}figma/${file}.png`} alt={`${screen} in Figma`} />
        <figcaption>Figma</figcaption>
      </figure>
      <figure>
        <img src={`${base}app/${file}.png`} alt={`${screen} in the app`} />
        <figcaption>App</figcaption>
      </figure>
      <ul className="diffs">
        {diffs.map((d) => (
          <li key={d}>{d}</li>
        ))}
      </ul>
    </div>
  );
}

type ShotImage = {
  src: string;
  alt: string;
  crop?: boolean;
  wide?: boolean;
  full?: boolean;
  caption?: string;
};

function ShotImages({ images }: { images: ShotImage[] }) {
  return (
    <div className="shots">
      {images.map(({ src, alt, crop, wide, full, caption }) => (
        <figure key={src}>
          <img
            className={crop ? 'crop' : wide ? 'wide' : full ? 'full' : undefined}
            src={`${import.meta.env.BASE_URL}${src}`}
            alt={alt}
          />
          {caption && <figcaption>{caption}</figcaption>}
        </figure>
      ))}
    </div>
  );
}

function Page({
  title,
  line,
  todo,
  shots,
  images,
  notes,
  children,
}: {
  title: string;
  line?: string;
  todo?: string;
  shots?: string[];
  images?: ShotImage[];
  notes: string;
  children?: ReactNode;
}) {
  return (
    <Slide notes={notes}>
      <h2>{title}</h2>
      {line && <p className="line">{line}</p>}
      {images && children ? (
        <div className="split">
          <div className="side-text">{children}</div>
          <ShotImages images={images} />
        </div>
      ) : (
        <>
          {children}
          {shots && (
            <div className="shots">
              {shots.map((label) => (
                <Shot key={label} label={label} />
              ))}
            </div>
          )}
          {images && <ShotImages images={images} />}
        </>
      )}
      {todo && <p className="todo">{todo}</p>}
    </Slide>
  );
}

function Flow({ steps }: { steps: string[] }) {
  return <p className="flow">{steps.join('  →  ')}</p>;
}

type ArchBox = { x: number; y: number; w: number; title: string; sub: string; dim?: boolean };

const ARCH_BOXES: ArchBox[] = [
  { x: 20, y: 44, w: 150, title: 'screens/', sub: 'S01 … S12' },
  { x: 205, y: 44, w: 150, title: 'widgets/', sub: 'shared components' },
  { x: 390, y: 44, w: 150, title: 'theme/', sub: 'design tokens' },
  { x: 190, y: 160, w: 180, title: 'ViewModel', sub: 'Notifier + ViewState<T>' },
  { x: 190, y: 260, w: 180, title: 'Service', sub: 'interfaces + Providers' },
  { x: 190, y: 370, w: 180, title: 'Implementation', sub: 'firebase/ · 15 classes' },
  { x: 190, y: 480, w: 180, title: 'Firebase SDK', sub: 'Auth · Firestore · …', dim: true },
  { x: 430, y: 370, w: 130, title: 'main.dart', sub: 'composition root', dim: true },
];

function ArchDiagram() {
  const line = { stroke: '#000', strokeWidth: 1.5, markerEnd: 'url(#arr)', fill: 'none' };
  return (
    <svg className="diagram" viewBox="-4 -4 568 662" role="img" aria-label="Architecture diagram">
      <defs>
        <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto">
          <path d="M0 0 L10 5 L0 10 z" fill="#000" />
        </marker>
        <marker id="arr-dim" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto">
          <path d="M0 0 L10 5 L0 10 z" fill="#888" />
        </marker>
      </defs>

      <rect x="0" y="0" width="560" height="124" rx="16" fill="none" stroke="#888" strokeWidth="1.5" strokeDasharray="6 5" />
      <text x="16" y="26" fontSize="15" fill="#888" fontWeight="600">View</text>

      <rect x="0" y="590" width="560" height="64" rx="12" fill="#f4f4f4" stroke="#888" strokeWidth="1.5" />
      <text x="280" y="619" textAnchor="middle" fontSize="20" fontWeight="600">models/ · plain Dart</text>
      <text x="280" y="641" textAnchor="middle" fontSize="14" fill="#555">Note · Mood · Challenge · AppUser</text>

      {ARCH_BOXES.map((b) => (
        <g key={b.title}>
          <rect
            x={b.x}
            y={b.y}
            width={b.w}
            height="64"
            rx="12"
            fill={b.dim ? '#f4f4f4' : '#fff'}
            stroke={b.dim ? '#888' : '#000'}
            strokeWidth="1.5"
          />
          <text x={b.x + b.w / 2} y={b.y + 27} textAnchor="middle" fontSize="20" fontWeight="600">{b.title}</text>
          <text x={b.x + b.w / 2} y={b.y + 49} textAnchor="middle" fontSize="14" fill="#555">{b.sub}</text>
        </g>
      ))}

      <g {...line}>
        <line x1="170" y1="76" x2="204" y2="76" />
        <line x1="355" y1="76" x2="389" y2="76" />
        <path d="M95 108 V192 H189" />
        <line x1="280" y1="224" x2="280" y2="259" />
        <line x1="280" y1="434" x2="280" y2="479" />
        <path d="M30 124 V589" />
        <path d="M190 210 H70 V589" />
        <path d="M190 290 H110 V589" />
        <path d="M190 400 H150 V589" />
      </g>
      <line x1="280" y1="369" x2="280" y2="325" stroke="#000" strokeWidth="1.5" strokeDasharray="5 4" markerEnd="url(#arr)" />
      <line x1="429" y1="402" x2="371" y2="402" stroke="#888" strokeWidth="1.5" strokeDasharray="2 4" markerEnd="url(#arr-dim)" />

      <g fontSize="14" fill="#555">
        <text x="292" y="247">calls interface</text>
        <text x="292" y="352">implements</text>
        <text x="400" y="394" textAnchor="middle">overrides</text>
        <text x="106" y="184">watch · call</text>
      </g>
    </svg>
  );
}

const DS_COLORS: { label: string; chips: [string, string][] }[] = [
  { label: 'Primary', chips: [['primary', '#3D4FD6'], ['primary-container', '#DDE1FF'], ['primary-dark', '#2B399F']] },
  { label: 'Surface', chips: [['surface', '#F6F7FB'], ['surface-card', '#FFFFFF'], ['surface-variant', '#E7E9F3'], ['outline', '#7A8094']] },
  { label: 'Text', chips: [['on-surface', '#1B1D2A'], ['on-surface-variant', '#555B6E']] },
  { label: 'Status', chips: [['error', '#B3261E'], ['warning', '#A84F00'], ['success', '#1F9D63']] },
  { label: 'Heat', chips: [['heat/1', '#A9DCF5'], ['heat/2', '#7FD9B3'], ['heat/3', '#FFD24A'], ['heat/4', '#FF9A3D'], ['heat/5', '#F0524B']] },
  {
    label: 'Tint',
    chips: [['blue', '#E3F3FB'], ['orange', '#FFEBD6'], ['red', '#FDE1DF'], ['green', '#DDF5EA'], ['violet', '#ECEBFC'], ['yellow', '#FFF4CC'], ['indigo', '#E4E7FF']],
  },
];

const DS_TYPE: [string, number, number][] = [
  ['Display · 44 Bold', 44, 700],
  ['Headline · 28 Bold', 28, 700],
  ['Title · 20 Bold', 20, 700],
  ['Body · 16 Regular', 16, 400],
  ['Label · 14 SemiBold', 14, 600],
  ['Caption · 12 Regular', 12, 400],
];

function DesignSystem() {
  return (
    <div className="ds">
      <div className="ds-colors">
        {DS_COLORS.map((g) => (
          <div className="ds-row" key={g.label}>
            <span className="ds-label">{g.label}</span>
            {g.chips.map(([name, hex]) => (
              <span className="ds-chip" key={name}>
                <i style={{ background: hex }} />
                <b>{name}</b>
                <em>{hex}</em>
              </span>
            ))}
          </div>
        ))}
      </div>
      <div className="ds-side">
        <div className="ds-type">
          {DS_TYPE.map(([name, size, weight]) => (
            <div key={name}>
              <span style={{ fontSize: size, fontWeight: weight }}>Nốt nhắc bạn</span>
              <small>{name}</small>
            </div>
          ))}
        </div>
        <div className="ds-scale">
          <span className="ds-label">Space</span>
          {[2, 4, 8, 12, 16, 24].map((v) => (
            <span className="ds-chip" key={v}>
              <i className="sq" style={{ width: v, height: v }} />
              <em>{v}</em>
            </span>
          ))}
        </div>
        <div className="ds-scale">
          <span className="ds-label">Radius</span>
          {[4, 6, 8, 12].map((v) => (
            <span className="ds-chip" key={v}>
              <i className="sq big" style={{ borderRadius: v }} />
              <em>{v}</em>
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <div className="stage">
      <Deck
        config={{
          width: 1280,
          height: 720,
          margin: 0,
          hash: true,
          slideNumber: 'c/t',
          showSlideNumber: 'all',
          transition: 'none',
          center: false,
          controls: false,
          progress: false,
        }}
        plugins={[RevealNotes]}
      >
        <Slide notes="Nốt is built for Minh, a 22-year-old final-year student. Lab 2 success criterion: log a mood and one win in under 30 seconds after tapping the evening notification.">
          <h1>Nốt</h1>
          <p className="line">One positive note every day</p>
          <ul className="speakers">
            <li>Đoàn Thị Kim Thúy · SE190992</li>
            <li>Phùng Thế Quân · SE193519</li>
            <li>Phan Đức Duy · SE193591</li>
            <li>Phan Hữu Phước · SE161951</li>
          </ul>
          <img
            className="hero-shot"
            src={`${import.meta.env.BASE_URL}assets/showcase/hero-showcase.png`}
            alt="Nốt app screens: welcome, today and jar"
          />
        </Slide>

        <Page
          title="Introduction"
          notes="The problem and how Nốt answers it: one small win goes into the jar every evening."
        >
          <p className="intro">
            Tiny Wins (Nốt) is a mobile app for burned-out final-year students: every evening they
            drop one small win into a jar instead of staring at an unfinished to-do list. After a
            rough day, the jar hands back an old win to remember. Small bravery and movement
            challenges, a one-tap self-control log and a guided journal help them rebuild
            confidence, one note at a time.
          </p>
        </Page>

        <Page
          title="Persona"
          line="Minh, 22, final-year student."
          notes="Lab 2 success criterion: log a mood and one win in under 30 seconds after tapping the evening notification."
        >
          <p className="flow">Success criterion: under 30 seconds</p>
        </Page>

        <Page
          title="Figma vs app · Today"
          line="S02, the first tab."
          notes="Figma on the left, app on the right. D-04 Android status bar, D-25 shortcut icons and captions, D-29 the Ghi nốt sheet, D-14 the jar shows real notes. Full list: docs/design-traceability.md, section 5."
        >
          <Compare
            screen="S02"
            diffs={[
              'Android status bar instead of the iPhone one (D-04).',
              'Shortcuts get new icons and a one-line caption each (D-25).',
              '"Ghi nốt" first asks: small win or journal (D-29).',
              'The jar is empty here: notes are coloured from real data (D-14).',
            ]}
          />
        </Page>

        <Page
          title="Figma vs app · Write a note"
          line="S03b, step 2 of 3."
          notes="D-28: the extra writing is not a journal entry, so the label changed after users misread it. The 120 limit is a handoff value (D-02). Free-tell with AI is planned, not built."
        >
          <Compare
            screen="S03b"
            diffs={[
              '"Bỏ qua nhật ký" became "Bỏ qua phần kể thêm" (D-28).',
              'A 0/120 counter under the field (D-02).',
              'Quick chips fill the field; the Figma example text is not prefilled.',
              'Free-tell with AI is still planned, so it is not on this screen.',
            ]}
          />
        </Page>

        <Page
          title="Figma vs app · Stats"
          line="S11b, the Stats tab."
          notes="D-18 compares with the previous 30 days instead of a fixed month; D-09 the chart scales with the card; D-06 the weekly card PDF goes to Cloud Storage before sharing. The screenshot comes from a test account with a single note."
        >
          <Compare
            screen="S11b"
            diffs={[
              'Trend is compared with the previous 30 days (D-18).',
              'The chart scales to the card width (D-09).',
              'The weekly goal opens a full-screen weekly card (D-06).',
              'Test account has a single note, so the trend needs more days.',
            ]}
          />
        </Page>

        <Page
          title="MVVM"
          notes="Widgets never call an SDK. Each screen has an explicit state model. Services are injected through Riverpod, so ViewModels can be tested with fakes. Details: docs/architecture.md."
        >
          <div className="arch">
            <pre className="tree">{`lib/
├── main.dart               composition root
├── app.dart                MaterialApp.router
├── router/
│   └── auth_redirect.dart  signed out → /welcome
├── theme/
│   └── app_tokens.dart     spacing, radius
├── models/
│   └── note.dart           plain Dart
├── services/
│   └── note_repository.dart
│                           interface + Provider
├── firebase/
│   └── firestore_note_repository.dart
│                           implementation
├── viewmodels/
│   ├── view_state.dart     Loading | Empty | Failure | Data
│   └── today_view_model.dart
│                           Notifier + ViewState
├── screens/today/
│   └── today_screen.dart   switch on ViewState
├── widgets/
│   └── app_button.dart     shared component
└── utils/
    └── dates.dart          pure helpers`}</pre>
            <ArchDiagram />
          </div>
        </Page>

        <Page
          title="Design system"
          notes="Tokens live in lib/theme, components in lib/widgets. Example: AppButton has 5 variants and 4 states."
        >
          <DesignSystem />
        </Page>

        <Page
          title="Authentication"
          line="Cancelled sign-in: a message and a retry."
          images={[
            { src: 'app/welcome.png', alt: 'Welcome screen with Google and email sign-in' },
            { src: 'app/welcome-cancelled.png', alt: 'Welcome screen after cancelling: Bạn đã huỷ đăng nhập.' },
          ]}
          notes="Google and email sign-in. Signed-out users go to S01 and the destination is kept through next. Cancelling the Google account chooser shows Bạn đã huỷ đăng nhập. and the button is ready again. The account chooser itself is not shown because it displays a real name and email. Console check by CLI: firebase auth:export on prm393-not-lab3 returned 1 account with provider google.com."
        >
          <pre className="log">{`$ firebase auth:export users.json --project prm393-not-lab3
Exported 1 account(s) · provider: google.com`}</pre>
        </Page>

        <Page
          title="Cloud Messaging · Permission"
          line="Permission denied: a prompt to open settings."
          images={[
            { src: 'app/fcm-denied.png', alt: 'Prompt asking to open settings', crop: true },
            { src: 'app/fcm-os-settings.png', alt: 'Android notification settings for the app', crop: true },
          ]}
          notes="S12 Khu demo Firebase, row Thông báo đẩy (FCM). First tap asks Android for POST_NOTIFICATIONS. After a refusal the row explains why and offers Mở cài đặt, which opens the system page for this app. FirebaseMessagingService.permission() and requestPermission()."
        />

        <Page
          title="Cloud Messaging · Delivery"
          line="One message, three app states. Sent with the FCM HTTP v1 API."
          images={[
            { src: 'app/fcm-foreground.png', alt: 'Heads-up notification while the app is open', wide: true, caption: 'Foreground' },
            { src: 'app/fcm-background.png', alt: 'Notification in the shade while the app is in the background', wide: true, caption: 'Background' },
            { src: 'app/fcm-terminated.png', alt: 'Notification in the shade while the app is closed', wide: true, caption: 'Terminated' },
          ]}
          notes="Foreground: Android shows nothing on its own, so the app shows a heads-up with flutter_local_notifications. Background and terminated: the system tray shows it; tapping reaches onMessageOpenedApp or getInitialMessage. Sent from the terminal with an access token from gcloud to the device token printed in the debug log."
        />

        <Page
          title="Cloud Messaging · Inbox"
          line="Each message is stored with the state it arrived in."
          images={[{ src: 'app/fcm-inbox.png', alt: 'Inbox sheet listing three notifications', crop: true }]}
          notes="Inbox sheet in S12. Newest first: Từ nền, App đã tắt, Đang mở app. Stored locally in shared_preferences (fcm_inbox, last 50)."
        />

        <Page
          title="Analytics"
          line="Measures the 30-second goal, with no personal data."
          todo="Console DebugView not captured: the Analytics property is not linked yet. The event above is from the device log."
          notes="AnalyticsService is an interface; FirebaseAnalyticsService logs to the real project, DebugAnalyticsService prints on the Emulator. Events: login, logout, note_saved (mood, note_type, has_journal, duration_ms), challenge_completed, report_exported, plus screen_view by route pattern. No titles, bodies, emails or group names. Unit tests assert the parameters. Evidence: adb logcat with debug.firebase.analytics.app set."
        >
          <pre className="log">{`$ adb shell setprop debug.firebase.analytics.app com.quanphungg.lab03

FA-SVC  Logging event: name=note_saved
        params={mood=vui, note_type=chien_thang,
                has_journal=false, duration_ms=13339}`}</pre>
          <p className="flow">13.3 s to save · goal under 30 s</p>
        </Page>

        <Page
          title="Crashlytics"
          line="Errors are recorded, and users still see a message."
          images={[{ src: 'app/crash-test.png', alt: 'Settings: test crash sent' }]}
          todo="The non-fatal path (note save failure) is coded but was not triggered on the device."
          notes="Test crash from S12 Khu demo Firebase (dev builds only). The report is enqueued and sent through Google DataTransport. recordError is also called when saving a note fails and when profile creation fails. Evidence: adb logcat with log.tag.FirebaseCrashlytics set to DEBUG."
        >
          <pre className="log">{`D/FirebaseCrashlytics: Enqueueing report: 6AE8A8BF...
D/FirebaseCrashlytics: Crashlytics report successfully
                       enqueued to DataTransport`}</pre>
        </Page>

        <Page
          title="Crashlytics · Console"
          line="A test crash and a real error, grouped by issue."
          images={[{ src: 'app/console-crashlytics.png', alt: 'Crashlytics dashboard with two open issues', full: true }]}
          notes="Crashlytics dashboard of prm393-not-lab3 on 2 Nov: 15 crashes, 1 user. SettingsScreen.build: Crashlytics test crash (2 events) is the test button. Hero._allHeroesFor: multiple heroes share the same tag (13 events) is a real defect found by the dashboard, not triggered on purpose."
        />

        <Page
          title="Cloud Firestore"
          line="challenges/{id}: 22 cards, read-only for users, seeded by script (D-10)."
          images={[{ src: 'app/console-firestore.png', alt: 'Firestore console showing challenges/dc-1-1', full: true }]}
          notes="Console view of challenges/dc-1-1: topic dung_cam, level 1, minutes 1, title, script and tip. The collection is seeded with firebase/scripts/seed-challenges.js from firebase/seed/challenges.json; Security Rules allow reads only."
        />

        <Page
          title="Remote Config"
          line="Change it in the Console, no rebuild. Defaults on failure."
          images={[
            { src: 'app/rc-before.png', alt: 'Settings before: milestone 25, first chip Dọn phòng', crop: true },
            { src: 'app/rc-after.png', alt: 'Settings after: milestone 10, first chip Uống đủ nước', crop: true },
          ]}
          notes="FirebaseRemoteConfigService sets in-app defaults, then fetches on launch. Before: milestone 25, chips start with Dọn phòng. After publishing in the Console and tapping the Remote Config row: milestone 10, chips start with Uống đủ nước. A failed fetch keeps the defaults. Parameters: quick_win_chips, monthly_milestone, discord_*, firebase_demo_enabled. Template: firebase/remoteconfig.template.json."
        />

        <Page
          title="ARTEMIS E2E"
          line="≥ 10 cases · error path · native step · exploratory · ≥ 3 runs each"
          shots={['Test plan', 'Pass rates', 'Trace']}
          todo="e2e_test/ scaffold and smoke test exist; no run results yet (needs a model API key). Missing: test-plan.md."
          notes="Cover F1, F2, F3, sign-in, 4 tabs, PDF export, sign-out. Compare the values the agent reports, not only SUCCESS. Fill in from real runs only; explain every flaky, failed or skipped test. Link docs/test-plan.md."
        />

        <Page
          title="AI code review"
          line="AI finds. We decide."
          shots={['Finding · Decision · Reason · Commit']}
          todo="Not done yet"
          notes="Needs at least 5 findings across 2 kinds and 3 fix commits. Link docs/code-review.md."
        />

        <Page
          title="Lessons learned"
          line="Record each deviation as it happens."
          notes="Examples: the Emulator has no real Analytics or Crashlytics; D-11, two Lab 2 documents conflicted; D-26 and D-28 changed labels after users misread them. Add challenges from the test stage. AI disclosure: Claude Code for brief analysis and slides; add other tools. Links must open in a private window."
        >
          <p className="foot">Repo · docs/ · evidence/ · Video · AI tools: Claude Code · [add others]</p>
        </Page>
      </Deck>
    </div>
  );
}
