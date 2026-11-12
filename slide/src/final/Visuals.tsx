import type { ReactNode } from 'react';
import { Slide } from '@revealjs/react';
import type { LucideIcon } from 'lucide-react';
import { ArrowRight } from 'lucide-react';

/** Extra visual slides for the Final deck: agenda, part dividers, storyboards, galleries. */

const base = import.meta.env.BASE_URL;
const img = (name: string) => `${base}final/${name}`;

function Logo({ white }: { white?: boolean }) {
  return <img className={white ? 'org-logo white' : 'org-logo'} src={`${base}assets/fpt-logo.webp`} alt="FPT University" />;
}

export type Part = {
  code: 'p1' | 'p2' | 'p3' | 'p4';
  num: string;
  name: string;
  question: string;
  minutes: string;
  slides: string[];
  icon: LucideIcon;
};

export function Agenda({ parts }: { parts: Part[] }) {
  return (
    <Slide className="fd px agenda" notes="Four parts, the lecturer's order. Time budget (for us, not on the slide): Problem ≈ 3.5 min · Design ≈ 6 min · Demo ≈ 6.5 min · Proof ≈ 2.5 min · total 18–20 min, demo about a third.">
      <Logo />
      <p className="kicker">
        <span className="chip">AGENDA</span>Four parts
      </p>
      <h2>Problem → Design → Demo → Proof</h2>
      <div className="agenda-row">
        {parts.map((p) => {
          const I = p.icon;
          return (
            <div key={p.code} className={`ag ${p.code}`}>
              <span className="ag-num">{p.num}</span>
              <span className="ag-ic">
                <I size={34} />
              </span>
              <span className="ag-name">{p.name}</span>
              <span className="ag-q">{p.question}</span>
              <ul>
                {p.slides.map((s) =>
                  s.startsWith('§') ? (
                    <li key={s} className="grp">
                      {s.slice(1)}
                    </li>
                  ) : (
                    <li key={s}>{s}</li>
                  ),
                )}
              </ul>
            </div>
          );
        })}
      </div>
    </Slide>
  );
}

export function Divider({ part, shots }: { part: Part; shots: string[] }) {
  const I = part.icon;
  return (
    <Slide className={`fd ${part.code} divider`} notes={`Part ${part.num}: ${part.name}. ${part.question} Time budget ${part.minutes}.`}>
      <Logo white />
      <div className="dv-left">
        <span className="dv-num">{part.num}</span>
        <span className="dv-ic">
          <I size={44} />
        </span>
        <h1>{part.name}</h1>
        <p className="dv-q">{part.question}</p>
        <ul className="dv-list">
          {part.slides.map((s) =>
            s.startsWith('§') ? (
              <li key={s} className="grp">
                {s.slice(1)}
              </li>
            ) : (
              <li key={s}>{s}</li>
            ),
          )}
        </ul>
      </div>
      <div className="dv-shots">
        {shots.map((s, i) => (
          <img key={s} src={img(s)} alt="" className={`dv-shot dv-shot-${i}`} />
        ))}
      </div>
    </Slide>
  );
}

export type Step = { src: string; title: string; text: string; web?: boolean };

/** Numbered screenshot storyboard: one frame per workflow step, arrows between. */
export function Storyboard({ steps, h = 330 }: { steps: Step[]; h?: number }) {
  return (
    <div className="story">
      {steps.map((s, i) => (
        <div key={s.title} style={{ display: 'contents' }}>
          {i > 0 && (
            <span className="story-arrow">
              <ArrowRight size={26} />
            </span>
          )}
          <figure className={s.web ? 'story-frame web' : 'story-frame'}>
            <span className="story-n">{i + 1}</span>
            <img src={img(s.src)} alt={s.title} style={s.web ? { width: h * 0.95 } : { height: h }} />
            <figcaption>
              <b>{s.title}</b>
              {s.text}
            </figcaption>
          </figure>
        </div>
      ))}
    </div>
  );
}

