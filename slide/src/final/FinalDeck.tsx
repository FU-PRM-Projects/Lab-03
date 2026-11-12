import { createContext, useContext, type ReactNode } from 'react';
import { Deck, Slide } from '@revealjs/react';
import RevealNotes from 'reveal.js/plugin/notes';

import 'reveal.js/reveal.css';
import '../slides.css';
import './final.css';

const base = import.meta.env.BASE_URL;
const img = (name: string) => `${base}final/${name}`;

/** FPT University logo, top right of each page (top left on the cover). */
function OrgLogo({ cover }: { cover?: boolean }) {
  return <img className={cover ? 'org-logo cover' : 'org-logo'} src={`${base}assets/fpt-logo.webp`} alt="FPT University" />;
}

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
    <Slide className={dense ? 'fx dense' : 'fx'} notes={notes}>
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

/** A small red label over a plain block of text, no box around it. */
function Block({ head, tone, children }: { head: string; tone?: 'bad' | 'ok'; children: ReactNode }) {
  return (
    <div className={tone ? `fx-block ${tone}` : 'fx-block'}>
      <h3>{head}</h3>
      {children}
    </div>
  );
}

/* ---------------------------------------------------------------- diagrams */

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

        {/* 01 · Overview */}
        <Page
          part="PROBLEM · 01"
          title="Overview"
          foot="prm393-not-lab3.web.app · /admin/ · github.com/FU-PRM-Projects/Lab-03"
          notes="30 seconds. Product: Nốt. Users: final-year students (persona Minh). Value: notice small wins instead of unfinished tasks; a curated, growing challenge catalog. Platform: Android plus a Flutter Web admin, both live at prm393-not-lab3.web.app and /admin/; repo FU-PRM-Projects/Lab-03. Added on top of Lab 3: roles user / staff / admin and a web admin with 5 screens; the cross-role flow where a user shares a card, staff approve it and the app updates in real time; Nốt AI (Gemini via Firebase AI Logic); inbox for announcements, first-run onboarding, weekly card PDF saved on the device."
        >
          <div className="fx-split">
            <ul className="fx-list">
              <li>Users log a win on Android</li>
              <li>Staff curate the cards on the web</li>
              <li>Gemini sorts the day into notes</li>
              <li>One Firestore, rules per role</li>
            </ul>
            <Shot src="05-ai-free-tell-result.png" alt="Nốt AI suggestions" h={380} />
          </div>
        </Page>

        {/* 02 · Context */}
        <Page
          part="PROBLEM · 02"
          title="Context"
          foot="Source: Lab 2 persona and success criterion (docs/design-traceability.md)"
          notes="Context, not problem yet. Persona Minh, 22, final year, worn out. Lab 2 success criterion: log a mood and one small win in under 30 seconds after tapping the evening reminder. After Lab 3: one user, own data only (notes, habits, groups); challenge cards were a fixed seed list in Firestore; own cards stayed private. Now also involved: staff who write and curate cards, an admin who decides who is staff, and Gemini to cut typing in the evening."
        >
          <div className="fx-split">
            <ul className="fx-list">
              <li>Goal: a mood and one win in under 30 seconds</li>
              <li>Lab 3: one user, a fixed list of cards</li>
              <li>Missing: staff, an admin, a way to reach users</li>
            </ul>
            <Shot src="07-weekly-card.png" alt="Weekly card" h={380} cap="Weekly card, kept from Lab 3" />
          </div>
        </Page>

        {/* 03 · Problem */}
        <Page
          dense
          part="PROBLEM · 03"
          title="Problem"
          foot="Evidence: docs/gap-review.md. No user survey; impacts observed in the Lab 3 build."
          notes="Pain points with cause and impact. Evidence is our own Lab 3 state (docs/gap-review.md), not a survey; we say that openly."
        >
          <table className="fx-table">
            <thead>
              <tr>
                <th style={{ width: '26%' }}>Pain point</th>
                <th style={{ width: '38%' }}>Cause</th>
                <th>Impact</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><b>Static challenge content</b></td>
                <td>Cards were a seed list; changing one needed a developer</td>
                <td>Users run out of fresh cards</td>
              </tr>
              <tr>
                <td><b>No way to reach users</b></td>
                <td>No staff role, no announcements</td>
                <td>Nobody can tell users about news in the app</td>
              </tr>
              <tr>
                <td><b>Logging takes effort at night</b></td>
                <td>Each note is typed and classified by hand</td>
                <td>The 30 s goal slips on a busy day</td>
              </tr>
              <tr>
                <td><b>Lab 3 flow unfinished</b></td>
                <td>Weekly PDF went to Cloud Storage (paid plan)</td>
                <td>Export never worked on the real project</td>
              </tr>
            </tbody>
          </table>
        </Page>

        {/* 04 · Proposed solution */}
        <Page
          dense
          part="PROBLEM · 04"
          title="Proposed solution"
          foot="Out of scope: Cloud Functions, Cloud Storage, AI level 3 “Hỏi Nốt”, iOS"
          notes="Pain point to solution to value. Scope. In scope (MVP): WF-01 Log the day with Nốt AI; WF-02 Publish a user card to the catalog; WF-03 Announce to all users; onboarding, weekly PDF, roles, App Check. Out of scope on purpose: Cloud Functions and Cloud Storage (the brief and the paid plan), AI level 3 'Hỏi Nốt' (bonus, not built), iOS build."
        >
          <table className="fx-table">
            <thead>
              <tr>
                <th>Pain point</th>
                <th>Solution</th>
                <th>Value</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><b>Static content</b></td>
                <td>Web admin catalog; users share cards, staff approve</td>
                <td>Catalog grows without a release</td>
              </tr>
              <tr>
                <td><b>No channel</b></td>
                <td>Announcements and a personal inbox</td>
                <td>News lands in the same minute</td>
              </tr>
              <tr>
                <td><b>Slow evenings</b></td>
                <td>Nốt AI: tell the day once, confirm the notes</td>
                <td>Several notes from one paragraph</td>
              </tr>
              <tr>
                <td><b>Broken PDF</b></td>
                <td>Build and save it on the device</td>
                <td>Works on the free plan, offline</td>
              </tr>
            </tbody>
          </table>
        </Page>

        {/* 05 · Actors */}
        <Page
          dense
          part="PROBLEM · 05"
          title="Main actors"
          foot="Role lives in users/{uid}.role; only an admin changes it, never their own."
          notes="Actors match the real permission model in firestore.rules and the web admin's role check. First admin: set in the Firebase Console (Thị Kim Thúy Đoàn). Rules tests R-19…R-30 cover every role and collection."
        >
          <table className="fx-table">
            <thead>
              <tr>
                <th style={{ width: '14%' }}>Actor</th>
                <th style={{ width: '14%' }}>Client</th>
                <th>Main permissions</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><b>User</b></td>
                <td>Android app</td>
                <td>Own notes; share own cards (pending only); read catalog, announcements, own inbox</td>
              </tr>
              <tr>
                <td><b>Staff</b></td>
                <td>Web admin</td>
                <td>Create, edit, archive cards; approve or reject with a reason; post announcements</td>
              </tr>
              <tr>
                <td><b>Admin</b></td>
                <td>Web admin</td>
                <td>Everything staff can do, plus change other users' roles</td>
              </tr>
              <tr>
                <td><b>Gemini</b></td>
                <td>External</td>
                <td>Receives the scrubbed paragraph only; returns JSON suggestions</td>
              </tr>
              <tr>
                <td><b>Firebase</b></td>
                <td>Platform</td>
                <td>Rules decide every read and write; no custom server</td>
              </tr>
            </tbody>
          </table>
        </Page>

        {/* 06 · Features */}
        <Page
          part="PROBLEM · 06"
          title="Main features"
          foot="Also: onboarding · weekly PDF · streaks · self-control · groups · Discord link · dashboard"
          notes="Three workflows, one story: the user logs the day, shares a card that staff approve, staff announce it. Each has an actor, a trigger and a business result, not a list of buttons. Other features: onboarding & starter plan, weekly card PDF, streaks & journey, self-control & breathing, groups, Discord link, dashboard, roles."
        >
          <div className="fx-cols">
            {[
              ['WF-01', 'Log the day with Nốt AI', 'User', 'Taps Ghi nốt → Kể tự do', 'Notes saved after confirming'],
              ['WF-02', 'Publish a card to the catalog', 'User + Staff', 'Shares an own card', 'Card in catalog, inbox message'],
              ['WF-03', 'Announce to all users', 'Staff', 'Has news for everyone', 'Shown in every user inbox'],
            ].map(([id, name, actor, trigger, result]) => (
              <div key={id} className="fx-wf">
                <h3>{id}</h3>
                <b>{name}</b>
                <p>{actor}</p>
                <p>{trigger}</p>
                <p>→ {result}</p>
              </div>
            ))}
          </div>
        </Page>

        {/* 07 · Business flow */}
        <Page
          dense
          part="DESIGN · 07"
          title="Business flow"
          foot="BR-AI1: AI only when enabled, consented, App Check · BR-02: pending only · BR-03: reject needs a reason"
          notes="Walk the lanes left to right: WF-01 stays in the user's own data; WF-02 crosses from user to staff and back; WF-03 goes from staff to everyone. The three workflows share one Firestore; rules are the decision points. BR-AI1: AI only when enabled, consented and App Check passes. BR-02: user creates pending only. BR-03: reject needs a reason."
        >
          <BusinessFlow />
        </Page>

        {/* 08 · State machine */}
        <Page
          dense
          part="DESIGN · 08"
          title="State machine"
          foot="Tests R-20…R-24 · 30/30 rules tests pass"
          notes="Entity: challengeSubmissions/{id}. Event, guard, action. Every transition and every forbidden one has a rules test in the Emulator: R-20 create pending only, R-21 read own or staff, R-22 staff review with a reason on reject, R-23 withdraw while pending, R-24 inbox. 30/30 rules tests pass (R-01…R-30)."
        >
          <StateMachine />
        </Page>

        {/* 09 · Architecture */}
        <Page
          dense
          part="DESIGN · 09"
          title="System architecture"
          foot="GitHub Actions deploys Hosting (/ and /admin/) and rules on merge to main"
          notes="Decision: no custom server. Security Rules + App Check are the backend's access layer. Trade-off: no server means rules carry the business rules (validation, transitions). Benefit: free plan, real time, less to run. Cost: complex rules, so we test them. Deploy: GitHub Actions builds both clients, deploys Hosting and Firestore rules + indexes on merge to main."
        >
          <Architecture />
        </Page>

        {/* 10 · Tech stack */}
        <Page
          dense
          part="DESIGN · 10"
          title="Technology stack"
          foot="Source: app and web admin pubspec, discord_bot/Cargo.toml, GitHub workflows"
          notes="Only what is in pubspec / package.json / Cargo.toml / workflows. The Discord bot is the one non-Dart part: a Rust service (Poise on Serenity) that runs on a VPS with Docker through Dokploy. It chats with a linked user over DM, calls an OpenRouter model (default deepseek) through rig-core with tools that only touch that user's notes, and reads and writes Firestore through the REST API with a service account. Photos go to Cloudinary. A guard model checks abuse and there is a per-user cooldown. It is an extra, not part of the three core workflows."
        >
          <table className="fx-table fx-small">
            <thead>
              <tr>
                <th style={{ width: '11%' }}>Group</th>
                <th style={{ width: '43%' }}>Technology</th>
                <th>Used for</th>
              </tr>
            </thead>
            <tbody>
              <tr><td><b>Mobile</b></td><td>Flutter (Dart) · Riverpod · charts · PDF · sharing and camera</td><td>Android app in MVVM; charts; weekly card PDF saved and shared on the device</td></tr>
              <tr><td><b>Web</b></td><td>Flutter Web (Dart) · Riverpod · Firebase Hosting</td><td>Web admin for staff and admin, served from Firebase Hosting at /admin/</td></tr>
              <tr><td><b>Shared</b></td><td>Shared Dart package</td><td>Models, repositories and design tokens used by both clients</td></tr>
              <tr><td><b>Backend</b></td><td>Firebase: Firestore · Rules · Auth · Remote Config · Messaging · Analytics · Crashlytics</td><td>Data, role permissions, flags, push, usage and crash reports; no custom server</td></tr>
              <tr><td><b>AI</b></td><td>Firebase AI Logic · Google Gemini</td><td>Nốt AI: sort one paragraph into notes with a JSON schema, model name kept in Remote Config</td></tr>
              <tr><td><b>Security</b></td><td>Firebase App Check · Google Play Integrity · reCAPTCHA Enterprise</td><td>Only our own apps reach Firestore and Gemini</td></tr>
              <tr><td><b>Discord bot</b></td><td><b>Rust</b> · Discord API · async runtime · HTTP client</td><td>Assistant in Discord DM: the connect command links a Nốt account with a 6-character code, then the user manages notes by chatting</td></tr>
              <tr><td><b>Bot AI</b></td><td>LLM agent framework · OpenRouter · DeepSeek</td><td>Agent with tools bound to the linked user's own notes; a guard model and a cooldown limit abuse</td></tr>
              <tr><td><b>Bot data</b></td><td>Firestore REST API · Google service account · Cloudinary</td><td>Reads and writes notes and account links; uploads photos sent in the chat</td></tr>
              <tr><td><b>Media</b></td><td>Cloudinary</td><td>Note photos, because Cloud Storage needs the paid plan</td></tr>
              <tr><td><b>Quality</b></td><td>Flutter tests · Firebase Emulator · ARTEMIS · CodeRabbit</td><td>Unit and widget tests, rules tests, E2E on a real phone, AI code review on PRs</td></tr>
              <tr><td><b>DevOps</b></td><td>GitHub Actions · Firebase Hosting previews · Docker · Dokploy</td><td>CI, PR previews, deploy on merge; the bot ships as a Docker image on a VPS</td></tr>
            </tbody>
          </table>
        </Page>

        {/* 11 · UI/UX */}
        <Page
          dense
          part="DESIGN · 11"
          title="UI/UX design"
          foot="States: empty · loading · error (5 screens) · success"
          notes="Lab 2 tokens live in packages/core; the web admin reuses them in a wide layout. Same indigo, Be Vietnam Pro, mascot for empty and error. Show loading, empty, error, success on the web admin. Error uses the shared MessageView.error on 5 screens."
        >
          <div className="fx-row">
            <div className="fx-grid2">
              <Shot src="wa-07-review-empty.png" alt="Empty review queue" w={400} cap="Empty: review queue" />
              <Shot src="wa-13-dashboard-loading.png" alt="Dashboard loading" w={400} cap="Loading: dashboard" />
              <Shot src="wa-08-review-approved.png" alt="Approved list" w={400} cap="Success: approved cards" />
              <Shot src="wa-16-dashboard-error.png" alt="Dashboard error" w={400} cap="Error: dashboard, server unreachable" />
            </div>
            <Shot src="11-ai-off-remote-config.png" alt="Nốt AI off" h={440} cap="App: AI off" />
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
          foot="Tests swap in fakes · 290 app · 10 web admin · 5 core"
          notes="Business rules sit in the repository + Security Rules, not in widgets. Screen → Notifier/actions → service interface → Firestore implementation in packages/core. main.dart wires each provider to its Firebase implementation; fakes replace the interfaces in tests (290 app, 10 web admin, 5 core tests)."
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
          foot="Final additions only; Lab 3 data (notes, groups, habits, …) is not drawn · attributes: next slide"
          notes="Business-level model, drawn in crow's foot (IE) notation, so it has no attributes, keys or collection names; those are on the physical slide. Read each line with its verb: a user owns custom cards, sends submissions, receives inbox messages, saves weekly reports, answers the onboarding questions and reads announcements. A submission is shared from at most one custom card, and becomes at most one challenge card. A staff member (a user with role staff or admin) reviews submissions, which results in one inbox message, maintains challenge cards and posts announcements. Only the Final additions are drawn: the challenge catalog existed in Lab 3 as a seed list, and the Final added staff writing to it and the link to submissions. Lab 3 data (notes, groups, habits, progress, streaks) stays private to its owner and is not drawn. Notation and sources: docs/erd-notation.md."
        >
          <Erd />
        </Page>

        {/* 15 · DB physical */}
        <Page
          dense
          part="DESIGN · 15"
          title="Database design: physical"
          foot="Types, limits and rules per field: docs/erd.svg · docs/data-model.md"
          notes="No schema in Firestore, so the shape, sizes and transitions are enforced by rules and covered by tests. Indexes: submissions (uid, createdAt↓), (status, createdAt↓); notes (groupId, createdAt↓). Full table: docs/data-model.md. The diagram shows every collection with its fields; the full version with types and limits is docs/erd.svg. Rules per collection: users: only an admin changes a role, never their own; challenges: staff only, archive instead of delete; challengeSubmissions: create as pending, staff review, reason on reject; inbox: staff create, the owner may only flip read; announcements: staff create, every signed-in user reads; reports: owner only, id = ISO week; onboarding: owner only, enums checked."
        >
          <img className="fx-erd" src={img('erd-slide.svg')} alt="Firestore data model: collections, fields, keys and relationships" />
        </Page>

        {/* 16 · Traceability */}
        <Page
          dense
          part="DESIGN · 16"
          title="Traceability"
          foot="Full matrix: docs/design-traceability.md"
          notes="Feature → screen → class → collection → tests. Also shows where tests are still missing (ARTEMIS for new flows). Rules: firebase/tests/firestore.rules.test.js. E2E: e2e_test/."
        >
          <table className="fx-table">
            <thead>
              <tr>
                <th>Workflow</th>
                <th>Screen</th>
                <th>Class</th>
                <th>Collection</th>
                <th>Tests</th>
              </tr>
            </thead>
            <tbody>
              <tr><td><b>WF-01</b> Nốt AI</td><td>Kể tự do</td><td>FreeTellViewModel</td><td>notes</td><td>free_tell_flow_test · real device</td></tr>
              <tr><td><b>WF-02</b> Share</td><td>Review queue</td><td>ReviewActions</td><td>challengeSubmissions</td><td>R-20…R-24 · D-1…D-3</td></tr>
              <tr><td><b>WF-03</b> Announce</td><td>Announcements</td><td>AnnouncementActions</td><td>announcements</td><td>R-25 · inbox test</td></tr>
              <tr><td>Weekly PDF</td><td>Thẻ tuần</td><td>WeeklyReportViewModel</td><td>reports</td><td>R-28 · real device</td></tr>
              <tr><td>Onboarding</td><td>S13a–g</td><td>OnboardingViewModel</td><td>private/onboarding</td><td>R-27 · flow test</td></tr>
              <tr><td>Roles</td><td>Sign-in · Users</td><td>sessionProvider</td><td>users</td><td>R-01, R-26</td></tr>
            </tbody>
          </table>
        </Page>

        {/* 17 · Demo plan */}
        <Page
          part="DEMO · 17"
          title="Demo plan"
          foot="Ready: admin account · Galaxy A70 with debug token · ai_enabled toggle · backup video"
          notes="The result of each workflow is the input of the next. Order: WF-01 on the phone, WF-02 phone + web side by side, WF-03 on the web then the phone. Accounts ready, App Check debug token registered on the demo phone. Results: jar 11 → 14 notes and a streak starts; card 'Người dùng đề xuất' in the catalog plus an inbox message; announcement in the app inbox at 10:56, same minute. Exception paths shown live: Remote Config ai_enabled = false gives 'Nốt AI đang nghỉ' and the user writes by hand; reject without a reason is blocked; a non-staff account is rejected at sign-in."
        >
          <div className="fx-cols">
            {[
              ['01 · User', 'Kể tự do', 'One paragraph becomes 3 saved notes'],
              ['02 · User → Staff', 'Share and approve', '“Đi bộ 10 phút” shows up in the app'],
              ['03 · Staff → Users', 'Announce', '“Bạn đã vận động chưa?” in every user inbox'],
            ].map(([who, name, result]) => (
              <div key={who} className="fx-wf">
                <h3>{who}</h3>
                <b>{name}</b>
                <p>{result}</p>
              </div>
            ))}
          </div>
          <p className="fx-bar bad">Shown live: AI off, so the user writes by hand · reject without a reason is blocked</p>
        </Page>

        {/* 18 · WF-01 */}
        <Page
          dense
          part="DEMO · 18"
          title="WF-01 · Nốt AI"
          foot="Galaxy A70 · real Gemini (~2 s) · gemini-flash-lite-latest"
          notes="Trigger: evening, user taps Ghi nốt → Kể tự do. Steps: first use shows a consent sheet (what is and is not sent); the paragraph is scrubbed (email, phone) and capped at 500 chars; Gemini returns notes and a mood as JSON; suggestions are labelled 'Gợi ý từ Nốt AI', editable and untickable. Exception: AI off, quota, network or App Check gives a message and 'Ghi tay'; the paragraph is kept. Evidence: run 10/11/2026 on Galaxy A70 against the real project; AI level 2, JSON schema to AiSortResult, confirmed by the user."
        >
          <div className="fx-split">
            <div className="fx-text">
              <Block head="Trigger">
                <p>Evening: Ghi nốt → Kể tự do</p>
              </Block>
              <Block head="Result">
                <p>Gemini returns labelled notes; the user edits and saves</p>
              </Block>
              <Block head="Exception" tone="bad">
                <p>AI off or error: message and “Ghi tay”, text kept</p>
              </Block>
            </div>
            <div className="fx-row">
              <Shot src="04-ai-consent.png" alt="Kể tự do input screen" h={430} cap="Input (consent sheet on first use)" />
              <Shot src="05-ai-free-tell-result.png" alt="Suggestions" h={430} cap="Suggestions" />
              <Shot src="11-ai-off-remote-config.png" alt="AI off" h={430} cap="ai_enabled = false" />
            </div>
          </div>
        </Page>

        {/* 19 · WF-02 */}
        <Page
          dense
          part="DEMO · 19"
          title="WF-02 · Share a card"
          foot="Server write 1.4 s after Duyệt · phone ≤ 3.4 s (D-2), ≤ 2.3 s (D-3), 22 s (D-1, idle phone)"
          notes="Cross-role, measured three times on the deployed system (docs/cross-role-flow.md). D-1 slow (22 s, listener idle); D-2 and D-3 within 2–4 s. State: pending → approved, or rejected with a reason. Steps: user taps Gửi cho mọi người; staff opens Hàng chờ duyệt and picks Duyệt with a level; a batch writes the catalog card, the status and an inbox message; the app shows 'Đã vào kho chung ✓' and a bell badge. Exception: reject needs a reason (rules + UI); a user cannot approve (R-22). Also mention the approve bug found here and fixed."
        >
          <div className="fx-row">
            <Shot src="cr-02-phone-pending.png" alt="Pending" h={440} cap="1 · Đang chờ duyệt" />
            <Shot src="wa-08-review-approved.png" alt="Approved on web" h={200} cap="2 · Web: approved" />
            <Shot src="cr-06-phone-inbox-3-messages.png" alt="Inbox" h={440} cap="3 · App: inbox" />
          </div>
        </Page>

        {/* 20 · WF-03 */}
        <Page
          dense
          part="DEMO · 20"
          title="WF-03 · Announce"
          foot="Rules R-25: staff only · authorUid = self · title ≤ 80 · body 1–1000"
          notes="Form validation (title ≤ 80, body ≤ 1000), staff only. Exception: empty body or non-staff, rules deny (R-25). Shows in the app inbox at the same minute. Web checklist #9–11."
        >
          <div className="fx-row">
            <div className="fx-stack">
              <Shot src="wa-09-announcement-form.png" alt="Announcement form" w={380} cap="1 · Compose" />
              <Shot src="wa-10-announcement-sent.png" alt="Announcement sent" w={380} cap="2 · Sent at 10:56" />
            </div>
            <Shot src="wa-11-app-inbox-announcement.png" alt="App inbox" h={440} cap="3 · App inbox, 10:56" />
          </div>
        </Page>

        {/* 21 · Testing */}
        <Page
          dense
          part="PROOF · 21"
          title="Testing"
          foot="CI on every PR: format, analyze, all suites, rules in the Emulator, builds, Hosting preview"
          notes="Numbers from the latest runs on main. Be honest about what is not run yet: ARTEMIS for the Final flows. CI on every PR: format, analyze, all test suites, rules in the Emulator, web build, Android build, Hosting preview."
        >
          <div className="fx-stats">
            <p><b>30/30</b><span>rules tests</span></p>
            <p><b>290</b><span>app tests</span></p>
            <p><b>10 + 5</b><span>web + core tests</span></p>
            <p><b>41/42</b><span>ARTEMIS runs (Lab 3)</span></p>
          </div>
          <table className="fx-table">
            <thead>
              <tr>
                <th style={{ width: '20%' }}>Level</th>
                <th>Evidence</th>
                <th style={{ width: '14%' }}>Result</th>
              </tr>
            </thead>
            <tbody>
              <tr><td><b>Rules</b></td><td>Emulator: allowed and denied per role per collection</td><td className="ok">30 / 30</td></tr>
              <tr><td><b>Unit / widget</b></td><td>ViewModels, repositories, screens at 360 dp</td><td className="ok">all pass</td></tr>
              <tr><td><b>Cross-role</b></td><td>3 timed runs on the deployed system</td><td className="ok">3 / 3</td></tr>
              <tr><td><b>Web checklist</b></td><td>13 screenshots: actions, rejection, empty, loading</td><td className="ok">done</td></tr>
              <tr><td><b>Real device</b></td><td>Onboarding, Nốt AI, PDF, AI off on Galaxy A70</td><td className="ok">pass</td></tr>
              <tr><td><b>E2E (ARTEMIS)</b></td><td>Lab 3 flows 3× each; Final flows written, not run</td><td className="warn">partial</td></tr>
            </tbody>
          </table>
        </Page>

        {/* 22 · Achievements */}
        <Page
          dense
          part="PROOF · 22"
          title="Achievements"
          notes="Objective → implemented → validated. Point to the evidence folders."
        >
          <table className="fx-table">
            <thead>
              <tr>
                <th>Brief requirement</th>
                <th>Implemented</th>
                <th>Evidence</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>Web admin, deployed</td><td>Dashboard, catalog, review, announcements, users</td><td><code>evidence/web-admin/</code></td></tr>
              <tr><td>Role-based rules, tested</td><td>user / staff / admin, R-01…R-30</td><td><code>evidence/firestore/</code></td></tr>
              <tr><td>Cross-role flow, real time</td><td>Share card → approve → app + inbox</td><td><code>docs/cross-role-flow.md</code></td></tr>
              <tr><td>AI level 2 with fallback</td><td>Kể tự do on Gemini, Remote Config flags</td><td><code>docs/ai-feature.md</code></td></tr>
              <tr><td>App Check</td><td>reCAPTCHA Enterprise · Play Integrity</td><td><code>evidence/app-check/</code></td></tr>
              <tr><td>Lab 3 PDF on device</td><td>pdf + share_plus, metadata in Firestore</td><td>15.4 KB file from the phone</td></tr>
              <tr><td>Mobile data with inbox</td><td>Announcements + personal inbox</td><td>web checklist #11</td></tr>
            </tbody>
          </table>
        </Page>

        {/* 23 · Limitations */}
        <Page
          dense
          part="PROOF · 23"
          title="Limitations & next steps"
          notes="Honest list, each with impact and a next step."
        >
          <table className="fx-table">
            <thead>
              <tr>
                <th>Limitation</th>
                <th>Impact</th>
                <th style={{ width: '11%' }}>Priority</th>
                <th>Next step</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>ARTEMIS not run for Final flows</td><td>No 3× E2E evidence for them</td><td className="bad">High</td><td>Run on the Galaxy A70, 3× each</td></tr>
              <tr><td>App Check on Authentication only monitored</td><td>26% of sign-in requests are unverified</td><td className="warn">Medium</td><td>Enforce once all traffic is verified</td></tr>
              <tr><td>Lab 2 flows A3 and P4 not built</td><td>Two designed flows missing</td><td className="warn">Medium</td><td>Build A3 on the same AiService</td></tr>
              <tr><td>D-1 took 22 s on an idle phone</td><td>Real time not guaranteed after idle</td><td>Low</td><td>Re-listen on resume</td></tr>
              <tr><td>Sideloaded release builds fail Play Integrity</td><td>AI blocked outside Play / debug</td><td>Low</td><td>Demo on debug; Play internal track</td></tr>
            </tbody>
          </table>
        </Page>

        {/* 24 · Lessons */}
        <Page
          dense
          part="PROOF · 24"
          title="Lessons learned"
          notes="Three bugs surfaced only against the real project; all three are fixed, the first two with regression tests. The lesson: test on the deployed system with real accounts and real devices, not only the Emulator."
        >
          <div className="fx-lessons">
            <p className="fx-bar bad"><b>Approve timed out</b>Riverpod paused the unwatched provider. Fixed: read once (PR #70).</p>
            <p className="fx-bar bad"><b>Dashboard spun offline</b><code>count()</code> waits forever. Fixed: 15 s timeout (PR #71).</p>
            <p className="fx-bar bad"><b>Gemini model retired</b>404 for new projects. Fixed: model name in Remote Config.</p>
            <p className="fx-bar"><b>Rules are the backend</b>Every business rule is a rules condition, so rules need tests.</p>
            <p className="fx-bar"><b>Read the brief twice</b>We removed the PDF, then re-read: the brief wanted it on the device.</p>
            <p className="fx-bar"><b>AI needs a plan B</b>App Check, quota and model changes broke AI; hand-writing kept the flow alive.</p>
          </div>
        </Page>

        {/* 25 · Conclusion */}
        <Page
          part="PROOF · 25"
          title="Conclusion"
          foot="prm393-not-lab3.web.app · /admin/ · github.com/FU-PRM-Projects/Lab-03"
          notes="Three messages, then leave this slide up for Q&A. Problem solved: content is curated by staff and grows from users' own cards; news reaches every user in the same minute. Working product: WF-01, WF-02, WF-03 run live on Android and the deployed web admin, on the free plan. Verified: 30/30 rules tests, 300+ code tests in CI, 3 timed cross-role runs, real-device AI and PDF evidence."
        >
          <div className="fx-cols">
            {[
              ['1', 'Problem solved', 'Staff curate the cards; news reaches every user in the same minute'],
              ['2', 'Working product', 'Three workflows run live on Android and the web admin'],
              ['3', 'Verified', '30/30 rules tests, 3 timed runs, real-device evidence'],
            ].map(([n, head, text]) => (
              <div key={n} className="fx-wf">
                <h3>{n}</h3>
                <b>{head}</b>
                <p>{text}</p>
              </div>
            ))}
          </div>
        </Page>

        {/* A1 · Appendix */}
        <Page
          dense
          part="APPENDIX · A1"
          title="AI examples"
          foot="Inputs are scrubbed (email, phone) and capped at 500 characters"
          notes="Backup slide for AI questions. From docs/ai-feature.md. Inputs are scrubbed (email, phone) and capped at 500 characters; no names, emails or photos are sent."
        >
          <table className="fx-table">
            <thead>
              <tr>
                <th style={{ width: '40%' }}>Input (Kể tự do)</th>
                <th>Gemini output</th>
              </tr>
            </thead>
            <tbody>
              <tr><td>Ran 2 km, ate a snack I meant to skip, calmed down without blaming myself</td><td>chien_thang “Chạy bộ 2km quanh hồ” · nhat_ky · tu_chu · mood binh_thuong</td></tr>
              <tr><td>Asked a stranger in the library where to charge my phone; wrote a few lines about the rainy afternoon</td><td>chien_thang “Lấy hết can đảm hỏi mượn chỗ sạc pin” · nhat_ky · mood vui</td></tr>
              <tr><td>Tired for days, only tidied my desk today</td><td>chien_thang “Mình đã dọn dẹp được cái bàn học” · 2× nhat_ky · mood met</td></tr>
              <tr><td><b>Handled failure</b></td><td>404 or 401 → <code>ai_error</code> logged, text kept, “Ghi tay” offered</td></tr>
            </tbody>
          </table>
        </Page>

        {/* A2 · App Check */}
        <Page
          dense
          part="APPENDIX · A2"
          title="App Check"
          foot="Web: reCAPTCHA Enterprise · Android: Play Integrity + debug token · evidence/app-check/ (12/11/2026)"
          notes="Backup slide. After both apps were registered (web with reCAPTCHA Enterprise, Android with Play Integrity), App Check was enforced for Cloud Firestore on 12/11/2026 and for Firebase AI Logic earlier; Authentication is still Monitoring. The console shows 55% verified and 45% unverified requests over 7 days: the unverified ones are the old app builds without App Check, now blocked on purpose. After enforcing, the web admin still reads the user role and the release build on the Galaxy A70 still loads the jar and the challenges, with no PERMISSION_DENIED in logcat. A debug build only reads Firestore if its debug token is registered under App Check, Apps, lab03 (android), so register it before running ARTEMIS on a debug build."
        >
          <div className="fx-row">
            <Shot src="ac-firestore-enforced.png" alt="App Check APIs: Cloud Firestore enforced" h={330} cap="Cloud Firestore and AI Logic: Enforced" />
            <Shot src="ac-mobile-after-enforce.png" alt="Jar tab after enforcing" h={400} cap="Galaxy A70, 5 min after enforcing: Hũ loads" />
          </div>
        </Page>
      </Deck>
    </div>
  );
}
