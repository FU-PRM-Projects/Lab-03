# Gap review: Lab 2 và Lab 3 trước Final

Final Assignment, Stage 1. Đối chiếu thiết kế Lab 2 (Figma `03 Final UI`,
`DESIGN.md`, `flutter-handoff.md`, ánh xạ ở [`design-traceability.md`](design-traceability.md))
và yêu cầu Lab 3 với code trên `main` (cập nhật 10/11/2026; nhánh chưa merge ghi rõ ở từng dòng). Đề Final: luồng Lab 2 / Lab 3
làm dở bị trừ điểm, tính năng mới không được điểm; nên mỗi dòng dưới đây có
quyết định **Làm**, **Đã đóng** hoặc **Bỏ (có lý do)**.

## 1. Luồng Lab 2

| Luồng | Trạng thái trên `main` | Thiếu | Quyết định |
|---|---|---|---|
| F1 Ghi nốt buổi tối | Xong | — | Đã đóng |
| F2 Tự chủ (S09, S10) | Xong | — | Đã đóng |
| F3 Thử thách (S07, S08) | Xong | — | Đã đóng |
| P1 Làm quen lần đầu (đăng nhập, xin quyền thông báo) | Xong: đăng nhập Google / email, huỷ, mất mạng; xin quyền khi bật lời nhắc và khi mở hộp thư | — | Đã đóng |
| P2 Đăng ký email, quên mật khẩu | Xong | — | Đã đóng |
| P3 Ghi một lần vận động | Xong | — | Đã đóng |
| P4 Viết nhật ký dài | Một phần: viết, câu hỏi gợi ý, chọn tiêu đề | "Tiếp tục bản nháp?" khi app bị tắt giữa chừng | Làm (nhỏ) |
| P5 Xem, sửa, xoá nốt | Xong | — | Đã đóng |
| P6 Ngày tệ: nhìn lại hành trình | Xong | — | Đã đóng |
| P7 Thông báo mở đúng màn | Xong: FCM 3 trạng thái app, lời nhắc trên máy, `?next=` qua đăng nhập | — | Đã đóng |
| P8 Hồ sơ và cài đặt | Xong: giờ nhắc, Giờ tỉnh, khoá, ẩn nội dung, Nốt AI (công tắc), đăng xuất; "Làm lại khảo sát" ở mục Tài khoản (nhánh `feat/onboarding`) | — | Đóng khi merge `feat/onboarding` |
| T1–T3 Hũ rỗng, mất mạng, đang tải | Xong | — | Đã đóng |
| T4 Bố cục 360 / 412 dp | Kiểm tra bằng widget test ở 360 và 412 dp (`settings_flow_test`, `today_flow_test`, …) | Golden test ảnh | Bỏ golden test: widget test đã kiểm tra tràn bố cục ở cả hai kích thước |
| G1 Nhóm lần đầu | Xong: kệ nhóm, tạo nhóm (tên trùng xếp vào nhóm có sẵn), "Lần đầu tiên!", chi tiết nhóm, xoá có Hoàn tác | Gợi ý nhóm bằng AI (thuộc A1) | Làm cùng A1 |
| D1 Phòng Discord | Xong | — | Đã đóng |
| D2 Thử thách cấp 3 #chao-hoi | Một phần: S07 → S08 → S08d (câu chào có sẵn) → Discord → S08 | S08b tập nói với AI, S08d câu chào do AI viết | Làm (A3) |
| **A1 Nốt AI · Kể tự do** (S03b) | Code xong ở nhánh `feat/ai`: tab "Kể tự do", sheet quyền riêng tư lần đầu, đang đọc, gợi ý để xác nhận (sửa được, gắn nhãn AI), AI nghỉ, thẻ hỗ trợ khi `needs_support`; Remote Config `ai_*`, App Check, log `ai_request` / `ai_result_accepted` / `ai_error` | Chạy với Gemini thật: API Firebase AI Logic của project còn tắt (HTTP 403 `SERVICE_DISABLED`), nên `docs/ai-feature.md` chưa có 3 ví dụ thật | **Làm**: bật API, merge `feat/ai`, ghi 3 ví dụ + 1 lỗi |
| **A2 Làm quen và thẻ khởi đầu** (S13a–g) | Code xong ở nhánh `feat/onboarding`: 4 câu khảo sát, hồ sơ khởi đầu + 3 thẻ theo bảng luật, ghi `users/{uid}/private/onboarding`, làm lại từ S12 | Thẻ khởi đầu do AI viết (bảng luật là bản dự phòng, đang dùng) | Đóng khi merge `feat/onboarding` |
| **A3 Tập nói và lời nhắn** (S08b, S08c) | Chưa có | Chat đóng vai, lời nhắn sau thử thách | **Làm** |
| S11 Hỏi Nốt (bonus, AI mức 3) | Chưa có | Function calling đếm nốt | Làm nếu còn thời gian |

