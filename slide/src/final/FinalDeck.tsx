import { createContext, useContext, type ReactNode } from 'react';
import { Deck, Slide } from '@revealjs/react';
import RevealNotes from 'reveal.js/plugin/notes';
import { ArrowRight, Beaker, Layers, PlayCircle, BedDouble, Bot, CheckCircle2, ClipboardCheck, Compass, Flame, ListTodo, Megaphone, Monitor, NotebookPen, PenLine, Repeat, ShieldCheck, Smartphone, Sparkles, Sunset, UserCog, Users, Wrench, Link2, Timer, WifiOff, BookOpen, LifeBuoy } from 'lucide-react';
import ServerlessMap from './ServerlessMap';
import { Card, Code, Shot as LShot, S, Steps, Thumb } from './Legacy';
import { ActorMap, Divider, EvidenceWall, Storyboard, FlowDiagram, IllJournal, IllRepeat, IllTodo, MiniAvatar } from './Visuals';
import type { Part } from './Visuals';

import 'reveal.js/reveal.css';
import '../slides.css';
import './final.css';

const base = import.meta.env.BASE_URL;
const img = (name: string) => `${base}final/${name}`;

/** FPT University logo, top right of each page (top left on the cover). */
function OrgLogo({ cover }: { cover?: boolean }) {
  return <img className={cover ? 'org-logo cover' : 'org-logo'} src={`${base}assets/fpt-logo.webp`} alt="FPT University" />;
}

/** Colour stripe on the left edge, one colour per part (same as the part dividers). */
const PART_STRIPE: Record<string, string> = { PROBLEM: 'stripe-p1', DESIGN: 'stripe-p2', DEMO: 'stripe-p3', PROOF: 'stripe-p4', APPENDIX: 'stripe-px' };

/** One page, same shape as the Lab 3 deck: short title, one line, a body; detail goes in the notes. */
function Page({
  part,
  title,
  line,
  foot,
  notes,
  dense,
  children,
}: {
  part: string;
  title: string;
  line?: string;
  foot?: string;
  notes: string;
  dense?: boolean;
  children: ReactNode;
}) {
  return (
    <Slide className={[dense ? 'fx dense' : 'fx', PART_STRIPE[part.split(' ')[0]] ?? ''].join(' ').trim()} notes={notes}>
      <OrgLogo />
      <p className="tech-step">{part}</p>
      <h2>{title}</h2>
      {line && <p className="line">{line}</p>}
      <div className="page-body">{children}</div>
      {foot && <p className="foot">{foot}</p>}
    </Slide>
  );
}

function Shot({ src, alt, h, w, cap }: { src: string; alt: string; h?: number; w?: number; cap?: string }) {
  return (
    <figure className="fx-shot">
      <img src={img(src)} alt={alt} style={w ? { width: w, height: 'auto' } : { height: h }} />
      {cap && <figcaption>{cap}</figcaption>}
    </figure>
  );
}

/* ---------------------------------------------------------------- diagrams */

/** Shows one region of a screenshot, scaled down (never up) so it stays sharp. */
function Crop({ src, w, cx, cy, rw, bw, bh }: { src: string; w: number; cx: number; cy: number; rw: number; bw: number; bh: number }) {
  const k = bw / rw;
  return (
    <div
      className="ux-crop"
      style={{
        width: bw,
        height: bh,
        backgroundImage: `url(${img(src)})`,
        backgroundSize: `${w * k}px auto`,
        backgroundPosition: `${-(cx * k - bw / 2)}px ${-(cy * k - bh / 2)}px`,
      }}
    />
  );
}

/** Low-fi wireframe of S02 Today, drawn to match the final layout (grey boxes, no colour). */
function WireToday() {
  const g = '#e3e5ea';
  const d = '#9aa0ab';
  const t = { fontSize: 15, fill: '#6b7280', fontFamily: 'Inter, sans-serif' } as const;
  return (
    <svg viewBox="0 0 360 800" className="ux-wire" aria-label="Wireframe S02 Today">
      <rect x="0.5" y="0.5" width="359" height="799" rx="14" fill="#fff" stroke="#d1d5db" />
      <rect x="18" y="16" width="70" height="10" rx="5" fill={g} />
      <rect x="18" y="80" width="190" height="26" rx="6" fill={g} />
      <text x="24" y="99" {...t} fontSize={13}>Ngày hôm nay</text>
      <circle cx="266" cy="94" r="22" fill="none" stroke={d} strokeWidth="1.5" />
      <text x="266" y="98" textAnchor="middle" {...t} fontSize={10}>chuông</text>
      <circle cx="322" cy="94" r="22" fill="none" stroke={d} strokeWidth="1.5" />
      <text x="322" y="98" textAnchor="middle" {...t} fontSize={10}>avatar</text>
      <circle cx="180" cy="266" r="112" fill="none" stroke={d} strokeWidth="1.5" />
      <path d="M100 186 L260 346 M260 186 L100 346" stroke={g} strokeWidth="2" />
      <rect x="112" y="250" width="136" height="32" rx="6" fill="#fff" />
      <text x="180" y="271" textAnchor="middle" {...t} fontSize={14}>hũ + mascot</text>
      <rect x="40" y="408" width="280" height="18" rx="6" fill={g} />
      <text x="180" y="422" textAnchor="middle" {...t} fontSize={12}>câu hỏi: hôm nay làm được gì?</text>
      <rect x="16" y="448" width="328" height="48" rx="10" fill="#4b5563" />
      <text x="180" y="478" textAnchor="middle" fontSize={16} fontWeight={700} fill="#fff" fontFamily="Inter, sans-serif">+ Ghi nốt</text>
      {[64, 180, 296].map((x, i) => (
        <g key={x}>
          <circle cx={x} cy="578" r="28" fill="none" stroke={d} strokeWidth="1.5" />
          <text x={x} y="630" textAnchor="middle" {...t} fontSize={13}>{['Dừng lại', 'Thở 90 giây', 'Thử thách'][i]}</text>
        </g>
      ))}
      <rect x="16" y="718" width="328" height="56" rx="28" fill="none" stroke={d} strokeWidth="1.5" />
      <rect x="24" y="726" width="128" height="40" rx="20" fill={g} />
      <text x="88" y="751" textAnchor="middle" {...t} fontSize={13}>Hôm nay</text>
      {[200, 258, 316].map((x) => (
        <rect key={x} x={x - 11} y="735" width="22" height="22" rx="5" fill="none" stroke={d} strokeWidth="1.5" />
      ))}
    </svg>
  );
}

/** Sitemap of both clients with screen codes (S = Android app, W = web admin). */
function SiteMap() {
  const w = 112;
  const h = 40;
  const col = (n: number) => 6 + n * 134;
  return (
    <Svg id="sitemap" viewBox="0 0 620 470">
      <text x={6} y={14} fontSize={12} fontWeight={800} fill={C.primary}>ANDROID APP · user</text>
      <Box x={col(0)} y={24} w={w} h={h} t="S01 Sign in" />
      <Box x={col(1)} y={24} w={w} h={h} t="S13 Onboarding" s="first run" />
      <Arrow d={`M${col(0) + w} 44 H${col(1) - 4}`} />
      <Arrow d={`M${col(0) + w / 2} 64 V96`} />
      <text x={col(0) + w / 2 + 8} y={84} fontSize={11} fill={C.muted}>4 tabs</text>
      <rect x={2} y={92} width={522} height={50} rx={8} fill="none" stroke={C.primary} strokeDasharray="5 4" />
      <Box x={col(0)} y={97} w={w} h={h} t="S02 Today" bold stroke={C.primary} />
      <Box x={col(1)} y={97} w={w} h={h} t="S05 Jar" bold stroke={C.primary} />
      <Box x={col(2)} y={97} w={w} h={h} t="S07 Challenges" bold stroke={C.primary} />
      <Box x={col(3)} y={97} w={w} h={h} t="S11 Journey" bold stroke={C.primary} />
      <Box x={col(0)} y={168} w={w} h={h} t="S03 Ghi nốt" s="S03b Nốt AI" />
      <Box x={col(1)} y={168} w={w} h={h} t="S06 Note" />
      <Box x={col(2)} y={168} w={w} h={h} t="S08 Challenge" />
      <Box x={col(3)} y={168} w={w} h={h} t="S12 Settings" s="avatar, any tab" />
      <Box x={col(0)} y={234} w={w} h={h} t="S04 Saved" />
      <Box x={col(1)} y={234} w={w} h={h} t="S09 · S10" s="stop · breathe" />
      <Box x={col(2)} y={234} w={w} h={h} t="Inbox" s="bell, any tab" />
      <Box x={col(3)} y={234} w={w} h={h} t="S14 Rooms" s="Discord" />
      {[0, 1, 2, 3].map((n) => (
        <Arrow key={n} d={`M${col(n) + w / 2} 142 V164`} />
      ))}
      <Arrow d={`M${col(0) + w / 2} 208 V230`} />
      <Arrow d={`M${col(0) + w} 117 H${col(0) + w + 7} Q${col(0) + w + 11} 117 ${col(0) + w + 11} 121 V250 Q${col(0) + w + 11} 254 ${col(0) + w + 15} 254 H${col(1) - 2}`} />
      <Arrow d={`M${col(3) + w / 2} 208 V230`} />

      <line x1={0} y1={300} x2={620} y2={300} stroke={C.line} />
      <text x={6} y={326} fontSize={12} fontWeight={800} fill={C.primary}>WEB ADMIN · staff, admin</text>
      <Box x={col(0)} y={338} w={w} h={h} t="W0 Sign in" s="role check" />
      <rect x={2} y={404} width={616} height={52} rx={8} fill="none" stroke={C.primary} strokeDasharray="5 4" />
      <text x={col(1)} y={398} fontSize={11} fill={C.muted}>sidebar</text>
      <Box x={6} y={410} w={112} h={h} t="W1 Dashboard" bold stroke={C.primary} />
      <Box x={128} y={410} w={112} h={h} t="W2 Catalog" bold stroke={C.primary} />
      <Box x={250} y={410} w={112} h={h} t="W3 Review" bold stroke={C.primary} />
      <Box x={372} y={410} w={118} h={h} t="W4 Announce" bold stroke={C.primary} />
      <Box x={500} y={410} w={114} h={h} t="W5 Users" s="admin only" bold stroke={C.primary} />
      <Arrow d={`M${col(0) + w / 2} 378 V406`} />
    </Svg>
  );
}



const C = {
  ink: '#111',
  muted: '#555',
  line: '#bbb',
  fill: '#fff',
  primary: '#3d4fd6',
  ok: '#1f9d55',
  bad: '#e5262b',
};

function Box({
  x,
  y,
  w,
  h,
  t,
  s,
  stroke = C.line,
  bold,
}: {
  x: number;
  y: number;
  w: number;
  h: number;
  t: string;
  s?: string;
  stroke?: string;
  bold?: boolean;
}) {
  return (
    <g>
      <rect x={x} y={y} width={w} height={h} rx={6} fill={C.fill} stroke={stroke} strokeWidth={stroke === C.line ? 1 : 1.8} />
      <text x={x + w / 2} y={y + (s ? h / 2 - 3 : h / 2 + 5)} textAnchor="middle" fontSize={14} fontWeight={bold ? 700 : 600} fill={C.ink}>
        {t}
      </text>
      {s && (
        <text x={x + w / 2} y={y + h / 2 + 15} textAnchor="middle" fontSize={11.5} fill={C.muted}>
          {s}
        </text>
      )}
    </g>
  );
}