export type Screen = { src: string; code: string; name: string; web?: boolean };

export function ScreenRow({ label, screens, h }: { label: ReactNode; screens: Screen[]; h: number }) {
  return (
    <div className="screen-row">
      <span className="screen-label">{label}</span>
      <div className="screen-list">
        {screens.map((s) => (
          <figure key={s.code} className={s.web ? 'scr web' : 'scr'}>
            <img src={img(s.src)} alt={s.name} style={s.web ? { width: h * 1.55 } : { height: h }} />
            <figcaption>
              <span className="scr-code">{s.code}</span> {s.name}
            </figcaption>
          </figure>
        ))}
      </div>
    </div>
  );
}

export type Proof = { src?: string; term?: string[]; label: string; result: string };

export function EvidenceWall({ items }: { items: Proof[] }) {
  return (
    <div className="wall">
      {items.map((p) => (
        <figure key={p.label} className="wall-item">
          {p.src ? (
            <img src={img(p.src)} alt={p.label} />
          ) : (
            <pre className="term">
              {(p.term ?? []).map((l) => (
                <span key={l}>{l}</span>
              ))}
            </pre>
          )}
          <figcaption>
            <span>{p.label}</span>
            <b>{p.result}</b>
          </figcaption>
        </figure>
      ))}
    </div>
  );
}

/** The persona's drawn face on its own, for places where a full card is too much. */
export function MiniAvatar({ size = 64 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 120 120" aria-hidden="true">
      <circle cx="60" cy="60" r="58" fill="#e6efff" />
      <path d="M22 112c4-24 20-36 38-36s34 12 38 36" fill="#3d4fd6" />
      <circle cx="60" cy="48" r="22" fill="#f5c9a8" />
      <path d="M38 46c0-16 10-25 23-25 14 0 22 9 22 22-6-6-14-9-24-9-9 0-15 4-21 12z" fill="#2b2e3b" />
      <circle cx="52" cy="50" r="2.4" fill="#2b2e3b" />
      <circle cx="68" cy="50" r="2.4" fill="#2b2e3b" />
      <path d="M53 61c4 2.5 10 2.5 14 0" stroke="#2b2e3b" strokeWidth="2.4" fill="none" strokeLinecap="round" />
    </svg>
  );
}

/** Small persona card: drawn avatar, name, three short facts. */
export function PersonaCard({
  name,
  meta,
  facts,
}: {
  name: string;
  meta: string;
  facts: [string, string][];
}) {
  return (
    <div className="persona">
      <svg className="persona-avatar" viewBox="0 0 120 120" aria-hidden="true">
        <circle cx="60" cy="60" r="58" fill="#e6efff" />
        <path d="M22 112c4-24 20-36 38-36s34 12 38 36" fill="#3d4fd6" />
        <circle cx="60" cy="48" r="22" fill="#f5c9a8" />
        <path d="M38 46c0-16 10-25 23-25 14 0 22 9 22 22-6-6-14-9-24-9-9 0-15 4-21 12z" fill="#2b2e3b" />
        <circle cx="52" cy="50" r="2.4" fill="#2b2e3b" />
        <circle cx="68" cy="50" r="2.4" fill="#2b2e3b" />
        <path d="M53 61c4 2.5 10 2.5 14 0" stroke="#2b2e3b" strokeWidth="2.4" fill="none" strokeLinecap="round" />
        <rect x="74" y="80" width="18" height="28" rx="3" fill="#1b1d2a" />
        <rect x="76.5" y="83" width="13" height="20" rx="1.5" fill="#9fb4ff" />
      </svg>
      <div className="persona-body">
        <span className="persona-name">{name}</span>
        <span className="persona-meta">{meta}</span>
        <dl>
          {facts.map(([k, v]) => (
            <div key={k}>
              <dt>{k}</dt>
              <dd>{v}</dd>
            </div>
          ))}
        </dl>
      </div>
    </div>
  );
}

