// Chụp 3 bằng chứng cho slide "AI code review": CodeRabbit review trên PR,
// bảng kết luận trong docs/code-review.md, và commit sửa lỗi. Khoanh đỏ chỗ
// cần nhìn. Ảnh lưu vào public/review/. Chạy trong slide/:
//   node scripts/capture-proof.mjs
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';

const repo = 'https://github.com/FU-PRM-Projects/Lab-03';
const red = "'3px solid #e5262b'";

// Commit sửa lỗi: khoanh phần thân message có dòng "Addresses CodeRabbit finding".
const commitPick = `(() => {
  const msg = [...document.querySelectorAll('div, pre')].filter((e) => /Addresses CodeRabbit\\s+finding/.test(e.textContent) && e.children.length < 6).pop();
  const line = [...msg.querySelectorAll('*'), msg].find((e) => e.childElementCount === 0 && /Addresses CodeRabbit/.test(e.textContent)) ?? msg;
  line.style.outline = ${red};
  line.style.outlineOffset = '3px';
  line.style.borderRadius = '4px';
  return msg.parentElement?.parentElement ?? msg;
})()`;

// Mỗi mục: trang, rồi đoạn JS trả về phần tử cần chụp (đã khoanh đỏ).
const shots = [
  {
    file: 'proof-review',
    url: `${repo}/pull/38`,
    pick: `(() => {
      const box = document.getElementById('pullrequestreview-5739302136');
      const item = box.closest('.js-timeline-item') ?? box;
      item.querySelectorAll('.comment-body details').forEach((d) => (d.open = false));
      const head = item.querySelector('.comment-body h2, .comment-body h3');
      if (head) { head.style.outline = ${red}; head.style.outlineOffset = '4px'; head.style.borderRadius = '6px'; }
      return item;
    })()`,
  },
  {
    file: 'proof-verdicts',
    url: `${repo}/blob/chore/submission-files/docs/code-review.md`,
    pick: `(() => {
      const table = [...document.querySelectorAll('.markdown-body table')].find((t) => t.rows[0].cells.length > 5);
      [...table.rows].slice(8).forEach((r) => (r.style.display = 'none'));
      const col = [...table.rows[0].cells].findIndex((c) => c.textContent.trim() === 'Kết luận');
      [...table.rows].slice(0, 8).forEach((r) => {
        const c = r.cells[col];
        c.style.outline = ${red};
        c.style.outlineOffset = '-3px';
      });
      table.style.display = 'table';
      return table;
    })()`,
  },
  ...['736453a', '5e13651'].map((sha) => ({
    file: `proof-commit-${sha}`,
    url: `${repo}/commit/${sha}`,
    pick: commitPick,
  })),
];

const chrome = process.env.CHROME ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const port = 9335;
const proc = spawn(chrome, [
  '--headless=new', '--disable-gpu', `--remote-debugging-port=${port}`,
  `--user-data-dir=${join(tmpdir(), 'proof-cdp')}`, 'about:blank',
], { stdio: 'ignore' });

let target;
for (let i = 0; i < 40 && !target; i++) {
  await sleep(250);
  try {
    target = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find((t) => t.type === 'page');
  } catch {}
}
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener('open', r));
let id = 0;
const pending = new Map();
ws.addEventListener('message', (e) => {
  const msg = JSON.parse(e.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
});
const send = (method, params = {}) => new Promise((resolve, reject) => {
  const n = ++id;
  pending.set(n, (m) => (m.error ? reject(new Error(JSON.stringify(m.error))) : resolve(m.result)));
  ws.send(JSON.stringify({ id: n, method, params }));
});

// Ghim phần tử lên đầu màn hình, nền trắng, để vùng chụp không lệch và không
// bị thanh tiêu đề dính của GitHub che.
const pin = (pick) => `(() => {
  const el = ${pick};
  const width = Math.min(el.getBoundingClientRect().width, 1500);
  window.scrollTo(0, 0);
  el.style.cssText += ';position:fixed;top:16px;left:24px;width:' + width + 'px;z-index:99999;background:#fff;box-shadow:0 0 0 30px #fff;margin:0';
  el.dataset.capture = '1';
  return 'ok';
})()`;
const measure = `JSON.stringify((() => {
  const r = document.querySelector('[data-capture]').getBoundingClientRect();
  return { x: r.left - 12, y: r.top - 12, w: r.width + 24, h: Math.min(r.height + 24, 1180) };
})())`;

mkdirSync('public/review', { recursive: true });
await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1200, deviceScaleFactor: 2, mobile: false });
await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'light' }] });
for (const s of shots) {
  await send('Page.navigate', { url: 'about:blank' });
  await sleep(300);
  await send('Page.navigate', { url: s.url });
  await sleep(6000);
  const res = await send('Runtime.evaluate', { expression: pin(s.pick), returnByValue: true });
  if (res.exceptionDetails) throw new Error(`${s.file}: ${res.exceptionDetails.exception?.description}`);
  await sleep(1500);
  const box = JSON.parse((await send('Runtime.evaluate', { expression: measure, returnByValue: true })).result.value);
  const { data } = await send('Page.captureScreenshot', {
    format: 'png',
    clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: 1 },
  });
  writeFileSync(`public/review/${s.file}.png`, Buffer.from(data, 'base64'));
  console.log(s.file, Math.round(box.w), 'x', Math.round(box.h));
}
ws.close();
proc.kill();
