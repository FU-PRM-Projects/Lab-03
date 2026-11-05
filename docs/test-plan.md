# Kế hoạch kiểm thử E2E với ARTEMIS

Phạm vi: các luồng chính của Nốt, chạy trên emulator Android 15 bằng agent ARTEMIS.
Mã test: [`e2e_test/`](../e2e_test). Bằng chứng: `evidence/artemis/` (nhánh
`feat/firebase-remote-fcm-analytics`).

## 1. Mục tiêu và phạm vi

Kiểm tra bằng agent AI rằng ba luồng chính của Lab 2 chạy được trên app thật, kể cả
nhánh lỗi và một tương tác Android gốc.

| Trong phạm vi | Ngoài phạm vi (và lý do) |
|---|---|
| F1 ghi nốt: nhánh chính, nội dung trống, thoát giữa chừng, mất mạng | Đăng nhập Google: trình chọn tài khoản hiện tên và email thật, agent không nên thao tác (T15, T16 dùng đăng nhập email thay thế) |
| F2 tự chủ: màn tự chủ, thở 90 giây | Thông báo FCM: cần token thiết bị và gửi từ Console |
| F3 thử thách: mở thẻ, để mai | |
| Tab, Cài đặt (cờ Remote Config), Home rồi mở lại app | |
| Analytics: `note_saved` được ghi (T13), xuất và tải thẻ tuần (T14) | |
| Đăng xuất, đăng nhập email, sai mật khẩu (T15, T16) | |
| Phiên khám phá 15–30 phút, profile Pro (X01) | |

## 2. Môi trường

| Mục | Giá trị |
|---|---|
| Thiết bị | Emulator `sdk_gphone64_x86_64`, Android 15, 1290×2796 |
| App | `com.quanphungg.lab03` bản debug, đăng nhập sẵn bằng tài khoản thử |
| Agent | ARTEMIS `351ca84` (google/artemis), profile Flash |
| Model | `deepseek/deepseek-v4.1-flash-1017` qua OpenRouter (mọi node) |
| Bộ chạy | `pytest` + `artemis-client`; mỗi ca chạy 3 lần (`--runs 3`) |

Thay đổi so với ARTEMIS gốc: `config/artemis.jsonc` trỏ mọi node sang OpenRouter và tắt
`step_summarizer` (chỉ hỗ trợ model Google). Trên emulator tắt `stylus_handwriting_enabled`
để thanh công cụ viết tay của Gboard không chắn ô nhập.

## 3. Cách khẳng định

Mỗi ca giao mục tiêu bằng ngôn ngữ tự nhiên và yêu cầu agent trả lời bằng một từ khoá cố
định. Test khẳng định trên giá trị agent báo về (`report_task_status.explanation`), không chỉ
trên trạng thái "thành công". Server hiện không điền `TaskResult.output`, nên fixture
`reported` đọc giá trị từ `/api/sessions/{id}/steps`.

Ca ghi dữ liệu dùng nốt `E2E test note`; ca T03 xoá mọi nốt đó sau các ca ghi.

## 4. Các ca kiểm thử

