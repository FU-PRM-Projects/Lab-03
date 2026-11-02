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

type GalleryItem = {
  src: string;
  alt: string;
  caption?: string;
  /** CSS aspect-ratio plus cover crop, for tall phone screenshots cut to a band. */
  ratio?: string;
  pos?: string;
};

/** A small grid of screenshots with one-line captions. */
function Gallery({ items, cols, height }: { items: GalleryItem[]; cols: number; height: number }) {
  return (
    <div className="gallery" style={{ gridTemplateColumns: `repeat(${cols}, 1fr)` }}>
      {items.map(({ src, alt, caption, ratio, pos }) => (
        <figure key={src}>
          <img
            src={`${import.meta.env.BASE_URL}${src}`}
            alt={alt}
            style={
              ratio
                ? { aspectRatio: ratio, objectFit: 'cover', objectPosition: pos ?? '50% 50%' }
                : { height }
            }
          />
          {caption && <figcaption>{caption}</figcaption>}
        </figure>
      ))}
    </div>
  );
}

type Pair = { screen: string; title: string; diffs: string[] };

/** Figma frame and app screen side by side for three screens, with short notes. */
function CompareTriple({ pairs }: { pairs: Pair[] }) {
  const base = import.meta.env.BASE_URL;
  return (
    <div className="triple">
      {pairs.map(({ screen, title, diffs }) => (
        <div key={screen} className="triple-col">
          <h3>{title}</h3>
          <div className="triple-imgs">
            <figure>
              <img src={`${base}figma/${screen.toLowerCase()}.png`} alt={`${screen} in Figma`} />
              <figcaption>Figma</figcaption>
            </figure>
            <figure>
              <img src={`${base}app/${screen.toLowerCase()}.png`} alt={`${screen} in the app`} />
              <figcaption>App</figcaption>
            </figure>
          </div>
          <ul>
            {diffs.map((d) => (
              <li key={d}>{d}</li>
            ))}
          </ul>
        </div>
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
  dense,
  children,
}: {
  title: string;
  line?: string;
  todo?: string;
  shots?: string[];
  images?: ShotImage[];
  notes: string;
  dense?: boolean;
  children?: ReactNode;
}) {
  return (
    <Slide notes={notes} className={dense ? 'dense' : undefined}>
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
          notes="Nốt is built for Minh. Lab 2 success criterion: log a mood and one win in under 30 seconds after tapping the evening notification."
        >
          <p className="intro">
            Tiny Wins (Nốt) is a mobile app for burned-out final-year students like Minh (22): every evening they
            drop one small win into a jar instead of staring at an unfinished to-do list. After a
            rough day, the jar hands back an old win to remember. Small bravery and movement
            challenges, a one-tap self-control log and a guided journal help them rebuild
            confidence, one note at a time. Success criterion: log a mood and one win in under 30
            seconds.
          </p>
        </Page>

        <Page
          dense
          title="Figma vs app"
          notes="Three screens, Figma on the left and the running app on the right. D-xx ids are in docs/design-traceability.md, section 5. S03b free-tell with AI is planned and not built. The Stats screenshot comes from a test account with a few notes."
        >
          <CompareTriple
            pairs={[
              {
                screen: 'S02',
                title: 'Today',
                diffs: [
                  'Android status bar (D-04)',
                  'New shortcut icons and captions (D-25)',
                  '"Ghi nốt" asks win or journal first (D-29)',
                ],
              },
              {
                screen: 'S03b',
                title: 'Write a note',
                diffs: [
                  '"Bỏ qua nhật ký" is now "Bỏ qua phần kể thêm" (D-28)',
                  '0/120 counter under the field (D-02)',
                  'AI free-tell is planned, not built',
                ],
              },
              {
                screen: 'S11b',
                title: 'Stats',
                diffs: [
                  'Compared with the previous 30 days (D-18)',
                  'Chart scales to the card width (D-09)',
                  'Weekly goal opens the weekly card (D-06)',
                ],
              },
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
          dense
          title="Authentication"
          images={[
            { src: 'app/welcome.png', alt: 'Welcome screen with Google and email sign-in' },
            { src: 'app/welcome-cancelled.png', alt: 'Welcome screen after cancelling: Bạn đã huỷ đăng nhập.' },
          ]}
          notes="Google and email sign-in. authStateChanges drives the router: signed-out users go to /welcome and the destination is kept through next. Cancelling the account chooser shows Bạn đã huỷ đăng nhập. The chooser itself is not shown because it displays a real name and email. Sign-out clears local data. Console check by CLI: firebase auth:export returned 1 account with provider google.com."
        >
          <pre className="log">{`$ firebase auth:export users.json
Exported 1 account(s) · provider: google.com

Cancel   → "Bạn đã huỷ đăng nhập."
Offline  → "Không có mạng. Kiểm tra Wi-Fi rồi thử lại."
Sign out → local data cleared, back to /welcome`}</pre>
        </Page>

        <Page
          dense
          title="Cloud Messaging"
          notes="Row 1: permission denied prompt with Mở cài đặt, the system notification page, the inbox listing the three delivery states, and a tap on a message with data route=/jar landing on the jar. Row 2: foreground (heads-up from flutter_local_notifications), background and terminated (system tray), and a test message sent from the Firebase Console. Sent with the FCM HTTP v1 API and from Console, Messaging, Send test message, to the device token printed in the debug log (the token is not stored in the repo). routeFromData only accepts allow-listed internal routes."
        >
          <Gallery
            cols={4}
            height={260}
            items={[
              { src: 'app/fcm-denied.png', alt: 'Prompt asking to open settings', caption: 'Denied → open settings', ratio: '0.95', pos: '50% 38%' },
              { src: 'app/fcm-os-settings.png', alt: 'Android notification settings', caption: 'System settings', ratio: '0.95', pos: '50% 36%' },
              { src: 'app/fcm-inbox.png', alt: 'Inbox with three notifications', caption: 'Inbox: 3 states', ratio: '0.95', pos: '50% 18%' },
              { src: 'app/fcm-route.png', alt: 'Jar screen opened from a notification', caption: 'Tap · route=/jar', ratio: '0.95', pos: '50% 20%' },
            ]}
          />
          <Gallery
            cols={4}
            height={100}
            items={[
              { src: 'app/fcm-foreground.png', alt: 'Foreground heads-up', caption: 'Foreground' },
              { src: 'app/fcm-background.png', alt: 'Background notification', caption: 'Background' },
              { src: 'app/fcm-terminated.png', alt: 'Terminated notification', caption: 'Terminated' },
              { src: 'app/fcm-console.png', alt: 'Message sent from the Firebase Console', caption: 'Sent from Console' },
            ]}
          />
        </Page>

        <Page
          dense
          title="Analytics"
          notes="docs/analytics-plan.md lists each event with its trigger, parameter types, Lab 2 flow and product question. DebugView shows the live stream from the emulator (debug.firebase.analytics.app). The text below is from adb logcat on the same run; every event fired except report_exported, which only fires after a successful upload and the Storage bucket is not provisioned. DebugView lists the top seven names, so login and self_control_logged are only in the log."
        >
          <div className="half">
            <figure className="half-img">
              <img
                src={`${import.meta.env.BASE_URL}app/console-analytics.png`}
                alt="DebugView with screen_view, note_saved and challenge events"
              />
              <figcaption>DebugView · top events of one run on the emulator</figcaption>
            </figure>
            <div className="half-text">
              <p>
                Eight custom events go through an <code>AnalyticsService</code> interface (Firebase
                in the app, a console logger on the Emulator). No titles, note text, emails or
                names are logged. The Firebase user ID is set after sign-in and cleared on sign-out.
              </p>
              <ul>
                <li>
                  <b>login / logout</b> · <code>method</code>
                </li>
                <li>
                  <b>note_saved</b> · <code>mood, note_type, has_journal, duration_ms</code>. Tracks
                  the 30-second goal: 7.7 s in this run.
                </li>
                <li>
                  <b>note_viewed</b> · <code>note_type</code>
                </li>
                <li>
                  <b>challenge_opened / challenge_completed</b> · <code>challenge_id, note_type</code>
                </li>
                <li>
                  <b>self_control_logged</b> · <code>has_habit</code>
                </li>
                <li>
                  <b>report_exported</b> · <code>format</code>. Fires after a successful upload, so
                  it needs the Storage bucket.
                </li>
              </ul>
              <p>
                Checked three ways: DebugView (left), <code>adb logcat</code> for all events except
                report_exported, and unit tests that assert the parameters.
              </p>
            </div>
          </div>
        </Page>

        <Page
          dense
          title="Crashlytics"
          notes="Report export fails in the real flow because the Storage bucket is not provisioned: the user sees Chưa tạo được thẻ tuần. Thử lại nhé. and WeeklyReportViewModel records a non-fatal (reason report_export). Console: the non-fatal issue FirebaseStorageService.uploadReport, its Keys tab (screen=/journey) and Data tab (User ID). The dashboard also shows the test crash from the dev-only button and a real Hero error found by the dashboard and fixed (heroTag null on the add-note button)."
        >
          <Gallery
            cols={2}
            height={215}
            items={[
              { src: 'app/report-error.png', alt: 'App showing the export error message', caption: 'User still sees a message', ratio: '2.9', pos: '50% 94%' },
              { src: 'app/console-crash-nonfatal.png', alt: 'Console non-fatal issue', caption: 'Non-fatal in Console' },
              { src: 'app/console-crash-keys.png', alt: 'Custom key and user ID', caption: 'Key screen · user ID' },
              { src: 'app/console-crashlytics.png', alt: 'Dashboard with the test crash and the Hero error', caption: 'Test crash + a real Hero error' },
            ]}
          />
        </Page>

        <Page
          dense
          title="Remote Config"
          notes="Remote Config as feature flags. custom_challenges_enabled hides the add-your-own-card button on the Challenges tab; groups_enabled hides the first-time groups shelf on the jar; firebase_demo_enabled hides the Firebase demo area in Settings. Each flag has an in-app default (on), so a failed or empty fetch keeps every feature available. The values are published from firebase/remoteconfig.template.json with firebase deploy --only remoteconfig and fetched at launch (fetch interval zero in debug, one hour in release); activated values stay cached until the next fetch. Before: both flags on. After: both off, same app build, no rebuild."
        >
          <Gallery
            cols={4}
            height={330}
            items={[
              { src: 'app/rc-jar-before.png', alt: 'Jar with the first-time groups shelf', caption: 'groups_enabled = true' },
              { src: 'app/rc-jar-after.png', alt: 'Jar without the shelf', caption: 'groups_enabled = false' },
              { src: 'app/rc-challenges-before.png', alt: 'Challenges tab with the add button', caption: 'custom_challenges_enabled = true' },
              { src: 'app/rc-challenges-after.png', alt: 'Challenges tab without the add button', caption: 'custom_challenges_enabled = false' },
            ]}
          />
          <Gallery
            cols={1}
            height={150}
            items={[{ src: 'app/console-remoteconfig.png', alt: 'Remote Config feature flags in the Console', caption: 'Console · three feature flags' }]}
          />
        </Page>

        <Page
          title="ARTEMIS E2E"
          shots={['Test plan', 'Pass rates', 'Trace']}
          todo="e2e_test/ scaffold and smoke test exist; no run results yet (needs a model API key). Missing: test-plan.md."
          notes="Cover F1, F2, F3, sign-in, 4 tabs, PDF export, sign-out. Compare the values the agent reports, not only SUCCESS. Fill in from real runs only; explain every flaky, failed or skipped test. Link docs/test-plan.md."
        />

        <Page
          title="AI code review"
          shots={['Finding · Decision · Reason · Commit']}
          todo="Not done yet"
          notes="Needs at least 5 findings across 2 kinds and 3 fix commits. Link docs/code-review.md."
        />

        <Page
          title="Lessons learned"
          notes="Examples: the Emulator has no real Analytics or Crashlytics; D-11, two Lab 2 documents conflicted; D-26 and D-28 changed labels after users misread them. Add challenges from the test stage. AI disclosure: Claude Code for brief analysis and slides; add other tools. Links must open in a private window."
        >
          <p className="foot">Repo · docs/ · evidence/ · Video · AI tools: Claude Code · [add others]</p>
        </Page>
      </Deck>
    </div>
  );
}
