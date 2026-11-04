import type { ReactNode } from 'react';
import { Deck, Slide } from '@revealjs/react';
import RevealNotes from 'reveal.js/plugin/notes';
import {
  BellRing,
  Bot,
  Cloud,
  FileStack,
  GitPullRequest,
  Tag,
  Bug,
  ChartColumn,
  CloudUpload,
  Database,
  KeyRound,
  SlidersHorizontal,
} from 'lucide-react';

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

/** FPT University logo, top right of each page (top left on the cover). */
function OrgLogo({ cover }: { cover?: boolean }) {
  return (
    <img
      className={cover ? 'org-logo cover' : 'org-logo'}
      src={`${import.meta.env.BASE_URL}assets/fpt-logo.webp`}
      alt="FPT University"
    />
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
      <OrgLogo />
      <h2>{title}</h2>
      {line && <p className="line">{line}</p>}
      <div className="page-body">
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
      </div>
      {todo && <p className="todo">{todo}</p>}
    </Slide>
  );
}

function Flow({ steps }: { steps: string[] }) {
  return <p className="flow">{steps.join('  →  ')}</p>;
}

type ArchBox = { x: number; y: number; w: number; title: string; sub: string; dim?: boolean; n?: number };

const ARCH_BOXES: ArchBox[] = [
  { x: 20, y: 44, w: 150, title: 'screens/', sub: 'S01 … S12', n: 1 },
  { x: 205, y: 44, w: 150, title: 'widgets/', sub: 'shared components', n: 2 },
  { x: 390, y: 44, w: 150, title: 'theme/', sub: 'design tokens', n: 3 },
  { x: 190, y: 160, w: 180, title: 'ViewModel', sub: 'Notifier + ViewState<T>', n: 4 },
  { x: 190, y: 260, w: 180, title: 'Service', sub: 'interfaces + Providers', n: 5 },
  { x: 190, y: 370, w: 180, title: 'Implementation', sub: 'firebase/ · 15 classes', n: 6 },
  { x: 190, y: 480, w: 180, title: 'Firebase SDK', sub: 'Auth · Firestore · …', dim: true },
  { x: 430, y: 370, w: 130, title: 'main.dart', sub: 'composition root', dim: true, n: 7 },
];

function Badge({ x, y, n }: { x: number; y: number; n: number }) {
  return (
    <g>
      <circle cx={x + 2} cy={y + 2} r="13" fill="#e5262b" />
      <text x={x + 2} y={y + 7} textAnchor="middle" fontSize="14" fontWeight="700" fill="#fff">
        {n}
      </text>
    </g>
  );
}

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
      <Badge x={0} y={590} n={8} />

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
          {b.n && <Badge x={b.x} y={b.y} n={b.n} />}
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

/** Cắt một vùng của ảnh chụp: [x, y] và kích thước tính theo px CSS của ảnh gốc. */
function Crop({
  src,
  alt,
  natural,
  x = 0,
  y = 0,
  w,
  h,
  scale,
}: {
  src: string;
  alt: string;
  natural: number;
  x?: number;
  y?: number;
  w: number;
  h: number;
  scale: number;
}) {
  return (
    <div className="crop" style={{ width: w * scale, height: h * scale }}>
      <img src={src} alt={alt} style={{ width: natural * scale, marginLeft: -x * scale, marginTop: -y * scale }} />
    </div>
  );
}

/** Ảnh chụp code thật trên GitHub (nhánh main), số khớp với sơ đồ MVVM. */
function CodeShot({ n, layer, file, shot }: { n: number; layer: string; file: string; shot: string }) {
  return (
    <figure className="cs">
      <figcaption>
        <em>{n}</em>
        <b>{layer}</b>
        <code>lib/{file}</code>
      </figcaption>
      <img src={`code/${shot}.png`} alt={`${layer}: lib/${file} on GitHub, key lines marked in red`} />
    </figure>
  );
}