const MarkerCtx = createContext('ah');

function Arrow({ d, dash, color = C.muted }: { d: string; dash?: boolean; color?: string }) {
  const id = useContext(MarkerCtx);
  return <path d={d} fill="none" stroke={color} strokeWidth={1.6} strokeDasharray={dash ? '5 4' : undefined} markerEnd={`url(#${id})`} />;
}

/** One diagram: its arrowhead marker has its own id, so slides never share (or lose) a marker. */
function Svg({ id, viewBox, children }: { id: string; viewBox: string; children: ReactNode }) {
  const mid = `ah-${id}`;
  return (
    <svg className="fx-diagram" viewBox={viewBox} preserveAspectRatio="xMinYMid meet">
      <MarkerCtx.Provider value={mid}>
        <defs>
          <marker id={mid} viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
            <path d="M0 0 L10 5 L0 10 z" fill={C.muted} />
          </marker>
        </defs>
        {children}
      </MarkerCtx.Provider>
    </svg>
  );
}

function Label({ x, y, t, color = C.muted, anchor = 'middle' }: { x: number; y: number; t: string; color?: string; anchor?: 'start' | 'middle' | 'end' }) {
  return (
    <text x={x} y={y} textAnchor={anchor} fontSize={12} fill={color} fontWeight={600}>
      {t}
    </text>
  );
}

/** Slide 07: one swimlane flow for the whole system. */
function BusinessFlow() {
  const lanes = ['USER · mobile', 'APP + GEMINI', 'FIRESTORE + RULES', 'STAFF · web admin'];
  const laneH = 108;
  return (
    <Svg id="d0" viewBox="0 0 1168 440">
      {lanes.map((l, i) => (
        <g key={l}>
          <line x1={0} y1={i * laneH} x2={1168} y2={i * laneH} stroke="#ddd" />
          <text x={4} y={i * laneH + 20} fontSize={12} fontWeight={700} fill={C.bad} letterSpacing="0.06em">
            {l}
          </text>
        </g>
      ))}
      <line x1={0} y1={4 * laneH} x2={1168} y2={4 * laneH} stroke="#ddd" />
      {/* WF-01 */}
      <Box x={150} y={34} w={150} h={52} t="Tell the day" s="WF-01 Kể tự do" stroke={C.primary} />
      <Box x={150} y={142} w={150} h={52} t="Gemini sorts notes" s="BR-AI1 · App Check" />
      <Box x={150} y={250} w={150} h={52} t="notes saved" s="after user confirms" />
      <Arrow d="M225 86 V140" />
      <Arrow d="M225 194 V248" />
      <path d="M300 168 H340" stroke={C.bad} strokeWidth={1.6} strokeDasharray="5 4" fill="none" />
      <Label x={344} y={164} t="AI off / error → write by hand" color={C.bad} anchor="start" />
      {/* WF-02 */}
      <Box x={540} y={34} w={170} h={52} t="Share own card" s="WF-02 · status = pending" stroke={C.primary} />
      <Box x={540} y={250} w={170} h={52} t="challengeSubmissions" s="BR-02 rules check" />
      <Box x={760} y={358} w={170} h={52} t="Review queue" s="approve / reject" />
      <Box x={760} y={250} w={170} h={52} t="batch: card + inbox" s="BR-03 reason if reject" />
      <Box x={760} y={34} w={170} h={52} t="Card status + inbox" s="≈ 2–4 s (D-2, D-3)" stroke={C.ok} />
      <Arrow d="M625 86 V248" />
      <Arrow d="M710 290 C740 320 760 330 790 356" />
      <Arrow d="M845 358 V304" />
      <Arrow d="M845 250 V88" />
      {/* WF-03 */}
      <Box x={990} y={358} w={160} h={52} t="Post announcement" s="WF-03" stroke={C.primary} />
      <Box x={990} y={250} w={160} h={52} t="announcements" s="staff only" />
      <Box x={990} y={34} w={160} h={52} t="Inbox for all users" s="reads announcements" stroke={C.ok} />
      <Arrow d="M1070 358 V304" />
      <Arrow d="M1070 250 V88" />
    </Svg>
  );
}

/** Slide 08: lifecycle of a shared card. */
function StateMachine() {
  return (
    <Svg id="d1" viewBox="0 0 760 380">
      <circle cx={40} cy={190} r={10} fill={C.ink} />
      <Box x={110} y={160} w={150} h={60} t="pending" s="user sent the card" stroke={C.primary} bold />
      <Box x={430} y={50} w={160} h={60} t="approved" s="card in catalog" stroke={C.ok} bold />
      <Box x={430} y={270} w={160} h={60} t="rejected" s="reason ≥ 1 char" stroke={C.bad} bold />
      <Box x={110} y={300} w={150} h={50} t="(deleted)" s="withdrawn" />
      <Arrow d="M50 190 H108" />
      <Label x={78} y={178} t="submit" />
      <Arrow d="M260 175 C330 140 360 100 428 82" />
      <Label x={362} y={128} t="approve [staff]" color={C.ok} anchor="start" />
      <Arrow d="M260 205 C330 240 360 280 428 300" />
      <Label x={436} y={258} t="reject [staff, reason]" color={C.bad} anchor="start" />
      <Arrow d="M185 220 V298" dash />
      <Label x={196} y={262} t="withdraw [owner]" anchor="start" />
      <text x={620} y={150} fontSize={13} fill={C.bad} fontWeight={700}>Forbidden (rules deny)</text>
      <text x={620} y={172} fontSize={12.5} fill={C.ink}>user → approved</text>
      <text x={620} y={192} fontSize={12.5} fill={C.ink}>approved → pending</text>
      <text x={620} y={212} fontSize={12.5} fill={C.ink}>reject without reason</text>
      <text x={620} y={232} fontSize={12.5} fill={C.ink}>withdraw after review</text>
    </Svg>
  );
}

/** Slide 09: containers and where they run. */
function Architecture() {
  return (
    <Svg id="arch" viewBox="0 0 760 410">
      <Box x={20} y={20} w={200} h={64} t="Android app (Flutter)" s="role: user · MVVM" stroke={C.primary} />
      <Box x={20} y={110} w={200} h={64} t="Web admin (Flutter Web)" s="staff · admin · Hosting /admin/" stroke={C.primary} />
      <Box x={20} y={210} w={200} h={64} t="packages/core" s="models · repositories · theme" />
      <Arrow d="M20 52 H8 V242 H18" />
      <Arrow d="M120 174 V208" />
      <rect x={300} y={10} width={440} height={300} rx={10} fill="none" stroke="#ccc" strokeDasharray="5 4" />
      <text x={316} y={34} fontSize={13} fontWeight={700} fill={C.bad}>FIREBASE · Spark (no-cost) · rules guard both apps</text>
      <Box x={316} y={50} w={130} h={54} t="Firestore" s="+ Security Rules" bold />
      <Box x={458} y={50} w={130} h={54} t="Auth" s="Google · email" />
      <Box x={600} y={50} w={126} h={54} t="App Check" s="Play · reCAPTCHA" />
      <Box x={316} y={118} w={130} h={54} t="AI Logic" s="Gemini Dev API" />
      <Box x={458} y={118} w={130} h={54} t="Remote Config" s="flags · ai_*" />
      <Box x={600} y={118} w={126} h={54} t="Hosting" s="/ and /admin/" />
      <Box x={316} y={186} w={130} h={54} t="Analytics" s="both clients" />
      <Box x={458} y={186} w={130} h={54} t="Crashlytics" s="mobile" />
      <Box x={600} y={186} w={126} h={54} t="FCM" s="push" />
      <text x={316} y={276} fontSize={12} fill={C.muted}>Snapshots to both apps · rules decide every app read and write</text>
      <Arrow d="M220 52 C260 52 270 70 314 74" />
      <Arrow d="M220 142 C260 142 270 86 314 82" />
      <Box x={20} y={340} w={200} h={56} t="GitHub Actions" s="CI · deploys Hosting + rules" />
      <Arrow d="M220 366 C260 366 270 320 298 306" dash />
      <Box x={316} y={340} w={200} h={56} t="Cloudinary" s="note photos (Lab 3)" />
      <Box x={540} y={340} w={200} h={56} t="Discord bot (Rust)" s="extra · VPS · service account" stroke={C.bad} />
      <Arrow d="M640 340 V312" color={C.bad} />
      <Arrow d="M540 368 H518" dash />
      <Label x={652} y={330} t="REST · bypasses rules" color={C.bad} anchor="start" />
    </Svg>
  );
}

/** Slide 12: approve, one interaction across layers. */
function Sequence() {
  const lanes = [
    ['Staff', 60],
    [':ReviewScreen', 194],
    [':ReviewActions', 328],
    [':FirestoreCatalog\nRepository', 462],
    [':FirestoreSubmission\nRepository', 596],
    ['Firestore + Rules', 730],
    ['App (snapshot)', 864],
  ] as const;
  const id = useContext(MarkerCtx);
  const msg = (y: number, from: number, to: number, t: string, color = C.ink, dash = false) => (
    <g>
      <path d={`M${from} ${y} H${to + (to > from ? -5 : 5)}`} stroke={color} strokeWidth={1.5} strokeDasharray={dash ? '5 4' : undefined} markerEnd={`url(#${id})`} fill="none" />
      <text x={(from + to) / 2} y={y - 6} textAnchor="middle" fontSize={12} fill={color}>
        {t}
      </text>
    </g>
  );
  return (
    <>
      {lanes.map(([name, x]) => (
        <g key={name}>
          <rect x={x - 62} y={8} width={124} height={34} rx={6} fill="#fff" stroke={C.line} />
          {name.split('\n').map((p, i, a) => (
            <text key={p} x={x} y={a.length > 1 ? 22 + i * 13 : 30} textAnchor="middle" fontSize={11} fontWeight={600} fill={C.ink}>
              {p}
            </text>
          ))}
          <line x1={x} y1={42} x2={x} y2={390} stroke="#ccc" strokeDasharray="4 4" />
        </g>
      ))}
      {msg(70, 60, 194, '1. Duyệt (level)')}
      {msg(100, 194, 328, '2. approve(submission, level)')}
      {msg(130, 328, 462, '3. watchAll().first')}
      {msg(160, 328, 596, '4. approve(level, order)')}
      {msg(190, 596, 730, '5. batch: card + submission + inbox')}
      {msg(220, 730, 596, '6. commit ok (1.4 s)', C.ok, true)}
      {msg(250, 730, 864, '7. snapshot: approved + inbox', C.ok, true)}
      <rect x={340} y={276} width={566} height={106} rx={6} fill="none" stroke={C.bad} strokeDasharray="5 4" />
      <text x={352} y={296} fontSize={12.5} fontWeight={700} fill={C.bad}>alt</text>
      <text x={380} y={296} fontSize={12} fill={C.ink}>[reject, empty reason] → reason-required → "Cần ghi lý do khi từ chối."</text>
      <text x={380} y={320} fontSize={12} fill={C.ink}>[staff offline &gt; 10 s] → TimeoutException → "Không kết nối được máy chủ"</text>
      <text x={380} y={344} fontSize={12} fill={C.ink}>[not staff] → requireStaff throws · rules deny (R-22)</text>
      <text x={380} y={368} fontSize={12} fill={C.muted}>Message names are the real Dart methods; rules are the second guard.</text>
    </>
  );
}

