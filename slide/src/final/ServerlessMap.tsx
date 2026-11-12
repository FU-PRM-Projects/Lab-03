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

const S = 44; // icon square

function Brand({ x, y, icon, size = S }: { x: number; y: number; icon: SimpleIcon; size?: number }) {
  const pad = size * 0.16;
  const k = (size - pad * 2) / 24;
  return (
    <g>
      <rect x={x} y={y} width={size} height={size} rx={8} fill="#fff" stroke="#d9dce6" />
      <path d={icon.path} fill={`#${icon.hex}`} transform={`translate(${x + pad} ${y + pad}) scale(${k})`} />
    </g>
  );
}

/** Firebase product: amber tile + white glyph + small Firebase flame badge. */
function Fire({ x, y, I, color = FIRE }: { x: number; y: number; I: LucideIcon; color?: string }) {
  return (
    <g>
      <rect x={x} y={y} width={S} height={S} rx={8} fill={color} />
      <I x={x + 10} y={y + 10} width={24} height={24} color="#fff" strokeWidth={2} />
      <circle cx={x + S - 2} cy={y + 2} r={9} fill="#fff" stroke="#e3e5ee" />
      <path d={siFirebase.path} fill={`#${siFirebase.hex}`} transform={`translate(${x + S - 9} ${y - 5}) scale(${14 / 24})`} />
    </g>
  );
}

function Plain({ x, y, I, color }: { x: number; y: number; I: LucideIcon; color: string }) {
  return (
    <g>
      <rect x={x} y={y} width={S} height={S} rx={8} fill={color} />
      <I x={x + 10} y={y + 10} width={24} height={24} color="#fff" strokeWidth={2} />
    </g>
  );
}

/** Icon at (cx - S/2, y) with a two-line caption under it. */
function Node({ cx, y, icon, t, s }: { cx: number; y: number; icon: (x: number, y: number) => ReactNode; t: string; s?: string }) {
  return (
    <g>
      {icon(cx - S / 2, y)}
      <text x={cx} y={y + S + 14} textAnchor="middle" fontSize={11.5} fontWeight={700} fill={INK}>
        {t}
      </text>
      {s && (
        <text x={cx} y={y + S + 27} textAnchor="middle" fontSize={10} fill={MUTED}>
          {s}
        </text>
      )}
    </g>
  );
}

function Block({ x, y, w, h, t, color }: { x: number; y: number; w: number; h: number; t: string; color: string }) {
  return (
    <g>
      <rect x={x} y={y} width={w} height={h} rx={6} fill="#fff" stroke={color} strokeWidth={1.8} strokeDasharray="7 5" />
      <text x={x + w / 2} y={y + 16} textAnchor="middle" fontSize={11.5} fontWeight={700} fill={INK}>
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
      strokeWidth={1.4}
      strokeDasharray={async ? '7 3 2 3' : undefined}
      markerEnd="url(#sa)"
    />
  );
}

/** Thick grey chevron between blocks, like the AWS sample. */
function Big({ x, y, rot = 0 }: { x: number; y: number; rot?: number }) {
  return (
    <path
      d="M0 -7 H18 V-15 L34 0 L18 15 V7 H0 Z"
      fill="#6b7080"
      transform={`translate(${x} ${y}) rotate(${rot})`}
    />
  );
}