export type FlowStep = { icon: LucideIcon; title: string; note: string; warn?: boolean; stat?: string };

/** Process diagram: numbered circles with icons, arrows between, short note under each. */
export function FlowDiagram({ steps }: { steps: FlowStep[] }) {
  return (
    <div className="procflow">
      {steps.map((s, i) => {
        const I = s.icon;
        return (
          <div key={s.title} className={s.warn ? 'flow-step warn' : 'flow-step'}>
            <div className="flow-node">
              <span className="flow-n">{i + 1}</span>
              <I size={30} />
            </div>
            {i < steps.length - 1 && <span className="flow-line" />}
            <b>{s.title}</b>
            <small>{s.note}</small>
            {s.stat && (
              <span className="flow-stat">
                <b>{s.stat.split('|')[0]}</b>
                {s.stat.split('|')[1]}
              </span>
            )}
          </div>
        );
      })}
    </div>
  );
}

/* ---------------------------------------------------------------- problem illustrations (slide 03) */

/** A to-do list: one small thing done, many boxes still empty. */
export function IllTodo() {
  const rows = [true, false, false, false, false];
  return (
    <svg viewBox="0 0 200 120" className="ill" aria-hidden="true">
      <rect x="40" y="6" width="120" height="108" rx="10" fill="#fff" stroke="#d7dce8" strokeWidth="2" />
      <rect x="40" y="6" width="120" height="20" rx="10" fill="#eef1f7" />
      <text x="100" y="20" textAnchor="middle" fontSize="10" fontWeight="700" fill="#5b6478">TO DO</text>
      {rows.map((done, i) => (
        <g key={i} transform={`translate(52 ${36 + i * 15})`}>
          <rect width="10" height="10" rx="2" fill={done ? '#cfe9df' : '#fff'} stroke={done ? '#0f8a6a' : '#c81e1e'} strokeWidth="1.6" />
          {done && <path d="M2 5l2.5 2.5L8.5 2.5" stroke="#0f8a6a" strokeWidth="1.6" fill="none" />}
          <rect x="16" y="3" width={done ? 40 : 70 - i * 6} height="4" rx="2" fill={done ? '#cfd5e1' : '#9aa3b5'} />
        </g>
      ))}
      <circle cx="168" cy="20" r="14" fill="#c81e1e" />
      <text x="168" y="25" textAnchor="middle" fontSize="14" fontWeight="800" fill="#fff">4</text>
    </svg>
  );
}

/** A journal page that asks for far more than a tired person can give. */
export function IllJournal() {
  return (
    <svg viewBox="0 0 200 120" className="ill" aria-hidden="true">
      <rect x="44" y="6" width="112" height="108" rx="8" fill="#fff" stroke="#d7dce8" strokeWidth="2" />
      <text x="56" y="22" fontSize="10" fontWeight="700" fill="#5b6478">Dear diary…</text>
      {[0, 1, 2, 3, 4, 5, 6].map((i) => (
        <rect key={i} x="56" y={32 + i * 10} width={i === 6 ? 40 : 88} height="3" rx="1.5" fill="#d7dce8" />
      ))}
      <rect x="56" y="32" width="22" height="3" rx="1.5" fill="#5b6478" />
      <rect x="112" y="100" width="40" height="10" rx="5" fill="#fde8e8" />
      <text x="132" y="108" textAnchor="middle" fontSize="7.5" fontWeight="700" fill="#c81e1e">12 / 500</text>
      <g transform="translate(160 70)">
        <circle r="14" fill="#fff4e5" stroke="#c2410c" strokeWidth="1.6" />
        <text y="5" textAnchor="middle" fontSize="13" fill="#c2410c">z</text>
      </g>
    </svg>
  );
}

