import type { ReactNode, SyntheticEvent } from 'react';
import { Deck, Slide } from '@revealjs/react';
import RevealNotes from 'reveal.js/plugin/notes';
import RevealZoom from 'reveal.js/plugin/zoom';
import {
  BellRing,
  Bot,
  Cloud,
  FileStack,
  GitPullRequest,
  Tag,
  Bug,
  ChartColumn,
  ImageUp,
  Database,
  KeyRound,
  Layers,
  SlidersHorizontal,
} from 'lucide-react';

import 'reveal.js/reveal.css';
import './slides.css';
import { technologies } from './lab3-technologies';

/** Slot for a real screenshot. Replace with <img> once evidence exists; never fill in assumed results. */
function Shot({ label }: { label: string }) {
  return <div className="shot">{label}</div>;
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
  id,
  title,
  line,
  todo,
  shots,
  images,
  notes,
  dense,
  children,
}: {
  id?: string;
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
    <Slide id={id} notes={notes} className={dense ? 'dense' : undefined}>
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

function TechImage({ image }: { image: [string, string] }) {
  const [path, caption] = image;
  return (
    <figure className={/^(code|review)\//.test(path) ? 'tech-image tech-image-code' : 'tech-image'}>
      <img src={`${import.meta.env.BASE_URL}${path}`} alt={caption} />
      <figcaption>{caption}</figcaption>
    </figure>
  );
}

const technologyIcons = {
  auth: KeyRound,
  firestore: Database,
  cloudinary: ImageUp,
  fcm: BellRing,
  analytics: ChartColumn,
  crashlytics: Bug,
  'remote-config': SlidersHorizontal,
  riverpod: Layers,
  artemis: Bot,
  coderabbit: GitPullRequest,
};

function TechHeading({ id, step }: { id: keyof typeof technologies; step: string }) {
  const Icon = technologyIcons[id];
  return (
    <>
      <OrgLogo />
      <p className="tech-step">{step}</p>
      <h2 className="tech-title"><Icon aria-hidden="true" />{technologies[id].name}</h2>
    </>
  );
}

/** Renders text with `backtick` spans as <code>. */
function rich(text: string): ReactNode {
  return text.split('`').map((part, i) => (i % 2 ? <code key={i}>{part}</code> : part));
}

const plain = (text: string) => text.replaceAll('`', '');

/** A screenshot that is not taken yet shows a grey slot instead of a broken image. */
function markMissing(e: SyntheticEvent<HTMLImageElement>) {
  e.currentTarget.closest('figure')?.classList.add('tech-missing');
}

/** HOW row: give each step a width in proportion to its screenshot, so all screenshots share one height. */
function fitByRatio(e: SyntheticEvent<HTMLImageElement>) {
  const { naturalWidth: w, naturalHeight: h } = e.currentTarget;
  const figure = e.currentTarget.closest('figure');
  if (figure && w && h) figure.style.flex = `${(w / h).toFixed(3)} 1 0`;
}

function TechnologySlides({ id }: { id: keyof typeof technologies }) {
  const { what, points, example, why, alternatives, how, setupTitle, setup, where, images } = technologies[id];
  const base = import.meta.env.BASE_URL;
  return [
    <Slide key={`${id}-what`} className="tech-slide" notes={`${what} ${points.map(plain).join('. ')}. ${example}`}>
      <TechHeading id={id} step="01 / WHAT · What is it?" />
      <div className="tech-layout">
        <div>
          <p className="tech-lead">{what}</p>
          <ul className="tech-points">
            {points.map((p) => <li key={p}>{rich(p)}</li>)}
          </ul>
          <p className="tech-example">{example}</p>
        </div>
        <TechImage image={images[0]} />
      </div>
    </Slide>,
    <Slide
      key={`${id}-why`}
      className="tech-slide"
      notes={`Why we use it. ${why.map(([head, text]) => `${head}: ${plain(text)}`).join(' ')} Why not something else. ${alternatives.map(([name, text]) => `${plain(name)}: ${plain(text)}`).join(' ')}`}
    >
      <TechHeading id={id} step="02 / WHY · Why this, and not something else?" />
      <div className="tech-why">
        <div>
          <h3>Why we use it</h3>
          <ul className="tech-reasons">
            {why.map(([head, text]) => (
              <li key={head}>
                <b>{head}</b>
                <span>{rich(text)}</span>
              </li>
            ))}
          </ul>
        </div>
        <div>
          <h3>Why not something else?</h3>
          <ul className="tech-alternatives">
            {alternatives.map(([name, text]) => (
              <li key={name}>
                <b>{rich(name)}</b>
                <span>{rich(text)}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </Slide>,
    <Slide
      key={`${id}-how`}
      className="tech-slide tech-slide-tight"
      notes={`How: ${plain(how)} ${setup.map(([, step], i) => `Step ${i + 1}: ${plain(step)}.`).join(' ')}`}
    >
      <TechHeading id={id} step={`03 / HOW · How did we set it up? · ${setupTitle}`} />
      <p className="tech-how">{rich(how)}</p>
      <div className="tech-setup">
        {setup.map(([img, step], i) => (
          <figure key={img + step}>
            <div className="tech-setup-img">
              <img src={`${base}${img}`} alt={plain(step)} onError={markMissing} onLoad={fitByRatio} />
              <span className="tech-missing-label">Screenshot to add: {img}</span>
            </div>
            <figcaption>
              <em>{i + 1}</em>
              <span>{rich(step)}</span>
            </figcaption>
          </figure>
        ))}
      </div>
      <a className="tech-evidence" href={`#/evidence-${id}`}>View demo and evidence →</a>
    </Slide>,
    <Slide
      key={`${id}-where`}
      className="tech-slide tech-slide-tight"
      notes={`Where in the code: ${where.map(([, file, lines, does]) => `${file}, lines ${lines}: ${plain(does)}.`).join(' ')}`}
    >
      <TechHeading id={id} step="04 / WHERE · Where is it in the code?" />
      <div className={where.length > 3 ? 'tech-code tech-code-4' : 'tech-code'}>
        {where.map(([img, file, lines, does]) => (
          <figure key={img}>
            <figcaption>
              <code>{file}</code>
              <span className="tech-at">:{lines}</span>
              <span className="tech-does">{rich(does)}</span>
            </figcaption>
            <div className="tech-code-img">
              <img src={`${base}${img}`} alt={`${file} lines ${lines}: ${plain(does)}`} onError={markMissing} />
              <span className="tech-missing-label">Screenshot to add: {img}</span>
            </div>
          </figure>
        ))}
      </div>
      <p className="tech-source">Real code on GitHub · FU-PRM-Projects/Lab-03 · branch main · key lines boxed in red</p>
    </Slide>,
  ];
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

function DesignSystemMap() {
  const swatches = DS_COLORS.flatMap((g) => g.chips).filter(([name]) =>
    ['primary', 'primary-container', 'surface', 'on-surface', 'error', 'success', 'heat/3', 'heat/5'].includes(name),
  );
  const components: [string, string][] = [
    ['Button · 5 variants × 4 states', 'AppButton(variant:, loading:)'],
    ['Text field · error, disabled', 'AppTextField(errorText:)'],
    ['Card/Nốt · 4 note types', 'NoteCard(type:)'],
    ['BottomNav · 4 tabs', 'AppBottomNav(currentIndex:)'],
    ['Dialog · confirm, destructive', 'showAppDialog(kind:)'],
    ['Loading · Empty · Error', 'LoadingState · EmptyState · ErrorState'],
    ['MoodOption · selected', 'MoodOption(mood:, selected:)'],
    ['Mascot · 8 states (below)', 'Mascot(state:)'],
    ['Illustration/Hũ chiến thắng', 'JarIllustration(notes:)'],
  ];
  return (
    <div className="dsm">
      <div className="dsm-tokens">
        <h3>Tokens → ThemeData</h3>
        <div className="dsm-block">
          <p className="dsm-head">
            Colour → <code>ColorScheme</code> <small>app_colors.dart</small>
          </p>
          <div className="dsm-swatches">
            {swatches.map(([name, hex]) => (
              <figure key={name}>
                <i style={{ background: hex }} />
                <figcaption>
                  {name}
                  <small>{hex}</small>
                </figcaption>
              </figure>
            ))}
          </div>
        </div>
        <div className="dsm-block">
          <p className="dsm-head">
            Type → <code>TextTheme</code> <small>app_typography.dart · Be Vietnam Pro</small>
          </p>
          {(
            [
              ['Display', 44, 700, 'displayMedium', 28],
              ['Headline', 28, 700, 'headlineMedium', 21],
              ['Title', 18, 700, 'titleMedium', 17],
              ['Body', 16, 400, 'bodyLarge', 15],
              ['Label', 14, 600, 'labelLarge', 13.5],
            ] as const
          ).map(([name, size, weight, role, shown]) => (
            <div key={name} className="dsm-type">
              <span style={{ fontSize: shown, fontWeight: weight }}>Nốt nhắc bạn</span>
              <small>
                {name} {size} · <code>{role}</code>
              </small>
            </div>
          ))}
        </div>
        <div className="dsm-block dsm-sizes">
          <div>
            <p className="dsm-head">
              Space → <code>AppSpace</code>
            </p>
            <div className="dsm-space">
              {[4, 8, 12, 16, 24].map((s) => (
                <span key={s}>
                  <i style={{ width: s * 1.5 }} />
                  {s}
                </span>
              ))}
            </div>
          </div>
          <div>
            <p className="dsm-head">
              Radius → <code>AppRadius</code>
            </p>
            <div className="dsm-radius">
              {(
                [
                  [8, '8'],
                  [14, '14 note'],
                  [16, '16 card'],
                  [999, 'full'],
                ] as const
              ).map(([r, label]) => (
                <span key={label}>
                  <i style={{ borderRadius: Math.min(r, 17) }} />
                  {label}
                </span>
              ))}
            </div>
          </div>
        </div>
        <p className="dsm-theme">
          <code>AppTheme.light()</code> wires all of it into one <code>ThemeData</code>; screens read the theme, never a raw
          colour or size
        </p>
      </div>
      <div className="dsm-comps">
        <h3>Lab 2 components → widgets/</h3>
        <table>
          <tbody>
            {components.map(([lab2, widget]) => (
              <tr key={lab2}>
                <td>{lab2}</td>
                <td>→</td>
                <td>
                  <code>{widget}</code>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="dsm-cast">
          {(
            [
              ['xong', 'Xong'],
              ['thong-tha', 'Thong Thả'],
              ['doi', 'Đợi'],
              ['ngu', 'Ngủ'],
              ['lac', 'Lạc'],
              ['tap-trung', 'Tập Trung'],
              ['voi', 'Vội'],
              ['chay', 'Cháy'],
            ] as const
          ).map(([m, name]) => (
            <figure key={m}>
              <img src={`assets/mascot/mascot-not-${m}.svg`} alt="" />
              <figcaption>{name}</figcaption>
            </figure>
          ))}
          <figure>
            <img className="dsm-jar" src="assets/illustrations/jar.svg" alt="" />
            <figcaption>Hũ</figcaption>
          </figure>
        </div>
        <p className="dsm-cast-cap">Tụi Nốt: one face per mood and app state, so mood is never colour alone</p>
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
        plugins={[RevealNotes, RevealZoom]}
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
          notes="Read left to right, this is how Lab 3 was built. One: start from the Lab 2 Figma design, all 12 screens and flows F1 to F3, including error states. Two: keep MVVM with Riverpod, so screens talk to ViewModels, ViewModels to services, and only lib/firebase imports the SDK. Three: wire in the Firebase services, Auth, Firestore, Analytics, Crashlytics, Remote Config and Cloud Messaging; photos go to Cloudinary because Firebase Storage needs the paid Blaze plan; and tell the user in plain words when something fails. Four: back every claim with evidence someone else can check: Console screenshots, logs, ARTEMIS runs, all in evidence/."
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
                      [ImageUp, 'Cloudinary'],
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
                <span>Sign-in, notes in Firestore, photos on Cloudinary</span>
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
          dense
          title="Design system in code"
          line="Lab 2 tokens become one ThemeData; each Lab 2 component is one reusable widget"
          notes="Left: the Lab 2 tokens from flutter-handoff.md live only in lib/theme: colours in a ColorScheme (app_colors.dart), text styles in a TextTheme (app_typography.dart), spacing, radius and elevation as named constants (app_tokens.dart). AppTheme.light() wires them into one ThemeData, and screens read the theme rather than hard-coding a colour or size. Right: each Lab 2 component is one widget in lib/widgets with its variants and states as parameters, for example AppButton has 5 variants and 4 states. The mascot Tụi Nốt has 8 states, one face per mood so mood is never shown by colour alone, and the jar fills with every saved note. The full component table is section 3 of docs/design-traceability.md."
        >
          <DesignSystemMap />
          <p className="foot">docs/design-traceability.md §3 components, §4 tokens · lib/theme/ · lib/widgets/</p>
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
          <p className="foot">docs/design-traceability.md · §1 screens, §5 every deviation with its reason</p>
        </Page>

        <TechnologySlides id="riverpod" />

        <Page id="evidence-riverpod"
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
          <p className="foot">docs/architecture.md · layers, sequence diagram, ViewModel ↔ service table</p>
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

        <TechnologySlides id="auth" />

        <Page id="evidence-auth"
          dense
          title="Authentication"
          line="When it fails: cancel → “Bạn đã huỷ đăng nhập.” · offline → “Không có mạng. Kiểm tra Wi-Fi rồi thử lại.” · sign-out error → “Chưa đăng xuất được. Thử lại.”"
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
          <p className="foot">evidence/auth/ · lib/firebase/firebase_auth_service.dart</p>
        </Page>

        <TechnologySlides id="firestore" />

        <Page id="evidence-firestore"
          dense
          title="Cloud Firestore"
          line="When it fails: offline → saved on the device + banner · load error or over 10 s → error state + Thử lại · denied → message, draft kept"
          notes="Firestore holds all the app's data. Everything private lives under users/{uid}: notes, first-time groups, habits and settings, challenge progress and shared streak images; the challenge catalogue is a shared read-only collection seeded from firebase/seed/challenges.json. Photos are not stored here, only their Cloudinary link. The repository writes a note with doc.set and waits at most two seconds for the server; offline, the write stays in Firestore's offline cache, the screen shows Đã lưu trên máy and Firestore sends it when the network returns. The note uses the device time, not serverTimestamp, so an offline note still appears in today's list. The rules deny by default: a user only reads and writes their own data, and validNote checks the keys, the type and mood lists and the lengths. 18 rules tests run on the Emulator with npm run test:rules, all passing; the output is in evidence/firestore/rules-tests.txt."
        >
          <div className="fs">
            <div className="fs-col">
              <h3>Data model</h3>
              <table>
                <tbody>
                  {[
                    ['users/{uid}', 'role, photo'],
                    ['…/notes/{id}', 'type, title, body, mood, createdAt, image'],
                    ['…/groups/{id}', 'first-time groups'],
                    ['…/private/*', 'habits, settings'],
                    ['…/challengeProgress', 'level per topic'],
                    ['…/sharedStreaks', 'shared streak image'],
                    ['challenges/{id}', 'catalogue, read-only'],
                  ].map(([path, what]) => (
                    <tr key={path}>
                      <td>
                        <code>{path}</code>
                      </td>
                      <td>{what}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className="fs-tests">
                <b>18 / 18</b> rules tests pass
                <small>Emulator · npm run test:rules · R-01 … R-18</small>
              </div>
            </div>
            <div className="fs-col">
              <figure>
                <figcaption>
                  <b>Write a note</b> <code>firestore_note_repository.dart</code>
                </figcaption>
                <Crop src="code/fs-add.png" alt="add() writes type, title, body, mood, createdAt, groupId and image with doc.set" natural={620} y={22} w={620} h={226} scale={0.62} />
              </figure>
              <figure>
                <figcaption>
                  <b>Only the owner, only valid notes</b> <code>firestore.rules</code>
                </figcaption>
                <Crop src="code/fs-validnote.png" alt="validNote: required and allowed keys, type list, title 1 to 120, body up to 2000, mood list" natural={620} y={22} w={620} h={186} scale={0.62} />
              </figure>
            </div>
            <div className="fs-col fs-ev">
              <figure>
                <img className="fs-phone" src="app/artemis-offline.jpg" alt="Note saved offline with the Đã lưu trên máy banner" />
                <figcaption>Offline: "Đã lưu trên máy"</figcaption>
              </figure>
              <figure>
                <img src="evidence/firestore-challenges.png" alt="Firestore console with the challenges collection" />
                <figcaption>Console · seeded challenges</figcaption>
              </figure>
            </div>
          </div>
          <p className="foot">firebase/firestore.rules · lib/firebase/firestore_note_repository.dart · evidence/firestore/ · evidence/deploy/</p>
        </Page>

        <TechnologySlides id="cloudinary" />

        <Page id="evidence-cloudinary"
          dense
          title="Photos on Cloudinary"
          line="Why: Firebase Storage needs the paid Blaze plan, so profile, note and group photos are uploaded to Cloudinary"
          notes="Firebase Storage now needs the Blaze plan to create a bucket, so we moved photo uploads to Cloudinary's free plan. Three places take a photo: the profile picture in Settings, a photo attached to a note in step 3, and a photo for a first-time group. The app uploads with an unsigned upload preset, so no API secret is in the app; the format and size limits are set on the preset, and the app also refuses files over 5 MB. Each upload gets a random public id under not/avatars, not/notes or not/groups, so it cannot be guessed or overwritten. The upload streams its progress, as in the first screenshot, and can be cancelled. Firestore only keeps the reference, url and publicId; firestore.rules accepts it only as exactly those two keys with a secure URL on res.cloudinary.com (validImage, PR 47, tests R-16 to R-18). Errors show a message: no network, expired session, wrong file type or size. A successful upload logs image_uploaded with the folder and size."
        >
          <Gallery
            cols={4}
            height={300}
            items={[
              { src: 'app/cld-uploading.png', alt: 'Note step 3 uploading a photo at 0 percent with a cancel button', caption: '1 · Uploading, with progress' },
              { src: 'app/cld-attached.png', alt: 'Photo attached to the note, loaded from Cloudinary', caption: '2 · Attached to the note' },
              { src: 'app/cld-note.png', alt: 'Note detail showing the attached photo', caption: '3 · Saved note with its photo' },
              { src: 'app/cld-avatar.png', alt: 'Settings with the new profile photo', caption: '4 · Profile photo in Settings' },
            ]}
          />
          <div className="cld-row">
            <figure>
              <figcaption>
                <b>Upload</b> · unsigned preset, random id <code>cloudinary_image_service.dart</code>
              </figcaption>
              <Crop src="code/cld-upload.png" alt="Upload form with upload_preset and a random public_id, posted to the Cloudinary upload API with send progress" natural={620} y={22} w={620} h={284} scale={0.56} />
            </figure>
            <ul>
              <li>
                <b>No secret in the app:</b> only the cloud name and an unsigned preset
              </li>
              <li>
                <b>Firestore keeps the link only:</b> <code>{'{url, publicId}'}</code>, checked by <code>validImage</code> in the rules
              </li>
              <li>
                <b>When it fails:</b> no Wi-Fi, expired session, wrong type or over 5 MB each show a message
              </li>
              <li>
                <b>Weekly card PDF:</b> saved locally in the current build
              </li>
            </ul>
          </div>
          <p className="foot">lib/firebase/cloudinary_image_service.dart · firebase/firestore.rules · evidence/cloudinary/</p>
        </Page>

        <TechnologySlides id="fcm" />

        <Page id="evidence-fcm"
          dense
          title="Cloud Messaging"
          line="When it fails: permission denied → dialog + “Mở cài đặt” · unknown route → opens Today · FCM start error → logged, the app keeps running"
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
          <p className="foot">evidence/fcm/ · docs/analytics-plan.md §10</p>
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
          <p className="foot">evidence/fcm/ · lib/firebase/firebase_messaging_service.dart</p>
        </Page>

        <TechnologySlides id="analytics" />

        <Page id="evidence-analytics"
          dense
          title="Analytics"
          line="When it fails: a failed log is caught and skipped (SafeAnalytics.track), so the user's action never fails"
          notes="docs/analytics-plan.md lists each event with its trigger, parameter types, Lab 2 flow and product question. DebugView shows the live stream from the emulator (debug.firebase.analytics.app). The text below is from adb logcat on the same run; every event fired except report_exported, which only fires after a successful upload and the Storage bucket is not provisioned. The second image puts together the DebugView panels with each parameter opened: login sends method google, self_control_logged sends has_habit false on a new account, and group_viewed for the system group Bắt chuyện sends group_source system, group_idea nguoi_la and note_count 0, with no group name."
        >
          <div className="half">
            <div className="dv-gal" style={{ width: '84%' }}>
              <Gallery
                cols={1}
                height={190}
                items={[
                  { src: 'app/console-analytics.png', alt: 'DebugView with screen_view, note_saved and challenge events', caption: '1 · DebugView · top events of one run', ratio: '3', pos: '50% 35%' },
                  { src: 'app/dv-params.png', alt: 'DebugView parameters: login method google, self_control_logged has_habit false, group_viewed group_source system and group_idea nguoi_la', caption: '2 · Values sent, cut from DebugView panels', ratio: '1.907' },
                ]}
              />
            </div>
            <div className="half-text">
              <p>
                Nine custom events go through an <code>AnalyticsService</code> interface (Firebase
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
                  <b>note_viewed / group_viewed</b> · <code>note_type</code> ·{' '}
                  <code>group_source, group_idea, note_count</code>
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
          <p className="foot">docs/analytics-plan.md §4 event table · evidence/analytics/</p>
        </Page>

        <TechnologySlides id="crashlytics" />

        <Page id="evidence-crashlytics"
          dense
          title="Crashlytics"
          line="When it fails: the user still sees the error message; Emulator and web builds use a no-op reporter"
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
          <p className="foot">docs/analytics-plan.md §6 · evidence/crashlytics/</p>
        </Page>

        <TechnologySlides id="remote-config" />

        <Page id="evidence-remote-config"
          dense
          title="Remote Config"
          line="When it fails: fetch error → in-app defaults · broken JSON on the Console → default list · refresh shows “Cấu hình chưa có gì mới.”"
          notes="Remote Config as feature flags. custom_challenges_enabled hides the add-your-own-card button on the Challenges tab; groups_enabled hides the first-time groups shelf on the jar; firebase_demo_enabled hides the Firebase demo area in Settings. Each flag has an in-app default (on), so a failed or empty fetch keeps every feature available. The values are published from firebase/remoteconfig.template.json with firebase deploy --only remoteconfig and fetched at launch (fetch interval zero in debug, one hour in release); activated values stay cached until the next fetch. Before: both flags on. After: both off, same app build, no rebuild."
        >
          <p className="rc-same">
            <b>Same APK, no rebuild:</b> only the value on the Console changed between before and after
          </p>
          <Gallery
            cols={4}
            height={262}
            items={[
              { src: 'app/rc-jar-before.png', alt: 'Jar with the first-time groups shelf', caption: 'Before · groups_enabled = true' },
              { src: 'app/rc-jar-after.png', alt: 'Jar without the shelf', caption: 'After · groups_enabled = false' },
              { src: 'app/rc-challenges-before.png', alt: 'Challenges tab with the add button', caption: 'Before · custom_challenges_enabled = true' },
              { src: 'app/rc-challenges-after.png', alt: 'Challenges tab without the add button', caption: 'After · custom_challenges_enabled = false' },
            ]}
          />
          <div className="rc-row">
            <figure>
              <figcaption>
                <b>Console</b> · three feature flags
              </figcaption>
              <img src="app/console-remoteconfig.png" alt="Remote Config feature flags in the Console" />
            </figure>
            <figure>
              <figcaption>
                <b>In-app defaults</b> · used until a fetch succeeds
              </figcaption>
              <Crop src="code/rc-defaults.png" alt="setDefaults: every flag defaults to true, same values as firebase/remote-config-defaults.json" natural={620} y={22} w={620} h={250} scale={0.52} />
            </figure>
            <figure>
              <figcaption>
                <b>Fetch and cache</b> · debug: every launch · release: 1 h cache
              </figcaption>
              <Crop src="code/rc-fetch.png" alt="setConfigSettings: fetchTimeout 10 s, minimumFetchInterval 1 hour in release and zero in debug, then fetchAndActivate; errors keep the defaults" natural={620} y={22} w={620} h={268} scale={0.52} />
            </figure>
          </div>
          <p className="foot">docs/analytics-plan.md §10 · firebase/remote-config-defaults.json · evidence/remote-config/</p>
        </Page>

        <TechnologySlides id="artemis" />

        <Page id="evidence-artemis"
          dense
          title="ARTEMIS E2E"
          notes="ARTEMIS drives the real app on the Android 15 emulator through ADB. Model: deepseek-v4.1-flash via OpenRouter, Flash profile. 14 cases (T01 to T14) cover F1 write a note (main path, empty note, leave with a draft, offline), F2 self-control and breathing, F3 challenges, the four tabs, Settings (feature flags) and a native Android case (Home, notification shade, relaunch). Each case ran 3 times and asserts on the value the agent reports, not only on success. First full run: 31 of 36. Two failures came from wrong assertions in our tests (T05 run 3 accepted only an answer starting with DIALOG; T12 demanded the Today screen although the app correctly restores the previous screen). We fixed those and re-ran T05 and T12: 6 of 6. T06 run 3 timed out after 420 seconds in the offline case and stays a failure. T13 (analytics event read from adb logcat) and T14 (weekly card export) were added later: 6 of 6 after a fixture fix. Final: 41 of 42. The exploratory session ran for 25 minutes with the Pro profile and reported 10 issues; the sign-in cases need an email test account. Details and the table: docs/test-plan.md (branch feat/e2e-artemis); proofs in evidence/artemis/."
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
                  <b>14 cases:</b> F1 save, empty, draft dialog, offline · F2 · F3 · tabs · flags ·
                  native Home and relaunch · analytics event · weekly card export
                </li>
                <li>
                  <b>41 of 42 runs pass.</b> T06 (offline) timed out once.
                </li>
                <li>
                  Three test bugs, not app bugs, were found on the way: two wrong assertions and a
                  fixture that read the answer too early (fixed, re-run).
                </li>
                <li>Exploratory session (25 min, Pro): the agent reported 10 issues. Not run: sign-in and sign-out cases.</li>
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
          <p className="foot">docs/test-plan.md · e2e_test/ · evidence/artemis/</p>
        </Page>

        <Page
          dense
          title="ARTEMIS: result per case"
          line="14 cases × 3 runs · 41 of 42 pass (98%) · T01–T12 full run 62 minutes"
          notes="This is the table from docs/test-plan.md section 5. Each case ran three times; time is the range of one run. T04, T05 and T06 are error paths: empty note, leaving with a draft, and no network. T06 and T12 act outside the app: airplane mode over adb, the Home button and the notification shade. T06 run 3 is a real failure: it timed out after 420 seconds and the agent reported nothing; we have not found the root cause and have no evidence it is an app bug. T05 run 3 and all of T12 failed first because our own assertions were wrong, so we fixed the assertions, said so in the test plan, and re-ran both cases: 6 of 6. T13 and T14 were added later. T13 checks Analytics: the agent saves a note and the test reads adb logcat for note_saved with mood and note_type and without the note text. Its first run failed although the agent had answered SAVED: our fixture read the steps before the last one was stored, so we added a retry and re-ran T13: 3 of 3. T14 exports the weekly card; with no Storage bucket the correct result is the error message with Thử lại: 3 of 3. JUnit files: evidence/artemis/junit-full-run.xml, junit-rerun-t05-t12.xml, junit-t13-t14.xml and junit-rerun-t13.xml."
        >
          <div className="rt">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Flow</th>
                  <th>Agent must report</th>
                  <th>Pass</th>
                  <th>Time / run</th>
                </tr>
              </thead>
              <tbody>
                {[
                  ['T01', 'Launch', 'WELCOME or TODAY', '3/3', '20–52 s'],
                  ['T02', 'F1 main path: save a note', 'SAVED', '3/3', '31–206 s'],
                  ['T03', 'Jar: open and delete the note', 'DELETED', '3/3', '256–391 s'],
                  ['T04', 'F1 error: empty note', 'DISABLED', '3/3', '55–56 s'],
                  ['T05', 'F1 error: Back with a draft', 'DIALOG', '3/3 *', '108–214 s'],
                  ['T06', 'F1 error: airplane mode (adb)', 'OFFLINE_BANNER', '2/3', '264–421 s'],
                  ['T07', 'F2 self-control', 'SELF_CONTROL', '3/3', '38–52 s'],
                  ['T08', 'F2 hard to stop: breathing', 'BREATHING', '3/3', '20–28 s'],
                  ['T09', 'F3 open a challenge, back', 'DETAIL_THEN_BACK', '3/3', '46–82 s'],
                  ['T10', 'Four tabs', 'ALL_TABS', '3/3', '33–40 s'],
                  ['T11', 'Settings: Remote Config row', '“Cờ tính năng”', '3/3', '13–19 s'],
                  ['T12', 'Native: Home, shade, relaunch', 'LOGGED_IN', '3/3 *', '32–39 s'],
                  ['T13', 'Analytics: note_saved in logcat', 'SAVED + event', '3/3 *', '66–119 s'],
                  ['T14', 'Export the weekly card', 'ERROR_MESSAGE', '3/3', '41–71 s'],
                ].map(([id, flow, expect, pass, time]) => (
                  <tr key={id} className={pass === '2/3' ? 'rt-fail' : undefined}>
                    <td>
                      <b>{id}</b>
                    </td>
                    <td>{flow}</td>
                    <td>
                      <code>{expect}</code>
                    </td>
                    <td>{pass}</td>
                    <td>{time}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="rt-notes">
              <p>
                <b>T06 run 3 · real failure:</b> timed out at 420 s, no answer from the agent. Root
                cause not found; no sign it is an app bug.
              </p>
              <p>
                <b>* T05 run 3, T12:</b> our assertions were wrong (the app was right). Fixed, re-ran: 6 of 6.
                <br />
                <b>* T13 run 1:</b> the agent said SAVED, but our fixture read it before the last step was
                stored. Fixed (retry), re-ran: 3 of 3.
              </p>
              <p>
                <b>Error paths:</b> T04, T05, T06
                <br />
                <b>Outside the app:</b> T06, T12
                <br />
                <b>T14:</b> no Storage bucket, so the expected result is the error message + Thử lại
              </p>
            </div>
          </div>
          <p className="foot">docs/test-plan.md §5 · evidence/artemis/ junit-full-run · junit-rerun-t05-t12 · junit-t13-t14 · junit-rerun-t13</p>
        </Page>

        <Page
          dense
          title="Semantics labels"
          line="41 files in lib/ set Semantics, including 17 of the 21 shared widgets"
          notes="Every main control has a Semantics label, so TalkBack reads a clear name, and test tools that read the accessibility tree can find the control by name. Three examples from lib/widgets. MoodOption: a button with selected state and the label Tâm trạng plus the mood, and excludeSemantics so the reader does not also read the emoji and text inside. ShortcutButton: the Today shortcuts read their label and caption as one button. OfflineBanner: a live region, so the screen reader announces the offline message as soon as it appears."
        >
          <div className="sem-wrap">
            <div className="sem">
            <figure>
              <figcaption>
                <b>Mood choice</b> · button, selected, one clear label <code>mood_option.dart</code>
              </figcaption>
              <Crop src="code/sem-mood.png" alt="MoodOption Semantics: button true, selected, label Tâm trạng plus mood, excludeSemantics" natural={620} y={22} w={620} h={154} scale={0.95} />
            </figure>
            <figure>
              <figcaption>
                <b>Today shortcuts</b> · label and caption read together <code>shortcut_button.dart</code>
              </figcaption>
              <Crop src="code/sem-shortcut.png" alt="ShortcutButton Semantics: button true, label with caption, excludeSemantics" natural={620} y={22} w={620} h={114} scale={0.95} />
            </figure>
            <figure>
              <figcaption>
                <b>Offline banner</b> · live region, announced when it appears <code>offline_banner.dart</code>
              </figcaption>
              <Crop src="code/sem-offline.png" alt="OfflineBanner Semantics with liveRegion true" natural={620} y={22} w={620} h={54} scale={0.95} />
            </figure>
          </div>
            <div className="sem-why">
              <p>
                <b>Why</b>
              </p>
              <ul>
                <li>TalkBack reads one clear name per control, not the icon and text inside it.</li>
                <li>
                  <code>selected</code> and <code>liveRegion</code> tell the reader about state and new messages.
                </li>
                <li>Test tools that read the accessibility tree can find a control by its name.</li>
              </ul>
            </div>
          </div>
          <p className="foot">lib/widgets/ · mood_option.dart · shortcut_button.dart · offline_banner.dart</p>
        </Page>

        <Page
          dense
          title="ARTEMIS: not run yet"
          line="Every other case has a result; these two need an email account made only for tests"
          notes="We are open about the gaps. Every other case has a result, including the exploratory session on the next slide. T15 and T16 sign out, then sign in with an email test account, once with a wrong password; Google sign-in is avoided because the account picker shows a real name and email. They need an email account made only for tests, so they have not run."
        >
          <div className="gap">
            {[
              ['T15 · Sign-out, sign-in', 'Sign out, then sign in with an email test account (not Google: its picker shows a real name and email)', 'Needs a test account'],
              ['T16 · Wrong password', 'Error message under the field, then sign in with the right password', 'Needs a test account'],
            ].map(([what, why, next]) => (
              <div key={what} className="gap-row">
                <b>{what}</b>
                <span>{why}</span>
                <span className="gap-next">{next}</span>
              </div>
            ))}
          </div>
          <p className="foot">e2e_test/test_main_flows.py · docs/test-plan.md §4, §6</p>
        </Page>

        <Page
          dense
          title="ARTEMIS: exploratory session"
          line="X01 · Pro profile · 25 min 38 s · 112 steps · the agent reported 10 issues; we have not checked them yet"
          notes="X01 is the free exploratory session. The agent got one goal: explore Nốt for about 20 minutes like a curious new user, try odd input, rotate the screen, press Back a lot, and list every problem as a BUG line. It ran with the Pro profile for 25 minutes 38 seconds and 112 steps, and ended on Today, still signed in. These are the agent's reports, copied from the server; we have not verified or fixed them yet, so they are candidates, not confirmed bugs. Some have likely explanations: the not responding dialog may come from the debug build on the emulator, the count mismatch from two screens loading at different moments, and the cut group names from the one-line design in D-23. Two things went wrong on our side: the Pro profile does not call report_task_status, so our fixture failed to read the answer and the JUnit file shows an error although the session completed; the fixture now reads the final answer. And the agent created several notes on the test account although that was not forbidden in the goal; together with two notes left by T13 they were deleted afterwards, first with T03 and then by hand, so the jar is back to the 9 notes it had before testing. Full list: docs/test-plan.md section 5 and evidence/artemis/x01-bugs.txt."
        >
          <div className="x01">
            <table>
              <thead>
                <tr>
                  <th>#</th>
                  <th>Where</th>
                  <th>What the agent saw</th>
                </tr>
              </thead>
              <tbody>
                {[
                  ['X-01', 'Relaunch', 'Back from Today, reopen: “Lab 03 isn’t responding”, recovers after Wait'],
                  ['X-02', 'Jar, landscape', 'The + button covers “Xem tất cả”'],
                  ['X-03', 'Today, landscape', 'Tab bar covers the streak card; jar fills the screen'],
                  ['X-04', 'Jar vs Today', 'Notes this month: 22 on one, 21 on the other'],
                  ['X-05', 'Group list', 'Two group names cut with “…”'],
                  ['X-06', 'Journal editor', 'Empty or spaces only: Xong disabled, no reason shown'],
                  ['X-07', 'Jar', 'Tapping the jar picture does nothing'],
                  ['X-08', 'After saving', 'Blank “Đang tải” screen for a few seconds'],
                  ['X-09', 'Journey · Calendar', 'Mood legend does not say which colour is which'],
                  ['X-10', 'Journey · Year', '12-month grid has no month names, cells tiny'],
                ].map(([id, where, what]) => (
                  <tr key={id}>
                    <td>
                      <b>{id}</b>
                    </td>
                    <td>{where}</td>
                    <td>{what}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="x01-side">
              <Gallery
                cols={2}
                height={250}
                items={[
                  { src: 'app/x01-anr.jpg', alt: 'Lab 03 isn’t responding dialog after relaunch', caption: 'X-01 · step 100' },
                  { src: 'app/x01-loading.jpg', alt: 'Blank loading screen after saving', caption: 'X-08 · step 13' },
                ]}
              />
              <p>
                <b>Not checked yet.</b> These are candidates from the agent. Some may have a reason
                (debug build, two screens loading at different times, one-line names in D-23).
              </p>
              <p>
                <b>Our side:</b> the Pro profile answers without <code>report_task_status</code>, so the
                JUnit file shows a fixture error; the fixture now reads the final answer.
              </p>
              <p>
                <b>Clean-up:</b> the runs left 7 test notes on the account; T03 and a manual pass
                removed them (back to 9 notes this month).
              </p>
            </div>
          </div>
          <p className="foot">docs/test-plan.md §5 · evidence/artemis/x01-bugs.txt · evidence/artemis/x01/ · junit-x01.xml</p>
        </Page>

        <TechnologySlides id="coderabbit" />

        <Page id="evidence-coderabbit"
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
          <p className="foot">docs/code-review.md · rows 38-bfeb007a, 38-75b5e00c</p>
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
          <p className="foot">docs/code-review.md · rows 38-cfffb9a5, 29-c0bdd08c</p>
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
          <div className="thanks-ai">
            <span className="thanks-ai-label">AI tools used</span>
            {[
              ['claude', 'Claude Code', 'code, docs, slides'],
              ['coderabbit', 'CodeRabbit', 'PR review'],
              ['google', 'ARTEMIS', 'E2E agent'],
              ['deepseek', 'DeepSeek', 'ARTEMIS model'],
            ].map(([logo, name, role]) => (
              <span key={name} className="thanks-ai-tool">
                <img src={`logos/${logo}.svg`} alt="" />
                <b>{name}</b>
                <small>{role}</small>
              </span>
            ))}
          </div>
        </Slide>

      </Deck>
    </div>
  );
}
