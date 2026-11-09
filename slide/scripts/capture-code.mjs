// Chụp đoạn code thật trên GitHub cho các slide MVVM và Authentication, khoanh
// đỏ các dòng được tô sáng. Ảnh lưu vào public/code/. Chạy trong slide/:
//   node scripts/capture-code.mjs            (chụp tất cả)
//   node scripts/capture-code.mjs signout    (chỉ chụp ảnh có tên đó)
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';

const repo = 'https://github.com/FU-PRM-Projects/Lab-03/blob';
// [ảnh, file trong lib/, dòng đầu, dòng cuối được khoanh, nhánh (mặc định main)]
const all = [
  ['screens', 'screens/today/today_screen.dart', 29, 34],
  ['widgets', 'widgets/app_button.dart', 11, 14],
  ['theme', 'theme/app_tokens.dart', 4, 8],
  ['viewmodel', 'viewmodels/today_view_model.dart', 48, 55],
  ['service', 'services/note_repository.dart', 9, 12],
  ['implementation', 'firebase/firestore_note_repository.dart', 18, 22],
  ['main', 'main.dart', 83, 85],
  ['models', 'models/note.dart', 5, 8],
  ['redirect', 'router/auth_redirect.dart', 25, 29],
  // Cloud Storage: luật bảo mật (ngoài lib/), tải lên kèm tiến độ và URL.
  ['storage-rules', '../firebase/storage.rules', 6, 10],
  ['storage-upload', 'firebase/report_impl.dart', 250, 264],
  ['storage-progress', 'screens/journey/weekly_card_page.dart', 173, 179],
  // Remote Config: giá trị mặc định trong app, chu kỳ tải và cache.
  ['rc-defaults', 'firebase/firebase_remote_config_service.dart', 53, 64],
  ['rc-fetch', 'firebase/firebase_remote_config_service.dart', 65, 77],
  // Semantics: nhãn cho trình đọc màn hình và cho agent ARTEMIS.
  ['sem-mood', 'widgets/mood_option.dart', 28, 34],
  ['sem-shortcut', 'widgets/shortcut_button.dart', 32, 36],
  ['sem-offline', 'widgets/offline_banner.dart', 22, 23],
  // Ảnh trên Cloudinary và chuỗi ngày (PR #43, #46).
  ['cld-upload', 'firebase/cloudinary_image_service.dart', 73, 86],
  ['streak-count', 'utils/journey_stats.dart', 103, 113],
  // Cloud Firestore: ghi nốt, luật cho nốt.
  ['fs-add', 'firebase/firestore_note_repository.dart', 182, 192],
  ['fs-rules-notes', '../firebase/firestore.rules', 79, 82],
  ['fs-validnote', '../firebase/firestore.rules', 25, 33],
  // Bản xoá hộp thư FCM khi đăng xuất (736453a) đang ở nhánh này.
  ['signout', 'viewmodels/auth_view_model.dart', 120, 127, 'chore/submission-files'],
];
const only = process.argv.slice(2);
const shots = only.length ? all.filter(([file]) => only.includes(file)) : all;
// Dòng ngữ cảnh chụp thêm phía trên và dưới vùng khoanh.
const pad = 1;

const chrome = process.env.CHROME ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const port = 9336;
const proc = spawn(chrome, [
  '--headless=new', '--disable-gpu', `--remote-debugging-port=${port}`,
  `--user-data-dir=${join(tmpdir(), 'code-cdp')}`, 'about:blank',
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

// Cuộn để vùng code nằm giữa màn, vẽ khung đỏ quanh các dòng khoanh, trả về
// vùng chụp (kể cả vài dòng ngữ cảnh).
const mark = (from, to) => `(() => {
  const line = (n) => document.querySelector('.react-line-number[data-line-number="' + n + '"]');
  const top = Math.max(1, ${from} - ${pad});
  const first = line(top) ?? line(${from});
  first.scrollIntoView({ block: 'center' });
  const a = line(${from}).getBoundingClientRect();
  const b = line(${to}).getBoundingClientRect();
  const box = document.createElement('div');
  box.style.cssText = 'position:absolute;z-index:99999;pointer-events:none;border:3px solid #e5262b;border-radius:8px;left:' + (a.left - 6 + scrollX) + 'px;top:' + (a.top - 4 + scrollY) + 'px;width:600px;height:' + (b.bottom - a.top + 8) + 'px';
  document.documentElement.appendChild(box);
  const t = (line(top) ?? line(${from})).getBoundingClientRect();
  const lastCtx = line(${to} + ${pad}) ?? line(${to});
  const e = lastCtx.getBoundingClientRect();
  // Vùng chụp của CDP tính theo toạ độ trang, nên cộng thêm phần đã cuộn.
  return JSON.stringify({ x: a.left - 12 + scrollX, y: t.top - 8 + scrollY, w: 620, h: e.bottom - t.top + 16 });
})()`;

mkdirSync('public/code', { recursive: true });
await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1500, height: 1100, deviceScaleFactor: 2, mobile: false });
await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'light' }] });
for (const [file, path, from, to, ref = 'main'] of shots) {
  const blob = `${repo}/${ref}/lib`;
  await send('Page.navigate', { url: 'about:blank' });
  await sleep(300);
  await send('Page.navigate', { url: `${blob}/${path}#L${from}-L${to}` });
  await sleep(5000);
  const res = await send('Runtime.evaluate', { expression: mark(from, to), returnByValue: true });
  if (res.exceptionDetails) throw new Error(`${file}: ${res.exceptionDetails.exception?.description}`);
  const box = JSON.parse(res.result.value);
  await sleep(700);
  const { data } = await send('Page.captureScreenshot', {
    format: 'png',
    clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: 1 },
  });
  writeFileSync(`public/code/${file}.png`, Buffer.from(data, 'base64'));
  console.log(file, Math.round(box.w), 'x', Math.round(box.h));
}
ws.close();
proc.kill();