export default function ServerlessMap() {
  return (
    <svg className="diagram" viewBox="0 0 1168 492">
      <defs>
        <marker id="sa" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
          <path d="M0 0 L10 5 L0 10 z" fill={ARROW} />
        </marker>
      </defs>

      {/* brand strip + legend */}
      <g>
        <path d={siFlutter.path} fill={`#${siFlutter.hex}`} transform="translate(176 4) scale(0.9)" />
        <text x={200} y={20} fontSize={13} fontWeight={700} fill={INK}>Flutter</text>
        <path d={siFirebase.path} fill={`#${siFirebase.hex}`} transform="translate(256 4) scale(0.9)" />
        <text x={280} y={20} fontSize={13} fontWeight={700} fill={INK}>Firebase</text>
        <path d={siGooglecloud.path} fill={`#${siGooglecloud.hex}`} transform="translate(346 4) scale(0.9)" />
        <text x={370} y={20} fontSize={13} fontWeight={700} fill={INK}>Google Cloud · serverless, Spark plan</text>
      </g>
      <g>
        <path d="M876 12 H916" stroke={ARROW} strokeWidth={1.4} strokeDasharray="7 3 2 3" />
        <text x={922} y={16} fontSize={11} fill={MUTED}>realtime / asynchronous</text>
        <rect x={1084} y={4} width={22} height={16} rx={3} fill="none" stroke="#f0b429" strokeDasharray="4 3" />
        <text x={1112} y={16} fontSize={11} fill={MUTED}>a block</text>
      </g>

      {/* system boundary */}
      <rect x={170} y={34} width={994} height={322} rx={4} fill="none" stroke="#454a5a" strokeWidth={1.4} strokeDasharray="2 4" />
      <text x={180} y={50} fontSize={11} fontWeight={700} fill={MUTED}>FIREBASE PROJECT prm393-not-lab3 · asia-southeast1</text>

      {/* ---- Frontend (outside) */}
      <Block x={0} y={96} w={160} h={250} t="Frontend" color="#3b82f6" />
      <Node cx={40} y={118} t="User" s="phone" icon={(x, y) => <Plain x={x} y={y} I={Smartphone} color="#64748b" />} />
      <Node cx={120} y={118} t="Staff" s="browser" icon={(x, y) => <Plain x={x} y={y} I={Laptop} color="#64748b" />} />
      <Node cx={40} y={208} t="App" s="Flutter" icon={(x, y) => <Brand x={x} y={y} icon={siFlutter} />} />
      <Node cx={120} y={208} t="Web admin" s="Flutter Web" icon={(x, y) => <Brand x={x} y={y} icon={siGooglechrome} />} />
      <g>
        <Brand x={22} y={296} icon={siAndroid} size={30} />
        <Brand x={65} y={296} icon={siDart} size={30} />
        <Brand x={108} y={296} icon={siGoogleplay} size={30} />
      </g>
      <A d="M40 180 V206" />
      <A d="M120 180 V206" />

      {/* ---- Entry: App Check + Hosting */}
      <Node cx={226} y={170} t="App Check" s="gate for every call" icon={(x, y) => <Fire x={x} y={y} I={ShieldCheck} />} />
      <A d="M160 230 H202" />
      <Block x={188} y={258} w={128} h={94} t="Website Hosting" color="#16a34a" />
      <Node cx={252} y={276} t="Hosting" s="app + /admin/" icon={(x, y) => <Fire x={x} y={y} I={Rocket} />} />
      <A d="M120 262 C120 330 170 312 228 300" async />

      {/* ---- Users & Authentication */}
      <Block x={330} y={60} w={250} h={124} t="Users & Authentication" color="#f0b429" />
      <Node cx={380} y={84} t="Firebase Auth" s="session" icon={(x, y) => <Fire x={x} y={y} I={KeyRound} />} />
      <rect x={430} y={78} width={74} height={88} rx={4} fill="none" stroke="#9aa1b3" strokeDasharray="3 3" />
      <Node cx={467} y={84} t="Google" s="identity" icon={(x, y) => <Brand x={x} y={y} icon={siGoogle} />} />
      <Node cx={542} y={84} t="users/{uid}" s="role check" icon={(x, y) => <Plain x={x} y={y} I={User} color="#3B48CC" />} />
      <A d="M402 106 H443" />
      <A d="M489 106 H518" />
      <A d="M250 192 C280 150 300 120 356 106" />

      {/* ---- Business data: rules + Firestore */}
      <Block x={330} y={200} w={250} h={146} t="Business API = Security Rules" color="#f28b82" />
      <Node cx={372} y={226} t="Rules" s="BR-02…05" icon={(x, y) => <Fire x={x} y={y} I={ScrollText} />} />
      <Node cx={456} y={226} t="Firestore" s="realtime NoSQL" icon={(x, y) => <Fire x={x} y={y} I={Database} color="#ffa000" />} />
      <Node cx={540} y={226} t="Remote Config" s="flags · prompts" icon={(x, y) => <Fire x={x} y={y} I={SlidersHorizontal} />} />
      <A d="M250 214 C280 240 320 250 356 248" />
      <A d="M394 248 H432" />
      <text x={455} y={318} textAnchor="middle" fontSize={10} fill={MUTED}>no custom server: rules hold the business logic</text>

      <Big x={590} y={160} />
      <Big x={590} y={268} />

      {/* ---- AI */}
      <Block x={636} y={60} w={236} h={124} t="AI  (level 2)" color="#22c55e" />
      <Node cx={690} y={84} t="AI Logic" s="Firebase SDK" icon={(x, y) => <Fire x={x} y={y} I={Sparkles} color="#01A88D" />} />
      <Node cx={812} y={84} t="Gemini" s="flash-lite · JSON" icon={(x, y) => <Brand x={x} y={y} icon={siGooglegemini} />} />
      <A d="M712 106 H788" />
      <text x={750} y={100} textAnchor="middle" fontSize={9.5} fill={MUTED}>scrubbed text</text>

      {/* ---- Files & media */}
      <Block x={636} y={200} w={236} h={146} t="Files & Media" color="#a16207" />
      <Node cx={690} y={226} t="Weekly PDF" s="saved on device" icon={(x, y) => <Plain x={x} y={y} I={FileText} color="#a16207" />} />
      <Node cx={812} y={226} t="Cloudinary" s="note photos" icon={(x, y) => <Brand x={x} y={y} icon={siCloudinary} />} />
      <text x={754} y={318} textAnchor="middle" fontSize={10} fill={MUTED}>metadata in Firestore · no Cloud Storage (paid)</text>

      <Big x={882} y={120} />
      <Big x={882} y={270} />

      {/* ---- Back-end to front-end push */}
      <Block x={928} y={60} w={226} h={150} t="Back-end → front-end push" color="#60a5fa" />
      <Node cx={980} y={86} t="Snapshots" s="Firestore realtime" icon={(x, y) => <Fire x={x} y={y} I={Radio} color="#ffa000" />} />
      <Node cx={1100} y={86} t="Cloud Messaging" s="FCM push" icon={(x, y) => <Fire x={x} y={y} I={BellRing} />} />
      <text x={1040} y={186} textAnchor="middle" fontSize={10} fill={MUTED}>card approved · inbox · reminders</text>
      <A d="M1002 108 H1076" async />

      {/* ---- Extra async service */}
      <Block x={928} y={222} w={226} h={124} t="Asynchronous extra · Discord" color="#8b5cf6" />
      <Node cx={970} y={246} t="Bot (Rust)" s="slash commands" icon={(x, y) => <Brand x={x} y={y} icon={siRust} />} />
      <Node cx={1040} y={246} t="Docker" s="Dokploy" icon={(x, y) => <Brand x={x} y={y} icon={siDocker} />} />
      <Node cx={1110} y={246} t="Discord" s="rooms" icon={(x, y) => <Brand x={x} y={y} icon={siDiscord} />} />
      <A d="M992 268 H1016" async />
      <A d="M1062 268 H1086" async />

      {/* ---- outside the system: security, monitoring, DevOps */}
      <Block x={170} y={372} w={250} h={116} t="Security" color="#ef4444" />
      <Node cx={220} y={396} t="App Check" s="Play Integrity" icon={(x, y) => <Brand x={x} y={y} icon={siGoogleplay} />} />
      <Node cx={296} y={396} t="reCAPTCHA" s="web admin" icon={(x, y) => <Brand x={x} y={y} icon={siGoogle} />} />
      <Node cx={372} y={396} t="Rules tests" s="30/30" icon={(x, y) => <Fire x={x} y={y} I={ShieldCheck} />} />

      <Block x={436} y={372} w={250} h={116} t="Monitoring" color="#ec4899" />
      <Node cx={486} y={396} t="Crashlytics" s="mobile crashes" icon={(x, y) => <Fire x={x} y={y} I={Bug} />} />
      <Node cx={561} y={396} t="Analytics" s="events" icon={(x, y) => <Brand x={x} y={y} icon={siGoogleanalytics} />} />
      <Node cx={636} y={396} t="App Check" s="traffic metrics" icon={(x, y) => <Fire x={x} y={y} I={Activity} />} />

      <Block x={702} y={372} w={462} h={116} t="DevOps · CI/CD" color="#7c3aed" />
      <Node cx={752} y={396} t="GitHub" s="PRs · branches" icon={(x, y) => <Brand x={x} y={y} icon={siGithub} />} />
      <Node cx={842} y={396} t="CodeRabbit" s="AI review" icon={(x, y) => <Brand x={x} y={y} icon={siCoderabbit} />} />
      <Node cx={932} y={396} t="GitHub Actions" s="format · test · build" icon={(x, y) => <Brand x={x} y={y} icon={siGithubactions} />} />
      <Node cx={1022} y={396} t="Hosting deploy" s="+ rules, indexes" icon={(x, y) => <Fire x={x} y={y} I={Rocket} />} />
      <Node cx={1110} y={396} t="Preview" s="channel per PR" icon={(x, y) => <Fire x={x} y={y} I={Laptop} />} />
      <A d="M774 418 H818" />
      <A d="M864 418 H908" />
      <A d="M954 418 H998" />
      <A d="M1044 418 H1086" async />
    </svg>
  );
}
