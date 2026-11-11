// Chụp code thật trên GitHub (nhánh main) cho slide WHERE của từng công nghệ,
// khoanh đỏ các dòng chính. Ảnh lưu vào public/where/. Chạy trong slide/:
//   node scripts/capture-where.mjs              (chụp tất cả)
//   node scripts/capture-where.mjs w-fs-add     (chỉ chụp ảnh có tên đó)
// Đường dẫn tính từ gốc repo; số dòng phải khớp với code trên main.
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';

const repo = 'https://github.com/FU-PRM-Projects/Lab-03/blob';
// [ảnh, file, dòng đầu, dòng cuối được khoanh, nhánh (mặc định main)]
const all = [
  // Riverpod + MVVM
  ['w-rp-screen', 'lib/screens/today/today_screen.dart', 41, 45],
  ['w-rp-vm', 'lib/viewmodels/today_view_model.dart', 55, 62],
  ['w-rp-main', 'lib/main.dart', 100, 107],
  ['h-rp-pubspec', 'pubspec.yaml', 27, 27],
  ['h-rp-test', 'test/viewmodels/today_and_saved_view_model_test.dart', 21, 27],
  // MVVM: one shot per layer of the diagram (1 screens and 4 ViewModel reuse w-rp-screen, w-rp-vm)
  ['mv-widgets', 'lib/widgets/app_button.dart', 11, 15],
  ['mv-theme', 'packages/core/lib/theme/app_tokens.dart', 4, 10],
  ['mv-service', 'lib/services/note_repository.dart', 9, 15],
  ['mv-impl', 'lib/firebase/firestore_note_repository.dart', 19, 23],
  ['mv-main', 'lib/main.dart', 107, 109],
  ['mv-models', 'lib/models/note.dart', 7, 14],
  // Firebase Authentication
  ['w-auth-google', 'lib/firebase/firebase_auth_service.dart', 47, 58],
  ['w-auth-map', 'lib/firebase/firebase_auth_service.dart', 119, 131],
  ['w-auth-redirect', 'lib/router/auth_redirect.dart', 25, 29],
  ['w-auth-signout', 'lib/viewmodels/auth_view_model.dart', 116, 127],
  // Cloud Firestore
  ['w-fs-add', 'lib/firebase/firestore_note_repository.dart', 180, 192],
  ['w-fs-write', 'lib/firebase/firestore_note_repository.dart', 87, 95],
  ['w-fs-watch', 'lib/firebase/firestore_note_repository.dart', 108, 116],
  ['w-fs-rules', 'firebase/firestore.rules', 156, 159],
  // Cloudinary
  ['w-cld-upload', 'lib/firebase/cloudinary_image_service.dart', 72, 82],
  ['w-cld-response', 'lib/firebase/cloudinary_image_service.dart', 89, 101],
  ['w-cld-rules', 'firebase/firestore.rules', 20, 27],
  ['w-cld-main', 'lib/main.dart', 127, 133],
  // Firebase Cloud Messaging
  ['w-fcm-main', 'lib/main.dart', 82, 86],
  ['w-fcm-start', 'lib/firebase/firebase_messaging_service.dart', 77, 87],
  ['w-fcm-fg', 'lib/firebase/firebase_messaging_service.dart', 97, 107],
  ['w-fcm-route', 'lib/router/app_router.dart', 234, 237],
  // Google Analytics
  ['w-an-track', 'lib/viewmodels/note_composer_view_model.dart', 253, 264],
  ['w-an-safe', 'lib/services/analytics_service.dart', 39, 46],
  ['w-an-impl', 'lib/firebase/firebase_analytics_service.dart', 11, 20],
  ['w-an-events', 'lib/services/analytics_events.dart', 5, 13],
  // Crashlytics
  ['w-cr-handlers', 'lib/firebase/crash_handlers.dart', 9, 19],
  ['w-cr-reporter', 'lib/firebase/firebase_crash_reporter.dart', 9, 20],
  ['w-cr-nonfatal', 'lib/viewmodels/note_composer_view_model.dart', 276, 281],
  ['w-cr-main', 'lib/main.dart', 80, 81],
  // Remote Config
  ['w-rc-defaults', 'lib/firebase/firebase_remote_config_service.dart', 53, 58],
  ['w-rc-fetch', 'lib/firebase/firebase_remote_config_service.dart', 75, 87],
  ['w-rc-shelf', 'lib/screens/groups/group_shelf.dart', 33, 36],
  ['w-rc-challenges', 'lib/screens/challenges/challenges_screen.dart', 150, 152],
  // ARTEMIS
  ['w-ar-ask', 'e2e_test/conftest.py', 138, 147],
  ['w-ar-t02', 'e2e_test/test_main_flows.py', 39, 48],
  ['w-ar-t06', 'e2e_test/test_main_flows.py', 76, 86],
  ['w-ar-model', 'tools/artemis/config/artemis.jsonc', 9, 12],
  // CodeRabbit: các chỗ đã sửa hoặc bác bỏ
  ['w-cb-inbox', 'lib/viewmodels/auth_view_model.dart', 123, 127],
  ['w-cb-payload', 'lib/firebase/firebase_messaging_service.dart', 101, 107],
  ['w-cb-rejected', 'lib/screens/challenges/create_challenge_sheet.dart', 97, 98],
];
const only = process.argv.slice(2);
const shots = only.length ? all.filter(([file]) => only.includes(file)) : all;
// Dòng ngữ cảnh chụp thêm phía trên và dưới vùng khoanh.
const pad = 1;

const chrome = process.env.CHROME ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const port = 9337;
const proc = spawn(chrome, [
  '--headless=new', '--disable-gpu', `--remote-debugging-port=${port}`,
  `--user-data-dir=${join(tmpdir(), 'where-cdp')}`, 'about:blank',
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

mkdirSync('public/where', { recursive: true });
await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1500, height: 1100, deviceScaleFactor: 2, mobile: false });
await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'light' }] });
for (const [file, path, from, to, ref = 'main'] of shots) {
  const blob = `${repo}/${ref}`;
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
  writeFileSync(`public/where/${file}.png`, Buffer.from(data, 'base64'));
  console.log(file, Math.round(box.w), 'x', Math.round(box.h));
}
ws.close();
proc.kill();
