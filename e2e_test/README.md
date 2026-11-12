# E2E với Google ARTEMIS

ARTEMIS là agent AI điều khiển điện thoại Android qua ADB. Test ở đây gửi mục
tiêu bằng ngôn ngữ tự nhiên tới server ARTEMIS rồi khẳng định trên giá trị nó
báo về. Mỗi test chạy 3 lần (`--runs`), theo yêu cầu của handout.

- Phiên bản gốc: ARTEMIS commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`
  (đổi cả trong `pyproject.toml` khi nâng cấp).
- Python ≥ 3.12, `uv`, `adb`.

## 1. Server ARTEMIS (một lần)

ARTEMIS nằm sẵn trong repo ở `tools/artemis` (chép từ
`google/artemis@351ca8422f7b5b54e80a9c1ce03a222e02415b6b`, đã bỏ `.git`).
Thay đổi so với bản gốc: `config/artemis.jsonc` trỏ mọi node sang OpenRouter
model `deepseek/deepseek-v4.1-flash-1017`.

```sh
cd tools/artemis
uv sync
cp .env.example .env
```

Điền khoá vào `tools/artemis/.env` (`OPEN_ROUTER_API_KEY=`). File này bị
`.gitignore`, không commit.

Chạy server (chạy riêng thay vì `start.bat`: script đó còn tải Node/scrcpy,
cài ffmpeg và ghi cấu hình MCP vào các IDE AI trên máy):

```sh
uv run python -m artemis ui --port 8000 --no-open
```

Server nghe ở `http://127.0.0.1:8000`. Không mở cổng này ra internet (API quản
trị chưa có xác thực).

## 2. Thiết bị

Bật emulator (hoặc cắm điện thoại bật USB debugging), cài app và đăng nhập sẵn
bằng tài khoản test:

```sh
flutter run -d emulator-5554
adb devices
```

## 3. Chạy test

```sh
cd e2e_test
uv sync
uv run pytest test_smoke.py          # kiểm tra cả chuỗi hoạt động, 3 lần
uv run pytest                        # toàn bộ ca (mỗi ca 3 lần)
uv run pytest --runs 1 -k smoke      # chạy nhanh một lần
uv run pytest -m exploratory         # phiên khám phá 15–30 phút (profile Pro)
```

Biến môi trường: `ARTEMIS_BASE_URL`, `ARTEMIS_DEVICE_SERIAL`,
`ARTEMIS_PROFILE` (`flash` mặc định, `pro` cho kịch bản dài).

Cho các ca T14–T16:

- `E2E_EMAIL`, `E2E_PASSWORD`: tài khoản email **chỉ dùng cho test** (T15, T16 bỏ
  qua nếu thiếu). Mật khẩu được gửi cho model của agent, không dùng tài khoản thật.
- `E2E_STORAGE_READY=1` khi project đã có Storage bucket: T14 khi đó đòi tải lên
  thành công thay vì câu báo lỗi.

## Viết ca mới

### Chạy các ca Android của Final

Bộ flow chuẩn duy nhất là `test_main_flows.py` của Thúy (PR #78):

| Mã | Flow | Kỳ vọng |
|---|---|---|
| T17 | Trả lời 4 câu Làm quen, xem 3 thẻ khởi đầu, không bấm Bắt đầu | `PLAN_SHOWN` |
| T18 | Kể tự do, xem gợi ý Gemini, không lưu nốt | `SUGGESTIONS` |
| T19 | Tắt AI bằng Remote Config, mở Ghi tay, không lưu nốt | `AI_OFF_MANUAL MANUAL_OPENS` |
| T20 | Gửi thẻ thử, kiểm tra chờ, rút/xoá thẻ thử; xem thẻ đã duyệt và tin có sẵn | `PENDING APPROVED INBOX` |

Dùng Android đã đăng nhập tài khoản demo như mô tả trong báo cáo, có thẻ đã duyệt
và tin hộp thư cho T20. Giữ server ARTEMIS chạy, app ở Hôm nay; bật AI trước T18.
T17 tự khởi động lại app để tránh ghi đè khảo sát. T20 dọn thẻ thử do chính ca tạo.
Luồng staff duyệt đúng thẻ mới trên web được đo riêng trong
[báo cáo liên vai trò](../docs/cross-role-flow.md).

```powershell
cd D:\Lab-03\e2e_test
$env:ARTEMIS_DEVICE_SERIAL = 'emulator-5554'
uv run pytest test_main_flows.py -k 't17 or t18 or t20' --runs 3 -v --junitxml=../evidence/artemis/final-rerun-t17-t18-t20.xml
```

T19 chạy riêng: đặt `ai_enabled=false` trên Console, Publish và tải cấu hình mới
trong app trước khi chạy. Sau khi test, bật lại `ai_enabled=true` và tải lại.

```powershell
$env:E2E_AI_DISABLED = '1'
uv run pytest test_main_flows.py -k t19 --runs 3 -v --junitxml=../evidence/artemis/final-rerun-t19.xml
Remove-Item Env:E2E_AI_DISABLED
```

Log gốc của Thúy được giữ ở `evidence/artemis/final-t14-t17-t18-t20.txt` và
`final-t19.txt`; dùng tên `final-rerun-*` cho đợt mới để tránh ghi đè.
Chỉ dùng mã ca trong `test_main_flows.py` để chạy test và tổng hợp slide.

T02 dùng gợi ý nhanh “Dọn phòng” để kiểm tra thao tác lưu. T03 chỉ dọn nốt
có dấu hiệu riêng `E2E test note`, nên các nốt thử từ gợi ý cần dọn riêng
trên tài khoản test nếu cần.

### Nguyên tắc viết ca

- Nhận `client`, `app_id` và `attempt` để được chạy lặp và khoá vào app Nốt.
- Khẳng định trên `result.output` (giá trị ARTEMIS báo), không chỉ
  `result.succeeded`.
- Kịch bản ghi vào Firestore thật (tạo thẻ, ghi nốt) nên dùng tài khoản test và
  dọn sau khi chạy.
