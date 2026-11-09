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
| T14 | Thẻ tuần PDF | Tab Hành trình → Thống kê → Mục tiêu tuần → 'Lưu thẻ tuần (PDF)' → đóng hộp chia sẻ | `SAVED_SHARED` ('Đã lưu thẻ tuần vào máy.' + tên `weekly-….pdf`, hộp chia sẻ đã mở). Final: lưu trên máy, không dùng Cloud Storage |
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
| T13 | đạt (chạy lại) | đạt (chạy lại) | đạt (chạy lại) | 3/3 | 66–119 s |
| T14 | đạt | đạt | đạt | 3/3 | 41–71 s |

Tổng: **41/42 lần đạt (98%)**. T13 và T14 chạy ngày 06/11 (máy, model và profile như mục 2). File kết quả: `evidence/artemis/junit-full-run.xml`, `junit-t13-t14.xml`, `junit-rerun-t13.xml` và
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

- **T13 lần 1 (lỗi của fixture):** agent đã báo `SAVED` (bước cuối của phiên `05807d72`), nhưng
  fixture `reported` đọc danh sách bước ngay khi phiên vừa xong, lúc bước cuối chưa được lưu, nên
  nhận chuỗi rỗng. Thêm vòng thử lại (5 lần, cách 2 giây) rồi chạy lại T13 đủ 3 lần: 3/3. Lần
  chạy đầu (2/3 cho T13) vẫn giữ trong `junit-t13-t14.xml`.
- **T14 (Lab 3):** chưa có Storage bucket nên kết quả đúng là câu báo lỗi kèm "Thử lại" (3/3).
  Ở Final, PDF lưu trên máy nên T14 đòi lưu và mở hộp chia sẻ thành công; cần chạy lại 3 lần.

### Phiên khám phá X01

Chạy một lần ngày 06/11, profile Pro, 25 phút 38 giây, 112 bước (63 chạm, 12 vuốt, 10 phím,
5 lần nhập chữ). Phiên `44655b9a`. Agent kết thúc ở màn Hôm nay, vẫn đăng nhập.

Profile Pro không gọi `report_task_status`; câu trả lời nằm sau "Final answer:" trong phần suy
nghĩ của bước cuối. Fixture chưa xử lý trường hợp này nên `junit-x01.xml` ghi lỗi
`AttributeError`, dù phiên đã hoàn thành. Danh sách lỗi dưới đây chép nguyên văn từ server
(`evidence/artemis/x01-bugs.txt`); fixture đã được sửa để đọc được câu trả lời này.

| # | Màn | Agent báo | Nhóm đã kiểm tra chưa |
|---|---|---|---|
| X-01 | Mở lại app | Back ở Hôm nay để thoát rồi mở lại: hộp "Lab 03 isn't responding", phải bấm Wait | Chưa. Có thể do bản debug chạy JIT trên emulator |
| X-02 | Hũ, xoay ngang | Nút "+" che chữ "Xem tất cả" | Chưa |
| X-03 | Hôm nay, xoay ngang | Thẻ chuỗi ngày bị thanh tab che, hũ chiếm gần hết màn | Chưa |
| X-04 | Hũ và Hôm nay | Số nốt tháng không khớp (22 và 21) cùng lúc | Chưa. Có thể do hai màn đếm khác thời điểm |
| X-05 | Danh sách nhóm | Hai tên thẻ bị cắt "…" | Chưa. Thẻ nhóm hiện tên 1 dòng theo D-23 |
| X-06 | Viết nhật ký | Ô trống hay chỉ khoảng trắng: nút "Xong" mờ, không giải thích; bộ đếm tính cả khoảng trắng | Chưa |
| X-07 | Hũ | Chạm hình hũ không có phản hồi | Chưa |
| X-08 | Sau khi lưu (thử thách, nhật ký, thở, nhóm) | Màn trắng chỉ có chữ "Đang tải" vài giây | Chưa |
| X-09 | Hành trình, Lịch | Chú giải màu tâm trạng không ghi mức nào ứng với màu nào | Chưa |
| X-10 | Hành trình, Năm | Lưới 12 tháng không có tên tháng, ô rất nhỏ | Chưa |

Đây là những gì agent báo; nhóm chưa kiểm tra lại từng lỗi, nên chưa sửa lỗi nào. Trong phiên,
agent đã tạo thêm vài nốt trên tài khoản test (số nốt tháng 11 tăng lên 21–22), dù mục tiêu chỉ
cấm đăng xuất, xoá tài khoản và gửi ra ngoài app. Sau khi chạy, T03 xoá các nốt `E2E test note`; 7 nốt test còn lại (5 của X01, 2 của T13 mà agent đặt tên bằng chip gợi ý) được xoá tay, nên hũ tháng 11 về lại 9 nốt như trước khi test. Thẻ nhóm "Bắt chuyện" vẫn ghi 1 nốt vì số đếm của nhóm không giảm khi xoá nốt.

### Quan sát khi chạy

- Trước khi tắt thanh viết tay của Gboard, agent bấm nhầm vào thanh này nên không gõ được chữ
  vào ô nội dung (bộ đếm vẫn `0/120`) và ca T02 quá thời gian.
- Khởi động lại server ARTEMIS khi đang có phiên chạy để lại tiến trình agent mồ côi chiếm
  emulator và làm nghẽn hàng đợi; phải dừng chúng tay.
- Trong lần smoke đầu agent còn bấm một nút dù mục tiêu ghi "không bấm nút nào". Ca T01 hiện
  vẫn đạt vì chỉ khẳng định màn đầu tiên.
- Server không quay được video (thiếu `scrcpy`), nên trace không có video; bằng chứng là ảnh
  chụp emulator định kỳ và trang Workspace của ARTEMIS.
- T01–T14 không tìm thấy lỗi nào của app; X01 báo 10 lỗi (ở trên), chưa kiểm tra lại.

## 6. Hạn chế và việc chưa làm

- **T15 và T16 chưa chạy**: cần một tài khoản email chỉ dùng cho test.
  Đặt `E2E_EMAIL`, `E2E_PASSWORD` rồi chạy `uv run pytest -k "t15 or t16"`.
- T14 (bản Final: lưu PDF trên máy) chưa chạy lại trên ARTEMIS.
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
