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

Dùng máy Android đăng nhập tài khoản test riêng, đã hoàn thành Làm quen.
Giữ server ARTEMIS chạy và để app ở tab Hôm nay trước ca đầu tiên.

```powershell
cd D:\Lab-03\e2e_test
$env:ARTEMIS_DEVICE_SERIAL = 'emulator-5554'
$env:E2E_FINAL_TEST_ACCOUNT = '1'
$env:E2E_REVIEW_BATCH = 'final-demo-01'
uv run pytest test_final_flows.py -k t17 --runs 3 -v --junitxml=../evidence/artemis/final-t17.xml
```

Chọn mã đợt mới mỗi khi chạy lại T17. Staff duyệt trên Web Admin đúng ba
thẻ `E2E-final-demo-01-1`, `E2E-final-demo-01-2` và `E2E-final-demo-01-3`,
sau đó chạy T18 bằng cùng mã đợt:

```powershell
$env:E2E_REVIEW_OUTCOME = 'approved'
uv run pytest test_final_flows.py -k t18 --runs 3 -v --junitxml=../evidence/artemis/final-t18.xml
```

Để test nhánh từ chối, dùng một đợt T17 mới. Trên web, từ chối cả ba thẻ
với lý do `Trung voi the da co`, rồi chạy T18 với `E2E_REVIEW_OUTCOME=rejected`.
T17/T18 xác minh phía Android. Ba lượt đo thời gian trên bản deploy được
ghi riêng trong [báo cáo luồng liên vai trò](../docs/cross-role-flow.md).

Các ca AI chạy theo từng cấu hình. Mỗi lần chuẩn bị Remote Config trên
môi trường test và tải lại trong app trước khi chạy. T21 cần cấu hình
AI vẫn bật nhưng phát sinh lỗi có kiểm soát (ví dụ model thử không tồn tại).
Khôi phục cấu hình sau khi test. Bộ pytest chỉ đọc biến để chọn ca chạy.

```powershell
$env:E2E_AI_MODE = 'on'
uv run pytest test_final_flows.py -k t19 --runs 3 -v --junitxml=../evidence/artemis/final-t19.xml
# Sau khi tắt ai_enabled và tải lại trên app
$env:E2E_AI_MODE = 'off'
uv run pytest test_final_flows.py -k t20 --runs 3 -v --junitxml=../evidence/artemis/final-t20.xml
# Sau khi chuẩn bị lỗi AI có kiểm soát
$env:E2E_AI_MODE = 'error'
uv run pytest test_final_flows.py -k t21 --runs 3 -v --junitxml=../evidence/artemis/final-t21.xml
```

T22–T24 lần lượt kiểm tra Thống kê/Lịch, viết nhật ký và khảo sát Làm quen.
T25 kiểm tra ghi vận động khi dừng sớm. T26 cần ba nốt test được tạo sẵn
trên cùng tài khoản, có tiêu đề `E2E edit <mã đợt> 1`, `E2E edit <mã đợt> 2`
và `E2E edit <mã đợt> 3`. Đặt `E2E_EDIT_BATCH` bằng mã đợt đó rồi chạy T26.
T27 ghi một lần tự chủ.
T02 dùng gợi ý nhanh “Dọn phòng” để kiểm tra thao tác lưu. T03 chỉ dọn nốt
có dấu hiệu riêng `E2E test note`, nên các nốt thử từ gợi ý cần dọn riêng
trên tài khoản test nếu cần.

### Nguyên tắc viết ca

- Nhận `client`, `app_id` và `attempt` để được chạy lặp và khoá vào app Nốt.
- Khẳng định trên `result.output` (giá trị ARTEMIS báo), không chỉ
  `result.succeeded`.
- Kịch bản ghi vào Firestore thật (tạo thẻ, ghi nốt) nên dùng tài khoản test và
  dọn sau khi chạy.