## 2. Yêu cầu Lab 3

| Yêu cầu | Trạng thái | Quyết định |
|---|---|---|
| Firebase Auth, Firestore, FCM, Analytics, Crashlytics, Remote Config | Xong | Đã đóng |
| Tạo file PDF (Thẻ tuần) | Gỡ nhầm ở PR #57 rồi làm lại ở PR #65: tạo PDF trên máy (font đóng gói, chạy offline), lưu vào thư mục của app, mở hộp chia sẻ, metadata `users/{uid}/reports/{isoWeek}` (rules R-28) | Đóng khi merge PR #65. Đề Final mục 4: *"The Lab 3 PDF report is saved and shared on the device, with its metadata in Firestore"*; Cloud Storage ngoài phạm vi |
| ARTEMIS E2E ≥ 10 ca, 3 lần chạy | Xong ở Lab 3 (`docs/test-plan.md`); T14 đổi sang lưu và chia sẻ PDF trên máy (PR #65), chưa chạy lại | Chạy lại cho Final kèm các luồng mới (`docs/test-report.md`) |
| AI code review ≥ 5 góp ý, sửa ≥ 3 | Xong ([`code-review.md`](code-review.md)) | Đã đóng; Final làm thêm review cho code mới |
| Không dữ liệu mock | Xong (kho thẻ trên Firestore, seed script) | Đã đóng |

## 3. Góp ý code review Lab 3

Các góp ý đã sửa và các góp ý chọn không sửa (kèm lý do) nằm ở
[`code-review.md`](code-review.md) mục "Từng góp ý". Không còn góp ý nào để ngỏ.

## 4. Thay đổi đã làm từ khi bắt đầu Final

| Việc | PR |
|---|---|
| Vai trò `staff` / `admin`, kho thẻ do staff quản lý, thẻ người dùng gửi duyệt, hộp thư, thông báo, rules + test R-19…R-26 | #54 |
| Web admin (`web_admin/`), package dùng chung `packages/core` | #54 |
| Gỡ xuất PDF và Cloud Storage | #57 |
| Hướng dẫn chạy web admin trong README | #58 |
| CI: Gradle bản `-bin`, cache, thử lại khi lỗi tải, bản sao Maven Central của Google | #59 |
| Dashboard web admin: KPI, biểu đồ hoạt động 14 ngày, trạng thái duyệt, kho thẻ theo chủ đề | #60 |
| App Check cho web admin (reCAPTCHA Enterprise / Fraud Defense) | #61 |
| Màn đăng nhập web admin: hoạ tiết nền, nút Google chuẩn | #62, #64 |
| Minh chứng App Check (`evidence/app-check/`) | #63 |
| Thẻ tuần PDF lưu và chia sẻ trên máy, metadata Firestore, rules R-28 | #65 |

## 5. Còn lại theo thứ tự

1. Merge `feat/onboarding` (A2, P8) rồi `feat/ai` (A1, App Check cho mobile và AI Logic). `feat/ai` xây trên `feat/onboarding`.
2. Bật API Firebase AI Logic cho project, chạy Kể tự do với Gemini thật, ghi 3 ví dụ + 1 lỗi vào `docs/ai-feature.md`.
3. A3 (S08b tập nói, S08c lời nhắn) và câu chào AI ở S08d.
4. P4 "Tiếp tục bản nháp?".
5. Chạy luồng liên vai trò 3 lần trên bản deploy (`docs/cross-role-flow.md`, bảng D-1…D-3).
6. S11 Hỏi Nốt (bonus).