function SequenceDiagram() {
  return (
    <Svg id="seq" viewBox="-8 0 940 400">
      <Sequence />
    </Svg>
  );
}

/** Cardinality end of a relation (crow's foot notation). p = point on the box edge, d = unit vector pointing away from the box. */
type Card = 'one' | 'many' | 'zero_one';

function CardEnd({ p, d, kind }: { p: [number, number]; d: [number, number]; kind: Card }) {
  const [x, y] = p;
  const [dx, dy] = d;
  const px = -dy;
  const py = dx;
  const at = (k: number, t: number): [number, number] => [x + dx * k + px * t, y + dy * k + py * t];
  const seg = (u: [number, number], v: [number, number], key: string) => (
    <line key={key} x1={u[0]} y1={u[1]} x2={v[0]} y2={v[1]} stroke={C.ink} strokeWidth={1.5} />
  );
  const circle = (k: number) => <circle cx={at(k, 0)[0]} cy={at(k, 0)[1]} r={4.5} fill="#fff" stroke={C.ink} strokeWidth={1.5} />;
  if (kind === 'one') return <g>{seg(at(9, -7), at(9, 7), 'a')}{seg(at(14, -7), at(14, 7), 'b')}</g>;
  if (kind === 'many') {
    return (
      <g>
        {seg(at(14, 0), at(0, 8), 'a')}
        {seg(at(14, 0), at(0, -8), 'b')}
        {seg(at(14, 0), at(0, 0), 'c')}
        {circle(20)}
      </g>
    );
  }
  return <g>{seg(at(9, -7), at(9, 7), 'a')}{circle(17)}</g>;
}

function Rel({ pts, from, to, dash }: { pts: [number, number][]; from: Card; to: Card; dash?: boolean }) {
  const unit = (u: [number, number], v: [number, number]): [number, number] => {
    const dx = v[0] - u[0];
    const dy = v[1] - u[1];
    const l = Math.hypot(dx, dy) || 1;
    return [dx / l, dy / l];
  };
  const n = pts.length;
  return (
    <g>
      <polyline points={pts.map((p) => p.join(',')).join(' ')} fill="none" stroke={C.ink} strokeWidth={1.4} strokeDasharray={dash ? '6 4' : undefined} />
      <CardEnd p={pts[0]} d={unit(pts[0], pts[1])} kind={from} />
      <CardEnd p={pts[n - 1]} d={unit(pts[n - 1], pts[n - 2])} kind={to} />
    </g>
  );
}

/** Slide 15: conceptual model, business level: no attributes, keys or collection names; verbs on every line. */
function Erd() {
  const t = (x: number, y: number, label: string, anchor: 'start' | 'middle' = 'middle') => (
    <text x={x} y={y} textAnchor={anchor} fontSize={12} fill="#374151" fontStyle="italic">
      {label}
    </text>
  );
  return (
    <Svg id="erd" viewBox="-30 0 1250 462">
      {/* entities: singular nouns with a one-line business definition */}
      <Box x={20} y={30} w={180} h={56} t="Weekly report" s="saved weekly card PDF" bold />
      <Box x={20} y={170} w={180} h={56} t="User" s="a student using the app" bold />
      <Box x={20} y={310} w={180} h={56} t="Onboarding answers" s="first-run questionnaire" bold />
      <Box x={270} y={30} w={180} h={56} t="Custom card" s="a user's own card" bold />
      <Box x={520} y={170} w={180} h={56} t="Submission" s="a card offered to everyone" bold />
      <Box x={520} y={310} w={180} h={56} t="Inbox message" s="result of a review" bold />
      <Box x={770} y={170} w={180} h={56} t="Challenge card" s="card in the shared catalog" bold />
      <Box x={1020} y={170} w={180} h={56} t="Staff member" s="user with staff/admin role" bold />
      <Box x={1020} y={310} w={180} h={56} t="Announcement" s="news posted for everyone" bold />

      {/* user side */}
      <Rel pts={[[110, 170], [110, 86]]} from="one" to="many" />
      {t(118, 134, 'saves', 'start')}
      <Rel pts={[[110, 226], [110, 310]]} from="one" to="zero_one" />
      {t(118, 272, 'answers', 'start')}
      <Rel pts={[[200, 184], [235, 184], [235, 58], [270, 58]]} from="one" to="many" />
      {t(243, 150, 'owns', 'start')}
      <Rel pts={[[200, 198], [520, 198]]} from="one" to="many" />
      {t(360, 190, 'sends')}
      <Rel pts={[[200, 212], [245, 212], [245, 338], [520, 338]]} from="one" to="many" />
      {t(380, 330, 'receives')}
      <Rel pts={[[20, 198], [-16, 198], [-16, 400], [1110, 400], [1110, 366]]} from="many" to="many" />
      {t(560, 392, 'reads')}

      {/* the submission flow */}
      <Rel pts={[[450, 58], [610, 58], [610, 170]]} from="zero_one" to="many" />
      {t(530, 50, 'is shared as')}
      <Rel pts={[[700, 198], [770, 198]]} from="zero_one" to="zero_one" />
      {t(735, 190, 'becomes')}
      <Rel pts={[[610, 226], [610, 310]]} from="zero_one" to="zero_one" />
      {t(618, 272, 'results in', 'start')}

      {/* staff side */}
      <Rel pts={[[1020, 198], [950, 198]]} from="zero_one" to="many" />
      {t(985, 190, 'maintains')}
      <Rel pts={[[1110, 170], [1110, 130], [660, 130], [660, 170]]} from="zero_one" to="many" />
      {t(885, 122, 'reviews')}
      <Rel pts={[[1110, 226], [1110, 310]]} from="one" to="many" />
      {t(1118, 272, 'posts', 'start')}

      <text x={270} y={440} fontSize={11.5} fill={C.muted}>Crow's foot (IE) notation: two bars = exactly one · circle + bar = zero or one · circle + crow's foot = zero or many</text>
      <text x={270} y={456} fontSize={11.5} fill={C.muted}>Business level only: no attributes, keys or collection names (see the physical model on the next slide).</text>
    </Svg>
  );
}

/* ---------------------------------------------------------------- deck */

const PARTS: Part[] = [
  { code: 'p1', num: '01', name: 'Problem', question: 'Why build it, and what is it?', minutes: '≈ 3.5 min', icon: Compass,
    slides: ['§Why build it?', '01 Overview', '02 Context', '03 Problem', '§What is it?', '04 Solution', '05 Actors', '06 Features'] },
  { code: 'p2', num: '02', name: 'Design', question: 'How is the whole system built?', minutes: '≈ 6 min', icon: Layers,
    slides: ['07 Business flow', '08 State machine', '09 Architecture', '10 Stack', '11 UI/UX', '12 Sequence', '13 Classes', '14–15 Database', '16 Traceability'] },
  { code: 'p3', num: '03', name: 'Demo', question: 'How do the workflows run for real?', minutes: '≈ 6.5 min', icon: PlayCircle,
    slides: ['17 Demo plan', '18 WF-01 Nốt AI', '18b WF-01 storyboard', '19 WF-02 Publish a card', '19b WF-02 storyboard', '20 WF-03 Announce', '20b WF-03 storyboard'] },
  { code: 'p4', num: '04', name: 'Proof', question: 'What can we prove?', minutes: '≈ 2.5 min', icon: Beaker,
    slides: ['21 Testing', '21b Evidence wall', '22 Achievements', '23 Limitations', '24 Lessons learned', '25 Conclusion'] },
];