/** The same challenge card again and again. */
export function IllRepeat() {
  return (
    <svg viewBox="0 0 200 120" className="ill" aria-hidden="true">
      {[2, 1, 0].map((i) => (
        <g key={i} transform={`translate(${48 + i * 10} ${14 + i * 8})`}>
          <rect width="92" height="70" rx="8" fill="#fff" stroke="#d7dce8" strokeWidth="2" />
          <rect x="10" y="12" width="44" height="5" rx="2.5" fill="#9aa3b5" />
          <rect x="10" y="24" width="64" height="4" rx="2" fill="#d7dce8" />
          <rect x="10" y="32" width="54" height="4" rx="2" fill="#d7dce8" />
          <text x="10" y="58" fontSize="8" fontWeight="700" fill="#5b6478">Walk 10 min</text>
        </g>
      ))}
      <g transform="translate(166 30)" fill="none" stroke="#c81e1e" strokeWidth="2.4" strokeLinecap="round">
        <path d="M-10 0a10 10 0 1 1 3 7" />
        <path d="M-12 -6l2 6 6 -2" />
      </g>
      <text x="166" y="58" textAnchor="middle" fontSize="8" fontWeight="800" fill="#c81e1e">day 30</text>
    </svg>
  );
}

/* ---------------------------------------------------------------- actor map (slide 05) */

export type ActorRow = {
  icon: LucideIcon;
  name: string;
  who: string;
  tone: 'u' | 's' | 'a';
  perms: string[];
  client: { icon: LucideIcon; label: string; shot: string; phone?: boolean };
  badge?: string;
};

/** Roles on the left, the client each one uses, then Firebase (rules) and Gemini on the right. */
export function ActorMap({
  rows,
  hub,
  ext,
}: {
  rows: ActorRow[];
  hub: { icon: LucideIcon; name: string; lines: string[]; rule: string };
  ext: { icon: LucideIcon; name: string; lines: string[] };
}) {
  const H = hub.icon;
  const E = ext.icon;
  return (
    <div className="amap">
      {rows.map((r, i) => {
        const I = r.icon;
        const C = r.client.icon;
        return (
          <div key={r.name} className={`amap-row ${r.tone}`} style={{ gridRow: i + 1 }}>
            <div className="amap-who">
              <span className="amap-av"><I size={26} /></span>
              <div>
                <b>{r.name}</b>
                {r.badge && <span className="amap-badge">{r.badge}</span>}
                <small>{r.who}</small>
              </div>
            </div>
            <ul className="amap-perms">
              {r.perms.map((p) => (
                <li key={p}>{p}</li>
              ))}
            </ul>
            <div className="amap-client">
              <img src={img(r.client.shot)} alt="" className={r.client.phone ? 'phone' : 'web'} />
              <span><C size={15} /> {r.client.label}</span>
            </div>
          </div>
        );
      })}
      <svg className="amap-join" viewBox="0 0 80 480" preserveAspectRatio="none" aria-hidden="true">
        <defs>
          <marker id="amap-head" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
            <path d="M0 0L10 5L0 10z" fill="#5b6478" />
          </marker>
        </defs>
        {[80, 240, 400].map((y) => (
          <path key={y} d={`M2 ${y} C 40 ${y}, 40 240, 76 240`} fill="none" stroke="#5b6478" strokeWidth="2.5" markerEnd="url(#amap-head)" />
        ))}
      </svg>
      <div className="amap-hub">
        <span className="amap-hub-ic"><H size={30} /></span>
        <b>{hub.name}</b>
        {hub.lines.map((l) => (
          <small key={l}>{l}</small>
        ))}
        <span className="amap-rule">{hub.rule}</span>
      </div>
      <span className="amap-arrow ext"><ArrowRight size={30} strokeWidth={2.5} /></span>
      <div className="amap-ext">
        <span className="amap-hub-ic"><E size={28} /></span>
        <b>{ext.name}</b>
        {ext.lines.map((l) => (
          <small key={l}>{l}</small>
        ))}
      </div>
    </div>
  );
}
