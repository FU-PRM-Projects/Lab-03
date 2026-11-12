/* Slide helpers from the guideline branch (docs/final-slides-guideline), used by the Demo part. */
import type { ReactNode } from 'react';
import { Slide } from '@revealjs/react';

const base = import.meta.env.BASE_URL;
const img = (name: string) => `${base}final/${name}`;

export function Logo() {
  return <img className="org-logo" src={`${base}assets/fpt-logo.webp`} alt="FPT University" />;
}

/** One content slide: part label, conclusion title, subtitle, body, footnote. */
export function S({
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

export function Shot({ src, alt, h, w, cap }: { src: string; alt: string; h?: number; w?: number; cap?: string }) {
  return (
    <figure className="shot">
      <img src={img(src)} alt={alt} style={w ? { width: w, height: 'auto' } : { height: h }} />
      {cap && <figcaption>{cap}</figcaption>}
    </figure>
  );
}

/** Code captured from GitHub main, red box around the key lines (scripts/capture-where.mjs). */
export function Code({ name, w, h, cap }: { name: string; w?: number; h?: number; cap?: string }) {
  return (
    <figure className="shot">
      <img src={`${base}where/${name}.png`} alt={cap ?? name} style={w ? { width: w, height: 'auto' } : { height: h }} />
      {cap && <figcaption>{cap}</figcaption>}
    </figure>
  );
}

export function Thumb({ src, h = 78 }: { src: string; h?: number }) {
  return <img className="thumb" src={img(src)} alt="" style={{ height: h }} />;
}

export function Card({
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

export function Steps({ items }: { items: [string, string][] }) {
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