| ID | Luồng | Các bước chính | Kỳ vọng (giá trị agent báo) |
|---|---|---|---|
| T01 | Khởi động | Mở app, nhìn màn đầu, không bấm gì | `WELCOME` hoặc `TODAY` |
| T02 | F1 nhánh chính | Ghi nốt → điều làm được → tâm trạng → gõ nội dung → bỏ qua phần kể thêm → lưu | `SAVED` (màn xác nhận) |
| T03 | Hũ: mở và xoá | Tab Hũ → mở nốt `E2E test note` → xoá → kiểm tra danh sách | `DELETED` (hoặc `NOT_FOUND`) |
| T04 | F1 lỗi: trống | Ghi nốt, chọn tâm trạng, để trống nội dung | `DISABLED` (không đi tiếp) |
| T05 | F1 lỗi: thoát giữa chừng | Gõ vài chữ rồi bấm Back | `DIALOG` (hỏi giữ nháp) |
| T06 | F1 lỗi: mất mạng | Bật chế độ máy bay bằng `adb`, ghi nốt | `OFFLINE_BANNER` ("đã lưu trên máy") |
| T07 | F2 | Lối tắt "Dừng lại, ghi 1 lần tự chủ", không ghi gì | `SELF_CONTROL` |
| T08 | F2 khó dừng | Thẻ "Stress?" | `BREATHING` |
| T09 | F3 | Tab Thử thách → mở thẻ đầu → Back / để mai | `DETAIL_THEN_BACK` |
| T10 | Điều hướng | Bấm lần lượt bốn tab | `ALL_TABS` |
| T11 | Cài đặt, Remote Config | Đọc dòng phụ của hàng Remote Config | chứa "Cờ tính năng" |
| T12 | Android gốc | Home → kéo thanh thông báo → mở lại app từ launcher | `LOGGED_IN` (giữ màn đang xem) |
| T13 | Analytics | Bật log `FA` qua `adb`, ghi nốt như T02, test tự đọc `adb logcat` | `SAVED`, và logcat có `note_saved` kèm `mood`, `note_type`, không có nội dung nốt |
| T14 | Xuất và tải lên | Tab Hành trình → Thẻ tuần → 'Lưu thẻ tuần (PDF)' | `UPLOADED` khi có bucket (`E2E_STORAGE_READY=1`), ngược lại `ERROR_MESSAGE` (câu lỗi + 'Thử lại') |
| T15 | Đăng xuất, đăng nhập | Cài đặt → Đăng xuất → 'Đăng nhập bằng email' với tài khoản test | `OUT_WELCOME IN_TODAY` |
| T16 | Đăng nhập lỗi | Đăng xuất → email đúng, mật khẩu sai → rồi mật khẩu đúng | `ERROR_SHOWN IN_TODAY` |
| X01 | Khám phá | Profile Pro, khoảng 20 phút, agent tự đi khắp app | Danh sách `BUG: màn \| bước \| thấy gì` hoặc `NO_BUGS` |

T13 chạy trước T03 vì T03 xoá nốt `E2E test note`. T15 và T16 đổi phiên đăng nhập nên
đặt cuối file và cần `E2E_EMAIL`, `E2E_PASSWORD` (bỏ qua nếu thiếu). Mật khẩu đi qua model
của agent, nên chỉ dùng tài khoản email tạo riêng cho test. X01 chỉ chạy với
`-m exploratory`.

T06 và T12 dùng thao tác ngoài app (chế độ máy bay, nút Home, thanh thông báo); T12 chạy
không khoá vào gói app.

## 5. Kết quả

Lượt chạy đầy đủ (36 lần, 62 phút): 31 đạt, 5 lỗi. Hai nhóm lỗi do khẳng định sai của test
(T05 lần 3, T12) đã sửa rồi chạy lại T05 và T12 đủ 3 lần: 6/6 đạt.

| ID | Lần 1 | Lần 2 | Lần 3 | Đạt | Thời gian mỗi lần |
|---|---|---|---|---|---|
| T01 | đạt | đạt | đạt | 3/3 | 20–52 s |
| T02 | đạt | đạt | đạt | 3/3 | 31–206 s |
| T03 | đạt | đạt | đạt | 3/3 | 256–391 s |
| T04 | đạt | đạt | đạt | 3/3 | 55–56 s |
| T05 | đạt | đạt | đạt (chạy lại) | 3/3 | 108–214 s |
| T06 | đạt | đạt | **lỗi** | 2/3 | 264–421 s |
| T07 | đạt | đạt | đạt | 3/3 | 38–52 s |
| T08 | đạt | đạt | đạt | 3/3 | 20–28 s |
| T09 | đạt | đạt | đạt | 3/3 | 46–82 s |
| T10 | đạt | đạt | đạt | 3/3 | 33–40 s |
| T11 | đạt | đạt | đạt | 3/3 | 13–19 s |
| T12 | đạt (chạy lại) | đạt (chạy lại) | đạt (chạy lại) | 3/3 | 32–39 s |

