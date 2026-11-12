import type { ReactNode } from 'react';
import type { LucideIcon } from 'lucide-react';
import {
  Activity,
  BellRing,
  Bug,
  Database,
  FileText,
  KeyRound,
  Laptop,
  Radio,
  Rocket,
  ScrollText,
  ShieldCheck,
  SlidersHorizontal,
  Smartphone,
  Sparkles,
  User,
} from 'lucide-react';
import type { SimpleIcon } from 'simple-icons';
import {
  siAndroid,
  siCloudinary,
  siCoderabbit,
  siDart,
  siDiscord,
  siDocker,
  siFirebase,
  siFlutter,
  siGithub,
  siGithubactions,
  siGoogle,
  siGoogleanalytics,
  siGooglechrome,
  siGooglecloud,
  siGooglegemini,
  siGoogleplay,
  siRust,
} from 'simple-icons';

/** Slide 10: "typical serverless architecture" in the AWS style, with real logos. */

const INK = '#1b1d2a';
const MUTED = '#555b6e';
const FIRE = '#F57C00';
const ARROW = '#3a3f50';

const S = 50; // icon square
const G = 28; // glyph size inside a square

function Brand({ x, y, icon, size = S }: { x: number; y: number; icon: SimpleIcon; size?: number }) {
  const pad = size * 0.17;
  const k = (size - pad * 2) / 24;
  return (
    <g>
      <rect x={x} y={y} width={size} height={size} rx={9} fill="#fff" stroke="#d9dce6" />
      <path d={icon.path} fill={`#${icon.hex}`} transform={`translate(${x + pad} ${y + pad}) scale(${k})`} />
    </g>
  );
}

/** Firebase product: amber tile + white glyph + small Firebase flame badge. */
function Fire({ x, y, I, color = FIRE }: { x: number; y: number; I: LucideIcon; color?: string }) {
  return (
    <g>
      <rect x={x} y={y} width={S} height={S} rx={9} fill={color} />
      <I x={x + (S - G) / 2} y={y + (S - G) / 2} width={G} height={G} color="#fff" strokeWidth={2} />
      <circle cx={x + S - 2} cy={y + 2} r={10} fill="#fff" stroke="#e3e5ee" />
      <path d={siFirebase.path} fill={`#${siFirebase.hex}`} transform={`translate(${x + S - 10} ${y - 6}) scale(${16 / 24})`} />
    </g>
  );
}

function Plain({ x, y, I, color }: { x: number; y: number; I: LucideIcon; color: string }) {
  return (
    <g>
      <rect x={x} y={y} width={S} height={S} rx={9} fill={color} />
      <I x={x + (S - G) / 2} y={y + (S - G) / 2} width={G} height={G} color="#fff" strokeWidth={2} />
    </g>
  );
}

/** Icon at (cx - S/2, y) with a two-line caption under it. */
function Node({ cx, y, icon, t, s }: { cx: number; y: number; icon: (x: number, y: number) => ReactNode; t: string; s?: string }) {
  return (
    <g>
      {icon(cx - S / 2, y)}
      <text x={cx} y={y + S + 17} textAnchor="middle" fontSize={13.5} fontWeight={700} fill={INK}>
        {t}
      </text>
      {s && (
        <text x={cx} y={y + S + 32} textAnchor="middle" fontSize={11.5} fill={MUTED}>
          {s}
        </text>
      )}
    </g>
  );
}

function Block({ x, y, w, h, t, color }: { x: number; y: number; w: number; h: number; t: string; color: string }) {
  return (
    <g>
      <rect x={x} y={y} width={w} height={h} rx={7} fill="#fff" stroke={color} strokeWidth={2} strokeDasharray="8 5" />
      <text x={x + w / 2} y={y + 19} textAnchor="middle" fontSize={13.5} fontWeight={800} fill={INK}>
        {t}
      </text>
    </g>
  );
}

function A({ d, async }: { d: string; async?: boolean }) {
  return (
    <path
      d={d}
      fill="none"
      stroke={ARROW}
      strokeWidth={1.6}
      strokeDasharray={async ? '8 3 2 3' : undefined}
      markerEnd="url(#sa)"
    />
  );
}

function Note({ x, y, t }: { x: number; y: number; t: string }) {
  return (
    <text x={x} y={y} textAnchor="middle" fontSize={11.5} fill={MUTED} fontStyle="italic">
      {t}
    </text>
  );
}

/** Thick grey chevron between blocks, like the AWS sample. */
function Big({ x, y }: { x: number; y: number }) {
  return <path d="M0 -7 H16 V-15 L32 0 L16 15 V7 H0 Z" fill="#6b7080" transform={`translate(${x} ${y})`} />;
}

