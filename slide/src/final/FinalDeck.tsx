import type { ReactNode } from 'react';
import { Deck, Slide } from '@revealjs/react';
import RevealNotes from 'reveal.js/plugin/notes';
import {
  BellRing, Code2, Beaker, Compass, Layers, PlayCircle, Bell, Bot, Boxes, CheckCircle2, ClipboardCheck, FileText, Flame, Link2, Megaphone, MoonStar, PenLine, ShieldCheck, Smartphone, Sparkles, UserCog, Users,
} from 'lucide-react';

import ServerlessMap from './ServerlessMap';
import { Agenda, Divider, EvidenceWall, FlowDiagram, PersonaCard, ScreenRow, Storyboard } from './Visuals';
import type { Part } from './Visuals';

import 'reveal.js/reveal.css';
import '../slides.css';
import './final.css';

const base = import.meta.env.BASE_URL;
const img = (name: string) => `${base}final/${name}`;

function Logo() {
  return <img className="org-logo" src={`${base}assets/fpt-logo.webp`} alt="FPT University" />;
}

/** One content slide: part label, conclusion title, subtitle, body, footnote. */
function S({
  part,
  title,
  sub,
  foot,
  notes,
  wide,
  children,
}: {
  wide?: boolean;
  part: string;
  title: string;
  sub?: string;
  foot?: ReactNode;
  notes: string;
  children: ReactNode;
}) {
  const [code, ...rest] = part.split(' · ');
  const tone = code.startsWith('P') ? code.toLowerCase() : 'px';
  if (code.startsWith('P')) rest.shift(); // part name is shown by the colour and the divider slide
  const chip = code;
  const qtag = ['WHY', 'WHAT', 'WHY + WHAT'].includes(rest[rest.length - 1] ?? '') ? rest.pop() : undefined;
  return (
    <Slide className={`fd ${tone}${wide ? ' wide' : ''}`} notes={notes}>
      <Logo />
      <p className="kicker">
        <span className="chip">{chip}</span>
        {rest.join(' · ')}
        {qtag && <span className="qtag">{qtag === 'WHY' ? 'Why build it?' : qtag === 'WHAT' ? 'What is it?' : 'Why + what'}</span>}
      </p>
      <h2>{title}</h2>
      {sub && <p className="sub">{sub}</p>}
      <div className="body">{children}</div>
      {foot && <p className="foot">{foot}</p>}
    </Slide>
  );
}

function Shot({ src, alt, h, w, cap }: { src: string; alt: string; h?: number; w?: number; cap?: string }) {
  return (
    <figure className="shot">
      <img src={img(src)} alt={alt} style={w ? { width: w, height: 'auto' } : { height: h }} />
      {cap && <figcaption>{cap}</figcaption>}
    </figure>
  );
}

/** Code captured from GitHub main, red box around the key lines (scripts/capture-where.mjs). */
function Code({ name, w, h, cap }: { name: string; w?: number; h?: number; cap?: string }) {
  return (
    <figure className="shot">
      <img src={`${base}where/${name}.png`} alt={cap ?? name} style={w ? { width: w, height: 'auto' } : { height: h }} />
      {cap && <figcaption>{cap}</figcaption>}
    </figure>
  );
}

function Thumb({ src, h = 78 }: { src: string; h?: number }) {
  return <img className="thumb" src={img(src)} alt="" style={{ height: h }} />;
}

function Card({
  head,
  tone,
  children,
}: {
  head?: string;
  tone?: 'accent' | 'ok' | 'bad' | 'warn';
  children: ReactNode;
}) {
  return (
    <div className={tone ? `card ${tone}` : 'card'}>
      {head && <h4>{head}</h4>}
      {children}
    </div>
  );
}

function Steps({ items }: { items: [string, string][] }) {
  return (
    <div className="steps">
      {items.map(([head, text], i) => (
        <div key={head} style={{ display: 'contents' }}>
          {i > 0 && <span className="arrow">→</span>}
          <div className="step">
            <b>{head}</b>
            {text}
          </div>
        </div>
      ))}
    </div>
  );
}

/* ---------------------------------------------------------------- diagrams */

const C = {
  ink: '#1b1d2a',
  muted: '#555b6e',
  line: '#c3c7d4',
  card: '#f6f7fb',
  primary: '#3d4fd6',
  soft: '#dce6ff',
  ok: '#187a4d',
  okSoft: '#ddf5ea',
  bad: '#b3261e',
  badSoft: '#fde1df',
};

