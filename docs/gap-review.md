# Gap review: Lab 2 và Lab 3 trước Final

Final Assignment, Stage 1. Đối chiếu thiết kế Lab 2 (Figma `03 Final UI`,
`DESIGN.md`, `flutter-handoff.md`, ánh xạ ở [`design-traceability.md`](design-traceability.md))
và yêu cầu Lab 3 với code trên `main` (cập nhật 11/11/2026, sau PR #75). Đề Final: luồng Lab 2 / Lab 3
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
| P4 Viết nhật ký dài | Xong: viết, câu hỏi gợi ý, chọn tiêu đề; trang đang viết lưu trên máy (`JournalDraftStore`, lưu sau 0,8 s ngừng gõ và khi app xuống nền), mở lại thì hỏi "Tiếp tục bản nháp?" (Viết tiếp / Bắt đầu trang mới); lưu thành nốt, bấm Bỏ hoặc đăng xuất thì xoá nháp | — | Đã đóng |
| P5 Xem, sửa, xoá nốt | Xong | — | Đã đóng |
| P6 Ngày tệ: nhìn lại hành trình | Xong | — | Đã đóng |
| P7 Thông báo mở đúng màn | Xong: FCM 3 trạng thái app, lời nhắc trên máy, `?next=` qua đăng nhập | — | Đã đóng |
| P8 Hồ sơ và cài đặt | Xong: giờ nhắc, Giờ tỉnh, khoá, ẩn nội dung, Nốt AI (công tắc), đăng xuất; "Làm lại khảo sát" ở mục Tài khoản (PR #67) | — | Đã đóng |
| T1–T3 Hũ rỗng, mất mạng, đang tải | Xong | — | Đã đóng |
| T4 Bố cục 360 / 412 dp | Kiểm tra bằng widget test ở 360 và 412 dp (`settings_flow_test`, `today_flow_test`, …) | Golden test ảnh | Bỏ golden test: widget test đã kiểm tra tràn bố cục ở cả hai kích thước |
| G1 Nhóm lần đầu | Xong: kệ nhóm, tạo nhóm (tên trùng xếp vào nhóm có sẵn), "Lần đầu tiên!", chi tiết nhóm, xoá có Hoàn tác; người dùng chọn nhóm khi ghi nốt (S03) | Gợi ý nhóm bằng AI cho các nốt tách từ Kể tự do | **Bỏ phần gợi ý AI (có lý do)**: Kể tự do tạo nhiều nốt cùng lúc, gợi ý nhóm phải ghép với `GroupRepository.recordNote` cho từng nốt; người dùng vẫn xếp nốt vào nhóm ở S03, và yêu cầu AI của đề đã đạt bằng A1 (deviation D-36) |
| D1 Phòng Discord | Xong | — | Đã đóng |
| D2 Thử thách cấp 3 #chao-hoi | Xong: S07 → S08 (cấp 3) → S08d (Tụi Nốt AI viết 3 câu chào; AI nghỉ thì câu có sẵn) → Discord → S08 "Bạn vừa ghé phòng chung" → S04 | Bước S08b (tập nói với AI) trước S08d | **Bỏ S08b (có lý do)**, xem dòng A3; phần còn lại đã đóng |
| **A1 Nốt AI · Kể tự do** (S03b) | Xong (PR #68): tab "Kể tự do", sheet quyền riêng tư lần đầu, đang đọc, gợi ý để xác nhận (sửa được, gắn nhãn AI), AI nghỉ, thẻ hỗ trợ khi `needs_support`; Remote Config `ai_*` (cả 3 prompt, Console Version 19), App Check, log `ai_request` / `ai_result_accepted` / `ai_error`. Chạy với Gemini thật trên máy thật, 3 ví dụ + 1 lỗi ở [`ai-feature.md`](ai-feature.md) | — | Đã đóng |
| **A2 Làm quen và thẻ khởi đầu** (S13a–g) | Xong (PR #67, #68): 4 câu khảo sát, hồ sơ khởi đầu + 3 thẻ do Gemini chọn (bảng luật `StarterPlanRules` là bản dự phòng khi AI nghỉ), ghi `users/{uid}/private/onboarding`, làm lại từ S12 | — | Đã đóng |
| **A3 Tập nói và lời nhắn** (S08b, S08c) | Không làm | Chat đóng vai trước thử thách (S08b), lời nhắn AI sau thử thách (S08c) | **Bỏ (có lý do)**, xem [mục 1.1](#11-vì-sao-bỏ-a3-s08b-s08c) |
| S11 Hỏi Nốt (bonus, AI mức 3) | Chưa có | Function calling đếm nốt | Làm nếu còn thời gian |

### 1.1 Vì sao bỏ A3 (S08b, S08c)

A3 gồm hai màn AI quanh thử thách "Dũng cảm": **S08b** cho người dùng nhắn
qua lại với Tụi Nốt đóng vai một người trong #chao-hoi (tối đa 6 lượt) trước khi
làm thử thách thật; **S08c** cho Gemini viết lời nhắn sau khi chọn kết quả, kèm
thẻ hỗ trợ khi `needs_support`. Nhóm quyết định không làm cả hai màn vì:

1. **Trùng mục đích với phần đã có.** Mục tiêu của S08b là bớt run trước khi mở
   lời; S08d đã làm việc đó (Tụi Nốt AI viết sẵn 3 câu chào để chọn, sao chép rồi
   mở Discord). Thử thách thật là chào **người thật** trong #chao-hoi; tập với AI
   chỉ là bước đệm, không đổi kết quả của luồng D2. Phần ghi cảm xúc sau thử
   thách của S08c cũng đã có ở S08 khi quay lại từ Discord (ô "Kể một câu", mức
   "Sau đó bạn thấy sao?" lưu `anxietyAfter`, deviation D-30).
2. **Rủi ro dữ liệu cá nhân.** S08b là chat nhiều lượt, gõ tự do: người dùng dễ
   kể tên bạn bè, lớp, chuyện riêng, và mọi lượt đều gửi tới Gemini. Đề Final
   mục 8 yêu cầu không gửi dữ liệu cá nhân; `scrubForAi` chỉ che được email và
   số điện thoại, không che được tên (xem `test-report.md` CR-F2). Một ô kể ngắn
   có sheet đồng ý (A1) còn kiểm soát được; một cuộc chat 6 lượt thì không.
3. **Yêu cầu AI của đề đã đạt.** Đề cần một tính năng Gemini giúp một bước của
   luồng Lab 2; Nốt AI · Kể tự do (A1, mức 2: JSON → Dart, người dùng xác nhận)
   cùng Làm quen (A2) và câu chào S08d đã đáp ứng. Thêm S08b / S08c không thêm
   điểm (đề: "New features earn no points") mà tốn quota Gemini nhiều nhất
   (mỗi lượt chat một lần gọi) và khó kiểm thử E2E vì câu trả lời mỗi lần một
   khác.
4. **Thẻ hỗ trợ vẫn có.** Lối tới thẻ "Nói với người bạn tin" khi Gemini thấy
   dấu hiệu cần hỗ trợ đã có ở Kể tự do (S03b, dialog P6), nên bỏ S08c không làm
   mất phần chăm sóc người dùng.

Thay đổi so với thiết kế ghi ở `design-traceability.md` (S08b, S08c, A3, D2 và
deviation D-37). Key Remote Config `ai_prompt_roleplay`, `ai_roleplay_max_turns`
trong Spec không dùng tới.

## 2. Yêu cầu Lab 3

| Yêu cầu | Trạng thái | Quyết định |
|---|---|---|
| Firebase Auth, Firestore, FCM, Analytics, Crashlytics, Remote Config | Xong | Đã đóng |
| Tạo file PDF (Thẻ tuần) | Gỡ nhầm ở PR #57 rồi làm lại ở PR #65: tạo PDF trên máy (font đóng gói, chạy offline), lưu vào thư mục của app, mở hộp chia sẻ, metadata `users/{uid}/reports/{isoWeek}` (rules R-28); chạy trên máy thật ([`evidence/mobile-final/`](../evidence/mobile-final/README.md) 07–10) | Đã đóng. Đề Final mục 4: *"The Lab 3 PDF report is saved and shared on the device, with its metadata in Firestore"*; Cloud Storage ngoài phạm vi |
| ARTEMIS E2E ≥ 10 ca, 3 lần chạy | Xong ở Lab 3 (`docs/test-plan.md`); T14 đổi sang lưu và chia sẻ PDF trên máy (PR #65). Final 12/11 trên máy thật: T14, T17, T18, T20 đạt 11/12 lần; T19, T15, T16 chưa chạy | Chạy lại cho Final kèm các luồng mới; tổng hợp kiểm thử và AI code review cho Final ở [`test-report.md`](test-report.md) |
| AI code review ≥ 5 góp ý, sửa ≥ 3 | Xong ([`code-review.md`](code-review.md)) | Đã đóng; Final làm thêm review cho code mới |
| Không dữ liệu mock | Xong (kho thẻ trên Firestore, seed script) | Đã đóng |
| Mỗi client từ chối tài khoản sai vai trò (đề Final mục 6) | Web admin từ chối `user`; app mobile từ chối `staff` / `admin` bằng màn "Tài khoản này dành cho web admin" (`WrongRoleScreen`), có test | Đã đóng: xem [`data-model.md`](data-model.md) mục "Mỗi client từ chối tài khoản sai vai trò" |

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
| Gap review (tài liệu này) | #66 |
| Làm quen và thẻ khởi đầu (A2), "Làm lại khảo sát" (P8) | #67 |
| Nốt AI với Gemini (A1), câu chào AI (S08d), App Check cho mobile và AI Logic | #68 |
| Minh chứng chạy trên máy thật (`evidence/mobile-final/`) | #69 |
| Sửa lỗi duyệt thẻ khi staff chưa mở Kho thẻ (tìm ra khi chạy luồng liên vai trò D-1) | #70 |
| Checklist web admin và minh chứng (`evidence/web-admin/`) | #71 |
| Slide Final | #72 |
| App từ chối tài khoản staff / admin, nháp nhật ký (P4), vai trò web admin theo thời gian thực, prompt AI trong Remote Config, `docs/test-report.md`, bỏ A3 (có lý do) | #75 |
| Test rules R-29 (staff / admin không đọc dữ liệu riêng), R-30 (`sharedStreaks`); data model đủ collection Lab 3; README (admin đầu tiên, tài khoản demo, phiên bản, công cụ AI) | PR này |

## 5. Còn lại theo thứ tự

Mọi luồng Lab 2 và yêu cầu Lab 3 ở mục 1–3 đã có quyết định: **Đã đóng** hoặc
**Bỏ (có lý do)** (A3; phần gợi ý AI của G1; golden test của T4). Việc còn lại
là kiểm thử và sản phẩm nộp:

1. ARTEMIS T19 (cần tắt `ai_enabled` trên Remote Config) và T15, T16 (cần tài khoản test); T14, T17, T18, T20 đã chạy 12/11 (11/12)
   ([`test-report.md`](test-report.md) mục 2.2).
2. Bật Enforce App Check cho Cloud Firestore (đang Monitoring) và chụp minh chứng.
3. Ảnh trạng thái lỗi của web admin; chụp lại ảnh `mobile-final/08` và
   `web-admin/11` đủ màn hình.
4. Slide, report Final (`report/Final_SE190992.pdf`), video.
5. S11 Hỏi Nốt (bonus, AI mức 3): chỉ làm nếu còn thời gian.
