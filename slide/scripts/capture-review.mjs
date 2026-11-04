// Chụp comment CodeRabbit trên GitHub và khoanh đỏ: (1) file và dòng code,
// (2) loại góp ý, (3) điều AI tìm thấy. Ảnh lưu vào public/review/.
// Chạy trong slide/: node scripts/capture-review.mjs
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';

const repo = 'https://github.com/FU-PRM-Projects/Lab-03';
const shots = [
  { file: 'inbox', pr: 38, id: 'discussion_r4444517565' },
  { file: 'payload', pr: 38, id: 'discussion_r4445377398' },
  { file: 'ios', pr: 38, id: 'discussion_r4444517594' },
  { file: 'saving', pr: 29, id: 'discussion_r4442083170' },
];

const chrome = process.env.CHROME ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const port = 9334;
const proc = spawn(chrome, [
  '--headless=new', '--disable-gpu', `--remote-debugging-port=${port}`,
  `--user-data-dir=${join(tmpdir(), 'review-cdp')}`, 'about:blank',
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

// Khoanh đỏ và đánh số trong chính trang GitHub, rồi trả về khung cần chụp.
const mark = (anchor) => `(() => {
  const el = document.getElementById('${anchor}');
  const thread = el.closest('review-thread-collapsible') ?? el;
  const body = el.querySelector('.comment-body');
  const paras = [...body.children].filter((c) => c.tagName === 'P');
  const marks = [
    thread.querySelector('summary, .file-header, a.Link--primary'),
    paras[0],
    paras[1],
  ];
  marks.forEach((m, i) => {
    if (!m) return;
    m.style.outline = '3px solid #e5262b';
    m.style.outlineOffset = '3px';
    m.style.borderRadius = '6px';
    m.style.position = 'relative';
    const badge = document.createElement('span');
    badge.textContent = String(i + 1);
    badge.style.cssText = 'position:absolute;left:-26px;top:50%;transform:translateY(-50%);width:20px;height:20px;border-radius:50%;background:#e5262b;color:#fff;font:700 12px/20px sans-serif;text-align:center;z-index:9';
    m.appendChild(badge);
  });
  // Ảnh gọn: chỉ giữ tên file, loại góp ý, tiêu đề và đoạn mô tả đầu tiên.
  body.querySelectorAll('details').forEach((d) => (d.style.display = 'none'));
  [...body.children].slice([...body.children].indexOf(paras[2]) + 1).forEach((c) => (c.style.display = 'none'));
  thread.querySelectorAll('table.diff-table, .blob-wrapper, table').forEach((d) => (d.style.display = 'none'));
  thread.querySelectorAll('.review-thread-reply, .js-inline-comment-form-container, .review-comment-contents ~ *, form').forEach((d) => (d.style.display = 'none'));
  // Ghim khung comment lên đầu màn hình, nền trắng, che mọi thứ khác (kể cả
  // thanh tiêu đề dính của GitHub), để vùng chụp không lệch.
  const width = thread.getBoundingClientRect().width;
  window.scrollTo(0, 0);
  thread.style.cssText += ';position:fixed;top:12px;left:44px;width:' + width + 'px;z-index:99999;background:#fff;box-shadow:0 0 0 40px #fff';
  thread.dataset.capture = '1';
  return 'ok';
})()`;

// Đo sau khi trang đã ổn định (badge, outline, details vừa đóng làm layout đổi).
const measure = `(() => {
  const r = document.querySelector('[data-capture]').getBoundingClientRect();
  return JSON.stringify({ x: r.left - 34, y: r.top - 8, w: r.width + 42, h: r.height + 16 });
})()`;

mkdirSync('public/review', { recursive: true });
await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1100, height: 1400, deviceScaleFactor: 2, mobile: false });
// Giao diện sáng của GitHub cho hợp nền trắng của slide.
await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'light' }] });
for (const s of shots) {
  // Cùng PR chỉ khác #anchor thì trình duyệt không tải lại: qua trang trắng trước.
  await send('Page.navigate', { url: 'about:blank' });
  await sleep(300);
  await send('Page.navigate', { url: `${repo}/pull/${s.pr}#${s.id}` });
  await sleep(6000);
  const res = await send('Runtime.evaluate', { expression: mark(s.id), returnByValue: true });
  if (res.exceptionDetails) {
    const title = await send('Runtime.evaluate', { expression: 'document.title', returnByValue: true });
    throw new Error(`${s.file}: ${res.exceptionDetails.exception?.description} · page: ${title.result.value}`);
  }
  await sleep(1500);
  const m = await send('Runtime.evaluate', { expression: measure, returnByValue: true });
  const box = JSON.parse(m.result.value);
  const { data } = await send('Page.captureScreenshot', {
    format: 'png',
    clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: 1 },
  });
  writeFileSync(`public/review/${s.file}.png`, Buffer.from(data, 'base64'));
  console.log(s.file, Math.round(box.w), 'x', Math.round(box.h));
}
ws.close();
proc.kill();