export default function FinalDeck() {
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
        {/* 00 · Cover */}
        <Slide
          className="fx-cover"
          notes="Nốt, Final Assignment: one complete system on Firebase. The Lab 3 app plus a web admin for staff, one shared Firestore with role-based rules, and a Gemini feature."
        >
          <OrgLogo cover />
          <h1>Nốt</h1>
          <p className="line">One positive note every day, now with staff, AI and a shared catalog</p>
          <ul className="speakers">
            <li>Đoàn Thị Kim Thúy · SE190992</li>
            <li>Phùng Thế Quân · SE193519</li>
            <li>Phan Đức Duy · SE193591</li>
            <li>Phan Hữu Phước · SE161951</li>
          </ul>
          <div className="fx-hero">
            <Shot src="wa-03-dashboard.png" alt="Web admin dashboard" w={480} />
            <Shot src="06-ai-notes-saved.png" alt="Nốt app on a Galaxy A70" h={340} />
          </div>
        </Slide>

        {/* Agenda */}
        <Page
          dense
          part="AGENDA · FOUR PARTS"
          title="Problem → Design → Demo → Proof"
          notes="Four parts, the lecturer's order. Time budget, for us only: Problem about 3.5 min, Design about 6 min, Demo about 6.5 min, Proof about 2.5 min; 18 to 20 minutes in total, the demo about a third."
        >
          <div className="p1-body">
            <div className="agenda-row">
              {[
                { c: 'p1', num: '01', name: 'Problem', q: 'Why build it, and what is it?', icon: Compass,
                  items: ['§Why build it?', '01 Overview', '02 Context', '03 Problem', '§What is it?', '04 Solution', '05 Actors', '06 Features'] },
                { c: 'p2', num: '02', name: 'Design', q: 'How is the whole system built?', icon: Layers,
                  items: ['07 Business flow', '08 State machine', '09 Architecture', '10 Stack', '11 UI/UX', '12 Sequence', '13 Classes', '14–15 Database', '16 Traceability'] },
                { c: 'p3', num: '03', name: 'Demo', q: 'How do the workflows run for real?', icon: PlayCircle,
                  items: ['17 Demo plan', '18 WF-01 Nốt AI', '18b WF-01 storyboard', '19 WF-02 Publish a card', '19b WF-02 storyboard', '20 WF-03 Announce', '20b WF-03 storyboard'] },
                { c: 'p4', num: '04', name: 'Proof', q: 'What can we prove?', icon: Beaker,
                  items: ['21 Testing', '21b Evidence wall', '22 Achievements', '23 Limitations', '24 Lessons learned', '25 Conclusion'] },
              ].map((p) => {
                const I = p.icon;
                return (
                  <div key={p.c} className={`ag ${p.c}`}>
                    <span className="ag-num">{p.num}</span>
                    <span className="ag-ic"><I size={34} /></span>
                    <span className="ag-name">{p.name}</span>
                    <span className="ag-q">{p.q}</span>
                    <ul>
                      {p.items.map((t) => (t.startsWith('§') ? <li key={t} className="grp">{t.slice(1)}</li> : <li key={t}>{t}</li>))}
                    </ul>
                  </div>
                );
              })}
            </div>
          </div>
        </Page>

        <Divider part={PARTS[0]} shots={['wa-03-dashboard-crop.png', 'm-today.png', '05-ai-free-tell-result.png']} />

        {/* 01 · Overview */}
        <Page
          dense
          part="PROBLEM · 01"
          title="Overview"
          notes="30 seconds. Name and type: Nốt, an Android app for logging small wins plus a Flutter web admin for staff. One sentence: for students who end the day feeling behind, Nốt makes one small win visible in under 30 s and keeps fresh challenges coming. Users, value, platform. It is live: point at the screenshots."
        >
          <div className="p1-body">
          <div className="ov">
            <div className="ov-head">
              <span className="ov-k">Project</span>
              <h3 className="ov-name">Nốt</h3>
              <p className="ov-type">Small-wins journal · Android app + web admin · one Firebase project</p>
            </div>
            <p className="ov-desc">
              For <b>students and young workers</b> who end a long day feeling they got nothing done: Nốt makes{' '}
              <b>one small win visible in under 30 seconds</b> and keeps <b>fresh small challenges</b> coming.
            </p>
            <div className="ov-sec">
              <span className="ov-k">Users</span>
              <div className="ov-roles">
                <div>
                  <span className="ov-ic r1"><Smartphone size={22} /></span>
                  <p><b>user</b>logs the day on the Android app</p>
                </div>
                <div>
                  <span className="ov-ic r2"><ClipboardCheck size={22} /></span>
                  <p><b>staff</b>reviews and creates cards, posts news on the web admin</p>
                </div>
                <div>
                  <span className="ov-ic r3"><UserCog size={22} /></span>
                  <p><b>admin</b>everything staff can, plus changes roles</p>
                </div>
              </div>
            </div>
            <div className="ov-sec">
              <span className="ov-k">Core value</span>
              <div className="ov-vals">
                <p><CheckCircle2 size={20} />One win in 30 s, typed or sorted by Gemini</p>
                <p><CheckCircle2 size={20} />New challenge cards without an app update</p>
                <p><CheckCircle2 size={20} />Staff news in every inbox in the same minute</p>
              </div>
            </div>
          </div>
          <div className="collage">
            <img className="c-web" src={img('wa-03-dashboard-crop.png')} alt="Web admin dashboard" />
            <img className="c-phone c-a" src={img('m-today.png')} alt="Today screen" />
            <img className="c-phone c-b" src={img('05-ai-free-tell-result.png')} alt="Nốt AI" />
            <span className="c-tag c-tag-web">Web admin · staff</span>
            <span className="c-tag c-tag-app">Android app · user</span>
          </div>
          </div>
        </Page>

        {/* 02 · Context */}
        <Page
          dense
          part="PROBLEM · 02"
          title="Context"
          line="Final-year students and young workers reach the evening with little energy left."
          notes="Context, no problem yet. Who: final-year students and young workers with a full day of classes, internships or work. The persona from Lab 2 is Minh, 22. What they use today: a to-do app, phone notes, sometimes a paper diary, and self-help tips seen on social media. Walk the evening: the day ends, Minh opens the to-do list and sees what is left, tries to write a diary and gives up, looks at the same goals as last week, and goes to bed feeling nothing got done. Nobody curates small, fresh challenges for them."
        >
          <div className="p1-body">
          <div className="col grow" style={{ gap: 30, justifyContent: 'center' }}>
            <div className="ctx3">
              <div className="ctx-col c1">
                <span className="ctx-h"><span className="ctx-ic"><Compass size={20} /></span><span className="ctx-k">Environment</span></span>
                <p>University life and first jobs</p>
                <small>long days of classes, internships, part-time work; the evening is the only free time</small>
              </div>
              <div className="ctx-col c2">
                <span className="ctx-h"><span className="ctx-ic"><Users size={20} /></span><span className="ctx-k">Who is involved</span></span>
                <div className="ctx-people">
                  <MiniAvatar size={52} />
                  <p><b>Minh, 22</b> · final-year student, tired, wants to feel the day counted</p>
                </div>
                <small>Nobody curates small, fresh challenges for people like Minh</small>
              </div>
              <div className="ctx-col c3">
                <span className="ctx-h"><span className="ctx-ic"><Wrench size={20} /></span><span className="ctx-k">Current tools</span></span>
                <p>To-do app, phone notes, paper diary</p>
                <small>plus self-help tips scattered across social media</small>
              </div>
            </div>
            <span className="ctx-proc">Current process</span>
            <FlowDiagram
              steps={[
                { icon: Sunset, title: 'Day ends', note: 'home late, low energy' },
                { icon: ListTodo, title: 'Checks to-do', note: 'sees only what is left', warn: true },
                { icon: NotebookPen, title: 'Tries a diary', note: 'blank page, gives up', warn: true },
                { icon: Repeat, title: 'Same goals', note: 'last week\'s list again', warn: true },
                { icon: BedDouble, title: 'Goes to bed', note: '"nothing done today"', warn: true },
              ]}
            />
            <p className="ctx-need">
              <b>So people need:</b> a way to see one small win in seconds, and fresh small challenges that someone keeps up for them.
            </p>
          </div>
          </div>
        </Page>

        {/* 03 · Problem */}
        <Page
          dense
          part="PROBLEM · 03"
          title="Problem"
          line="Most of us think it after a long day, even on days when we did plenty of small things."
          notes="Three pain points, each with a concrete cause and the impact we see. 1: to-do lists only track what is left, so the small things we did are never written anywhere. 2: diary apps ask for a long entry at the moment we are most tired. 3: goals and challenges stay the same, and nobody refreshes them or tells us what is new. Hit hardest: final-year students and young workers. Evidence: the Lab 2 persona and our own evenings as final-year students; we did not run a formal survey and we say so."
        >
          <div className="p1-body">
          <div className="pcx">
            <div className="pcx-head">
              <span className="h-pain">Pain point</span>
              <span />
              <span className="h-cause">Cause</span>
              <span />
              <span className="h-impact">Impact</span>
            </div>
            {[
              {
                head: 'At night we only see what is unfinished', Ill: IllTodo,
                cause: <>To-do lists track <b>what is left</b>; the small things we did are never written down</>,
                impact: <>We feel the day was wasted; motivation drops and <b>burnout</b> builds up</>,
              },
              {
                head: 'Writing the day down is one more task', Ill: IllJournal,
                cause: <>Diary apps ask for a <b>long entry</b>, at the moment we are most tired</>,
                impact: <>We skip it, then <b>stop after a few days</b>; the good moments are lost</>,
              },
              {
                head: 'Goals that never change stop motivating', Ill: IllRepeat,
                cause: <><b>Nobody refreshes</b> the challenges or tells us what is new</>,
                impact: <>The same list every week gets boring; good habits <b>break off</b></>,
              },
            ].map((x) => (
              <div key={x.head} className="pcx-row">
                <div className="pcx-pain">
                  <div className="pcx-thumb ill-box">
                    <x.Ill />
                  </div>
                  <b>{x.head}</b>
                </div>
                <ArrowRight className="pcx-arrow" size={22} />
                <p className="pcx-cause">{x.cause}</p>
                <ArrowRight className="pcx-arrow" size={22} />
                <p className="pcx-impact">{x.impact}</p>
              </div>
            ))}
            <p className="pcx-who">
              <span>Hit hardest</span>final-year students and young workers, whose evening is the only free time and the most tired one.
            </p>
            <p className="pcx-ev">
              <span>Evidence</span>Lab 2 persona (Minh, 22) and our own evenings as final-year students. No formal survey was run.
            </p>
          </div>
          </div>
        </Page>

        {/* 04 · Proposed solution */}
        <Page
          dense
          part="PROBLEM · 04"
          title="Proposed solution"
          line="An Android app for the evening, a staff web admin for content, and Gemini that sorts the day."
          notes="Each pain point from slide 03 gets one answer, and each answer is live: point at the screenshot. 1: the jar shows what you did; one mood and one small win in under 30 s. 2: Nốt AI, tell the day once and Gemini splits it into sorted notes you confirm. 3: staff keep the catalog fresh from the web admin, approve cards users share, and announce news to every inbox. Then scope: in scope are the three workflows plus onboarding, weekly PDF, roles and App Check; out of scope are Cloud Functions and Cloud Storage (paid plan), the bonus 'Hỏi Nốt' AI, and iOS."
        >
          <div className="p1-body">
          <div className="pcx">
            <div className="pcx-head sol">
              <span className="h-pain">Pain point</span>
              <span />
              <span className="h-sol">Solution in Nốt</span>
              <span />
              <span className="h-impact">Value</span>
            </div>
            {[
              {
                pain: 'At night we only see what is unfinished',
                shots: ['m-today.png'],
                sol: <><b>The jar of small wins</b>: one mood + one win, saved in under 30 s</>,
                value: <>The evening ends on <b>what we did</b>, not on what is left</>,
              },
              {
                pain: 'Writing the day down is one more task',
                shots: ['05-ai-free-tell-result.png'],
                sol: <><b>Nốt AI</b>: tell the day in one paragraph; Gemini splits it into sorted notes to confirm</>,
                value: <><b>3 notes</b> from one paragraph, no form to fill</>,
              },
              {
                pain: 'Goals that never change stop motivating',
                shots: ['wa-04-catalog-search-crop.png'],
                web: true,
                sol: <><b>Staff web admin</b>: keep the card catalog fresh, approve cards users share, announce news</>,
                value: <>New cards and news reach users <b>without an app update</b></>,
              },
            ].map((x) => (
              <div key={x.pain} className="pcx-row sol">
                <p className="sol-pain">{x.pain}</p>
                <ArrowRight className="pcx-arrow" size={22} />
                <div className="sol-mid">
                  <div className="sol-shots">
                    {x.shots.map((src) => (
                      <img key={src} src={img(src)} alt="" className={x.web ? 'web' : 'phone'} />
                    ))}
                  </div>
                  <p>{x.sol}</p>
                </div>
                <ArrowRight className="pcx-arrow" size={22} />
                <p className="pcx-impact">{x.value}</p>
              </div>
            ))}
            <p className="pcx-who">
              <span className="in">In scope</span>WF-01 Log the day with Nốt AI · WF-02 Publish a user card · WF-03 Announce news · onboarding, weekly
              PDF, roles, App Check
            </p>
            <p className="pcx-ev">
              <span className="out">Out of scope</span>Cloud Functions and Cloud Storage (paid plan) · "Hỏi Nốt" AI (bonus) · iOS build
            </p>
          </div>
          </div>
        </Page>

        {/* 05 · Actors */}
        <Page
          dense
          part="PROBLEM · 05"
          title="Main actors"
          line="The role lives in users/{uid}.role; only an admin changes it, and never their own."
          notes="Read the map left to right. User on the Android app, staff and admin on the web admin; an admin can do everything staff can, plus change other users' roles, never their own. Every request lands on Firebase, where Security Rules decide every read and write; there is no custom server. Gemini only receives the scrubbed paragraph through Firebase AI Logic and returns JSON. The first admin was set in the Firebase Console. Rules tests R-01 to R-30 cover every role and collection; BR-05 is R-26."
        >
          <div className="p1-body">
          <ActorMap
            rows={[
              {
                icon: Users, name: 'User', who: 'logs every evening', tone: 'u',
                perms: ['own notes and data', 'share own cards (pending only)', 'read catalog, news, own inbox'],
                client: { icon: Smartphone, label: 'Android app', shot: 'm-today.png', phone: true },
              },
              {
                icon: PenLine, name: 'Staff', who: 'content curator', tone: 's',
                perms: ['create, edit, archive cards', 'approve / reject with a reason', 'post announcements'],
                client: { icon: Monitor, label: 'Web admin', shot: 'wa-08-review-approved-crop.png' },
              },
              {
                icon: UserCog, name: 'Admin', who: 'team lead', tone: 'a', badge: 'all staff rights',
                perms: ['everything staff can do', "change other users' roles", 'never their own role'],
                client: { icon: Monitor, label: 'Web admin', shot: 'wa-12-users-crop.png' },
              },
            ]}
            hub={{ icon: Flame, name: 'Firebase', lines: ['Auth · Firestore', 'App Check · Remote Config · FCM'], rule: 'Security Rules decide every read and write' }}
            ext={{ icon: Bot, name: 'Gemini', lines: ['via Firebase AI Logic', 'gets the scrubbed paragraph only', 'returns JSON suggestions'] }}
          />
          </div>
        </Page>

        {/* 06 · Features */}
        <Page
          dense
          part="PROBLEM · 06"
          title="Main features"
          line="Each group links an actor to the pain point it solves, and names the workflow we demo live."
          notes="Four groups, left to right. Log the day is for the user and answers pains 1 and 2; WF-01 Nốt AI is the demo. Challenges joins user and staff and answers pain 3; WF-02 is the demo. News to users is staff talking to everyone; WF-03 is the demo. Admin and safety keeps the other three safe. Filled dots are the MVP, built and tested; hollow dots are extensions, either Lab 3 extras or next steps we did not build."
        >
          <div className="p1-body">
          <div className="col grow" style={{ minWidth: 0 }}>
            <div className="fg4">
              {[
                {
                  icon: Sparkles, name: 'Log the day', roles: [['u', 'User']], shot: '05-ai-free-tell-result.png',
                  items: [['star', 'Nốt AI: tell the day once', 'WF-01'], ['mvp', 'Jar of small wins, 30 s note'], ['mvp', 'Streak and weekly card PDF'], ['ext', 'Self-control and breathing']],
                  solves: 'Only seeing what is unfinished · writing is one more task',
                },
                {
                  icon: ClipboardCheck, name: 'Challenges', roles: [['u', 'User'], ['s', 'Staff']], shot: 'cr-05-phone-approved-run3.png',
                  items: [['star', 'Share a card, staff approve', 'WF-02'], ['mvp', 'Card catalog run on the web'], ['mvp', 'Onboarding + starter plan'], ['ext', 'Journey climb, groups']],
                  solves: 'Goals that never change',
                },
                {
                  icon: Megaphone, name: 'News to users', roles: [['s', 'Staff']], shot: 'wa-11-app-inbox-announcement.png',
                  items: [['star', 'Announce to every inbox', 'WF-03'], ['mvp', 'Personal inbox messages'], ['mvp', 'Evening push reminder'], ['ext', 'Discord room links']],
                  solves: 'Nobody tells us what is new',
                },
                {
                  icon: ShieldCheck, name: 'Admin and safety', roles: [['a', 'Admin']], shot: 'wa-12-users-crop.png', web: true,
                  items: [['mvp', 'Roles, changed by an admin only'], ['mvp', 'Dashboard'], ['mvp', 'App Check, AI on/off switch'], ['ext', 'next: "Hỏi Nốt" AI, iOS']],
                  solves: 'Keeps the other three safe',
                },
              ].map((g) => {
                const I = g.icon;
                return (
                  <div key={g.name} className="fg-col">
                    <div className="fg-head">
                      <span className="wf3-ic"><I size={20} /></span>
                      <h4>{g.name}</h4>
                    </div>
                    <span className="wf3-roles">
                      {g.roles.map(([t, r]) => (
                        <span key={r} className={`role ${t}`}>{r}</span>
                      ))}
                    </span>
                    <div className="fg-shot">
                      <img src={img(g.shot)} alt="" className={g.web ? 'web' : 'phone'} />
                    </div>
                    {g.items.filter(([k]) => k === 'star').map(([, t, wf]) => (
                      <p key={t} className="fg-demo"><span>Demo {wf}</span>{t}</p>
                    ))}
                    <div className="fg-sec">
                      <span className="fg-k mvp">MVP</span>
                      <ul>
                        {g.items.filter(([k]) => k === 'mvp').map(([, t]) => <li key={t}>{t}</li>)}
                      </ul>
                    </div>
                    <div className="fg-sec">
                      <span className="fg-k ext">Extra</span>
                      <ul className="ext">
                        {g.items.filter(([k]) => k === 'ext').map(([, t]) => <li key={t}>{t}</li>)}
                      </ul>
                    </div>
                    <p className="wf3-solves"><span>Solves</span>{g.solves}</p>
                  </div>
                );
              })}
            </div>
          </div>
          </div>
        </Page>

        <Divider part={PARTS[1]} shots={['ev-firestore-console.png', 'g-mobile-final-03-onboarding-starter-plan.png', 'g-journey-climb-dung-cam.png']} />

        {/* 07 · Business flow */}
        <Page
          dense
          part="DESIGN · 07"
          title="Business flow"
          notes="Walk the lanes left to right: WF-01 stays in the user's own data; WF-02 crosses from user to staff and back; WF-03 goes from staff to everyone. The three workflows share one Firestore; rules are the decision points. BR-AI1: AI only when enabled, consented and App Check passes. BR-02: user creates pending only. BR-03: reject needs a reason. On-screen footnote moved here: BR-AI1: AI only when enabled, consented, App Check · BR-02: pending only · BR-03: reject needs a reason"
        >
          <BusinessFlow />
        </Page>

        {/* 08 · State machine */}
        <Page
          dense
          part="DESIGN · 08"
          title="State machine"
          notes="Entity: challengeSubmissions/{id}. Event, guard, action. Every transition and every forbidden one has a rules test in the Emulator: R-20 create pending only, R-21 read own or staff, R-22 staff review with a reason on reject, R-23 withdraw while pending, R-24 inbox. 30/30 rules tests pass (R-01…R-30). On-screen footnote moved here: Tests R-20…R-24 · 30/30 rules tests pass"
        >
          <StateMachine />
        </Page>

        {/* 09 · Architecture */}
        <Page
          dense
          part="DESIGN · 09"
          title="System architecture"
          notes="Decision: no custom server. Security Rules + App Check are the backend's access layer. Trade-off: no server means rules carry the business rules (validation, transitions). Benefit: free plan, real time, less to run. Cost: complex rules, so we test them. Deploy: GitHub Actions builds both clients, deploys Hosting and Firestore rules + indexes on merge to main. On-screen footnote moved here: GitHub Actions deploys Hosting (/ and /admin/) and rules on merge to main"
        >
          <Architecture />
        </Page>

        {/* 10 · Tech stack map */}
        <Page
          dense
          part="DESIGN · 10"
          title="Technology stack"
          notes="Read it like an AWS diagram: FE (two Flutter clients) talks over HTTPS to serverless Firebase (BE + AI), which stores data in Firestore. Below: DevOps ships it, Ops watches it. Only services we really use (pubspec, workflows, compose file); no Grafana, monitoring is the Firebase Console. Details if asked: Only what is in pubspec / package.json / Cargo.toml / workflows. The Discord bot is the one non-Dart part: a Rust service (Poise on Serenity) that runs on a VPS with Docker through Dokploy. It chats with a linked user over DM, calls an OpenRouter model (default deepseek) through rig-core with tools that only touch that user's notes, and reads and writes Firestore through the REST API with a service account. Photos go to Cloudinary. A guard model checks abuse and there is a per-user cooldown. It is an extra, not part of the three core workflows."
        >
          <div className="p1-body map-full">
            <ServerlessMap />
          </div>
        </Page>

        {/* 11 · UI/UX: sitemap and design path */}
        <Page
          dense
          part="DESIGN · 11"
          title="UI/UX design"
          line="Sitemap of both clients, and how the Today screen went from wireframe to final Figma to the app."
          notes="Left: the sitemap with our screen codes (S for the Android app, W for the web admin); the same codes are used in docs/design-traceability.md and on every slide. Four tabs on the phone, everything else is nested; the web admin is one sidebar with five screens, Users only for admins. Right: the design path of the Today screen, from the Figma file PRM393-LAB2. The low-fi wireframe shows only the layout: date, bell and avatar, one big picture, the question, one main button, three shortcuts and the tab bar. The Lab 2 wireframes on page 02 date from the study-planner version, so this one is redrawn for Nốt from the same rules (one big picture, one main action). The final Figma on page 03 adds colour, the jar and the mascot with Auto Layout and components; the Flutter app implements it, with deviations logged as D-01 to D-37."
        >
          <div className="p1-body ux-body">
            <div className="ux-map">
              <SiteMap />
            </div>
            <div className="ux-path">
              {[
                ['wire', 'Wireframe', 'S02 Today, low-fi'],
                ['ux-figma-s02.png', 'Final Figma', 'page 03 Final UI'],
                ['m-today.png', 'Built app', 'Flutter, Galaxy A70'],
              ].map(([src, t, sub], i) => (
                <div key={src} className="ux-step">
                  {i > 0 && <span className="ux-arrow">→</span>}
                  <figure>
                    {src === 'wire' ? <WireToday /> : <img src={img(src)} alt={t} />}
                    <figcaption><b>{t}</b>{sub}</figcaption>
                  </figure>
                </div>
              ))}
            </div>
          </div>
        </Page>

        {/* 11b · UI/UX: states and feedback */}
        <Page
          dense
          part="DESIGN · 11"
          title="UI states and feedback"
          line="Every screen has empty, loading, error and success; three rounds of feedback changed the design."
          notes="Left: the four states on the web admin; the error uses the shared MessageView.error on five screens, and the phone has the same set plus 'Nốt AI đang nghỉ' when ai_enabled is false. Right: feedback that changed the design. One, the lecturer on 24/10 in Lab 2: a deadline planner is not a real pain, Minh already has Calendar and Notion, so we pivoted to a positive-notes app and kept the colours, font and mascot. Two, the lecturer again: too much text, cluttered, so every screen got one big picture and one main action, and the Jar became a grid of note sheets instead of a card list. Three, running the Final on the real project: the web admin kept retrying for about three minutes before showing an error, so retries are off and the error with 'Thử lại' shows at once."
        >
          <div className="p1-body ux-body">
            <div className="ux-states">
              {([
                ['wa-07-review-empty.png', 1280, 715, 362, 290, 'Empty', 'review queue'],
                ['wa-13-dashboard-loading.png', 1280, 716, 342, 250, 'Loading', 'dashboard'],
                ['wa-16-dashboard-error-crop.png', 960, 484, 432, 400, 'Error', 'server unreachable'],
                ['wa-08-review-approved.png', 1280, 600, 240, 560, 'Success', 'card approved'],
              ] as const).map(([src, w, cx, cy, rw, t, sub]) => (
                <figure key={src}>
                  <Crop src={src} w={w} cx={cx} cy={cy} rw={rw} bw={250} bh={166} />
                  <figcaption><b>{t}</b> · {sub}</figcaption>
                </figure>
              ))}
            </div>
            <div className="ux-fb">
              <h3>Feedback → change</h3>
              {[
                { who: 'Lecturer · Lab 2', said: '"A deadline planner is not a real pain."', change: 'Pivot to a positive-notes app; colours, font, mascot kept', before: 'ux-fb1-before.png', after: 'ux-figma-s02.png' },
                { who: 'Lecturer · Lab 2', said: '"Too much text, it feels cluttered."', change: 'One big picture + one action per screen; the Jar is a grid of notes', before: 'ux-fb2-before.png', after: 'ux-figma-s05.png' },
                { who: 'Real project · Final', said: 'Errors showed only after ~3 min of retries', change: 'Retries off: the error and "Thử lại" show at once', before: 'wa-13-dashboard-loading-crop.png', after: 'wa-16-dashboard-error-crop.png', web: true },
              ].map((f) => (
                <div key={f.said} className="ux-fb-item">
                  <div className="ux-fb-text">
                    <span>{f.who}</span>
                    <p className="said">{f.said}</p>
                    <p className="change">→ {f.change}</p>
                  </div>
                  {f.web ? (
                    <div className="ux-ba web">
                      <Crop src="wa-13-dashboard-loading.png" w={1280} cx={716} cy={342} rw={260} bw={104} bh={104} />
                      <i>→</i>
                      <Crop src="wa-16-dashboard-error-crop.png" w={960} cx={484} cy={432} rw={300} bw={104} bh={104} />
                    </div>
                  ) : (
                    <div className="ux-ba">
                      <img src={img(f.before)} alt="before" />
                      <i>→</i>
                      <img src={img(f.after)} alt="after" />
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </Page>

        {/* 12 · Sequence */}
        <Page
          dense
          part="DESIGN · 12"
          title="Sequence diagram"
          notes="Real method names. The alt box shows the exception branches, including the two bugs found on the deployed system and fixed."
        >
          <SequenceDiagram />
        </Page>

        {/* 13 · Class design */}
        <Page
          dense
          part="DESIGN · 13"
          title="Class design"
          notes="Business rules sit in the repository + Security Rules, not in widgets. Screen → Notifier/actions → service interface → Firestore implementation in packages/core. main.dart wires each provider to its Firebase implementation; fakes replace the interfaces in tests (290 app, 10 web admin, 5 core tests). On-screen footnote moved here: Tests swap in fakes · 290 app · 10 web admin · 5 core"
        >
          <table className="fx-table">
            <thead>
              <tr>
                <th>Layer</th>
                <th>WF-01 Nốt AI</th>
                <th>WF-02 Share & review</th>
                <th>WF-03 Announce</th>
              </tr>
            </thead>
            <tbody>
              <tr><td><b>Screen</b></td><td><code>FreeTellScreen</code></td><td><code>ReviewScreen</code></td><td><code>AnnouncementsScreen</code></td></tr>
              <tr><td><b>ViewModel</b></td><td><code>FreeTellViewModel</code></td><td><code>ReviewActions</code></td><td><code>AnnouncementActions</code></td></tr>
              <tr><td><b>Service</b></td><td><code>AiService</code></td><td><code>SubmissionRepository</code></td><td><code>AnnouncementRepository</code></td></tr>
              <tr><td><b>Implementation</b></td><td><code>FirebaseAiService</code></td><td><code>FirestoreSubmissionRepository</code></td><td><code>FirestoreAnnouncementRepository</code></td></tr>
              <tr><td><b>Model</b></td><td><code>AiSortResult</code></td><td><code>ChallengeSubmission</code></td><td><code>Announcement</code></td></tr>
            </tbody>
          </table>
        </Page>

        {/* 14 · DB conceptual */}
        <Page
          dense
          part="DESIGN · 14"
          title="Database design: conceptual"
          notes="Business-level model, drawn in crow's foot (IE) notation, so it has no attributes, keys or collection names; those are on the physical slide. Read each line with its verb: a user owns custom cards, sends submissions, receives inbox messages, saves weekly reports, answers the onboarding questions and reads announcements. A submission is shared from at most one custom card, and becomes at most one challenge card. A staff member (a user with role staff or admin) reviews submissions, which results in one inbox message, maintains challenge cards and posts announcements. Only the Final additions are drawn: the challenge catalog existed in Lab 3 as a seed list, and the Final added staff writing to it and the link to submissions. Lab 3 data (notes, groups, habits, progress, streaks) stays private to its owner and is not drawn. Notation and sources: docs/erd-notation.md. On-screen footnote moved here: Final additions only; Lab 3 data (notes, groups, habits, …) is not drawn · attributes: next slide"
        >
          <Erd />
        </Page>

        {/* 15 · DB physical */}
        <Page
          dense
          part="DESIGN · 15"
          title="Database design: physical"
          notes="No schema in Firestore, so the shape, sizes and transitions are enforced by rules and covered by tests. Indexes: submissions (uid, createdAt↓), (status, createdAt↓); notes (groupId, createdAt↓). Full table: docs/data-model.md. The diagram shows every collection with its fields; the full version with types and limits is docs/erd.svg. Rules per collection: users: only an admin changes a role, never their own; challenges: staff only, archive instead of delete; challengeSubmissions: create as pending, staff review, reason on reject; inbox: staff create, the owner may only flip read; announcements: staff create, every signed-in user reads; reports: owner only, id = ISO week; onboarding: owner only, enums checked. On-screen footnote moved here: Types, limits and rules per field: docs/erd.svg · docs/data-model.md"
        >
          <img className="fx-erd" src={img('erd-slide.svg')} alt="Firestore data model: collections, fields, keys and relationships" />
        </Page>

        {/* 16 · Traceability */}
        <Page
          dense
          part="DESIGN · 16"
          title="Traceability"
          line="Each feature traces from actor and screen to class, data, business rule and test."
          notes="Read one row left to right: who uses it, which screen (the S and W codes from the sitemap), which ViewModel or action class, which Firestore collection, which business rule, and which tests prove it. R-xx are the rules tests in firebase/tests/firestore.rules.test.js, T-xx are ARTEMIS runs on the Galaxy A70, the rest are Flutter tests. If asked what the matrix found: S11 Hỏi Nốt is designed but still Planned (bonus), S08b and S08c were dropped on purpose (D-37), MascotAnim is not built, and ARTEMIS T15 and T16 are written but not run because they need a test-only account. Full matrix: docs/design-traceability.md."
        >
          <div className="p1-body" style={{ flexDirection: 'column', gap: 14 }}>
            <table className="fx-table tr-table">
              <thead>
                <tr>
                  <th>Feature</th>
                  <th>Actor</th>
                  <th>Screen</th>
                  <th>Class / service</th>
                  <th>Entity</th>
                  <th>Rule</th>
                  <th>Tests</th>
                </tr>
              </thead>
              <tbody>
                <tr><td><b>WF-01</b> Log the day with Nốt AI</td><td>User</td><td>S03b</td><td>FreeTellViewModel</td><td>notes</td><td>BR-AI1</td><td>free_tell_flow_test · T18, T19</td></tr>
                <tr><td><b>WF-02</b> Publish a user card</td><td>User + Staff</td><td>S07 → W3</td><td>ReviewActions</td><td>challengeSubmissions</td><td>BR-02, BR-03</td><td>R-20…R-24 · cross-role 3/3 · T20</td></tr>
                <tr><td><b>WF-03</b> Announce to every user</td><td>Staff</td><td>W4 → Inbox</td><td>AnnouncementActions</td><td>announcements</td><td>BR-04</td><td>R-25 · notification_inbox_test</td></tr>
                <tr><td><b>SF-1</b> Weekly card PDF</td><td>User</td><td>S11b</td><td>WeeklyReportViewModel</td><td>reports</td><td>—</td><td>R-28 · T14</td></tr>
                <tr><td><b>SF-2</b> Onboarding</td><td>User</td><td>S13a–g</td><td>OnboardingViewModel</td><td>private/onboarding</td><td>—</td><td>R-27 · T17</td></tr>
                <tr><td><b>SF-3</b> Roles</td><td>Admin</td><td>W0, W5</td><td>sessionProvider</td><td>users</td><td>BR-05</td><td>R-01, R-26, R-29</td></tr>
              </tbody>
            </table>
          </div>
        </Page>

        <Divider part={PARTS[2]} shots={['wa-08-review-approved-crop.png', 'cr-02-phone-pending.png', 'cr-06-phone-inbox-3-messages.png']} />

        {/* 17 · Demo plan */}
        <S
          part="P3 · Demo · 17 Demo plan"
          title="Demo plan: one evening"
          sub="Minh logs his day and shares a card; staff publish it and announce. Each result feeds the next workflow."
          notes="Order: WF-01 on the phone, WF-02 phone + web side by side, WF-03 on the web then the phone. One account per actor, prepared before the session; the backup video is the fallback if the network fails. On-screen footnote moved here: Prepared: user account on a Galaxy A70 (release build, Play Integrity) · staff/admin account on the web admin · ai_enabled ready to toggle in Remote Config · empty review queue · backup video."
        >
          <div className="col grow">
            <Steps
              items={[
                ['01 · User', 'Kể tự do: one paragraph → 3 notes saved'],
                ['02 · User → Staff', 'Share "Đi bộ 10 phút" → staff approves → app shows it'],
                ['03 · Staff → Users', '"Bạn đã vận động chưa?" → every inbox'],
              ]}
            />
            <div className="cards" style={{ gridTemplateColumns: '1fr 1fr 1fr', marginTop: 12 }}>
              <Card head="Result WF-01" tone="ok">
                <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                  <Thumb src="06-ai-notes-saved.png" h={150} />
                  <p>Jar 11 → 14 notes, streak starts</p>
                </div>
              </Card>
              <Card head="Result WF-02" tone="ok">
                <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                  <Thumb src="cr-05-phone-approved-run3.png" h={150} />
                  <p>Card "Người dùng đề xuất" in catalog; inbox message</p>
                </div>
              </Card>
              <Card head="Result WF-03" tone="ok">
                <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                  <Thumb src="wa-11-app-inbox-announcement.png" h={150} />
                  <p>Announcement in app inbox at 10:56, same minute</p>
                </div>
              </Card>
            </div>
            <Card head="Exception paths shown live">
              <ul className="tight">
                <li>Remote Config <code>ai_enabled = false</code> → "Nốt AI đang nghỉ", user writes by hand</li>
                <li>Reject without reason → blocked (BR-03) · user account on the web, staff account on the phone → rejected (BR-05)</li>
              </ul>
            </Card>
          </div>
        </S>

        {/* 18 · WF-01 */}
        <S
          part="P3 · Demo · 18 WF-01 · User"
          title="WF-01 Log the day with Nốt AI"
          sub="One paragraph becomes three editable notes."
          notes="Trigger: evening. Steps: consent sheet, Gemini, labelled suggestions, edit, save. Exception: AI off via Remote Config. Evidence: Galaxy A70, real Gemini. On-screen footnote moved here: Evidence: Galaxy A70, real Gemini (~2 s) · ARTEMIS T18 2/3, T19 (AI off) 3/3 · AI level 2: JSON schema → AiSortResult."
        >
          <div className="col" style={{ width: 360 }}>
            <Card head="Trigger · precondition"><p>Evening, Ghi nốt → Kể tự do · role <code>user</code>, AI on (BR-01)</p></Card>
            <Card head="Steps → result">
              <ul className="tight">
                <li>Consent sheet on first use</li>
                <li>Scrubbed paragraph → Gemini → JSON notes + mood</li>
                <li>Labelled "Gợi ý từ Nốt AI", editable</li>
                <li><b>Result:</b> chosen notes saved, jar and streak update</li>
              </ul>
            </Card>
            <Card head="Exception" tone="bad">
              <p>BR-01 fails (AI off, App Check, network) → "Ghi tay", paragraph kept</p>
            </Card>
          </div>
          <LShot src="04-ai-consent.png" alt="Consent sheet" h={440} cap="Consent" />
          <LShot src="05-ai-free-tell-result.png" alt="Suggestions" h={440} cap="Suggestions" />
          <LShot src="11-ai-off-remote-config.png" alt="AI off" h={440} cap="ai_enabled = false" />
        </S>

        {/* 18b · WF-01 storyboard */}
        <S
          part="P3 · Demo · 18b WF-01 storyboard"
          title="WF-01 in four screens"
          sub="From an empty evening to three saved notes."
          notes="Walk the frames left to right while doing it live. Frame 4 is what the user sees after saving. On-screen footnote moved here: Exception shown live: ai_enabled = false → frame 2 says 'Nốt AI đang nghỉ' and only 'Ghi tay' is left."
        >
          <Storyboard
            steps={[
              { src: 'm-today.png', title: 'Ghi nốt', text: 'evening, from Today' },
              { src: '04-ai-consent.png', title: 'Consent', text: 'what is sent to Gemini' },
              { src: '05-ai-free-tell-result.png', title: 'Suggestions', text: '3 notes + mood, editable' },
              { src: '06-ai-notes-saved.png', title: 'Saved', text: 'jar 11 → 14, streak starts' },
            ]}
          />
        </S>

        {/* 19 · WF-02 */}
        <S
          part="P3 · Demo · 19 WF-02 · User + Staff"
          title="WF-02 Publish a card"
          sub="Staff approve on the web; the phone updates within seconds."
          notes="Cross-role. Measured three times on the deployed system. D-1 slow (listener idle); D-2, D-3 2–4 s. Also mention the approve bug found here and fixed. On-screen footnote moved here: Evidence: write 1.4 s after Duyệt · phone ≤ 3.4 s (D-2, D-3), 22 s when idle (D-1) · ARTEMIS T20 3/3 · docs/cross-role-flow.md"
        >
          <div className="col" style={{ width: 300 }}>
            <Card head="Trigger · state"><p>User shares own card · <b>pending → approved</b> / rejected</p></Card>
            <Card head="Steps">
              <ul className="tight">
                <li>User shares → pending</li>
                <li>Staff: Duyệt on the web</li>
                <li>Batch: card + status + inbox</li>
                <li>App: "Đã vào kho chung ✓"</li>
              </ul>
            </Card>
            <Card head="Exception" tone="bad"><p>BR-03 reason required · BR-02 user cannot approve</p></Card>
          </div>
          <LShot src="cr-02-phone-pending.png" alt="Pending" h={440} cap="Đang chờ duyệt" />
          <div className="col grow" style={{ alignItems: 'flex-start' }}>
            <LShot src="wa-08-review-approved-crop.png" alt="Approved on web" w={520} cap="Web: approved" />
            <LShot src="cr-06-phone-inbox-3-messages.png" alt="Inbox" h={160} cap="App: inbox" />
          </div>
        </S>

        {/* 19b · WF-02 storyboard */}
        <S
          part="P3 · Demo · 19b WF-02 storyboard"
          title="WF-02 in five screens"
          sub="A private card becomes everyone's card."
          notes="Phone and web side by side. Frames 1–2 on the phone, 3 on the web admin, 4–5 back on the phone within seconds. On-screen footnote moved here: Exception shown live: Từ chối without a reason is blocked (BR-03); the card stays pending."
        >
          <Storyboard
            h={300}
            steps={[
              { src: 'cr-01-phone-send-dialog.png', title: 'Share', text: 'user sends own card' },
              { src: 'cr-02-phone-pending.png', title: 'Pending', text: '"Đang chờ duyệt"' },
              { src: 'wa-08-review-approved-crop.png', title: 'Approve', text: 'staff, web admin', web: true },
              { src: 'cr-05-phone-approved-run3.png', title: 'In catalog', text: '"Đã vào kho chung ✓"' },
              { src: 'cr-06-phone-inbox-3-messages.png', title: 'Inbox', text: 'message for the author' },
            ]}
          />
        </S>

        {/* 20 · WF-03 */}
        <S
          part="P3 · Demo · 20 WF-03 · Staff"
          title="WF-03 Announce news to every user"
          sub="Staff post once; every inbox shows it in the same minute."
          notes="Trigger: staff has news. Precondition: staff or admin session. BR-04 is checked twice: in the form and in the rules. Result: the announcement exists and every user sees it in the inbox in real time. Exception: empty body, too long, or a user account → blocked. On-screen footnote moved here: Evidence: sent at 10:56, in the app inbox at 10:56 · rules R-25 (staff only, authorUid = self, title 1–80, body 1–1000) · web checklist #9–11."
        >
          <div className="col">
            <LShot src="wa-09-announcement-form-crop.png" alt="Announcement form" w={400} cap="1 · Compose (list still empty)" />
            <LShot src="wa-10-announcement-sent-crop.png" alt="Announcement sent" w={400} cap="2 · Sent at 10:56, form cleared" />
          </div>
          <LShot src="wa-11-app-inbox-announcement.png" alt="App inbox" h={470} cap="3 · App inbox, 10:56" />
          <div className="col grow">
            <Card head="Trigger · precondition"><p>Staff has news for every user · signed in as staff or admin</p></Card>
            <Card head="Decision (BR-04)"><p>Title 1–80 · body 1–1000 · authorUid = self, in the form and in the rules</p></Card>
            <Card head="Result" tone="ok"><p>Announcement published; every user's inbox shows it in real time</p></Card>
            <Card head="Exception" tone="bad"><p>Empty or too long → form error, nothing saved · user account → rejected at sign-in, rules deny (R-25)</p></Card>
          </div>
        </S>

        {/* 20b · WF-03 storyboard */}
        <S
          part="P3 · Demo · 20b WF-03 storyboard"
          title="WF-03 in three screens"
          sub="One form, every inbox."
          notes="Compose on the web, send, then show the phone inbox at the same minute. On-screen footnote moved here: Exception shown live: empty body or > 1000 characters → form error, nothing saved (BR-04)."
        >
          <Storyboard
            h={330}
            steps={[
              { src: 'wa-09-announcement-form-crop.png', title: 'Compose', text: 'staff, web admin', web: true },
              { src: 'wa-10-announcement-sent-crop.png', title: 'Sent', text: '10:56, form cleared', web: true },
              { src: 'wa-11-app-inbox-announcement.png', title: 'Every inbox', text: 'phone, 10:56' },
            ]}
          />
        </S>

        <Divider part={PARTS[3]} shots={['ac-firestore-enforced.png', 'm-wrong-role.png', 'm-journal-draft.png']} />

        {/* 21 · Testing */}
        <S
          part="P4 · Proof · 21 Testing"
          title="Testing at three levels"
          sub="Rules, code and the deployed system are each tested, with evidence in the repo."
          notes="Numbers from the latest runs on main (12/11/2026). Say what is not run: T15/T16 need a test-only email account. The one ARTEMIS failure was the agent typing key by key and timing out; the app showed the right screen. On-screen footnote moved here: CI on every PR: format, analyze, all test suites, rules in the Emulator, web build, Android build, Hosting preview · details: docs/test-report.md."
        >
          <div className="col" style={{ width: 360 }}>
            <div className="stats" style={{ gridTemplateColumns: '1fr 1fr' }}>
              <div className="stat"><b className="num">30/30</b><span>Security Rules tests</span></div>
              <div className="stat"><b className="num">303</b><span>Flutter app tests</span></div>
              <div className="stat"><b className="num">14 + 5</b><span>web admin + core tests</span></div>
              <div className="stat"><b className="num">14/15</b><span>ARTEMIS Final runs, real phone</span></div>
            </div>
          </div>
          <div className="col grow">
          <table style={{ fontSize: 15.5 }}>
            <thead>
              <tr>
                <th>Level</th>
                <th>Evidence</th>
                <th>Result</th>
              </tr>
            </thead>
            <tbody>
              <tr><td><b>Rules</b></td><td>Emulator, allowed + denied per role per collection (BR-02…BR-05)</td><td><span className="pill ok">30 / 30</span></td></tr>
              <tr><td><b>Unit / widget</b></td><td>ViewModels, repositories, screens at 360 dp</td><td><span className="pill ok">all pass</span></td></tr>
              <tr><td><b>Cross-role</b></td><td>3 runs on the deployed system, timed</td><td><span className="pill ok">3 / 3</span></td></tr>
              <tr><td><b>Web checklist</b></td><td>Actions, rejection, empty, loading, error, live role change</td><td><span className="pill ok">16 / 16</span></td></tr>
              <tr><td><b>Real device</b></td><td>Onboarding, Nốt AI, PDF, AI off, journal draft, role rejection on Galaxy A70</td><td><span className="pill ok">pass</span></td></tr>
              <tr><td><b>E2E (ARTEMIS)</b></td><td>Lab 3: 41/42 · Final T14, T17–T20 on Galaxy A70: 14/15 · T15/T16 not run</td><td><span className="pill warn">14 / 15</span></td></tr>
            </tbody>
          </table>
          <div style={{ display: 'flex', gap: 14 }}>
            <LShot src="ev-artemis.jpg" alt="ARTEMIS run" h={112} cap="ARTEMIS: agent reports SAVED" />
            <LShot src="ev-deploy-run.png" alt="GitHub Actions deploy" h={112} cap="GitHub Actions: deploy on main" />
          </div>
          </div>
        </S>

        {/* 21b · Evidence wall */}
        <S
          part="P4 · Proof · 21b Evidence wall"
          title="Evidence wall"
          sub="Every number on the testing slide has a screenshot or a log behind it."
          notes="Point at two or three tiles; all files are in evidence/ in the repo. On-screen footnote moved here: All files: evidence/ in the repo · details: docs/test-report.md"
        >
          <EvidenceWall
            items={[
              { term: ['✔ R-25 staff post announcements', '✔ R-26 only an admin changes roles', '✔ R-27 onboarding answers private', '✔ R-28 weekly PDF metadata', '✔ R-29 staff/admin cannot read private data', '✔ R-30 streak card once', 'ℹ tests 30', 'ℹ pass 30', 'ℹ fail 0'], label: 'Security Rules · Emulator', result: '30/30' },
              { src: 'ev-artemis.jpg', label: 'ARTEMIS on a real phone', result: '14/15' },
              { src: 'ev-deploy-run.png', label: 'GitHub Actions deploy', result: 'green' },
              { src: 'ac-firestore-enforced.png', label: 'App Check', result: 'enforced' },
              { src: 'wa-16-dashboard-error-crop.png', label: 'Web checklist · error state', result: '16/16' },
              { src: 'cr-05-phone-approved-run3.png', label: 'Cross-role, deployed', result: '3/3' },
              { src: 'g-crashlytics-nonfatal-list.png', label: 'Crashlytics', result: 'live' },
              { src: 'g-analytics-debugview-events.png', label: 'Analytics events', result: 'live' },
            ]}
          />
        </S>

        {/* 22 · Achievements */}
        <S
          part="P4 · Proof · 22 Achievements"
          title="Achievements"
          sub="Every brief requirement maps to a live feature and a piece of evidence."
          notes="Objective → implemented → validated. Point to evidence folders."
        >
          <table style={{ fontSize: 15.5 }}>
            <thead>
              <tr>
                <th>Brief requirement</th>
                <th>Implemented</th>
                <th>Evidence</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>Web admin: 4 screens + announcement form, deployed</td><td>Dashboard, catalog, review, announcements, users</td><td><code>evidence/web-admin/</code> (16 items)</td></tr>
              <tr><td>Role-based rules, deny by default, tested</td><td>user / staff / admin, R-01…R-30</td><td><code>evidence/firestore/rules-tests.txt</code></td></tr>
              <tr><td>Cross-role flow, real time, documented</td><td>Share card → approve → app + inbox</td><td><code>docs/cross-role-flow.md</code>, <code>evidence/cross-role/</code></td></tr>
              <tr><td>AI level 2 with RC, App Check, fallback</td><td>Kể tự do on Gemini, <code>ai_*</code> flags incl. prompts, enforced App Check</td><td><code>docs/ai-feature.md</code>, ARTEMIS T18/T19</td></tr>
              <tr><td>App Check on Firestore and AI Logic</td><td><b>Enforced</b> on both · Web: reCAPTCHA Enterprise; Android: Play Integrity</td><td><code>evidence/app-check/</code></td></tr>
              <tr><td>Lab 3 PDF saved & shared on device</td><td>pdf + share_plus, metadata in Firestore</td><td>15.4 KB file pulled from the phone</td></tr>
              <tr><td>Mobile data on Firestore with inbox</td><td>Announcements + personal inbox, real time</td><td>web checklist #11</td></tr>
              <tr><td colSpan={3} style={{ color: "#b3261e" }}><b>Not met:</b> ARTEMIS T15/T16 (email sign-in) not run → slide 23</td></tr>
            </tbody>
          </table>
        </S>

        {/* 23 · Limitations */}
        <S
          part="P4 · Proof · 23 Limitations & next steps"
          title="Limitations and next steps"
          sub="What is not done yet, and what it costs."
          notes="Honest list, each with impact and a next step."
        >
          <table>
            <thead>
              <tr>
                <th>Limitation</th>
                <th>Impact</th>
                <th>Priority</th>
                <th>Next step</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>ARTEMIS T15/T16 (email sign-in) not run</td><td>Sign-out / sign-in by email has widget tests only, no E2E on a device</td><td><span className="pill warn">Medium</span></td><td>Create a test-only account, run 3× each</td></tr>
              <tr><td>Names can reach Gemini (CR-F2)</td><td>Email and phone are scrubbed, but a friend's name is sent as typed</td><td><span className="pill warn">Medium</span></td><td>Consent sheet says so; add on-device name masking</td></tr>
              <tr><td>Exploratory session X01: 10 UI issues not rechecked</td><td>Possible small layout bugs on rarely used screens</td><td><span className="pill">Low</span></td><td>Re-run X01 on the Final build, fix or close each</td></tr>
              <tr><td>D-1 took 22 s on an idle phone</td><td>Real time not guaranteed after long idle</td><td><span className="pill">Low</span></td><td>Measure more runs; re-listen on resume</td></tr>
              <tr><td>App Check on Authentication only monitored</td><td>26% of sign-in requests are unverified; Firestore and AI Logic are enforced</td><td><span className="pill warn">Medium</span></td><td>Enforce once all traffic is verified</td></tr>
            </tbody>
          </table>
        </S>

        {/* 24 · Lessons */}
        <Page
          dense
          part="PROOF · 24"
          title="Lessons learned"
          line="Three bugs appeared only on the real project; three habits we keep."
          notes="Left: three bugs surfaced only against the real project or a real phone; all three are fixed, the first two with regression tests. Right: what we take away. The lesson: test on the deployed system with real accounts and real devices, not only the Emulator."
        >
          <div className="p1-body ls-body">
            <div className="ls-col">
              <h3 className="ls-h bad">Found on the real system, then fixed</h3>
              {[
                { I: Timer, t: 'Approve timed out', problem: 'Riverpod paused the provider nobody watched', fix: 'read it once · PR #70' },
                { I: WifiOff, t: 'Dashboard spun offline', problem: 'count() waited forever without a network', fix: '15 s timeout and an error state · PR #71' },
                { I: Bot, t: 'Gemini model retired', problem: 'new projects got a 404 from the old model name', fix: 'model name moved to Remote Config' },
              ].map(({ I, t, problem, fix }) => (
                <div key={t} className="ls-item">
                  <span className="ls-ic bad"><I size={22} /></span>
                  <div>
                    <b>{t}</b>
                    <p>{problem}</p>
                    <p className="fix">✓ Fixed: {fix}</p>
                  </div>
                </div>
              ))}
            </div>
            <div className="ls-col">
              <h3 className="ls-h">What we keep doing</h3>
              {[
                { I: ShieldCheck, t: 'Rules are the backend', text: 'Every business rule is a rules condition, so the rules get their own tests (30/30).' },
                { I: BookOpen, t: 'Read the brief twice', text: 'We removed the PDF, re-read the brief, and put it back: saved on the device.' },
                { I: LifeBuoy, t: 'AI needs a plan B', text: 'App Check, quota and model changes broke AI once; writing by hand kept the flow alive.' },
              ].map(({ I, t, text }) => (
                <div key={t} className="ls-item">
                  <span className="ls-ic"><I size={22} /></span>
                  <div>
                    <b>{t}</b>
                    <p>{text}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Page>

        {/* 25 · Conclusion */}
        <S
          part="P4 · Proof · 25 Conclusion"
          title="Conclusion"
          sub="Nốt is now a working multi-role system, and we can show every claim."
          notes="Three messages: the problem is solved, the product works, and every claim is verified. Then move to the thank-you slide for questions."
        >
          <div className="col grow cc-left">
            {[
              { I: CheckCircle2, head: 'Problem solved', text: 'One small win in 30 s, Gemini sorts the day, and staff keep the challenges fresh and reach every inbox.' },
              { I: Smartphone, head: 'Working product', text: 'WF-01, WF-02, WF-03 run live on Android and the deployed web admin, on the free plan.' },
              { I: ShieldCheck, head: 'Verified', text: '30/30 rules tests · 300+ code tests in CI · 14/15 ARTEMIS runs on a real phone · 3 timed cross-role runs · App Check enforced.' },
            ].map(({ I, head, text }, i) => (
              <div key={head} className="cc-item">
                <span className="cc-ic"><I size={26} /></span>
                <div>
                  <b><span>{i + 1}</span>{head}</b>
                  <p>{text}</p>
                </div>
              </div>
            ))}
            <div className="chips cc-chips">
              <span><Link2 size={15} /> prm393-not-lab3.web.app</span>
              <span><Link2 size={15} /> /admin/</span>
              <span><Link2 size={15} /> github.com/FU-PRM-Projects/Lab-03</span>
            </div>
          </div>
          <div className="collage">
            <img className="c-web" src={img('wa-05-catalog-edit-crop.png')} alt="Staff edit a card in the catalog" />
            <img className="c-phone c-a" src={img('g-streak-streak-today.png')} alt="Streak today" />
            <img className="c-phone c-b" src={img('07-weekly-card.png')} alt="Weekly card" />
            <span className="c-tag c-tag-web">Staff keep cards fresh</span>
            <span className="c-tag c-tag-app">A week of small wins</span>
          </div>
        </S>

        {/* A1 · Appendix */}
        <S
          part="Appendix · A1 · AI examples"
          title="AI examples"
          sub="Three real Gemini inputs and outputs, and one handled failure."
          notes="Backup slide for AI questions. From docs/ai-feature.md. On-screen footnote moved here: Inputs are scrubbed (email, phone) and capped at 500 characters; no names, emails or photos are sent."
        >
          <div className="col grow">
          <table style={{ fontSize: 15 }}>
            <thead>
              <tr>
                <th style={{ width: '40%' }}>Input (Kể tự do)</th>
                <th>Gemini output</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>Ran 2 km, ate a snack I meant to skip, calmed down without blaming myself</td><td>chien_thang "Chạy bộ 2km quanh hồ" · nhat_ky "Lỡ ăn thêm gói snack…" · tu_chu "Không tự trách và bình tĩnh lại" · mood binh_thuong</td></tr>
              <tr><td>Asked a stranger in the library where to charge my phone; wrote a few lines about the rainy afternoon</td><td>chien_thang "Lấy hết can đảm hỏi mượn chỗ sạc pin" · nhat_ky "Ghi lại vài dòng cảm xúc buổi chiều mưa" · mood vui</td></tr>
              <tr><td>Tired for days, only tidied my desk today</td><td>chien_thang "Mình đã dọn dẹp được cái bàn học" · 2× nhat_ky · mood met · needs_support false</td></tr>
              <tr><td><b>Handled failure</b></td><td>404 model retired / 401 missing App Check → <code>ai_error</code> logged, paragraph kept, "Ghi tay" offered; fixed by Remote Config model name</td></tr>
            </tbody>
          </table>
          </div>
          <div className="col" style={{ width: 340 }}>
            <Code name="f-ai-model" w={340} cap="JSON schema forces the answer shape" />
            <LShot src="ev-rc-params.png" alt="Remote Config parameters" w={340} cap="Remote Config: model, prompts, on/off" />
          </div>
        </S>

        {/* A2 · App Check */}
        <S
          part="Appendix · A2 · App Check"
          title="App Check: registered and enforced"
          sub="Both apps are registered; Firestore and AI Logic are enforced."
          notes="Backup slide. Before enforcing we checked that the release build passes Play Integrity (Gemini works with AI Logic enforced). After enforcing, the web admin and the phone still read Firestore. On-screen footnote moved here: Web: reCAPTCHA Enterprise (Fraud Defense) · Android: Play Integrity (debug builds need a registered debug token) · enforced 12/11/2026 · evidence/app-check/."
        >
          <LShot src="ac-apps-registered.png" alt="App Check apps registered" w={560} cap="Apps: lab03 (android) Play Integrity · lab03 (web) Fraud Defense" />
          <LShot src="ac-firestore-enforced.png" alt="Firestore enforced" w={560} cap="Cloud Firestore: Enforced · AI Logic: Enforced" />
        </S>

        {/* Thank you · last slide */}
        <Slide className="fd p1 closing" notes="Thank the panel and open the floor for questions. The appendix (AI examples, App Check) sits just before this slide if a question needs it.">
          <img className="org-logo" src={`${base}assets/fpt-logo.webp`} alt="FPT University" />
          <div className="cl-left">
            <p className="cl-kicker">Nốt · PRM393 Final Assignment</p>
            <h1>Thank you</h1>
            <p className="cl-q">Questions?</p>
            <p className="cl-links">prm393-not-lab3.web.app · /admin/ · github.com/FU-PRM-Projects/Lab-03</p>
          </div>
          <div className="cl-art">
            <img className="cl-confetti" src={`${base}assets/illustrations/confetti.svg`} alt="" />
            <img className="cl-jar" src={`${base}assets/illustrations/jar.svg`} alt="" />
            <img className="cl-mascot" src={`${base}assets/mascot/mascot-not-xong.svg`} alt="" />
          </div>
        </Slide>
      </Deck>
    </div>
  );
}
