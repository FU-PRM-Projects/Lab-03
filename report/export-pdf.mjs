// Xuất report/src/report.html thành report/Lab03_SE190992.pdf bằng Chrome headless.
// Chạy từ thư mục gốc repo:  node report/export-pdf.mjs
// Đổi đường dẫn Chrome bằng biến môi trường CHROME nếu cần.
import { spawnSync } from 'node:child_process';
import { join, resolve } from 'node:path';
import { tmpdir } from 'node:os';
import { pathToFileURL } from 'node:url';

const chrome = process.env.CHROME ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const src = pathToFileURL(resolve('report/src/report.html')).href;
const out = resolve('report/Lab03_SE190992.pdf');
const run = spawnSync(chrome, [
  '--headless=new', '--disable-gpu', `--user-data-dir=${join(tmpdir(), 'report-pdf')}`, '--no-pdf-header-footer', '--allow-file-access-from-files',
  '--virtual-time-budget=8000', `--print-to-pdf=${out}`, src,
], { stdio: 'inherit' });
process.exit(run.status ?? 1);
