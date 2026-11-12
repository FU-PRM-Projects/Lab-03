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

export type FlowStep = { icon: LucideIcon; title: string; note: string; warn?: boolean };

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
          </div>
        );
      })}
    </div>
  );
}
