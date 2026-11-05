// Chụp từng slide qua Chrome DevTools Protocol rồi ghép thành một PDF 16:9.
// Chạy trong slide/ khi `npx vite preview` đang mở cổng 4173:
//   node scripts/export-pdf.mjs http://localhost:4173/ 15 ../slides/Lab03_<StudentID>_slides.pdf
// Bản React không tự bật chế độ in `?print-pdf` của Reveal, nên chụp từng slide.
// Đổi đường dẫn Chrome bằng biến môi trường CHROME nếu cần.
import { spawn } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { setTimeout as sleep } from 'node:timers/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const [url, count, out] = process.argv.slice(2);
const chrome = process.env.CHROME ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const port = 9333;
const proc = spawn(chrome, [
  '--headless=new', '--disable-gpu', `--remote-debugging-port=${port}`,
  `--user-data-dir=${join(tmpdir(), 'slides-cdp')}`, '--window-size=1280,720', 'about:blank',
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

await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 2, mobile: false });
const shots = [];
for (let i = 0; i < Number(count); i++) {
  await send('Page.navigate', { url: `${url}#/${i}` });
  await sleep(i === 0 ? 3000 : 1500);
  // Hash đổi trong cùng trang thì Reveal không tải lại; ép đúng slide cho chắc.
  await send('Runtime.evaluate', { expression: `location.hash = '#/${i}'` });
  await sleep(800);
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  shots.push(data);
  console.log(`slide ${i + 1}/${count}`);
}

const html = `<!doctype html><html><head><style>
@page { size: 1280px 720px; margin: 0 }
html, body { margin: 0 }
img { display: block; width: 1280px; height: 720px; page-break-after: always }
</style></head><body>${shots.map((s) => `<img src="data:image/png;base64,${s}">`).join('')}</body></html>`;
const page = join(tmpdir(), 'slides-print.html');
writeFileSync(page, html);
await send('Emulation.clearDeviceMetricsOverride');
await send('Page.navigate', { url: 'file:///' + page.replace(/\\/g, '/') });
await sleep(2500);
const { data } = await send('Page.printToPDF', { preferCSSPageSize: true, printBackground: true, marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0 });
writeFileSync(out, Buffer.from(data, 'base64'));
console.log('wrote', out);
ws.close();
proc.kill();
