# Báo cáo kiểm thử (Final Assignment)

Đề Final mục 9: ARTEMIS cho mọi luồng Lab 2, phần mobile của luồng liên vai trò
và tính năng AI; Security Rules trên Emulator; checklist web admin; luồng liên
vai trò chạy 3 lần trên hệ thống đã deploy; AI code review cho code mới (≥ 3
góp ý kèm quyết định). File này gom kết quả và trỏ tới minh chứng trong
`evidence/`.

Cập nhật 12/11/2026. Mã ca và flow chuẩn theo `e2e_test/test_main_flows.py` của Thúy (PR #78). Minh chứng T02 chạy lại và review Codex được giữ riêng bên dưới.

## Tổng hợp

| Loại kiểm thử | Phạm vi | Kết quả | Minh chứng |
|---|---|---|---|
| Security Rules (Emulator) | R-01…R-30, mọi collection trừ Discord | **30/30 đạt** (chạy lại 11/11) | [`evidence/firestore/rules-tests.txt`](../evidence/firestore/rules-tests.txt) |
| Unit + widget test (Flutter) | App, `packages/core`, `web_admin` | **303 / 5 / 14 đạt** (app thêm 7 test vai trò, 6 test nháp nhật ký P4; web thêm 1 test vai trò theo thời gian thực và 3 test màn lỗi Tổng quan), `flutter analyze` không lỗi | [`evidence/flutter/analyze-and-test.txt`](../evidence/flutter/analyze-and-test.txt) |
| Mobile E2E (ARTEMIS) | T01–T14 (luồng Lab 2 / Lab 3) | **41/42 lần đạt (98%)** | [`test-plan.md`](test-plan.md) mục 5, `evidence/artemis/` |
| Mobile E2E (ARTEMIS) | Luồng mới của Final: T14 bản Final, T17–T20 (máy thật) | **14/15 lần đạt** (T18 2/3: một lần agent quá giờ); T15, T16 chưa chạy (mục 2.2) | `evidence/artemis/final-*.txt` |
| Mobile trên máy thật | Onboarding, Nốt AI, Thẻ tuần PDF, tắt AI bằng Remote Config | Chạy tay, đạt | [`evidence/mobile-final/`](../evidence/mobile-final/README.md) |
| Web admin (checklist) | 5 màn + form thông báo, từ chối sai vai trò, trống, đang tải | 16/16 mục đạt (thêm đổi vai trò khi đang mở hai chiều, trạng thái lỗi Tổng quan) | [`evidence/web-admin/`](../evidence/web-admin/README.md) |
| Luồng liên vai trò | Gửi thẻ trên app → duyệt trên web → app cập nhật + hộp thư | **3/3 lần đạt trên bản deploy** (D-1…D-3) | [`cross-role-flow.md`](cross-role-flow.md), `evidence/cross-role/` |
| AI code review | Code thêm cho Final | 5 góp ý của Claude và 3 góp ý bổ sung của Codex, có quyết định | Mục 6 |

## 1. Security Rules (Emulator)

Lệnh: `npm run test:rules` trong `firebase/` (Firebase Emulator, `node --test`,
project `demo-prm393`). Lần chạy 11/11/2026 22:10 (sau PR #75, thêm R-29 và R-30):
**30 test, 30 đạt, 0 lỗi** (khoảng 7 s).

Bảng từng ca (vai trò, thao tác, được phép / bị cấm) ở
[`data-model.md`](data-model.md) mục "Test rules". Tóm tắt theo collection:

| Collection | Vai trò có ca được phép | Vai trò có ca bị cấm | Test |
|---|---|---|---|
| `users/{uid}` | user (tạo hồ sơ `role = user`, đọc của mình), staff (đọc hồ sơ), admin (đổi vai trò người khác) | chưa đăng nhập, user (tự nâng vai trò, đọc hồ sơ staff), staff (đổi vai trò), admin (đổi vai trò của chính mình) | R-01–R-03, R-05, R-06, R-18, R-26 |
| `challenges` | staff (tạo, sửa, lưu trữ); user (đọc) | user (tạo, sửa); staff (xoá, dữ liệu sai) | R-12, R-19 |
| `challengeSubmissions` | user (gửi `pending`, rút thẻ `pending`), staff (duyệt / từ chối có lý do) | user (tự duyệt, đọc thẻ người khác), staff (từ chối không lý do, duyệt lại thẻ đã xử lý) | R-20–R-23 |
| `announcements` | staff (gửi, xoá), user (đọc) | chưa đăng nhập (đọc), user (gửi, xoá), staff (sửa, `authorUid` người khác) | R-25 |
| `users/{uid}/inbox` | staff (tạo tin), chủ (đọc, đánh dấu đã đọc, xoá) | user (tự tạo tin), staff (đọc hộp thư người khác) | R-24 |
| `users/{uid}/reports` | chủ (ghi metadata tuần, đọc, xoá) | người khác; dữ liệu sai hình dạng | R-28 |
| `users/{uid}/private/onboarding` | chủ | người khác; giá trị lạ | R-27 |
| Collection con của Lab 3 (`notes`, `private/*`, `challengeProgress`, `customChallenges`, `groups`, `stickers`, `reports`) | chủ | người dùng khác; **staff và admin** (đọc, ghi, xoá, truy vấn); dữ liệu sai | R-07–R-17, R-29 |
| `users/{uid}/sharedStreaks` | chủ (tạo, đọc, xoá) | sửa sau khi tạo; sai kiểu; trường lạ; ảnh quá 850 000 ký tự; người khác | R-30 |
| Collection không khai báo | — | mọi vai trò (deny by default) | R-04 |

Mỗi vai trò (`user`, `staff`, `admin`, chưa đăng nhập) có ít nhất một ca được phép
và một ca bị cấm trên mỗi collection mà vai trò đó chạm tới. Riêng dữ liệu riêng
của người dùng, staff và admin chỉ có ca bị cấm vì không vai trò nào ngoài chủ
tài khoản được đọc (R-29).

## 2. Mobile E2E (ARTEMIS)

### 2.1 Luồng Lab 2 / Lab 3 (đã chạy)

Chi tiết cách chạy, môi trường và từng lần chạy ở [`test-plan.md`](test-plan.md).
Mỗi ca chạy 3 lần trên emulator Android, ngày 05–06/11/2026.

| ID | Luồng | Đạt |
|---|---|---|
| T01 | Khởi động | 3/3 |
| T02 | F1 ghi nốt (nhánh chính) | 3/3 |
| T03 | P5 hũ: mở và xoá nốt | 3/3 |
| T04 | F1 lỗi: nội dung trống | 3/3 |
| T05 | F1 lỗi: thoát giữa chừng, hỏi giữ nháp | 3/3 |
| T06 | F1 lỗi: mất mạng | **2/3** |
| T07 | F2 tự chủ | 3/3 |
| T08 | F2 khó dừng → tập thở | 3/3 |
| T09 | F3 thử thách | 3/3 |
| T10 | Điều hướng bốn tab | 3/3 |
| T11 | Cài đặt, cờ Remote Config | 3/3 |
| T12 | Android gốc: Home rồi mở lại | 3/3 |
| T13 | Analytics `note_saved` | 3/3 |
| T14 | Thẻ tuần PDF (bản Lab 3) | 3/3 |
| **Tổng** | | **41/42 (98%)** |

T06 lần 3 quá 420 giây, agent không báo kết quả; chưa tìm được nguyên nhân gốc.
Phiên khám phá X01 (25 phút) báo 10 lỗi giao diện, nhóm chưa kiểm tra lại từng lỗi
([`test-plan.md`](test-plan.md) mục "Phiên khám phá X01").

### 2.1.1 T02 chạy lại ngày 12/11/2026


Đã build và cài bản code hiện tại lên `emulator-5554`, chạy thật T02 qua ARTEMIS Flash / OpenRouter. **3/3 pass (100%), 0 fail**, tổng thời gian pytest **172,32 giây**. Kịch bản: Hôm nay → Ghi nốt → Chiến thắng nhỏ → bỏ qua ảnh → chọn gợi ý Dọn phòng → Bỏ qua phần kể thêm → xác nhận Đã vào hũ cùng nội dung Dọn phòng. Ca này xác minh lưu bằng gợi ý nhanh; chưa kiểm chứng việc gõ nội dung tự do.

| Lượt | Kết quả | Thời gian JUnit | Phiên ARTEMIS |
|---|---|---|---|
| 1 | Pass | 62,359 giây | `0ba26d89-fb11-43ea-a2d0-8c8b6aa0a999` |
| 2 | Pass | 61,612 giây | `be1d97a7-d3f6-4923-8908-b116e6706e8e` |
| 3 | Pass | 48,258 giây | `03905ac0-e4e4-4914-bb2b-199e20637344` |

[Log pytest](../evidence/artemis/final-t02-2026-11-12.txt) · [JUnit ba lượt](../evidence/artemis/final-t02-2026-11-12.xml) · [Ảnh Workspace: ba phiên Completed và SAVED](../evidence/artemis/final-t02-workspace-2026-11-12.jpg)

Đã sửa kịch bản theo giao diện hiện tại, nâng timeout T02 lên 240 giây và bổ sung dừng tác vụ khi runner hết thời gian để tránh phiên chạy chồng nhau. Kết quả T02 này không thay cho kết quả toàn bộ Mobile E2E.

### 2.2 Luồng mới của Final

Chạy ngày 12/11/2026 trên **Galaxy A70 thật** (adb không dây), bản debug build từ
`main` sau PR #77, tài khoản "Thị Kim Thúy Đoàn" (`user`), ARTEMIS profile Flash
(model như mục 2.1), mỗi ca 3 lần. Tổng thời gian 47 phút. Log:
[`evidence/artemis/final-t14-t17-t18-t20.txt`](../evidence/artemis/final-t14-t17-t18-t20.txt) và
[`final-t19.txt`](../evidence/artemis/final-t19.txt).

**T19** chạy riêng: đặt `ai_enabled = false` trên Remote Config (Version 20), mở
lại app, chạy `E2E_AI_DISABLED=1 uv run pytest -k t19` (3/3, 6 phút), rồi đặt lại
`true` (Version 21). Cần bản debug vì bản release chỉ tải Remote Config mỗi giờ.
Ca nằm trong `e2e_test/test_main_flows.py`.

Các ca chạy trên tài khoản demo nên **không để lại dữ liệu**: T17 dừng ở màn "Hồ sơ
khởi đầu" rồi test tự tắt và mở lại app (bấm "Bắt đầu" sẽ ghi đè cấp thử thách và
giờ nhắc); T18 không lưu nốt; T20 rút lại và xoá thẻ thử ngay. Sau khi chạy đã
kiểm tra trên Console: `challengeSubmissions` không có thẻ `pending`, không còn thẻ
"E2E thẻ thử".

| ID | Luồng | Khẳng định | Lần 1 | Lần 2 | Lần 3 | Đạt |
|---|---|---|---|---|---|---|
| T14 | Thẻ tuần PDF bản Final: lưu trên máy, mở hộp chia sẻ | `SAVED_SHARED` | đạt | đạt | đạt | 3/3 |
| T17 | A2 Làm quen: 4 câu → "Hồ sơ khởi đầu" có "3 thẻ để bắt đầu" | `PLAN_SHOWN` | đạt | đạt | đạt | 3/3 |
| T18 | A1 Kể tự do → Gemini tách thành nốt gợi ý có nhãn "Gợi ý từ Nốt AI" | `SUGGESTIONS` | đạt | **quá giờ** | đạt | 2/3 |
| T19 | Remote Config `ai_enabled = false` → Kể tự do báo "Nốt AI đang nghỉ", chỉ còn "Ghi tay", ghi tay mở được | `AI_OFF_MANUAL MANUAL_OPENS` | đạt | đạt | đạt | 3/3 |
| T20 | Liên vai trò, phần mobile: gửi thẻ → "Đang chờ duyệt"; thẻ đã duyệt hiện "Đã vào kho chung"; hộp thư có tin duyệt | `PENDING APPROVED INBOX` | đạt | đạt | đạt | 3/3 |
| **Tổng** | | | | | | **14/15 (93%)** |

**T18 lần 2:** agent không gõ được chữ bằng lệnh `input_text` (chữ không vào ô),
chuyển sang bấm từng phím trên bàn phím ảo, nên quá giới hạn 480 giây. Ở bước
cuối agent vẫn thấy danh sách gợi ý có dòng "Gợi ý từ Nốt AI" và 3 nốt, rồi về
màn Hôm nay không lưu, tức là app chạy đúng; lỗi nằm ở cách agent nhập chữ. Tính
là không đạt theo quy tắc của bộ test.

**T20** chỉ kiểm phần mobile. Bước staff duyệt trên web đã chạy 3 lần trên bản
deploy (mục 5). Ca dùng thẻ cũ đã được duyệt để kiểm "Đã vào kho chung" và tin
trong hộp thư, nên không cần staff duyệt thẻ thử.

**Chưa chạy:**

| Ca | Lý do | Cách chạy |
|---|---|---|
| T15, T16 | Cần tài khoản email chỉ dùng cho test | Đặt `E2E_EMAIL`, `E2E_PASSWORD` rồi `uv run pytest -k "t15 or t16"` |

## 3. Mobile trên máy thật

Chạy tay ngày 10/11/2026 trên Samsung Galaxy A70 (Android 11), bản debug từ
`main` (`1aec01a`), nối Firebase thật `prm393-not-lab3`, App Check bằng debug
token. Chi tiết và ảnh ở [`evidence/mobile-final/README.md`](../evidence/mobile-final/README.md).

| Kiểm tra | Kết quả |
|---|---|
| Onboarding 4 câu → hồ sơ khởi đầu và 3 thẻ | Đạt |
| Nốt AI lần đầu: sheet quyền riêng tư | Đạt |
| Nốt AI với Gemini thật: tách đoạn kể thành 3 nốt, gắn nhãn AI, sửa được, lưu | Đạt |
| Tắt `ai_enabled` trên Remote Config → "Nốt AI đang nghỉ", vẫn ghi tay | Đạt |
| Thẻ tuần PDF: lưu vào thư mục của app, mở hộp chia sẻ, metadata Firestore | Đạt (file thật 15 775 byte) |
| Thông báo từ web tới hộp thư của app theo thời gian thực | Đạt ([`web-admin/11`](../evidence/web-admin/11-app-inbox-announcement.png)) |

## 4. Web admin (checklist)

Chạy ngày 10/11/2026 trên bản deploy `https://prm393-not-lab3.web.app/admin/`
(Chrome, 1920 px). Mỗi mục có một ảnh trong
[`evidence/web-admin/`](../evidence/web-admin/README.md).

| Màn | Thao tác chính | Từ chối sai vai trò | Trống | Đang tải | Lỗi |
|---|---|---|---|---|---|
| Đăng nhập | Google Sign-In (01) | Đạt (02) | — | — | Chưa có ảnh |
| Tổng quan | 5 số `count()` + 3 biểu đồ (03) | — | — | Đạt (13) | Đạt (16) |
| Kho thẻ | Tìm (04), sửa (05), lưu trữ (06) | — | — | — | Chưa có ảnh |
| Hàng chờ duyệt | Duyệt kèm giờ xử lý (08) | — | Đạt (07) | — | Chưa có ảnh |
| Thông báo | Gửi, hiện trong app (10, 11) | — | Đạt (09) | — | Chưa có ảnh |
| Người dùng | Danh sách, tìm, admin đổi vai trò, khoá vai trò của mình (12) | — | — | — | Chưa có ảnh |

Năm màn dữ liệu dùng chung `MessageView.error`. Đã có ảnh lỗi Tổng quan
trên bản deploy (ảnh 16); các màn listener còn thiếu ảnh lỗi riêng. Khi chụp thử (tắt mạng → Làm mới ở Tổng
quan) đã tìm ra lỗi quay vòng mãi; bản sửa (chờ tối đa 15 giây rồi báo lỗi,
`dashboardTimeout`) đã deploy ở PR #75.

Chụp lại ngày 11/11/2026 (chặn request `runAggregationQuery` trong tab) vẫn
quay vòng **hơn 3 phút**: Riverpod 3 mặc định tự thử lại provider lỗi 10 lần
và giữ trạng thái loading, `TimeoutException` cũng bị thử lại. Lỗi này ảnh
hưởng mọi màn lỗi của cả hai app (app mobile chậm vài chục giây mới báo lỗi).
**Đã sửa:** cả hai app dùng `ProviderScope(retry: noRetry)`
(`packages/core/lib/services/retry.dart`), vì mọi màn lỗi đã có nút Thử lại.
Test: `web_admin/test/dashboard_error_test.dart` (máy chủ không trả lời → lỗi
sau 15 giây và không tải lại ngầm; lỗi mạng → báo ngay, Thử lại tải đúng một
lần); hai test đầu trượt nếu bỏ `noRetry`. Chụp lại trên bản deploy sau PR #77:
lỗi hiện sau ~15 giây, Thử lại tải lại được (ảnh `web-admin/16`). Các màn còn
lại dùng chung `MessageView.error` nhưng đọc bằng listener thời gian thực, khó
giả lập lỗi trên bản deploy nên chưa có ảnh riêng.

## 5. Luồng liên vai trò

Người dùng gửi thẻ trên app (`pending`) → staff duyệt trên web admin → app đổi
trạng thái thẻ và có tin trong hộp thư. Chi tiết từng bước, rule cho phép và sơ
đồ ở [`cross-role-flow.md`](cross-role-flow.md).

| Lần | Môi trường | Bấm Duyệt → máy chủ ghi | Bấm Duyệt → app cập nhật | Kết quả |
|---|---|---|---|---|
| E-1 | Emulator | — | ≤ 3,3 s | Đạt |
| D-1 | Bản deploy | 1,4 s | 21–23 s | Đạt (app vừa mở lại, listener chậm) |
| D-2 | Bản deploy | 1,4 s | ≤ 3,4 s | Đạt |
| D-3 | Bản deploy | 1,5 s | ≤ 2,3 s | Đạt; hộp thư có đủ 3 tin |

Lỗi tìm ra khi chạy D-1: bấm Duyệt khi staff chưa mở màn Kho thẻ thì hết giờ sau
10 giây ("Có lỗi xảy ra"). Đã sửa ở PR #70 (đọc kho thẻ thẳng từ repository).

## 6. AI code review cho code Final

**Công cụ:** Claude Code (model Claude Opus 5.5), ngày 11/11/2026, trên `main`
commit `eb04447`. **Phạm vi:** code thêm hoặc đổi cho Final: `web_admin/lib/`
(session, view model duyệt thẻ, dashboard), `packages/core/lib/firebase/firestore_repositories.dart`
(duyệt / từ chối, dashboard, kho thẻ), `lib/firebase/firebase_ai_service.dart`
và `lib/services/ai_service.dart` (Nốt AI). Mỗi góp ý dưới đây đã được đối chiếu
lại với code trước khi ghi.

| # | Mức | Vị trí | Góp ý | Quyết định |
|---|---|---|---|---|
| CR-F1 | Trung bình | `web_admin/lib/viewmodels/session_view_model.dart` (`sessionProvider`) | Vai trò chỉ đọc **một lần** khi đăng nhập (`roleOf`). Nếu admin hạ một staff xuống `user` khi người đó đang mở web admin, giao diện vẫn hiện đủ quyền cho tới khi tải lại trang; mọi thao tác ghi sẽ báo lỗi quyền. | **Đã sửa** (sau khi gặp thật khi chạy thử 11/11: web vẫn hiện "Admin" trong khi mọi truy vấn báo không có quyền). `sessionProvider` đổi sang `StreamProvider` theo dõi `users/{uid}` bằng `UserDirectory.watchRole` (snapshot); vai trò đổi thì phiên chuyển ngay sang màn từ chối hoặc quay lại. Test: `web_admin/test/session_test.dart` "vai trò bị đổi khi đang mở web". |
| CR-F2 | Trung bình | `lib/services/ai_service.dart` (`scrubForAi`) | Trước khi gửi Gemini, app chỉ thay email và số điện thoại; **tên người** trong đoạn kể (ví dụ "đi ăn với Lan") vẫn được gửi đi. Đề yêu cầu không gửi dữ liệu cá nhân (tên, email, ảnh người). | **Chấp nhận có điều kiện.** Không lọc tên được chính xác bằng regex tiếng Việt. App đã: hỏi đồng ý lần đầu (sheet nói rõ "Gửi tới Gemini: đoạn bạn vừa kể"), cho tắt AI trong Cài đặt, không gửi uid / tên / email của tài khoản, và prompt yêu cầu Gemini không lặp lại tên người. Hạn chế đã ghi trong [`ai-feature.md`](ai-feature.md) mục "Yêu cầu của đề". |
| CR-F3 | Thấp | `lib/services/ai_service.dart` (`scrubForAi`) | Regex số điện thoại `\+?\d[\d .-]{7,}\d` bắt cả dãy số không phải điện thoại, ví dụ "2025-2026" bị đổi thành `[số điện thoại]`, làm câu gửi AI khó hiểu hơn. | **Chấp nhận.** Thà che nhầm còn hơn gửi lộ số điện thoại; ảnh hưởng chỉ là chất lượng gợi ý, người dùng vẫn sửa được kết quả. |
| CR-F4 | Thấp | `web_admin/lib/viewmodels/admin_view_models.dart` (`ReviewActions.approve`) và `firestore_repositories.dart` (`_compare`) | Thứ tự (`order`) của thẻ mới tính trên máy staff từ bản kho thẻ vừa đọc. Hai staff duyệt cùng lúc hai thẻ cùng chủ đề và cấp sẽ nhận **cùng `order`**; `_compare` không có tiêu chí phụ nên thứ tự hai thẻ đó trên app có thể đổi giữa các lần tải. | **Chấp nhận.** Dự án có một staff; staff sửa được `order` ở màn Kho thẻ. Nếu sửa: thêm so sánh theo `id` khi `order` bằng nhau. |
| CR-F5 | Thấp | `lib/firebase/firebase_ai_service.dart` (`_ask`) | Khi AI bị tắt bằng Remote Config, mỗi lần người dùng mở Kể tự do vẫn log `ai_error {reason: disabled}`, làm số `ai_error` trên Analytics tăng dù không có lỗi thật. | **Giữ nguyên.** `reason` tách riêng nên lọc được trên Analytics; số lần "AI tắt" cũng là dữ liệu hữu ích khi thử bật / tắt bằng Remote Config. |

Không góp ý nào là lỗi bảo mật hay mất dữ liệu: các thao tác của staff đều đi qua
batch write được Security Rules kiểm tra (duyệt lại thẻ đã xử lý bị rules chặn,
R-22), và lỗi của AI đều đi nhánh dự phòng (`ai-feature.md` mục "Một lỗi đã xử lý").

Review của Lab 3 (CodeRabbit, các góp ý đã sửa và chưa sửa) ở
[`code-review.md`](code-review.md).

### 6.1 Review bổ sung bằng Codex

Review tĩnh bằng OpenAI Codex ngày 10/11/2026 trên code Nốt AI của nhánh `main` tại `f8aa231`. Đây là góp ý của Codex. Cả ba góp ý đã được xử lý trong commit `aa88f70`. Flutter Analyze sạch và 15/15 ca trong `free_tell_flow_test.dart` và `onboarding_flow_test.dart` pass, gồm hai ca hồi quy mới.

| ID | Vị trí | Vấn đề | Quyết định và lý do |
|---|---|---|---|
| CR-F01 | [`FirebaseAiService._ask`](../lib/firebase/firebase_ai_service.dart#L53) | Lệnh ghi `ai_request` được chờ trước khối `try`. Nếu Analytics ném lỗi, lệnh gọi Gemini bị bỏ qua, trong khi ViewModel chỉ bắt `AiException`. Ghi `ai_error` cũng có thể che lỗi AI ban đầu. | **Đã sửa — `aa88f70`.** Ghi Analytics theo cơ chế best effort để lỗi đo lường không chặn Gemini hoặc che nguyên nhân fallback. |
| CR-F02 | [`FirebaseAiService.sortNotes`](../lib/firebase/firebase_ai_service.dart#L130) | Ép kiểu trực tiếp `type`, `title` và `mood` sang `String?` sau khi ra khỏi khối bắt lỗi của `_ask`. Nếu dữ liệu trả về sai kiểu, `TypeError` có thể thoát khỏi nhánh fallback và để màn ở trạng thái đang đọc. | **Đã sửa — `aa88f70`.** Kiểm tra kiểu trước khi tạo model và chuyển dữ liệu sai sang `AiException(parse)`. |
| CR-F03 | [`FreeTellViewModel.save`](../lib/viewmodels/free_tell_view_model.dart#L189) | Sau mỗi lần chờ ghi Firestore, lượt kế tiếp đọc lại `state.mood`. Sau khi ghi xong còn đọc Analytics provider trước khi kiểm tra `ref.mounted`. Rời màn giữa lúc ghi có thể làm gián đoạn lượt lưu nhiều nốt hoặc bỏ mất số lượng đã lưu trên giao diện. | **Đã sửa — `aa88f70`.** Giữ nguyên tâm trạng của lượt lưu và dừng trước lần ghi tiếp theo nếu màn đã đóng. Lần ghi đang chờ có thể hoàn tất. |

## 7. Việc còn lại

1. Chạy ARTEMIS T15–T16 (cần tài khoản email chỉ dùng cho test).
2. (Tuỳ chọn) Ảnh trạng thái lỗi cho các màn web admin dùng listener thời gian thực.

## Cách chạy lại

```sh
# Security Rules (cần Java 17+)
cd firebase && npm run test:rules

# Unit + widget test
flutter analyze && flutter test
cd packages/core && flutter analyze && flutter test
cd web_admin && flutter analyze && flutter test

# ARTEMIS (xem e2e_test/README.md)
cd tools/artemis && uv sync && uv run python -m artemis ui --port 8000 --no-open
cd e2e_test && uv sync && uv run pytest
```