Tổng: **35/36 lần đạt (97%)**. File kết quả: `evidence/artemis/junit-full-run.xml` và
`junit-rerun-t05-t12.xml`.

### Các ca không đạt hoặc không ổn định

- **T06 lần 3 (lỗi thật, giữ nguyên):** quá 420 giây, agent không báo kết quả. T06 cũng là ca
  chậm nhất sau T03 (264–289 s ở hai lần đạt), nên nhiều khả năng agent bị kẹt khi mất mạng.
  Chưa điều tra nguyên nhân gốc; chưa có bằng chứng đây là lỗi của app.
- **T05 lần 3 (khẳng định sai):** hộp thoại "Giữ nốt đang ghi?" có hiện, nhưng agent trả lời
  một câu dài không bắt đầu bằng `DIALOG`. Đổi khẳng định từ `startswith` sang
  `"DIALOG" in answer and "NO_DIALOG" not in answer`.
- **T12 cả 3 lần (khẳng định sai):** app mở lại ở màn Cài đặt (màn đang xem trước đó) và vẫn
  đăng nhập, đúng hành vi mong muốn. Ca ban đầu đòi phải về màn Hôm nay. Đổi từ khoá thành
  `LOGGED_IN` và chạy lại.

Hai thay đổi khẳng định ở trên được làm sau khi thấy kết quả; chúng làm test đúng với hành vi
mong muốn, không phải để che lỗi của app.

### Quan sát khi chạy

- Trước khi tắt thanh viết tay của Gboard, agent bấm nhầm vào thanh này nên không gõ được chữ
  vào ô nội dung (bộ đếm vẫn `0/120`) và ca T02 quá thời gian.
- Khởi động lại server ARTEMIS khi đang có phiên chạy để lại tiến trình agent mồ côi chiếm
  emulator và làm nghẽn hàng đợi; phải dừng chúng tay.
- Trong lần smoke đầu agent còn bấm một nút dù mục tiêu ghi "không bấm nút nào". Ca T01 hiện
  vẫn đạt vì chỉ khẳng định màn đầu tiên.
- Server không quay được video (thiếu `scrcpy`), nên trace không có video; bằng chứng là ảnh
  chụp emulator định kỳ và trang Workspace của ARTEMIS.
- Chưa tìm thấy lỗi nào của app qua các ca này.

## 6. Hạn chế và việc chưa làm

- **T13–T16 và X01 đã viết nhưng chưa chạy**, nên bảng ở mục 5 chưa có các ca này.
  Chạy: `uv run pytest -k "t13 or t14 or t15 or t16"` và
  `uv run pytest -m exploratory --runs 1 -s` (in danh sách lỗi để chép vào đây).
- T14 chỉ kiểm tra nhánh lỗi cho tới khi có Storage bucket (gói Blaze).
- Agent là mô hình ngôn ngữ nên kết quả có thể thay đổi giữa các lần; 3 lần mỗi ca chỉ cho
  ước lượng thô về độ ổn định.
- Chỉ có một model (DeepSeek) và một thiết bị ảo; chưa thử điện thoại thật.
- Từ khoá trả lời do ta đặt, nên một ca đạt chỉ nói agent *quan sát* thấy điều kiện đó trên màn
  hình, không thay thế kiểm tra trực tiếp trạng thái dữ liệu.

## 7. Cách chạy lại

```sh
cd tools/artemis && uv sync && uv run python -m artemis ui --port 8000 --no-open
cd e2e_test && uv sync && uv run pytest              # toàn bộ, mỗi ca 3 lần
uv run pytest --runs 1 -k t02                        # một ca, một lần
```

Chi tiết cài đặt: [`e2e_test/README.md`](../e2e_test/README.md).
