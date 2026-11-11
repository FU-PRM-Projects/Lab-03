# Báo cáo kiểm thử (Final Assignment)

Đề Final mục 9: ARTEMIS cho mọi luồng Lab 2, phần mobile của luồng liên vai trò
và tính năng AI; Security Rules trên Emulator; checklist web admin; luồng liên
vai trò chạy 3 lần trên hệ thống đã deploy; AI code review cho code mới (≥ 3
góp ý kèm quyết định). File này gom kết quả và trỏ tới minh chứng trong
`evidence/`.

Cập nhật 11/11/2026, trên `main` commit `eb04447`.

## Tổng hợp

| Loại kiểm thử | Phạm vi | Kết quả | Minh chứng |
|---|---|---|---|
| Security Rules (Emulator) | R-01…R-28, mọi collection trừ Discord và `sharedStreaks` | **28/28 đạt** (chạy lại 11/11) | [`evidence/firestore/rules-tests.txt`](../evidence/firestore/rules-tests.txt) |
| Unit + widget test (Flutter) | App, `packages/core`, `web_admin` | **303 / 5 / 11 đạt** (app thêm 7 test vai trò, 6 test nháp nhật ký P4; web thêm 1 test vai trò theo thời gian thực), `flutter analyze` không lỗi | [`evidence/flutter/analyze-and-test.txt`](../evidence/flutter/analyze-and-test.txt) |
| Mobile E2E (ARTEMIS) | T01–T14 (luồng Lab 2 / Lab 3) | **41/42 lần đạt (98%)** | [`test-plan.md`](test-plan.md) mục 5, `evidence/artemis/` |
| Mobile E2E (ARTEMIS) | Luồng mới của Final | **Chưa chạy** (xem mục 2.2) | — |
| Mobile trên máy thật | Onboarding, Nốt AI, Thẻ tuần PDF, tắt AI bằng Remote Config | Chạy tay, đạt | [`evidence/mobile-final/`](../evidence/mobile-final/README.md) |
| Web admin (checklist) | 5 màn + form thông báo, từ chối sai vai trò, trống, đang tải | 13/13 mục đạt; **thiếu ảnh trạng thái lỗi** | [`evidence/web-admin/`](../evidence/web-admin/README.md) |
| Luồng liên vai trò | Gửi thẻ trên app → duyệt trên web → app cập nhật + hộp thư | **3/3 lần đạt trên bản deploy** (D-1…D-3) | [`cross-role-flow.md`](cross-role-flow.md), `evidence/cross-role/` |
| AI code review | Code thêm cho Final | 5 góp ý, có quyết định | Mục 6 |

## 1. Security Rules (Emulator)

Lệnh: `npm run test:rules` trong `firebase/` (Firebase Emulator, `node --test`,
project `demo-prm393`). Lần chạy 11/11/2026 13:21 trên `eb04447`:
**28 test, 28 đạt, 0 lỗi** (6,4 s).

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
| Collection con của Lab 3 (`notes`, `private/*`, `challengeProgress`, `customChallenges`, `groups`, `stickers`) | chủ | người dùng khác; dữ liệu sai | R-07–R-17 |
| Collection không khai báo | — | mọi vai trò (deny by default) | R-04 |

**Hạn chế:** các collection con của Lab 3 chỉ có ca cho vai trò `user`
(chủ / người khác); chưa có ca staff hoặc admin bị cấm đọc nốt của người dùng.
`sharedStreaks` chưa có test riêng.

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

### 2.2 Luồng mới của Final (chưa chạy)

Đề yêu cầu ARTEMIS cho phần mobile của luồng liên vai trò và tính năng AI, mỗi
ca 3 lần. Các luồng dưới đây **đã chạy tay trên máy thật** (minh chứng ở cột
cuối) nhưng **chưa có ca ARTEMIS**:

| Ca cần thêm | Luồng | Trạng thái ARTEMIS | Đã kiểm tra tay |
|---|---|---|---|
| T17 | A2 Làm quen: 4 câu → thẻ khởi đầu | Chưa có ca | [`mobile-final/01–03`](../evidence/mobile-final/README.md) |
| T18 | A1 Nốt AI · Kể tự do: đoạn kể → 3 nốt sửa được → lưu | Chưa có ca | [`mobile-final/04–06`](../evidence/mobile-final/README.md) |
| T19 | Nốt AI tắt bằng Remote Config → vẫn ghi tay | Chưa có ca | [`mobile-final/11`](../evidence/mobile-final/README.md) |
| T20 | Liên vai trò, phần mobile: gửi thẻ → thấy `pending` → thấy "Đã vào kho chung" + tin trong hộp thư | Chưa có ca | [`cross-role/`](../evidence/cross-role/) |
| T14 | Thẻ tuần PDF bản Final: lưu trên máy, mở hộp chia sẻ | Ca đã sửa ở `e2e_test/`, chưa chạy lại | [`mobile-final/07–10`](../evidence/mobile-final/README.md) |
| T15, T16 | Đăng xuất / đăng nhập, đăng nhập sai mật khẩu | Có ca, chưa chạy (cần tài khoản test) | — |

Lưu ý khi viết T18: agent không đọc được chữ của Gemini một cách ổn định giữa các
lần chạy, nên khẳng định nên dựa vào nhãn cố định "Gợi ý từ Nốt AI" và câu "Đã lưu
… nốt vào hũ", không dựa vào nội dung AI trả về.

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
| Tổng quan | 5 số `count()` + 3 biểu đồ (03) | — | — | Đạt (13) | Chưa có ảnh |
| Kho thẻ | Tìm (04), sửa (05), lưu trữ (06) | — | — | — | Chưa có ảnh |
| Hàng chờ duyệt | Duyệt kèm giờ xử lý (08) | — | Đạt (07) | — | Chưa có ảnh |
| Thông báo | Gửi, hiện trong app (10, 11) | — | Đạt (09) | — | Chưa có ảnh |
| Người dùng | Danh sách, tìm, admin đổi vai trò, khoá vai trò của mình (12) | — | — | — | Chưa có ảnh |

Năm màn dữ liệu dùng chung `MessageView.error`, nhưng chưa có ảnh
chụp trạng thái lỗi trên bản deploy. Khi chụp thử (tắt mạng → Làm mới ở Tổng
quan) đã tìm ra lỗi quay vòng mãi; bản sửa (chờ tối đa 15 giây rồi báo lỗi) đã có
trong code (`dashboardTimeout`), cần deploy rồi chụp lại.

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

## 7. Việc còn lại

1. Viết và chạy 3 lần các ca ARTEMIS T17–T20, chạy lại T14 (bản Final) và T15–T16.
2. Deploy bản sửa trạng thái lỗi của web admin rồi chụp ảnh lỗi cho từng màn.
3. Thêm ca rules cho staff / admin bị cấm đọc dữ liệu riêng của người dùng
   (`notes`, `private/*`) và cho `sharedStreaks`.

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