type Finding = {
  shot: string;
  where: string;
  kind: string;
  found: string;
  decision: 'Fixed' | "Won't fix" | 'Rejected';
  detail: string;
  commit?: string;
};

function ReviewFinding({ f }: { f: Finding }) {
  const tone = f.decision === 'Fixed' ? 'ok' : f.decision === 'Rejected' ? 'no' : 'skip';
  return (
    <div className="rv">
      <img className="rv-shot" src={`review/${f.shot}.png`} alt={`CodeRabbit comment: ${f.found}`} />
      <div className="rv-notes">
        <p>
          <em>1</em>
          <b>Where</b>
          {f.where}
        </p>
        <p>
          <em>2</em>
          <b>Kind</b>
          {f.kind}
        </p>
        <p>
          <em>3</em>
          <b>Found</b>
          {f.found}
        </p>
      </div>
      <span className="rv-arrow">→</span>
      <div className={`rv-decision rv-${tone}`}>
        <b>{f.decision}</b>
        {f.commit && <code>{f.commit}</code>}
        <span>{f.detail}</span>
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
          <OrgLogo cover />
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
          title="Overview"
          line="From the Lab 2 design to a cloud-connected Flutter app"
          notes="Read left to right, this is how Lab 3 was built. One: start from the Lab 2 Figma design, all 12 screens and flows F1 to F3, including error states. Two: keep MVVM with Riverpod, so screens talk to ViewModels, ViewModels to services, and only lib/firebase imports the SDK. Three: wire in seven Firebase services, Auth, Firestore, Storage, Analytics, Crashlytics, Remote Config and Cloud Messaging, and tell the user in plain words when something fails. Four: back every claim with evidence someone else can check: Console screenshots, logs, ARTEMIS runs, all in evidence/."
        >
          <div className="stages">
            <figure className="st">
              <div className="st-vis">
                <img className="st-phone" src="figma/s02.png" alt="S02 Today in the Lab 2 Figma file" />
                <div className="st-map">
                  <span>S02 Hôm nay</span>↓<code>/today</code>↓<code>TodayScreen</code>↓
                  <code>TodayViewModel</code>
                </div>
              </div>
              <figcaption>
                <b><em>1</em> Lab 2 design → code</b>
                <span>Each Figma screen mapped to a route, Screen and ViewModel</span>
              </figcaption>
            </figure>
            <span className="st-arrow">→</span>
            <figure className="st">
              <div className="st-vis st-layers">
                <span>
                  <small>View</small>TodayScreen
                </span>
                <span>
                  <small>ViewModel · Riverpod</small>TodayViewModel
                </span>
                <span>
                  <small>Service · interface</small>NoteRepository
                </span>
                <span className="st-fb">
                  <small>Firebase · lib/firebase</small>FirestoreNoteRepository
                </span>
              </div>
              <figcaption>
                <b><em>2</em> MVVM</b>
                <span>Screens never touch the SDK; only lib/firebase does</span>
              </figcaption>
            </figure>
            <span className="st-arrow">→</span>
            <figure className="st">
              <div className="st-vis">
                <img className="st-phone" src="app/welcome.png" alt="Sign-in screen with Google and email" />
                <div className="st-chips">
                  {(
                    [
                      [KeyRound, 'Auth'],
                      [Database, 'Firestore'],
                      [CloudUpload, 'Storage'],
                    ] as const
                  ).map(([Icon, name]) => (
                    <i key={name}>
                      <Icon size={14} strokeWidth={2.2} />
                      {name}
                    </i>
                  ))}
                </div>
              </div>
              <figcaption>
                <b><em>3</em> Firebase, round 1</b>
                <span>Sign-in, notes in Firestore, weekly PDF to Storage</span>
              </figcaption>
            </figure>

            <figure className="st">
              <div className="st-vis st-trio">
                {[
                  ['app/s02.png', 'S02'],
                  ['app/s03b.png', 'S03'],
                  ['app/artemis-challenge.jpg', 'S07'],
                ].map(([src, label]) => (
                  <span key={label}>
                    <img src={src} alt={`${label} in the running app`} />
                    {label}
                  </span>
                ))}
              </div>
              <figcaption>
                <b><em>4</em> Features</b>
                <span>All 12 screens; flows F1 to F3 with their error states</span>
              </figcaption>
            </figure>
            <span className="st-arrow">→</span>
            <figure className="st">
              <div className="st-vis st-col">
                <img className="st-wide" src="app/fcm-foreground.png" alt="FCM notification while the app is open" />
                <div className="st-chips st-chips-row">
                  {(
                    [
                      [ChartColumn, 'Analytics'],
                      [Bug, 'Crashlytics'],
                      [SlidersHorizontal, 'Remote Config'],
                      [BellRing, 'FCM'],
                    ] as const
                  ).map(([Icon, name]) => (
                    <i key={name}>
                      <Icon size={14} strokeWidth={2.2} />
                      {name}
                    </i>
                  ))}
                </div>
              </div>
              <figcaption>
                <b><em>5</em> Firebase, round 2</b>
                <span>Events, crashes, feature flags and push messages</span>
              </figcaption>
            </figure>
            <span className="st-arrow">→</span>
            <figure className="st">
              <div className="st-vis st-col">
                <img className="st-wide" src="app/console-analytics.png" alt="Analytics DebugView in the Firebase Console" />
                <img className="st-wide" src="app/console-crash-keys.png" alt="Crashlytics issue with user ID and custom keys" />
              </div>
              <figcaption>
                <b><em>6</em> Evidence</b>
                <span>Console, DebugView, Crashlytics, ARTEMIS · evidence/</span>
              </figcaption>
            </figure>
          </div>
        </Page>

        <Page
          title="Design system"
          notes="Tokens live in lib/theme, components in lib/widgets. Example: AppButton has 5 variants and 4 states."
        >
          <DesignSystem />
        </Page>

        <Page
          title="Meet Tụi Nốt and the jar"
          line="Eight mascot moods and one jar that fills up with your wins"
          notes="Tụi Nốt are the app's mascots: one sticky-note character in 8 states, exported as SVG from Lab 2 (DESIGN.md section 9) and drawn by the Mascot widget. Each mood a user picks has its own face, so mood is never shown by colour alone: Vui is Nốt Xong, Ổn is Thong Thả, Bình thường is Đợi, Mệt is Ngủ, Rối is Lạc. The same characters mark app states: Đợi for loading and empty, Lạc for errors, Ngủ when the AI is resting. Vội and Cháy are in the design system but not on a screen yet. The jar (Hũ chiến thắng) is the app's core metaphor: every saved note drops in as a slip coloured by its type, the 8 newest are shown, and the number next to it counts this month's notes. It appears on Today, after saving a note and on the Jar tab."
        >
          <div className="cast">
            <div className="cast-grid">
              {[
                ['xong', 'Nốt Xong', 'A win saved · Vui'],
                ['thong-tha', 'Nốt Thong Thả', 'Welcome, breathing · Ổn'],
                ['doi', 'Nốt Đợi', 'Loading, empty · Bình thường'],
                ['ngu', 'Nốt Ngủ', 'AI resting · Mệt'],
                ['lac', 'Nốt Lạc', 'Errors · Rối'],
                ['tap-trung', 'Nốt Tập Trung', 'Challenges, self-control'],
                ['voi', 'Nốt Vội', 'Design system only'],
                ['chay', 'Nốt Cháy', 'Design system only'],
              ].map(([file, name, role]) => (
                <figure key={file}>
                  <img src={`assets/mascot/mascot-not-${file}.svg`} alt={name} />
                  <figcaption>
                    <b>{name}</b>
                    <span>{role}</span>
                  </figcaption>
                </figure>
              ))}
            </div>
            <div className="cast-jar">
              <img src="assets/illustrations/jar.svg" alt="Hũ chiến thắng with coloured note slips" />
              <ul>
                <li>
                  <b>Hũ chiến thắng:</b> every saved note drops in as a slip
                </li>
                <li>Slip colour shows the type: Chiến thắng, Tự chủ, Thử thách, Nhật ký</li>
                <li>Shows the 8 newest; the number counts this month's notes</li>
                <li>Each mood has its own face, so mood is not shown by colour alone</li>
              </ul>
            </div>
          </div>
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
          dense
          title="MVVM in the code: View → ViewModel"
          line="S02 Today on GitHub (main). Numbers match the MVVM diagram"
          notes="Real source on GitHub, branch main, for screen S02 Today. One, screens: TodayScreen.build only watches todayViewModelProvider and switches on its state. Two, widgets: AppButton is the shared button component, used by every screen. Three, theme: AppSpace holds the spacing tokens, so screens never hard-code numbers. Four, ViewModel: todayViewModelProvider is a Riverpod NotifierProvider, and TodayViewModel extends Notifier of ViewState."
        >
          <div className="cs-grid">
            <CodeShot n={1} layer="screens/" file="screens/today/today_screen.dart" shot="screens" />
            <CodeShot n={2} layer="widgets/" file="widgets/app_button.dart" shot="widgets" />
            <CodeShot n={3} layer="theme/" file="theme/app_tokens.dart" shot="theme" />
            <CodeShot n={4} layer="ViewModel" file="viewmodels/today_view_model.dart" shot="viewmodel" />
          </div>
        </Page>

        <Page
          dense
          title="MVVM in the code: Service → Firebase"
          line="The data side of S02 Today. Only lib/firebase imports the Firebase SDK"
          notes="Five, Service: NoteRepository is an abstract interface; the ViewModel only knows this. Six, Implementation: FirestoreNoteRepository implements it with FirebaseFirestore. Seven, main.dart: the composition root overrides noteRepositoryProvider with the Firestore version; tests override it with a fake. Eight, models: Note is plain Dart, shared by every layer. A grep finds no Firebase import in lib/screens, lib/widgets or lib/viewmodels."
        >
          <div className="cs-grid">
            <CodeShot n={5} layer="Service" file="services/note_repository.dart" shot="service" />
            <CodeShot n={6} layer="Implementation" file="firebase/firestore_note_repository.dart" shot="implementation" />
            <CodeShot n={7} layer="main.dart" file="main.dart" shot="main" />
            <CodeShot n={8} layer="models/" file="models/note.dart" shot="models" />
          </div>
          <p className="cc-proof">
            <code>$ grep -rl "package:firebase" lib/screens lib/widgets lib/viewmodels</code>
            <span>→ 0 files</span>
          </p>
        </Page>

        <Page
          dense
          title="Authentication"
          line="Google Sign-In; the router follows auth state; sign-out clears the device"
          notes="Left: the router follows auth state. Signed out, any route redirects to /welcome with Google and email sign-in; signed in, /welcome redirects to /today. Cancelling the Google account chooser shows Bạn đã huỷ đăng nhập. The chooser itself is not shown because it displays a real name and email. Right, top: the Firebase Console of project Not - PRM393 Lab 3 (prm393-not-lab3), Authentication, Users tab: three accounts, all with the Google provider, emails hidden. Right, below: auth_redirect.dart decides the route from auth state, and signOut clears cached Firestore data, the note draft and the FCM inbox on this device."
        >
          <div className="au">
            <div className="au-phones">
              <figure>
                <img src="app/welcome.png" alt="Signed out: welcome screen with Google and email sign-in" />
                <figcaption>
                  <b>Signed out</b> → /welcome
                </figcaption>
              </figure>
              <span className="au-arrow">→</span>
              <figure>
                <img src="app/s02.png" alt="Signed in: Today screen" />
                <figcaption>
                  <b>Signed in</b> → /today
                </figcaption>
              </figure>
              <figure className="au-cancel">
                <img src="app/welcome-cancelled.png" alt="Cancelled sign-in: Bạn đã huỷ đăng nhập." />
                <figcaption>
                  <b>Cancelled</b> → message
                </figcaption>
              </figure>
            </div>
            <div className="au-side">
              <figure>
                <figcaption>
                  <b>Console</b> · Authentication › Users
                </figcaption>
                <div className="au-console">
                  <Crop
                    src="app/console-auth-users.png"
                    alt="Firebase Console header: project Not - PRM393 Lab 3, Authentication, Users tab"
                    natural={1810}
                    y={4}
                    w={1040}
                    h={128}
                    scale={0.45}
                  />
                  <Crop
                    src="app/console-auth-users.png"
                    alt="Users table: three accounts signed in with Google, emails hidden"
                    natural={1810}
                    x={490}
                    y={455}
                    w={1310}
                    h={250}
                    scale={0.357}
                  />
                </div>
              </figure>
              <figure>
                <figcaption>
                  <b>Routes by auth state</b> <code>lib/router/auth_redirect.dart</code>
                </figcaption>
                <Crop
                  src="code/redirect.png"
                  alt="auth_redirect.dart: signed out goes to welcome, signed in leaves welcome"
                  natural={620}
                  y={22}
                  w={620}
                  h={114}
                  scale={0.75}
                />
              </figure>
              <figure>
                <figcaption>
                  <b>Sign-out clears local data</b> <code>auth_view_model.dart</code>
                </figcaption>
                <Crop
                  src="code/signout.png"
                  alt="signOut clears local data, the draft and the FCM inbox"
                  natural={620}
                  y={22}
                  w={620}
                  h={174}
                  scale={0.75}
                />
              </figure>
            </div>
          </div>
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
          title="Cloud Messaging: requirements met"
          line="Each Lab 3 requirement for FCM, and the screenshot that proves it"
          notes="One: the same push arrives in all three app states. Foreground is shown by the app itself with flutter_local_notifications, because Android does not show FCM banners while the app is open; background and terminated go to the system tray. Two: on Android 13 and later the app asks for POST_NOTIFICATIONS; if the user said no, Settings explains it and opens the system page. Three: every message is saved to an inbox on the device, listing which state it arrived in. Four: a message carries data route, here /jar, and tapping it opens that screen; only allow-listed routes are accepted. Five: a test message sent from the Firebase Console, Messaging, Send test message, reached the device. The three state messages were sent the same way and through the FCM HTTP v1 API."
        >
          <div className="fq">
            <figure className="fq-states">
              <figcaption>
                <i>✓</i>
                <b>Foreground · background · terminated</b>
              </figcaption>
              {[
                ['fcm-foreground', 'Foreground'],
                ['fcm-background', 'Background'],
                ['fcm-terminated', 'Terminated'],
              ].map(([shot, label]) => (
                <div key={shot} className="fq-strip">
                  <span>{label}</span>
                  <img src={`app/${shot}.png`} alt={`Notification received while the app is ${label.toLowerCase()}`} />
                </div>
              ))}
              <figcaption className="fq-sub">
                <i>✓</i>
                <b>Test message from the Console</b>
              </figcaption>
              <div className="fq-strip">
                <span>Console</span>
                <img src="app/fcm-console.png" alt="Test message sent from the Firebase Console reached the device" />
              </div>
            </figure>
            <figure>
              <figcaption>
                <i>✓</i>
                <b>Asks permission (Android 13+)</b>
              </figcaption>
              <img className="fq-phone" src="app/fcm-denied.png" alt="Permission denied: the app explains and opens settings" />
            </figure>
            <figure>
              <figcaption>
                <i>✓</i>
                <b>List of received notifications</b>
              </figcaption>
              <img className="fq-inbox" src="app/fcm-inbox.png" alt="In-app inbox listing notifications from all three states" />
            </figure>
            <figure>
              <figcaption>
                <i>✓</i>
                <b>Tap opens the screen</b>
              </figcaption>
              <img className="fq-phone" src="app/fcm-route.png" alt="Tapping a message with route /jar opens the jar" />
              <small>data route = /jar → Jar tab</small>
            </figure>
          </div>
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
          <div className="half">
            <Gallery
              cols={2}
              height={190}
              items={[
                { src: 'app/report-error.png', alt: 'App showing the export error message', caption: '1 · User still sees a message', ratio: '1.6', pos: '50% 94%' },
                { src: 'app/console-crash-nonfatal.png', alt: 'Console non-fatal issue', caption: '2 · Non-fatal in Console', ratio: '1.6', pos: '50% 50%' },
                { src: 'app/console-crash-keys.png', alt: 'Custom key and user ID', caption: '3 · Key screen · user ID', ratio: '1.6', pos: '0% 40%' },
                { src: 'app/console-crashlytics.png', alt: 'Dashboard with the test crash and the Hero error', caption: '4 · Test crash + a real Hero error', ratio: '1.6', pos: '50% 50%' },
              ]}
            />
            <div className="half-text">
              <p>
                Crashlytics collects errors from real devices, so we see problems the Emulator never
                shows. Two kinds reach the dashboard:
              </p>
              <ul>
                <li>
                  <b>Non-fatal</b>: the app caught the error and kept running. Exporting the weekly
                  card fails because the Storage bucket is not provisioned; the user sees
                  "Chưa tạo được thẻ tuần. Thử lại nhé." and the app records the error (1, 2).
                </li>
                <li>
                  <b>Context on every report</b>: the Firebase user ID and a custom key{' '}
                  <code>screen</code> (here <code>/journey</code>) show who hit it and where (3).
                </li>
                <li>
                  <b>Crash</b>: a dev-only "Thử crash" button sends a test crash. The same dashboard
                  also surfaced a real Hero error, caused by two add-note buttons sharing one tag. We
                  fixed it with <code>heroTag: null</code> (4).
                </li>
              </ul>
            </div>
          </div>
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
          dense
          title="ARTEMIS E2E"
          notes="ARTEMIS drives the real app on the Android 15 emulator through ADB. Model: deepseek-v4.1-flash via OpenRouter, Flash profile. 12 cases (T01 to T12) cover F1 write a note (main path, empty note, leave with a draft, offline), F2 self-control and breathing, F3 challenges, the four tabs, Settings (feature flags) and a native Android case (Home, notification shade, relaunch). Each case ran 3 times and asserts on the value the agent reports, not only on success. First full run: 31 of 36. Two failures came from wrong assertions in our tests (T05 run 3 accepted only an answer starting with DIALOG; T12 demanded the Today screen although the app correctly restores the previous screen). We fixed those and re-ran T05 and T12: 6 of 6. T06 run 3 timed out after 420 seconds in the offline case and stays a failure. Final: 35 of 36. Not done: the 15 to 30 minute exploratory session. Details and the table: docs/test-plan.md (branch feat/e2e-artemis); proofs in evidence/artemis/."
        >
          <div className="half">
            <Gallery
              cols={1}
              height={235}
              items={[{ src: 'app/artemis-workspace.jpg', alt: 'ARTEMIS Workspace with the agent timeline and run history', caption: 'ARTEMIS Workspace · agent steps and run history (44 runs)' }]}
            />
            <div className="half-text">
              <p>
                An AI agent (<code>deepseek-v4.1-flash</code> via OpenRouter) drives the app on the
                Android 15 emulator over ADB. Each case runs 3 times and asserts on the value the
                agent reports.
              </p>
              <ul>
                <li>
                  <b>12 cases:</b> F1 save, empty, draft dialog, offline · F2 · F3 · tabs · flags ·
                  native Home and relaunch
                </li>
                <li>
                  <b>35 of 36 runs pass.</b> T06 (offline) timed out once.
                </li>
                <li>
                  First run was 31 of 36: two assertions in our tests were wrong (fixed, re-run
                  6 of 6).
                </li>
                <li>Not done yet: the 15 to 30 minute exploratory session.</li>
              </ul>
            </div>
          </div>
          <Gallery
            cols={5}
            height={245}
            items={[
              { src: 'app/artemis-saved.jpg', alt: 'Saved note confirmation', caption: 'T02 · note saved' },
              { src: 'app/artemis-offline.jpg', alt: 'Offline banner after saving without network', caption: 'T06 · saved on device' },
              { src: 'app/artemis-dialog.jpg', alt: 'Keep draft dialog', caption: 'T05 · keep-draft dialog' },
              { src: 'app/artemis-delete.jpg', alt: 'Note deleted in the jar', caption: 'T03 · note deleted' },
              { src: 'app/artemis-challenge.jpg', alt: 'Challenge card', caption: 'T09 · challenge opened' },
            ]}
          />
        </Page>

        <Page
          dense
          title="AI code review"
          line="CodeRabbit reviewed every PR: 52 findings on #28, #29 and #38"
          notes="Three real screenshots, left to right. One: CodeRabbit reviews every PR on GitHub; here is its review on PR #38 with follow-up comments and an inline comment on the FCM service. It left 52 findings on #28, #29 and #38. Two: we checked every finding against the code and wrote a verdict in docs/code-review.md; 51 were technically right and 1 was wrong. Of the right ones, 40 are real bugs and 11 are not worth fixing for this Lab. Three: each fix is its own commit, and the message names the finding it addresses; 211a4d5, 736453a and 5e13651 are fixed so far. The next two slides zoom in on four findings."
        >
          <div className="pf">
            <figure>
              <Crop
                src="review/proof-review.png"
                alt="CodeRabbit review on PR #38 with follow-up and inline comments"
                natural={840}
                w={840}
                h={720}
                scale={0.62}
              />
              <figcaption>
                <b><em>1</em> CodeRabbit reviews every PR</b>
                <span>52 findings on #28, #29 and #38</span>
              </figcaption>
            </figure>
            <span className="pf-arrow">→</span>
            <div className="pf-right">
              <figure>
                <Crop
                  src="review/proof-verdicts.png"
                  alt="docs/code-review.md: the AI finding, our verdict and a note for each row"
                  natural={1328}
                  x={795}
                  w={533}
                  h={172}
                  scale={1.05}
                />
                <figcaption>
                  <b><em>2</em> We judge every finding</b>
                  <span>51 right, 1 wrong · verdicts in docs/code-review.md</span>
                </figcaption>
              </figure>
              <figure>
                <div className="pf-commits">
                  {(
                    [
                      ['736453a', 118],
                      ['5e13651', 146],
                    ] as const
                  ).map(([sha, h]) => (
                    <Crop
                      key={sha}
                      src={`review/proof-commit-${sha}.png`}
                      alt={`Fix commit ${sha} naming the CodeRabbit finding it addresses`}
                      natural={1609}
                      y={52}
                      w={560}
                      h={h}
                      scale={1}
                    />
                  ))}
                </div>
                <figcaption>
                  <b><em>3</em> We fix with a commit</b>
                  <span>3 fixed so far; each message names its finding</span>
                </figcaption>
              </figure>
            </div>
          </div>
        </Page>

        <Page
          dense
          title="AI review: what we fixed"
          line="Real CodeRabbit comments on PR #38, marked in red, and the commit that fixed each one"
          notes="Two real CodeRabbit comments from PR #38. Box 1 is the file and lines it commented on, box 2 the kind and severity it gave, box 3 what it found. The first is a privacy bug: the FCM inbox is stored on the device and survived sign-out, so the next account could read the previous user's notifications. Commit 736453a clears it on sign-out. The second broke an FCM requirement: a notification shown while the app is open had no payload, so tapping it opened nothing. Commit 5e13651 passes the route as the payload. Both fixes come with tests."
        >
          <div className="rv-pair">
            <ReviewFinding
              f={{
                shot: 'inbox',
                where: 'firebase_messaging_service.dart, lines 12–18',
                kind: 'Major · Security & Privacy',
                found: 'The FCM inbox survives sign-out, so the next account can read old notifications',
                decision: 'Fixed',
                commit: '736453a',
                detail: 'Sign-out clears the inbox and the open sheet reloads. Two tests.',
              }}
            />
            <ReviewFinding
              f={{
                shot: 'payload',
                where: 'firebase_messaging_service.dart, lines 83–85',
                kind: 'Minor · Functional Correctness',
                found: 'A notification shown while the app is open has no payload, so a tap opens nothing',
                decision: 'Fixed',
                commit: '5e13651',
                detail: 'The payload carries the route; tapping opens that screen. Two tests.',
              }}
            />
          </div>
        </Page>

        <Page
          dense
          title="AI review: what we did not fix"
          line="Every comment was checked against the code before deciding"
          notes="Two comments we did not act on, and why. The first is right for iOS: flutter_local_notifications needs Darwin settings there. But this app ships on Android and web only, firebase_options.dart has no iOS app, so we marked it won't fix; calling it Major was too strong for this project. The second is wrong: CodeRabbit says _saving is set but never read, so a fast double tap could add the same card twice. In fact canSubmit is !_saving && the title is not empty, and the button is disabled while saving. Out of 52 findings this was the only one that was wrong."
        >
          <div className="rv-pair">
            <ReviewFinding
              f={{
                shot: 'ios',
                where: 'firebase_messaging_service.dart, lines 64–68',
                kind: 'Major · Functional Correctness',
                found: 'Notification setup has no iOS (Darwin) settings, so it would fail on iOS',
                decision: "Won't fix",
                detail: 'Right for iOS, but the app ships on Android and web only. Major is too strong here.',
              }}
            />
            <ReviewFinding
              f={{
                shot: 'saving',
                where: 'create_challenge_sheet.dart, lines 75–83',
                kind: 'Minor · Functional Correctness',
                found: '_submit sets _saving but never reads it, so one tap could add two cards',
                decision: 'Rejected',
                detail: 'The AI is wrong: canSubmit = !_saving && … already disables the button while saving.',
              }}
            />
          </div>
        </Page>

        <Page
          title="Lessons learned"
          notes="Five lessons, one per stage that surprised us. Emulator: Stage 5 could only be checked on the real project. D-11: two Lab 2 documents set different title limits. D-28: users misread the journal label. ARTEMIS: the first run failed 5 of 36; 4 of those came from two wrong assertions in our tests, and only 1 (T06 offline timeout) was real. CodeRabbit: 51 of 52 findings were technically right, but only 1 of 40 real bugs was fixed before merge. AI disclosure: Claude Code, CodeRabbit, ARTEMIS with DeepSeek. Links must open in a private window."
        >
          <div className="ll">
            {(
              [
                [Cloud, 'Test on the real project early', 'Emulator has no Analytics or FCM'],
                [FileStack, 'Design docs can disagree', 'Pick one, log it · D-11'],
                [Tag, 'Rename what users misread', '"Bỏ qua phần kể thêm" · D-28'],
                [Bot, 'Check the AI tester too', '4 of 5 failures: our own asserts'],
                [GitPullRequest, 'Read AI review before merging', '1 of 40 bugs fixed at merge'],
              ] as const
            ).map(([Icon, head, tag], i) => (
              <div key={head}>
                <span className="ll-icon">
                  <Icon size={34} strokeWidth={1.8} />
                </span>
                <em>{i + 1}</em>
                <b>{head}</b>
                <small>{tag}</small>
              </div>
            ))}
          </div>
        </Page>

        <Slide className="thanks" notes="Thank the audience and invite questions. Have the repo, docs/ and evidence/ open in case the teacher wants to check something live.">
          <OrgLogo cover />
          <div className="thanks-cast">
            {['thong-tha', 'xong', 'tap-trung'].map((m) => (
              <img key={m} src={`assets/mascot/mascot-not-${m}.svg`} alt="" />
            ))}
          </div>
          <h1>Thank you!</h1>
        </Slide>
      </Deck>
    </div>
  );
}