export default function ServerlessMap() {
  return (
    <svg className="diagram" viewBox="0 0 1220 528">
      <defs>
        <marker id="sa" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
          <path d="M0 0 L10 5 L0 10 z" fill={ARROW} />
        </marker>
      </defs>

      {/* brand strip + legend */}
      <g>
        <path d={siFlutter.path} fill={`#${siFlutter.hex}`} transform="translate(196 0) scale(0.95)" />
        <text x={222} y={17} fontSize={14} fontWeight={700} fill={INK}>Flutter</text>
        <path d={siFirebase.path} fill={`#${siFirebase.hex}`} transform="translate(282 0) scale(0.95)" />
        <text x={308} y={17} fontSize={14} fontWeight={700} fill={INK}>Firebase</text>
        <path d={siGooglecloud.path} fill={`#${siGooglecloud.hex}`} transform="translate(378 0) scale(0.95)" />
        <text x={404} y={17} fontSize={14} fontWeight={700} fill={INK}>Google Cloud · serverless · Spark plan</text>
      </g>
      <g>
        <path d="M900 12 H940" stroke={ARROW} strokeWidth={1.6} strokeDasharray="8 3 2 3" />
        <text x={946} y={16} fontSize={12} fill={MUTED}>realtime / async</text>
        <path d="M1046 12 H1082" stroke={ARROW} strokeWidth={1.6} markerEnd="url(#sa)" />
        <text x={1088} y={16} fontSize={12} fill={MUTED}>request</text>
        <rect x={1146} y={4} width={22} height={16} rx={3} fill="none" stroke="#f0b429" strokeDasharray="4 3" />
        <text x={1174} y={16} fontSize={12} fill={MUTED}>block</text>
      </g>

      {/* system boundary */}
      <rect x={186} y={28} width={1032} height={350} rx={4} fill="none" stroke="#454a5a" strokeWidth={1.5} strokeDasharray="2 4" />
      <text x={198} y={45} fontSize={12} fontWeight={700} fill={MUTED}>FIREBASE PROJECT prm393-not-lab3 · asia-southeast1</text>

      {/* ---- Frontend (outside the project) */}
      <Block x={0} y={70} w={172} h={308} t="Frontend" color="#3b82f6" />
      <Node cx={46} y={92} t="User" s="phone" icon={(x, y) => <Plain x={x} y={y} I={Smartphone} color="#64748b" />} />
      <Node cx={128} y={92} t="Staff" s="browser" icon={(x, y) => <Plain x={x} y={y} I={Laptop} color="#64748b" />} />
      <Node cx={46} y={202} t="App" s="Flutter" icon={(x, y) => <Brand x={x} y={y} icon={siFlutter} />} />
      <Node cx={128} y={202} t="Web admin" s="Flutter Web" icon={(x, y) => <Brand x={x} y={y} icon={siGooglechrome} />} />
      <A d="M46 177 V198" />
      <A d="M128 177 V198" />
      <g>
        <Brand x={20} y={322} icon={siAndroid} size={36} />
        <Brand x={68} y={322} icon={siDart} size={36} />
        <Brand x={116} y={322} icon={siGoogleplay} size={36} />
      </g>

      {/* ---- Entry: App Check gate + website hosting */}
      <Node cx={246} y={150} t="App Check" s="every call" icon={(x, y) => <Fire x={x} y={y} I={ShieldCheck} />} />
      <A d="M172 175 H219" />
      <Block x={200} y={262} w={136} h={108} t="Website Hosting" color="#16a34a" />
      <Node cx={268} y={286} t="Hosting" s="app + /admin/" icon={(x, y) => <Fire x={x} y={y} I={Rocket} />} />
      <A d="M172 311 H241" async />

      {/* ---- Users & Authentication */}
      <Block x={352} y={58} w={292} h={146} t="Users & Authentication" color="#f0b429" />
      <Node cx={405} y={86} t="Firebase Auth" s="session" icon={(x, y) => <Fire x={x} y={y} I={KeyRound} />} />
      <rect x={456} y={78} width={92} height={118} rx={5} fill="none" stroke="#9aa1b3" strokeDasharray="3 3" />
      <Node cx={502} y={86} t="Google" s="identity" icon={(x, y) => <Brand x={x} y={y} icon={siGoogle} />} />
      <Node cx={598} y={86} t="users/{uid}" s="role" icon={(x, y) => <Plain x={x} y={y} I={User} color="#3B48CC" />} />
      <A d="M430 111 H475" />
      <A d="M527 111 H571" />
      <A d="M271 162 C312 130 330 112 378 111" />

      {/* ---- Business API = Security Rules */}
      <Block x={352} y={218} w={292} h={152} t="Business API = Security Rules" color="#f28b82" />
      <Node cx={402} y={246} t="Rules" s="BR-02…05" icon={(x, y) => <Fire x={x} y={y} I={ScrollText} />} />
      <Node cx={494} y={246} t="Firestore" s="realtime NoSQL" icon={(x, y) => <Fire x={x} y={y} I={Database} color="#ffa000" />} />
      <Node cx={588} y={246} t="Remote Config" s="flags · prompts" icon={(x, y) => <Fire x={x} y={y} I={SlidersHorizontal} />} />
      <A d="M427 271 H467" />
      <A d="M271 188 C312 222 330 268 375 271" />
      <Note x={498} y={358} t="no custom server: rules hold the business logic" />

      <Big x={652} y={131} />
      <Big x={652} y={294} />

      {/* ---- AI */}
      <Block x={694} y={58} w={256} h={146} t="AI  (level 2)" color="#22c55e" />
      <Node cx={752} y={86} t="AI Logic" s="Firebase SDK" icon={(x, y) => <Fire x={x} y={y} I={Sparkles} color="#01A88D" />} />
      <Node cx={892} y={86} t="Gemini" s="flash-lite · JSON" icon={(x, y) => <Brand x={x} y={y} icon={siGooglegemini} />} />
      <A d="M777 111 H865" />
      <Note x={822} y={102} t="scrubbed text" />

      {/* ---- Files & Media */}
      <Block x={694} y={218} w={256} h={152} t="Files & Media" color="#a16207" />
      <Node cx={752} y={246} t="Weekly PDF" s="on the device" icon={(x, y) => <Plain x={x} y={y} I={FileText} color="#a16207" />} />
      <Node cx={892} y={246} t="Cloudinary" s="note photos" icon={(x, y) => <Brand x={x} y={y} icon={siCloudinary} />} />
      <Note x={822} y={358} t="no Cloud Storage (paid plan)" />

      <Big x={958} y={131} />
      <Big x={958} y={294} />

      {/* ---- Back-end → front-end push */}
      <Block x={998} y={58} w={214} h={146} t="Back-end → front-end push" color="#60a5fa" />
      <Node cx={1046} y={86} t="Snapshots" s="realtime" icon={(x, y) => <Fire x={x} y={y} I={Radio} color="#ffa000" />} />
      <Node cx={1164} y={86} t="FCM" s="push" icon={(x, y) => <Fire x={x} y={y} I={BellRing} />} />
      <A d="M1071 111 H1137" async />

      {/* ---- Async extra: Discord */}
      <Block x={998} y={218} w={214} h={152} t="Async extra · Discord" color="#8b5cf6" />
      <Node cx={1036} y={246} t="Rust bot" s="commands" icon={(x, y) => <Brand x={x} y={y} icon={siRust} />} />
      <Node cx={1105} y={246} t="Docker" s="Dokploy" icon={(x, y) => <Brand x={x} y={y} icon={siDocker} />} />
      <Node cx={1174} y={246} t="Discord" s="rooms" icon={(x, y) => <Brand x={x} y={y} icon={siDiscord} />} />
      <A d="M1061 271 H1078" async />
      <A d="M1130 271 H1147" async />

      {/* ---- outside the project: security, monitoring, DevOps */}
      <Block x={186} y={392} w={292} h={132} t="Security" color="#ef4444" />
      <Node cx={236} y={420} t="App Check" s="Play Integrity" icon={(x, y) => <Brand x={x} y={y} icon={siGoogleplay} />} />
      <Node cx={332} y={420} t="reCAPTCHA" s="web admin" icon={(x, y) => <Brand x={x} y={y} icon={siGoogle} />} />
      <Node cx={428} y={420} t="Rules tests" s="30/30" icon={(x, y) => <Fire x={x} y={y} I={ShieldCheck} />} />

      <Block x={494} y={392} w={292} h={132} t="Monitoring" color="#ec4899" />
      <Node cx={544} y={420} t="Crashlytics" s="crashes" icon={(x, y) => <Fire x={x} y={y} I={Bug} />} />
      <Node cx={640} y={420} t="Analytics" s="events" icon={(x, y) => <Brand x={x} y={y} icon={siGoogleanalytics} />} />
      <Node cx={736} y={420} t="App Check" s="traffic" icon={(x, y) => <Fire x={x} y={y} I={Activity} />} />

      <Block x={802} y={392} w={384} h={132} t="DevOps · CI/CD" color="#7c3aed" />
      <Node cx={842} y={420} t="GitHub" s="PRs" icon={(x, y) => <Brand x={x} y={y} icon={siGithub} />} />
      <Node cx={918} y={420} t="CodeRabbit" s="AI review" icon={(x, y) => <Brand x={x} y={y} icon={siCoderabbit} />} />
      <Node cx={996} y={420} t="Actions" s="test · build" icon={(x, y) => <Brand x={x} y={y} icon={siGithubactions} />} />
      <Node cx={1074} y={420} t="Deploy" s="Hosting · rules" icon={(x, y) => <Fire x={x} y={y} I={Rocket} />} />
      <Node cx={1148} y={420} t="Preview" s="per PR" icon={(x, y) => <Fire x={x} y={y} I={Laptop} />} />
      <A d="M867 445 H891" />
      <A d="M943 445 H969" />
      <A d="M1021 445 H1047" />
      <A d="M1099 445 H1121" async />
    </svg>
  );
}