function Box({
  x,
  y,
  w,
  h,
  t,
  s,
  fill = C.card,
  stroke = C.line,
  bold,
}: {
  x: number;
  y: number;
  w: number;
  h: number;
  t: string;
  s?: string;
  fill?: string;
  stroke?: string;
  bold?: boolean;
}) {
  return (
    <g>
      <rect x={x} y={y} width={w} height={h} rx={9} fill={fill} stroke={stroke} />
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

function Arrow({ d, dash, color = C.muted }: { d: string; dash?: boolean; color?: string }) {
  return <path d={d} fill="none" stroke={color} strokeWidth={1.6} strokeDasharray={dash ? '5 4' : undefined} markerEnd="url(#ah)" />;
}

function Defs() {
  return (
    <defs>
      <marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M0 0 L10 5 L0 10 z" fill={C.muted} />
      </marker>
    </defs>
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
    <svg className="diagram" viewBox="0 0 1168 440">
      <Defs />
      {lanes.map((l, i) => (
        <g key={l}>
          <rect x={0} y={i * laneH} width={1168} height={laneH} fill={i % 2 ? '#fff' : '#fafbfe'} stroke="#e3e5ee" />
          <text x={12} y={i * laneH + 20} fontSize={12} fontWeight={700} fill={C.primary} letterSpacing="0.06em">
            {l}
          </text>
        </g>
      ))}
      {/* WF-01 */}
      <Box x={150} y={34} w={150} h={52} t="Tell the day" s="WF-01 Kể tự do" fill={C.soft} stroke={C.soft} />
      <Box x={150} y={142} w={150} h={52} t="Gemini sorts notes" s="BR-01 · App Check" />
      <Box x={150} y={250} w={150} h={52} t="notes saved" s="after user confirms" />
      <Arrow d="M225 86 V140" />
      <Arrow d="M225 194 V248" />
      <path d="M300 168 H340" stroke={C.bad} strokeWidth={1.6} strokeDasharray="5 4" fill="none" />
      <Label x={344} y={164} t="AI off / error → write by hand" color={C.bad} anchor="start" />
      {/* WF-02 */}
      <Box x={540} y={34} w={170} h={52} t="Share own card" s="WF-02 · status = pending" fill={C.soft} stroke={C.soft} />
      <Box x={540} y={250} w={170} h={52} t="challengeSubmissions" s="BR-02 rules check" />
      <Box x={760} y={358} w={170} h={52} t="Review queue" s="approve / reject" />
      <Box x={760} y={250} w={170} h={52} t="batch: card + inbox" s="BR-03 reason if reject" />
      <Box x={760} y={34} w={170} h={52} t="Card status + inbox" s="real time ≤ 3.4 s" fill={C.okSoft} stroke={C.okSoft} />
      <Arrow d="M625 86 V248" />
      <Arrow d="M710 290 C740 320 760 330 790 356" />
      <Arrow d="M845 358 V304" />
      <Arrow d="M845 250 V88" />
      {/* WF-03 */}
      <Box x={990} y={358} w={160} h={52} t="Post announcement" s="WF-03" fill={C.soft} stroke={C.soft} />
      <Box x={990} y={250} w={160} h={52} t="announcements" s="BR-04 staff · 1–1000" />
      <Box x={990} y={34} w={160} h={52} t="Inbox for all users" s="same minute" fill={C.okSoft} stroke={C.okSoft} />
      <Arrow d="M1070 358 V304" />
      <Arrow d="M1070 250 V88" />
    </svg>
  );
}

/** Slide 08: lifecycle of a shared card. */
function StateMachine() {
  return (
    <svg className="diagram" viewBox="0 0 760 380">
      <Defs />
      <circle cx={40} cy={190} r={10} fill={C.ink} />
      <Box x={110} y={160} w={150} h={60} t="pending" s="user sent the card" fill={C.soft} stroke={C.primary} bold />
      <Box x={430} y={50} w={160} h={60} t="approved" s="card in catalog" fill={C.okSoft} stroke={C.ok} bold />
      <Box x={430} y={270} w={160} h={60} t="rejected" s="reason ≥ 1 char" fill={C.badSoft} stroke={C.bad} bold />
      <Box x={110} y={300} w={150} h={50} t="(deleted)" s="withdrawn" />
      <Arrow d="M50 190 H108" />
      <Label x={78} y={178} t="submit" />
      <Arrow d="M260 175 C330 140 360 100 428 82" />
      <Label x={335} y={110} t="approve [staff]" color={C.ok} />
      <Arrow d="M260 205 C330 240 360 280 428 300" />
      <Label x={330} y={278} t="reject [staff, reason]" color={C.bad} />
      <Arrow d="M185 220 V298" dash />
      <Label x={196} y={262} t="withdraw [owner]" anchor="start" />
      <text x={620} y={150} fontSize={13} fill={C.bad} fontWeight={700}>Forbidden (rules deny)</text>
      <text x={620} y={172} fontSize={12.5} fill={C.ink}>user → approved</text>
      <text x={620} y={192} fontSize={12.5} fill={C.ink}>approved → pending</text>
      <text x={620} y={212} fontSize={12.5} fill={C.ink}>reject without reason</text>
      <text x={620} y={232} fontSize={12.5} fill={C.ink}>withdraw after review</text>
    </svg>
  );
}

/** Slide 09: containers and where they run. */
function Architecture() {
  return (
    <svg className="diagram" viewBox="0 0 760 420">
      <Defs />
      <Box x={20} y={20} w={200} h={64} t="Android app (Flutter)" s="role: user · MVVM" fill={C.soft} stroke={C.soft} />
      <Box x={20} y={110} w={200} h={64} t="Web admin (Flutter Web)" s="staff · admin · Hosting /admin/" fill={C.soft} stroke={C.soft} />
      <Box x={20} y={210} w={200} h={64} t="packages/core" s="models · repositories · theme" />
      <Arrow d="M120 84 V108" dash />
      <Arrow d="M120 174 V208" />
      <rect x={300} y={10} width={440} height={300} rx={14} fill="#fffaf0" stroke="#f5c97a" />
      <text x={316} y={34} fontSize={13} fontWeight={700} fill="#a84f00">FIREBASE · Spark (no-cost) · no custom server</text>
      <Box x={316} y={50} w={130} h={54} t="Auth" s="Google · email" />
      <Box x={458} y={50} w={130} h={54} t="Firestore" s="+ Security Rules" bold />
      <Box x={600} y={50} w={126} h={54} t="App Check" s="Play · reCAPTCHA" />
      <Box x={316} y={118} w={130} h={54} t="AI Logic" s="Gemini Dev API" />
      <Box x={458} y={118} w={130} h={54} t="Remote Config" s="flags · ai_*" />
      <Box x={600} y={118} w={126} h={54} t="Hosting" s="/ and /admin/" />
      <Box x={316} y={186} w={130} h={54} t="Analytics" s="both clients" />
      <Box x={458} y={186} w={130} h={54} t="Crashlytics" s="mobile" />
      <Box x={600} y={186} w={126} h={54} t="FCM" s="push" />
      <text x={316} y={276} fontSize={12} fill={C.muted}>Realtime snapshots to both clients · rules decide every read/write</text>
      <Arrow d="M220 52 C260 52 270 80 314 80" />
      <Arrow d="M220 142 C260 142 270 90 314 86" />
      <Box x={20} y={320} w={200} h={64} t="GitHub Actions" s="CI · deploys Hosting + rules" />
      <Box x={316} y={330} w={200} h={54} t="Cloudinary" s="note photos (Lab 3)" />
      <Box x={540} y={330} w={200} h={54} t="Discord bot (Rust)" s="extra · service account" />
    </svg>
  );
}

/** Slide 12: approve, one interaction across layers. */
function Sequence() {
  const lanes = [
    ['Staff', 60],
    [':ReviewScreen', 190],
    [':ReviewActions', 330],
    [':FirestoreSubmission\nRepository', 490],
    ['Firestore + Rules', 650],
    ['App (snapshot)', 790],
  ] as const;
  const msg = (y: number, from: number, to: number, t: string, color = C.ink) => (
    <g>
      <path d={`M${from} ${y} H${to + (to > from ? -4 : 4)}`} stroke={color} strokeWidth={1.5} markerEnd="url(#ah)" fill="none" />
      <text x={(from + to) / 2} y={y - 6} textAnchor="middle" fontSize={12} fill={color}>
        {t}
      </text>
    </g>
  );
  return (
    <svg className="diagram" viewBox="0 0 860 400">
      <Defs />
      {lanes.map(([n, x]) => (
        <g key={n}>
          <rect x={x - 62} y={8} width={124} height={34} rx={7} fill={C.card} stroke={C.line} />
          {n.split('\n').map((p, i, a) => (
            <text key={p} x={x} y={a.length > 1 ? 22 + i * 13 : 30} textAnchor="middle" fontSize={11.5} fontWeight={600} fill={C.ink}>
              {p}
            </text>
          ))}
          <line x1={x} y1={42} x2={x} y2={390} stroke={C.line} strokeDasharray="4 4" />
        </g>
      ))}
      {msg(70, 60, 190, '1. Duyệt (level)')}
      {msg(100, 190, 330, '2. approve(submission, level)')}
      {msg(130, 330, 490, '3. catalog.watchAll().first')}
      {msg(160, 330, 490, '4. approve(level, order)')}
      {msg(190, 490, 650, '5. batch: challenges + submission + inbox')}
      {msg(220, 650, 490, '6. commit ok (1.4 s)', C.ok)}
      {msg(250, 650, 790, '7. snapshot: approved + inbox', C.ok)}
      <rect x={300} y={276} width={520} height={100} rx={8} fill="#fff7f6" stroke={C.bad} strokeDasharray="5 4" />
      <text x={312} y={296} fontSize={12.5} fontWeight={700} fill={C.bad}>alt</text>
      <text x={340} y={296} fontSize={12} fill={C.ink}>[reject with empty reason] → rules deny → "Cần ghi lý do khi từ chối."</text>
      <text x={340} y={320} fontSize={12} fill={C.ink}>[staff offline &gt; 10 s] → TimeoutException → "Không kết nối được máy chủ"</text>
      <text x={340} y={344} fontSize={12} fill={C.ink}>[not staff] → requireStaff throws · rules deny (R-22)</text>
      <text x={340} y={366} fontSize={12} fill={C.muted}>Message names are the real Dart methods.</text>
    </svg>
  );
}

/** Slide 14: conceptual model of what the Final added. */
function Erd() {
  return (
    <svg className="diagram" viewBox="0 0 760 360">
      <Defs />
      <Box x={20} y={140} w={150} h={64} t="USER" s="role: user/staff/admin" bold />
      <Box x={300} y={20} w={190} h={60} t="SUBMISSION" s="topic · title · status" bold />
      <Box x={570} y={20} w={170} h={60} t="CHALLENGE (catalog)" s="level · order · status" bold />
      <Box x={300} y={140} w={190} h={60} t="INBOX MESSAGE" s="kind · read" bold />
      <Box x={570} y={140} w={170} h={60} t="ANNOUNCEMENT" s="title · body" bold />
      <Box x={300} y={260} w={190} h={60} t="WEEKLY REPORT" s="isoWeek · file meta" bold />
      <Box x={570} y={260} w={170} h={60} t="ONBOARDING" s="answers · plan" bold />
      <path d="M170 160 C230 120 250 60 298 50" stroke={C.muted} fill="none" />
      <Label x={196} y={112} t="1 sends 0..*" anchor="start" />
      <path d="M490 50 H568" stroke={C.muted} fill="none" />
      <Label x={529} y={42} t="becomes" />
      <Label x={529} y={68} t="0..1" />
      <path d="M170 172 H298" stroke={C.muted} fill="none" />
      <Label x={234} y={164} t="1 has 0..*" />
      <path d="M395 80 V138" stroke={C.muted} strokeDasharray="4 4" fill="none" />
      <Label x={402} y={114} t="review → message" anchor="start" />
      <path d="M170 196 C230 240 250 290 298 290" stroke={C.muted} fill="none" />
      <Label x={176} y={258} t="1 saves 0..* (1 / week)" anchor="start" />
      <path d="M95 204 V340 H655 V322" stroke={C.muted} fill="none" />
      <Label x={380} y={334} t="1 has 0..1 onboarding" />
      <path d="M655 140 V82" stroke={C.muted} strokeDasharray="4 4" fill="none" />
      <Label x={662} y={116} t="all users read" anchor="start" />
    </svg>
  );
}

const PARTS: Part[] = [
  { code: 'p1', num: '01', name: 'Problem', question: 'Why build it, and what is it?', minutes: '≈ 3.5 min', icon: Compass,
    slides: ['§Why build it?', '01 Overview', '02 Context', '03 Problem', '§What is it?', '04 Solution', '05 Actors', '06 Features'] },
  { code: 'p2', num: '02', name: 'Design', question: 'How is the whole system built?', minutes: '≈ 6 min', icon: Layers,
    slides: ['07 Business flow', '08 State machine', '09 Architecture', '10 Stack', '11 UI/UX', '12 Sequence', '13 Classes', '14–15 Database', '16 Traceability'] },
  { code: 'p3', num: '03', name: 'Demo', question: 'How do the workflows run for real?', minutes: '≈ 6.5 min', icon: PlayCircle,
    slides: ['17 Demo plan', '18 WF-01 Nốt AI', '19 WF-02 Publish a card', '20 WF-03 Announce'] },
  { code: 'p4', num: '04', name: 'Proof', question: 'What can we prove?', minutes: '≈ 2.5 min', icon: Beaker,
    slides: ['21 Testing', '22 Achievements', '23 Limitations', '24 Conclusion'] },
];

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
        <Slide className="fd cover" notes="Nốt, Final Assignment: one complete system on Firebase. The Lab 3 app plus a web admin for staff, one shared Firestore with role-based rules, and a Gemini feature.">
          <Logo />
          <p className="kicker" style={{ marginTop: 40 }}>PRM393 · Final Assignment · One complete system on Firebase</p>
          <h1>Nốt</h1>
          <p className="tag">One positive note every day, now with staff, AI and a shared catalog</p>
          <p className="meta" style={{ maxWidth: 440 }}>
            Đoàn Thị Kim Thúy · SE190992
            <br />
            Phùng Thế Quân · SE193519
            <br />
            Phan Đức Duy · SE193591
            <br />
            Phan Hữu Phước · SE161951
          </p>
          <div style={{ position: 'absolute', right: 56, bottom: 80, display: 'flex', gap: 16, alignItems: 'flex-end' }}>
            <Shot src="wa-03-dashboard-crop.png" alt="Web admin dashboard" w={560} />
            <Shot src="06-ai-notes-saved.png" alt="Nốt app on a Galaxy A70" h={340} />
          </div>
        </Slide>

        <Agenda parts={PARTS} />
        <Divider part={PARTS[0]} shots={['wa-03-dashboard-crop.png', 'm-today.png', '05-ai-free-tell-result.png']} />

        {/* 01 · Overview */}
        <S
          part="P1 · Problem · 01 Overview"
          title="Nốt: a daily small-wins app with a staff web admin, live on one Firebase project"
          notes="30 seconds. Name and type: Nốt, an Android app for logging small wins plus a Flutter web admin for staff. One sentence: for students who end the day feeling behind, Nốt makes one small win visible in under 30 s and keeps fresh challenges coming. Users, value, platform. It is live: point at the screenshots."
        >
          <ul className="ovl">
            <li>
              <span className="ovl-k">Project</span>
              <p>
                <b className="ovl-name">Nốt</b> · a small-wins journal: an Android app for users and a web admin for staff,
                on one Firebase project
              </p>
            </li>
            <li>
              <span className="ovl-k">In one sentence</span>
              <p>
                For students who end a long day feeling they got nothing done, Nốt makes <b>one small win visible in under
                30 seconds</b> and keeps <b>fresh small challenges</b> coming.
              </p>
            </li>
            <li>
              <span className="ovl-k">Users &amp; value</span>
              <p>Final-year students log their day; staff curate challenge cards; admins manage roles.</p>
              <ul className="ovl-v">
                <li>One win in 30 s, typed or sorted by Gemini</li>
                <li>New challenge cards without an app update</li>
                <li>Staff news reaches every inbox in the same minute</li>
              </ul>
            </li>
          </ul>
          <div className="collage">
            <img className="c-web" src={img('wa-03-dashboard-crop.png')} alt="Web admin dashboard" />
            <img className="c-phone c-a" src={img('m-today.png')} alt="Today screen" />
            <img className="c-phone c-b" src={img('05-ai-free-tell-result.png')} alt="Nốt AI" />
            <span className="c-tag c-tag-web">Web admin · staff</span>
            <span className="c-tag c-tag-app">Android app · user</span>
          </div>
        </S>

        {/* 02 · Context */}
        <S
          part="P1 · Problem · 02 Context · WHY"
          title="Today Minh logs his evening alone, and the app around him never changes"
          sub="Who uses Nốt, what they want, and how it works after Lab 3; the problems come next."
          notes="Context, not problem yet. Persona Minh, 22, final year (Lab 2). Goal: one mood and one small win in under 30 s. Walk the current process left to right: reminder, typing and classifying by hand, picking from a fixed seed list, new cards only by a developer script, news only by a Console push. Point at the Console screenshot: seed documents dc-1-1, dc-1-2…"
          foot="Source: Lab 2 persona and success criterion (README, docs/design-traceability.md) · Lab 3 build · Firestore Console."
        >
          <div className="col grow" style={{ gap: 16 }}>
            <div style={{ display: 'flex', gap: 24, alignItems: 'center' }}>
              <div style={{ flex: 1 }}>
                <PersonaCard
                  name="Minh, 22"
                  meta="Final-year student · Lab 2 persona · Android"
                  facts={[
                    ['Goal', 'one mood + one small win in under 30 s'],
                    ['Uses', 'the Nốt app in the evening'],
                    ['Feels', 'behind, tired after a long day'],
                  ]}
                />
              </div>
              <Shot src="ev-firestore-console.png" alt="Seed challenge cards in Firestore" w={330} cap="Lab 3 cards: fixed seed documents dc-1-1…" />
            </div>
            <span className="k">How it works today (after Lab 3)</span>
            <FlowDiagram
              steps={[
                { icon: BellRing, title: 'Reminder', note: 'evening, Minh opens Nốt' },
                { icon: PenLine, title: 'Write', note: 'types each note, sorts it by hand' },
                { icon: Boxes, title: 'Challenge', note: 'picks from a fixed seed list' },
                { icon: Code2, title: 'New cards', note: 'only via a developer script', warn: true },
                { icon: Megaphone, title: 'News', note: 'only a Console push', warn: true },
              ]}
            />
            <p className="answer" style={{ margin: '4px 0 0', fontSize: 19, maxWidth: 'none' }}>
              One person, alone with their own data. Nobody curates content, and nobody can talk to users inside the app.
            </p>
          </div>
        </S>

        {/* 03 · Problem */}
        <S
          part="P1 · Problem · 03 Problem · WHY"
          title="“I didn’t get anything done today”: four gaps behind that feeling in Nốt"
          sub="Most of us think it after a long day: we remember unfinished tasks, writing the day down feels like one more task, and goals that never change stop motivating us."
          notes="Pain points with cause and impact. Evidence is our own Lab 3 state (gap review), not a survey; we say that openly."
          foot="Evidence: docs/gap-review.md (Lab 2 / Lab 3 gaps before the Final). No user survey was run; impacts are observed in the Lab 3 build."
        >
          <div className="grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
            {[
              [Boxes, 'Static challenge content', 'Cards were a seed list; changing one needed a developer and a script', 'Users run out of fresh cards; good ideas from users stay private'],
              [Megaphone, 'No way to reach users', 'No staff role, no announcements, push only from the Console', 'Nobody can tell users about new cards or events inside the app'],
              [MoonStar, 'Logging takes effort at night', 'Each note is typed and classified by hand (win, self-control, journal)', 'The 30 s goal slips when the day had several moments to record'],
              [FileText, 'Lab 3 flow left unfinished', 'The weekly card PDF went to Cloud Storage, which needs the paid plan', 'Export never worked on the real project'],
            ].map(([Icon, head, cause, impact]) => {
              const I = Icon as typeof Boxes;
              return (
                <div key={head as string} className="tile">
                  <span className="ic big"><I size={30} /></span>
                  <div>
                    <h4>{head as string}</h4>
                    <p><span className="k">Cause</span><br />{cause as string}</p>
                    <p style={{ marginTop: 8 }}><span className="k">Impact</span><br /><b>{impact as string}</b></p>
                  </div>
                </div>
              );
            })}
          </div>
        </S>

        {/* 04 · Proposed solution */}
        <S
          part="P1 · Problem · 04 Proposed solution · WHAT"
          title="One Firebase system: a staff web admin, a review flow, and Gemini that sorts the day"
          sub="Every pain point maps to a feature that is live and demonstrated."
          notes="Pain point to solution to value. Then scope: what we built and what we left out on purpose (paid plan services)."
        >
          <div className="col grow">
            <table style={{ fontSize: 16 }}>
              <thead>
                <tr>
                  <th>Pain point</th>
                  <th>Solution</th>
                  <th>Expected value</th>
                  <th>Live</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>Static content</td>
                  <td>Web admin catalog + users share cards, staff approve</td>
                  <td>Catalog grows without a release</td>
                  <td><Thumb src="wa-04-catalog-search-crop.png" h={66} /></td>
                </tr>
                <tr>
                  <td>No channel</td>
                  <td>Announcements + personal inbox (Firestore, real time)</td>
                  <td>News lands in the app in the same minute</td>
                  <td><Thumb src="wa-10-announcement-sent-crop.png" h={60} /></td>
                </tr>
                <tr>
                  <td>Slow evenings</td>
                  <td>Nốt AI: tell the day once, confirm sorted notes</td>
                  <td>Several notes from one paragraph</td>
                  <td><Thumb src="05-ai-free-tell-result.png" h={92} /></td>
                </tr>
                <tr>
                  <td>Broken PDF</td>
                  <td>Build and save the PDF on the device, metadata in Firestore</td>
                  <td>Works on the free plan, offline</td>
                  <td><Thumb src="09-pdf-saved.png" h={92} /></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div className="col" style={{ width: 300 }}>
            <Card head="In scope (MVP)" tone="ok">
              <ul className="tight">
                <li>WF-01 Log the day with Nốt AI</li>
                <li>WF-02 Publish a user card to the catalog</li>
                <li>WF-03 Announce news to every user</li>
                <li>Onboarding, weekly PDF, roles, App Check</li>
              </ul>
            </Card>
            <Card head="Out of scope" tone="warn">
              <ul className="tight">
                <li>Cloud Functions, Cloud Storage (brief + paid plan)</li>
                <li>AI level 3 "Hỏi Nốt" (bonus, not built)</li>
                <li>iOS build</li>
              </ul>
            </Card>
          </div>
        </S>

        {/* 05 · Actors */}
        <S
          part="P1 · Problem · 05 Main actors · WHAT"
          title="Three human roles and two external services, enforced by Security Rules"
          sub="The role lives in users/{uid}.role; only an admin changes it, and never their own."
          notes="Actors match the real permission model in firestore.rules and the web admin's role check."
          foot="First admin: set in the Firebase Console (Thị Kim Thúy Đoàn). Rules tests R-01…R-30 cover every role and collection (BR-05: R-26)."
        >
          <div className="col grow">
          <table style={{ fontSize: 15.5 }}>
            <thead>
              <tr>
                <th style={{ width: '19%' }}>Actor</th>
                <th style={{ width: '12%' }}>Client</th>
                <th style={{ width: '32%' }}>Who</th>
                <th>Main permissions</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><span className="ic" style={{ marginRight: 10, verticalAlign: 'middle' }}><Users size={22} /></span><b>User</b></td>
                <td>Android app</td>
                <td>Student using Nốt every evening</td>
                <td>Own notes and data; share own cards (pending only); read catalog, announcements, own inbox</td>
              </tr>
              <tr>
                <td><span className="ic" style={{ marginRight: 10, verticalAlign: 'middle' }}><PenLine size={22} /></span><b>Staff</b></td>
                <td>Web admin</td>
                <td>Content curator</td>
                <td>Create, edit, archive catalog cards; approve / reject with reason; post announcements</td>
              </tr>
              <tr>
                <td><span className="ic" style={{ marginRight: 10, verticalAlign: 'middle' }}><UserCog size={22} /></span><b>Admin</b></td>
                <td>Web admin</td>
                <td>Team lead</td>
                <td>Everything staff can do + change other users' roles</td>
              </tr>
              <tr>
                <td><span className="ic" style={{ marginRight: 10, verticalAlign: 'middle' }}><Bot size={22} /></span><b>Gemini</b></td>
                <td>External</td>
                <td>Firebase AI Logic, Gemini Developer API</td>
                <td>Receives the scrubbed paragraph only; returns JSON suggestions</td>
              </tr>
              <tr>
                <td><span className="ic" style={{ marginRight: 10, verticalAlign: 'middle' }}><Flame size={22} /></span><b>Firebase</b></td>
                <td>Platform</td>
                <td>Auth, Firestore, App Check, RC, FCM…</td>
                <td>Rules decide every read and write; no custom server</td>
              </tr>
            </tbody>
          </table>
          </div>
          <div className="col" style={{ width: 330 }}>
            <Shot src="wa-12-users-crop.png" alt="Users screen" w={330} cap="Admin changes roles (own role locked)" />
            <div style={{ display: 'flex', gap: 12, alignItems: 'flex-end' }}>
              <Shot src="m-wrong-role.png" alt="Wrong role on mobile" h={210} cap="Staff/admin on the phone" />
              <Shot src="wa-02-rejected-user-account-crop.png" alt="User on the web admin" w={170} cap="User on the web" />
            </div>
          </div>
        </S>

        {/* 06 · Features */}
        <S
          part="P1 · Problem · 06 Main features · WHAT"
          title="Three core workflows carry the demo; everything else supports them"
          sub="Each workflow has an actor, a trigger and a business result, not a list of buttons."
          notes="Three workflows, one story: the user logs the day, shares a card that staff approve, staff announce it. Other features listed underneath."
          foot="Supporting features: onboarding & starter plan · weekly card PDF · streaks & journey · self-control & breathing · groups · Discord link · dashboard · roles."
        >
          {[
            [Sparkles, 'WF-01', 'Log the day with Nốt AI', 'User', 'Evening, user taps Ghi nốt → Kể tự do', 'Notes saved after the user confirms', 'BR-01 · consent, Gemini JSON, edit, fallback', 'Slow evenings'],
            [ClipboardCheck, 'WF-02', 'Publish a user card to the shared catalog', 'User + Staff', 'User shares an own card', 'Card in the catalog, app updates, inbox message', 'BR-02 submit · BR-03 approve / reject + reason', 'Static content'],
            [Megaphone, 'WF-03', 'Announce news to every user', 'Staff', 'Staff has news for everyone', 'Announcement published; every inbox shows it', 'BR-04 title 1–80, body 1–1000, staff only', 'No channel'],
          ].map(([Icon, id, name, actor, trigger, result, rule, pain]) => {
            const I = Icon as typeof Sparkles;
            return (
              <div key={id as string} className="wf grow">
                <span className="ic big" style={{ background: '#fff' }}><I size={30} /></span>
                <span className="id">{id as string}</span>
                <span className="name">{name as string}</span>
                <dl>
                  <dt>Actor</dt><dd>{actor as string}</dd>
                  <dt>Trigger</dt><dd>{trigger as string}</dd>
                  <dt>Result</dt><dd><b>{result as string}</b></dd>
                  <dt>Rules</dt><dd>{rule as string}</dd>
                  <dt>Solves</dt><dd>{pain as string}</dd>
                </dl>
              </div>
            );
          })}
        </S>

        <Divider part={PARTS[1]} shots={['ev-firestore-console.png', 'g-mobile-final-03-onboarding-starter-plan.png', 'g-journey-climb-dung-cam.png']} />

        {/* 07 · Business flow */}
        <S
          part="P2 · Design · 07 Business flow"
          title="One swimlane view: who acts, where the data lands, where it branches"
          sub="The three workflows share one Firestore; rules are the decision points."
          notes="Walk the lanes left to right: WF-01 stays in the user's own data; WF-02 crosses from user to staff and back; WF-03 goes from staff to everyone."
          foot="BR-01 AI only when enabled, consented and App Check passes · BR-02 user creates pending only · BR-03 reject needs a reason · BR-04 announcements: staff only, title 1–80, body 1–1000 · BR-05 only admins change roles, never their own."
        >
          <BusinessFlow />
        </S>

        {/* 08 · State machine */}
        <S
          part="P2 · Design · 08 State machine"
          title="A shared card moves pending → approved or rejected, and nowhere else"
          sub="Entity: challengeSubmissions/{id}. Every transition and every forbidden one has a rules test."
          notes="Event, guard, action. Forbidden transitions are tested in the Emulator (R-20 to R-23)."
          foot="Tests: R-20 create pending only · R-21 read own or staff · R-22 staff review, reason on reject · R-23 withdraw while pending. 30/30 rules tests pass."
        >
          <div className="grow" style={{ minWidth: 0 }}>
            <StateMachine />
          </div>
          <div className="col" style={{ width: 430, justifyContent: 'center' }}>
            <Code name="f-rules-review" w={430} cap="firestore.rules · the guard on every review (BR-03)" />
          </div>
        </S>

        {/* 09 · Architecture */}
        <S
          part="P2 · Design · 09 System architecture"
          title="Two Flutter clients, one shared package, Firebase as the only backend"
          sub="Decision: no custom server. Security Rules + App Check are the backend's access layer."
          notes="Trade-off: no server means rules carry the business rules (validation, transitions). Benefit: free plan, real time, less to run. Cost: complex rules, so we test them."
          foot="Deploy: GitHub Actions builds both clients, deploys Hosting (/ and /admin/) and Firestore rules + indexes on merge to main."
        >
          <Architecture />
        </S>

        {/* 10 · Tech stack */}
        <S
          wide
          part="P2 · Design · 10 Technology stack"
          title="Serverless on Firebase: Security Rules are the backend"
          notes="Read it like an AWS diagram: FE (two Flutter clients) talks over HTTPS to serverless Firebase (BE + AI), which stores data in Firestore. Below: DevOps ships it, Ops watches it. Only services we really use (pubspec, workflows, compose file); no Grafana, monitoring is the Firebase Console."
        >
          <ServerlessMap />
        </S>

        {/* 11 · UI/UX */}
        <S
          part="P2 · Design · 11 UI/UX design"
          title="One design system across phone and web, with every UI state designed"
          sub="Lab 2 tokens live in packages/core; the web admin reuses them in a wide layout."
          notes="Same indigo, Be Vietnam Pro, mascot for empty/error. Show loading, empty, error, success on the web admin."
          foot="States: empty · loading · error (within 15 s, Thử lại) · success · wrong role rejected on web and mobile."
        >
          <div className="grow" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
            <Shot src="wa-07-review-empty-crop.png" alt="Empty review queue" h={200} cap="Empty · Hàng chờ duyệt" />
            <Shot src="wa-13-dashboard-loading-crop.png" alt="Dashboard loading" h={200} cap="Loading · Tổng quan" />
            <Shot src="wa-16-dashboard-error-crop.png" alt="Dashboard error" h={200} cap="Error · server unreachable, Thử lại" />
            <Shot src="wa-08-review-approved-crop.png" alt="Approved list" h={200} cap="Success · approved cards" />
          </div>
          <Shot src="11-ai-off-remote-config.png" alt="Nốt AI off" h={440} cap="App · AI off state" />
        </S>

        {/* 11b · Screen map */}
        <S
          part="P2 · Design · 11b Screen map"
          title="Twelve screens carry the three workflows, on two clients"
          sub="Real screenshots from the Galaxy A70 and the deployed web admin; codes match docs/design-traceability.md."
          notes="Top row: the Android app a user sees every evening. Bottom row: the five web admin screens staff use. WF-01 lives on S02 and S03b, WF-02 crosses S07 and the review queue, WF-03 goes from Announcements to the inbox."
        >
          <div className="screens">
            <ScreenRow
              label="Android · user"
              h={200}
              screens={[
                { src: 'm-today.png', code: 'S02', name: 'Today' },
                { src: '05-ai-free-tell-result.png', code: 'S03b', name: 'Nốt AI' },
                { src: 'g-app-check-final-mobile-jar-after-enforce.png', code: 'S05', name: 'Jar' },
                { src: 'cr-02-phone-pending.png', code: 'S07', name: 'Challenges' },
                { src: 'g-journey-climb-dung-cam.png', code: 'S11', name: 'Journey' },
                { src: '07-weekly-card.png', code: 'S11b', name: 'Weekly PDF' },
                { src: 'g-mobile-final-03-onboarding-starter-plan.png', code: 'S13', name: 'Onboarding' },
                { src: 'g-breathing-s10-inhale.png', code: 'S10', name: 'Breathing' },
              ]}
            />
            <ScreenRow
              label="Web · staff"
              h={120}
              screens={[
                { src: 'wa-03-dashboard-crop.png', code: 'W1', name: 'Dashboard', web: true },
                { src: 'wa-04-catalog-search-crop.png', code: 'W2', name: 'Catalog', web: true },
                { src: 'wa-08-review-approved-crop.png', code: 'W3', name: 'Review queue', web: true },
                { src: 'wa-10-announcement-sent-crop.png', code: 'W4', name: 'Announcements', web: true },
                { src: 'wa-12-users-crop.png', code: 'W5', name: 'Users & roles', web: true },
              ]}
            />
          </div>
        </S>

        {/* 12 · Sequence */}
        <S
          part="P2 · Design · 12 Sequence diagram"
          title="Approving a card is one batch write; rules guard it, snapshots carry it back"
          notes="Real method names. The alt box shows the exception branches, including the two bugs found on the deployed system and fixed."
        >
          <div className="grow" style={{ minWidth: 0 }}>
            <Sequence />
          </div>
          <div className="col" style={{ width: 330, justifyContent: 'center' }}>
            <Code name="f-approve-batch" w={330} cap="FirestoreSubmissionRepository.approve: one batch" />
          </div>
        </S>

        {/* 13 · Class design */}
        <S
          part="P2 · Design · 13 Class design"
          title="MVVM in both clients: screens never touch Firebase directly"
          sub="Business rules sit in the repository + Security Rules, not in widgets."
          notes="Screen → Notifier/actions → service interface → Firestore implementation in packages/core. Fakes replace the interfaces in tests."
          foot="main.dart wires each provider to its Firebase implementation; tests swap in fakes (303 app · 14 web admin · 5 core tests)."
        >
          <table>
            <thead>
              <tr>
                <th>Layer</th>
                <th>WF-01 Nốt AI</th>
                <th>WF-02 Share & review</th>
                <th>WF-03 Announce</th>
              </tr>
            </thead>
            <tbody>
              <tr><td><b>Screen</b></td><td><code>FreeTellScreen</code></td><td><code>ChallengesScreen</code> · <code>ReviewScreen</code></td><td><code>AnnouncementsScreen</code> · <code>NotificationInboxSheet</code></td></tr>
              <tr><td><b>ViewModel</b></td><td><code>FreeTellViewModel</code></td><td><code>CommunityActions</code> · <code>ReviewActions</code></td><td><code>AnnouncementActions</code> · <code>communityInboxProvider</code></td></tr>
              <tr><td><b>Service</b></td><td><code>AiService</code></td><td><code>SubmissionRepository</code> · <code>CatalogRepository</code></td><td><code>AnnouncementRepository</code> · <code>InboxRepository</code></td></tr>
              <tr><td><b>Implementation</b></td><td><code>FirebaseAiService</code></td><td><code>FirestoreSubmissionRepository</code></td><td><code>FirestoreAnnouncementRepository</code></td></tr>
              <tr><td><b>Model</b></td><td><code>AiSortResult</code> · <code>AiNoteSuggestion</code></td><td><code>ChallengeSubmission</code> · <code>CatalogCard</code></td><td><code>Announcement</code> · <code>InboxMessage</code></td></tr>
            </tbody>
          </table>
        </S>

        {/* 14 · DB conceptual */}
        <S
          part="P2 · Design · 14 Database design (conceptual)"
          title="The Final added six entities around the user"
          sub="Lab 3 entities (notes, habits, groups, progress) stay private to their owner."
          notes="Cardinalities. Submission becomes at most one catalog card. Reports: one per ISO week."
        >
          <Erd />
        </S>

        {/* 15 · DB physical */}
        <S
          part="P2 · Design · 15 Database design (physical)"
          title="Firestore collections, with constraints written as Security Rules"
          notes="No schema in Firestore, so the shape, sizes and transitions are enforced by rules and covered by tests."
          foot="Indexes: submissions (uid, createdAt↓), (status, createdAt↓) · notes (groupId, createdAt↓) · full table: docs/data-model.md"
        >
          <div className="col grow">
          <table style={{ fontSize: 14 }}>
            <thead>
              <tr>
                <th style={{ width: '30%' }}>Collection</th>
                <th>Key fields</th>
                <th style={{ width: '34%' }}>Constraints (rules)</th>
              </tr>
            </thead>
            <tbody>
              <tr><td><code>users/{'{uid}'}</code></td><td>role, displayName, email</td><td>self-create as user; only admin changes role, never own</td></tr>
              <tr><td><code>challenges/{'{id}'}</code></td><td>topic, level 1–10, order, title ≤ 80, status</td><td>staff only; updatedBy = auth.uid; archive, no delete</td></tr>
              <tr><td><code>challengeSubmissions/{'{id}'}</code></td><td>uid, topic, title, minutes, status, reason</td><td>create pending; staff review; reason on reject</td></tr>
              <tr><td><code>users/{'{uid}'}/inbox/{'{id}'}</code></td><td>kind, title, body, read</td><td>staff create; owner reads, may only flip read</td></tr>
              <tr><td><code>announcements/{'{id}'}</code></td><td>title ≤ 80, body ≤ 1000, authorUid</td><td>staff create/delete; every signed-in user reads</td></tr>
              <tr><td><code>users/{'{uid}'}/reports/{'{week}'}</code></td><td>isoWeek, fileName, sizeBytes, noteCount</td><td>owner only; id = week; savedAt = server time</td></tr>
              <tr><td><code>users/{'{uid}'}/private/onboarding</code></td><td>answers, profileLabel, planSource</td><td>owner only; enums and sizes checked</td></tr>
            </tbody>
          </table>
          </div>
          <div className="col" style={{ width: 360 }}>
            <Shot src="ev-firestore-console.png" alt="Firestore console" w={360} cap="Firestore Console · challenges" />
            <Code name="f-rules-announce" w={360} cap="Rules for announcements (BR-04)" />
          </div>
        </S>

        {/* 16 · Traceability */}
        <S
          part="P2 · Design · 16 Traceability"
          title="Each workflow traces from screen to rule to test"
          notes="Feature → screen → class → collection → tests. R-xx are rules tests, T-xx ARTEMIS cases on the real phone, D-x timed cross-role runs."
          foot="Full matrix: docs/design-traceability.md · rules: firebase/tests/firestore.rules.test.js · E2E: e2e_test/"
        >
          <table>
            <thead>
              <tr>
                <th>Workflow</th>
                <th>Screens</th>
                <th>Class / service</th>
                <th>Collection</th>
                <th>Tests</th>
              </tr>
            </thead>
            <tbody>
              <tr><td><b>WF-01</b> Nốt AI</td><td>S03b Kể tự do</td><td>FreeTellViewModel · AiService</td><td>notes</td><td>BR-01 · free_tell_flow_test · ARTEMIS T18 (2/3), T19 (3/3)</td></tr>
              <tr><td><b>WF-02</b> Share & review</td><td>S07 · Review queue · Inbox</td><td>CommunityActions · ReviewActions</td><td>challengeSubmissions · challenges · inbox</td><td>BR-02/03 · R-20…R-24 · ARTEMIS T20 (3/3) · D-1…D-3</td></tr>
              <tr><td><b>WF-03</b> Announce news</td><td>Announcements · Inbox</td><td>AnnouncementActions</td><td>announcements · inbox</td><td>BR-04 · R-25 · notification_inbox_test · web checklist #9–11</td></tr>
              <tr><td>Weekly PDF</td><td>S11b Thẻ tuần</td><td>WeeklyReportViewModel</td><td>reports</td><td>R-28 · weekly_report_test · ARTEMIS T14 (3/3)</td></tr>
              <tr><td>Onboarding</td><td>S13a–g</td><td>OnboardingViewModel</td><td>private/onboarding</td><td>R-27 · onboarding_flow_test · ARTEMIS T17 (3/3)</td></tr>
              <tr><td>Roles</td><td>Sign-in · Users</td><td>sessionProvider · UserActions</td><td>users</td><td>BR-05 · R-01, R-26, R-29 · session_test · auth_flow_test</td></tr>
            </tbody>
          </table>
        </S>

        <Divider part={PARTS[2]} shots={['wa-08-review-approved-crop.png', 'cr-02-phone-pending.png', 'cr-06-phone-inbox-3-messages.png']} />

        {/* 17 · Demo plan */}
        <S
          part="P3 · Demo · 17 Demo plan"
          title="The demo is one evening: Minh logs his day, shares a card, staff publish it and announce"
          sub="The result of each workflow is the input of the next."
          notes="Order: WF-01 on the phone, WF-02 phone + web side by side, WF-03 on the web then the phone. One account per actor, prepared before the session; the backup video is the fallback if the network fails."
          foot="Prepared: user account on a Galaxy A70 (release build, Play Integrity) · staff/admin account on the web admin · ai_enabled ready to toggle in Remote Config · empty review queue · backup video."
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
          title="WF-01 Log the day with Nốt AI: one paragraph becomes three editable notes"
          notes="Trigger: evening. Steps: consent sheet, Gemini, labelled suggestions, edit, save. Exception: AI off via Remote Config. Evidence: Galaxy A70, real Gemini."
          foot="Evidence: Galaxy A70, real Gemini (~2 s) · ARTEMIS T18 2/3, T19 (AI off) 3/3 · AI level 2: JSON schema → AiSortResult."
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
          <Shot src="04-ai-consent.png" alt="Consent sheet" h={440} cap="Consent" />
          <Shot src="05-ai-free-tell-result.png" alt="Suggestions" h={440} cap="Suggestions" />
          <Shot src="11-ai-off-remote-config.png" alt="AI off" h={440} cap="ai_enabled = false" />
        </S>

        {/* 18b · WF-01 storyboard */}
        <S
          part="P3 · Demo · 18b WF-01 storyboard"
          title="WF-01 in four screens: from an empty evening to three saved notes"
          notes="Walk the frames left to right while doing it live. Frame 4 is what the user sees after saving."
          foot="Exception shown live: ai_enabled = false → frame 2 says 'Nốt AI đang nghỉ' and only 'Ghi tay' is left."
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
          title="WF-02 Publish a card: staff approve on the web, the phone updates within seconds"
          notes="Cross-role. Measured three times on the deployed system. D-1 slow (listener idle); D-2, D-3 2–4 s. Also mention the approve bug found here and fixed."
          foot="Evidence: write 1.4 s after Duyệt · phone ≤ 3.4 s (D-2, D-3), 22 s when idle (D-1) · ARTEMIS T20 3/3 · docs/cross-role-flow.md"
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
          <Shot src="cr-02-phone-pending.png" alt="Pending" h={430} cap="Đang chờ duyệt" />
          <div className="col">
            <Shot src="wa-08-review-approved-crop.png" alt="Approved on web" w={420} cap="Web: approved" />
            <Shot src="cr-06-phone-inbox-3-messages.png" alt="Inbox" h={190} cap="App: inbox" />
          </div>
        </S>

        {/* 19b · WF-02 storyboard */}
        <S
          part="P3 · Demo · 19b WF-02 storyboard"
          title="WF-02 in five screens: a private card becomes everyone's card"
          notes="Phone and web side by side. Frames 1–2 on the phone, 3 on the web admin, 4–5 back on the phone within seconds."
          foot="Exception shown live: Từ chối without a reason is blocked (BR-03); the card stays pending."
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
          title="WF-03 Announce news to every user: staff post once, every inbox shows it in the same minute"
          notes="Trigger: staff has news. Precondition: staff or admin session. BR-04 is checked twice: in the form and in the rules. Result: the announcement exists and every user sees it in the inbox in real time. Exception: empty body, too long, or a user account → blocked."
          foot="Evidence: sent at 10:56, in the app inbox at 10:56 · rules R-25 (staff only, authorUid = self, title 1–80, body 1–1000) · web checklist #9–11."
        >
          <div className="col">
            <Shot src="wa-09-announcement-form-crop.png" alt="Announcement form" w={400} cap="1 · Compose (list still empty)" />
            <Shot src="wa-10-announcement-sent-crop.png" alt="Announcement sent" w={400} cap="2 · Sent at 10:56, form cleared" />
          </div>
          <Shot src="wa-11-app-inbox-announcement.png" alt="App inbox" h={470} cap="3 · App inbox, 10:56" />
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
          title="WF-03 in three screens: one form, every inbox"
          notes="Compose on the web, send, then show the phone inbox at the same minute."
          foot="Exception shown live: empty body or > 1000 characters → form error, nothing saved (BR-04)."
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
          title="Rules, code and the deployed system are each tested, with evidence in the repo"
          notes="Numbers from the latest runs on main (12/11/2026). Say what is not run: T15/T16 need a test-only email account. The one ARTEMIS failure was the agent typing key by key and timing out; the app showed the right screen."
          foot="CI on every PR: format, analyze, all test suites, rules in the Emulator, web build, Android build, Hosting preview · details: docs/test-report.md."
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
            <Shot src="ev-artemis.jpg" alt="ARTEMIS run" h={112} cap="ARTEMIS: agent reports SAVED" />
            <Shot src="ev-deploy-run.png" alt="GitHub Actions deploy" h={112} cap="GitHub Actions: deploy on main" />
          </div>
          </div>
        </S>

        {/* 21b · Evidence wall */}
        <S
          part="P4 · Proof · 21b Evidence wall"
          title="Every number on the testing slide has a screenshot or a log behind it"
          notes="Point at two or three tiles; all files are in evidence/ in the repo."
          foot="All files: evidence/ in the repo · details: docs/test-report.md"
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
          title="Every brief requirement maps to a live feature and a piece of evidence"
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
          title="What is not done yet, and what it costs"
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
              <tr><td>Lab 2 flow A3 (practice chat) dropped</td><td>Overlaps the Discord rooms; one designed flow not built</td><td><span className="pill">Low</span></td><td>Reason in docs/gap-review.md §1.1</td></tr>
            </tbody>
          </table>
        </S>

        {/* 24 · Conclusion */}
        <S
          part="P4 · Proof · 24 Conclusion"
          title="Nốt is now a working multi-role system, and we can show every claim"
          notes="Three messages, then leave this slide up for Q&A."
        >
          <div className="col grow">
            <div className="grid" style={{ gridTemplateColumns: '1fr 1fr 1fr' }}>
              {[
                [CheckCircle2, '1 · Problem solved', "Content is curated by staff and grows from users' own cards; news reaches every user in the same minute."],
                [Smartphone, '2 · Working product', 'WF-01, WF-02, WF-03 run live on Android and the deployed web admin, on the free plan.'],
                [ShieldCheck, '3 · Verified', '30/30 rules tests, 300+ code tests in CI, 14/15 ARTEMIS runs on a real phone, 3 timed cross-role runs, App Check enforced.'],
              ].map(([Icon, head, text]) => {
                const I = Icon as typeof CheckCircle2;
                return (
                  <div key={head as string} className="wf">
                    <span className="ic big" style={{ background: '#fff' }}><I size={30} /></span>
                    <span className="name">{head as string}</span>
                    <p style={{ margin: 0, fontSize: 22, lineHeight: 1.45 }}>{text as string}</p>
                  </div>
                );
              })}
            </div>
            <div className="chips" style={{ marginTop: 6 }}>
              <span><Link2 size={15} /> prm393-not-lab3.web.app</span>
              <span><Link2 size={15} /> prm393-not-lab3.web.app/admin/</span>
              <span><Link2 size={15} /> github.com/FU-PRM-Projects/Lab-03</span>
              <span><Bell size={15} /> Thank you · Questions?</span>
            </div>
          </div>
        </S>

        {/* A1 · Appendix */}
        <S
          part="Appendix · A1 · AI examples"
          title="Three real Gemini inputs and outputs, and one handled failure"
          notes="Backup slide for AI questions. From docs/ai-feature.md."
          foot="Inputs are scrubbed (email, phone) and capped at 500 characters; no names, emails or photos are sent."
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
            <Shot src="ev-rc-params.png" alt="Remote Config parameters" w={340} cap="Remote Config: model, prompts, on/off" />
          </div>
        </S>

        {/* A2 · App Check */}
        <S
          part="Appendix · A2 · App Check"
          title="Both apps are registered, and Firestore and AI Logic are enforced"
          notes="Backup slide. Before enforcing we checked that the release build passes Play Integrity (Gemini works with AI Logic enforced). After enforcing, the web admin and the phone still read Firestore."
          foot="Web: reCAPTCHA Enterprise (Fraud Defense) · Android: Play Integrity (debug builds need a registered debug token) · enforced 12/11/2026 · evidence/app-check/."
        >
          <Shot src="ac-apps-registered.png" alt="App Check apps registered" w={560} cap="Apps: lab03 (android) Play Integrity · lab03 (web) Fraud Defense" />
          <Shot src="ac-firestore-enforced.png" alt="Firestore enforced" w={560} cap="Cloud Firestore: Enforced · AI Logic: Enforced" />
        </S>

        {/* A3 · Lessons (appendix) */}
        <S
          part="Appendix · A3 · Lessons learned"
          title="Running the system for real found bugs the tests did not"
          sub="Five bugs surfaced only against the real project or a real device; all are fixed, with regression tests."
          notes="The lesson: test on the deployed system with real accounts and real devices, not only the Emulator."
        >
          <div className="cards grow" style={{ gridTemplateColumns: '1fr 1fr 1fr' }}>
            <Card head="Approve timed out" tone="bad">
              <p>Riverpod paused the unwatched catalog provider; approval waited 10 s and failed. Found while timing D-1. Fixed: read the repository once (PR #70).</p>
            </Card>
            <Card head="Dashboard spun offline" tone="bad">
              <p><code>count()</code> waits for the server forever. Found while shooting the error state. Fixed: 15 s timeout → error state (PR #71).</p>
            </Card>
            <Card head="Error states 3 min late" tone="bad">
              <p>Riverpod 3 retried failed providers 10× while showing loading. Found on the deployed web admin. Fixed: <code>retry: noRetry</code> in both apps (PR #77).</p>
            </Card>
            <Card head="Role read only once" tone="bad">
              <p>A demoted staff kept the admin UI until reload (CR-F1). Fixed: the session follows the user's role document live (PR #75).</p>
            </Card>
            <Card head="Gemini model retired" tone="bad">
              <p><code>gemini-2.5-flash</code> returned 404 for new projects. Fixed: default <code>gemini-flash-lite-latest</code>, model stays in Remote Config.</p>
            </Card>
            <Card head="AI needs a plan B">
              <p>App Check, quota and model changes all broke AI at some point; the hand-written path kept the flow alive.</p>
            </Card>
          </div>
        </S>
      </Deck>
    </div>
  );
}
