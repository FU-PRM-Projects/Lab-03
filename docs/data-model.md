# Mô hình dữ liệu và Security Rules

Final Assignment, Stage 2. Một Firestore dùng chung cho app mobile (vai trò
`user`) và web admin (`staff`, `admin`); không có server riêng. Quyền nằm ở
[`firebase/firestore.rules`](../firebase/firestore.rules): mặc định cấm, không
có `if true`, kiểm tra hình dạng dữ liệu và bước chuyển trạng thái. Model và
repository Firestore dùng chung ở [`packages/core`](../packages/core)
(`package:not_core`).

## Vai trò

| Vai trò | Client | Cách có |
|---|---|---|
| `user` | App mobile | Tự tạo `users/{uid}` với `role = user` khi đăng nhập lần đầu (cả app lẫn web admin) |
| `staff` | Web admin | Admin đổi ở màn Người dùng |
| `admin` | Web admin | Admin đầu tiên đặt trong Firebase Console (hoặc `npm run role -- <email> admin`); các admin sau do admin đổi |

Chỉ admin đổi vai trò, không ai đổi vai trò của chính mình.

### Mỗi client từ chối tài khoản sai vai trò

Đề Final mục 6: *"each client rejects accounts of the wrong role with a clear
message"*.

| Client | Cho vào | Từ chối | Câu báo | Code |
|---|---|---|---|---|
| Web admin | `staff`, `admin` | `user` | "Tài khoản này không có quyền vào web admin" ([ảnh](../evidence/web-admin/02-rejected-user-account.png)) | `web_admin/lib/viewmodels/session_view_model.dart` |
| App mobile | `user` | `staff`, `admin` | "Tài khoản này dành cho web admin", kèm địa chỉ web admin và nút Đăng xuất | `accountRoleProvider` (`lib/viewmodels/auth_view_model.dart`), `authRedirect` (`lib/router/auth_redirect.dart`), `WrongRoleScreen` |

App đọc `users/{uid}.role` mỗi khi tài khoản đăng nhập đổi, kể cả khi phiên cũ
được khôi phục lúc mở app. Trong lúc đọc, router giữ ở màn chờ để không lộ màn
nào của app. Tài khoản `staff` / `admin` chỉ thấy màn báo và nút Đăng xuất,
không có thanh tab. Chưa có hồ sơ (lần đăng nhập đầu) hoặc không đọc được vai
trò (mất mạng) thì coi như `user`: lúc đó Security Rules vẫn kiểm tra vai trò ở
mọi lần ghi, và app không có thao tác nào cần vai trò cao hơn `user`. Test:
`test/router/auth_redirect_test.dart` (nhóm "vai trò") và
`test/screens/auth_flow_test.dart`.

Vì vậy mỗi người cần hai tài khoản khi làm cả hai việc: tài khoản `user` ghi nốt
trên điện thoại, tài khoản `staff` / `admin` làm việc trên web. Demo luồng liên
vai trò dùng đúng hai tài khoản này.

## Collection

Bảng đầu là collection Final thêm hoặc đổi quyền (dùng chung giữa các vai
trò). Bảng sau là dữ liệu riêng của người dùng từ Lab 3: chỉ chủ tài khoản đọc
/ ghi, staff và admin cũng không đọc được (test R-29).

### Collection dùng chung và collection Final thêm

| Collection | Trường chính (kiểu) | Tạo | Đọc | Sửa | Xoá | Màn dùng |
|---|---|---|---|---|---|---|
| `users/{uid}` | `role` (`user`/`staff`/`admin`), `displayName`, `email`?, `photo`? | Chính mình, `role = user` | Chính mình; staff, admin | Admin: chỉ `role`, không phải của mình. Chủ: chỉ `photo` | — | App: hồ sơ, ảnh đại diện. Web: đăng nhập, Người dùng, Tổng quan |
| `challenges/{id}` | `topic` (`dung_cam`/`van_dong`), `level` (1–10), `order` (0–999), `title` (1–80), `minutes` (1–600), `tip` (≤120), `script` (≤300), `discordRoom`?, `status` (`active`/`archived`), `source` (`seed`/`staff`/`community`), `submissionId`?, `updatedBy`, `updatedAt` | Staff, admin (kèm `updatedBy` = mình, `updatedAt` = giờ server) | Mọi người đã đăng nhập (app ẩn thẻ `archived`) | Staff, admin, cùng điều kiện | — (lưu trữ thay vì xoá) | App: Thử thách, chi tiết thẻ. Web: Kho thẻ, Tổng quan |
| `challengeSubmissions/{id}` | `uid`, `topic`, `title` (1–80), `minutes` (1–600), `tip` (≤120), `customId`?, `status` (`pending`/`approved`/`rejected`), `reason` (≤200), `createdAt`, `reviewedBy`, `reviewedAt`, `challengeId`? | Người dùng, cho chính mình, `status = pending`, `createdAt` = giờ server | Người gửi; staff, admin | Staff, admin: chỉ `pending → approved` hoặc `pending → rejected` (cần `reason`), chỉ các trường duyệt, `reviewedBy` = mình | Người gửi, khi còn `pending` | App: thẻ tự thêm ("Gửi cho mọi người", trạng thái). Web: Hàng chờ duyệt, Tổng quan |
| `users/{uid}/reports/{isoWeek}` | `kind` (`weekly_card`), `isoWeek` (`YYYY-Www`, bằng id), `fileName` (`weekly-{isoWeek}.pdf`), `sizeBytes` (int, 1–5 000 000), `noteCount` (int ≥ 0), `savedAt` = giờ server | Chủ tài khoản | Chủ tài khoản | Chủ tài khoản (ghi đè khi lưu lại cùng tuần) | Chủ tài khoản | App: Thẻ tuần (S11b) hiện "Đã lưu tuần này lúc…". File PDF nằm trên máy, Firestore chỉ giữ metadata (đề Final, mục 4) |
| `users/{uid}/inbox/{id}` | `kind` (`submission_approved`/`submission_rejected`), `title` (1–80), `body` (1–500), `submissionId`?, `read` (bool), `createdAt` | Staff, admin, `read = false`, `createdAt` = giờ server | Chủ hộp thư | Chủ hộp thư: chỉ `read` | Chủ hộp thư | App: hộp thư (chuông). Web: tạo khi duyệt / từ chối |
| `users/{uid}/private/onboarding` | `strangerLevel` (1–4 hoặc null), `habits` (≤ 20), `move` (`it_khi`/`thinh_thoang`/`thuong_xuyen`/null), `freeSlot` (`sang`/`chieu`/`toi`/`khuya`/null), `goals` (≤ 2), `profileLabel` (≤ 30), `planSource` (`ai`/`rules`), `done` (true), `completedAt` | Chủ tài khoản | Chủ tài khoản | Chủ tài khoản, cùng điều kiện | — | App: S13a–g, S12 "Làm lại khảo sát" |
| `announcements/{id}` | `title` (1–80), `body` (1–1000), `authorUid`, `createdAt` | Staff, admin, `authorUid` = mình, `createdAt` = giờ server | Mọi người đã đăng nhập | — | Staff, admin | App: hộp thư. Web: Thông báo, Tổng quan |

### Dữ liệu riêng của người dùng (từ Lab 3)

Mọi collection dưới đây nằm trong `users/{uid}/…`. Quy tắc chung: **chỉ chủ tài
khoản** (`isOwner(uid)`) được tạo, đọc, sửa, xoá; người dùng khác, staff và
admin đều bị cấm (R-08, R-11, R-29). Rules kiểm tra hình dạng dữ liệu ở mọi lần
ghi.

| Collection | Trường chính (kiểu, giới hạn) | Tạo | Đọc | Sửa | Xoá | Màn dùng |
|---|---|---|---|---|---|---|
| `notes/{id}` | `type` (`chien_thang`/`tu_chu`/`thu_thach`/`nhat_ky`), `title` (1–120), `body`? (≤ 2000), `mood`? (`vui`/`on`/`binh_thuong`/`met`/`roi`), `createdAt` (timestamp); thử thách: `challengeId`, `subtype` (`nguoi_la`/`van_dong`), `outcome` (`suon_se`/`khong_nhu_y`), `anxietyBefore`/`anxietyAfter` (1–5), `minutes` (0–600); nhóm: `groupId`, `isFirst`; `image`? (Cloudinary `{url, publicId}`) | Chủ | Chủ | Chủ, cùng điều kiện | Chủ | S02 Hôm nay, S03 Ghi nốt, S03b Kể tự do, Viết nhật ký, S04, S05 Hũ, S06 chi tiết, S08 thử thách, S09 tự chủ, S11 Hành trình, Thẻ tuần |
| `private/habits` | `selected` (≤ 20), `custom` (≤ 8) | Chủ | Chủ | Chủ | — | S09 Tự chủ (thói quen muốn bớt), S13 Làm quen |
| `private/settings` | `eveningReminder`, `awakeEnabled`, `awakeStart`, `awakeEnd`, `lockSelfControl`, `aiEnabled`, `hideNotificationContent` | Chủ | Chủ | Chủ | — | S12 Cài đặt (giờ nhắc, Giờ tỉnh, khoá Tự chủ, Nốt AI, ẩn nội dung thông báo) |
| `private/onboarding` | Xem bảng trên (Final) | Chủ | Chủ | Chủ | — | S13a–g, S12 |
| `challengeProgress/{topic}` | id ∈ `dung_cam`/`van_dong`; `level` (int ≥ 1), `completed` | Chủ | Chủ | Chủ | — | S07 Thử thách, S11a con đường leo |
| `customChallenges/{id}` | `topic`, `title` (1–80), `minutes` (1–600), `tip`? (≤ 120), `createdAt` | Chủ | Chủ | — (không sửa) | Chủ | S07 "Thêm thẻ của bạn"; gửi lên kho chung tạo `challengeSubmissions` |
| `groups/{id}` | `name` (1–24), `idea` (`chien_thang`/`nhat_ky`/`tu_chu`/`nguoi_la`/`van_dong`), `source` (`system`/`user`/`ai_suggested`), `noteCount` (≥ 0), `firstNoteId`, `firstNoteTitle` (≤ 120), `firstAt`, `lastAt`, `createdAt`, `image`? | Chủ | Chủ | Chủ | Chủ (có Hoàn tác) | S05 kệ Nhóm lần đầu, S05e chi tiết nhóm, S03 chọn nhóm |
| `sharedStreaks/{id}` | `image` (PNG base64, ≤ 850 000 ký tự), `streak`, `record`, `milestone` (int), `createdAt` | Chủ | Chủ | — (tạo một lần) | Chủ | S02 thẻ chuỗi, S04 chúc mừng chuỗi, trang Chia sẻ chuỗi ngày (R-30) |
| `reports/{isoWeek}` | Xem bảng trên (Final) | Chủ | Chủ | Chủ | Chủ | Thẻ tuần (S11b) |
| `stickers/{month}` | `month` (bằng id `YYYY-MM`), `createdAt` | Chủ | Chủ | Chủ | — | S05 Hũ: nhãn dán tháng (sticker) |
| `inbox/{id}` | Xem bảng trên (Final) | Staff, admin | Chủ | Chủ: chỉ `read` | Chủ | Hộp thư |

Các collection của Discord bot (`discordConnectCodes`, `discordLinks`,
`users/{uid}/private/discord`) thuộc phần mở rộng ngoài phạm vi chấm của Final,
không ghi ở đây.

### Bước chuyển trạng thái

| Thực thể | Từ | Sang | Ai |
|---|---|---|---|
| `challengeSubmissions.status` | (mới) | `pending` | Người gửi (app) |
| | `pending` | `approved` | Staff, admin (web), cùng batch tạo `challenges/cm-{id}` và tin `submission_approved` |
| | `pending` | `rejected` + `reason` | Staff, admin (web), cùng batch tạo tin `submission_rejected` |
| | `pending` | (xoá) | Người gửi rút lại |
| | `approved` / `rejected` | — | Đã xử lý thì không đổi nữa |
| `challenges.status` | `active` | `archived` | Staff, admin |
| | `archived` | `active` | Staff, admin |

### Chỉ mục

`firebase/firestore.indexes.json`: `challengeSubmissions` theo (`uid`,
`createdAt` giảm dần) cho app và (`status`, `createdAt` giảm dần) cho hàng chờ
của web.

## Test rules

`npm run test:rules` trong `firebase/` (Emulator, `node --test`). R-01…R-18 từ
Lab 3; R-19…R-30 thêm cho Final, mỗi vai trò và collection mới có ít nhất một
ca được phép và một ca bị cấm:

| ID | Collection | Vai trò | Thao tác | Mong đợi |
|---|---|---|---|---|
| R-19 | `challenges` | staff | tạo, sửa, lưu trữ (kèm dấu sửa) | Cho phép |
| R-19 | `challenges` | staff | xoá; `status = deleted`; tên rỗng; `updatedBy` người khác; sửa thiếu dấu sửa | Cấm |
| R-19 | `challenges` | user | tạo, sửa | Cấm |
| R-20 | `challengeSubmissions` | user | tạo `pending` cho mình | Cho phép |
| R-20 | `challengeSubmissions` | user | tạo `approved`; cho người khác; tên > 80; `createdAt` giả; chưa đăng nhập | Cấm |
| R-21 | `challengeSubmissions` | user / staff | người gửi và staff đọc; staff truy vấn theo `status` | Cho phép |
| R-21 | `challengeSubmissions` | user | đọc thẻ của người khác; truy vấn theo `status` | Cấm |
| R-22 | `challengeSubmissions` | staff | `pending → approved`; `pending → rejected` có lý do | Cho phép |
| R-22 | `challengeSubmissions` | user / staff | user tự duyệt; từ chối không lý do; sửa tên khi duyệt; `reviewedBy` người khác; duyệt lại thẻ đã xử lý | Cấm |
| R-23 | `challengeSubmissions` | user | rút lại thẻ `pending` của mình | Cho phép |
| R-23 | `challengeSubmissions` | user | rút thẻ người khác; rút thẻ đã xử lý | Cấm |
| R-24 | `users/{uid}/inbox` | staff / user | staff tạo tin; chủ đọc, đánh dấu đã đọc, xoá | Cho phép |
| R-24 | `users/{uid}/inbox` | user / staff | user tự tạo tin; `kind` lạ; staff đọc hộp thư người khác; chủ sửa nội dung | Cấm |
| R-25 | `announcements` | staff / user | staff gửi, xoá; user đọc | Cho phép |
| R-25 | `announcements` | user / staff | chưa đăng nhập đọc; user gửi; `authorUid` người khác; nội dung rỗng; sửa; user xoá | Cấm |
| R-26 | `users` | staff | đọc hồ sơ người khác | Cho phép |
| R-26 | `users` | user / staff / admin | user đọc hồ sơ staff; staff đổi vai trò; tự nâng vai trò; admin đổi vai trò của mình; vai trò lạ | Cấm |
| R-27 | `users/{uid}/private/onboarding` | user | chủ ghi và đọc; bước bỏ qua để null | Cho phép |
| R-27 | `users/{uid}/private/onboarding` | user | người khác đọc / ghi; mức ngại 9; 3 mục tiêu; giá trị lạ; trường thêm (email) | Cấm |
| R-28 | `users/{uid}/reports` | user | chủ ghi metadata tuần, ghi đè khi lưu lại, đọc, xoá | Cho phép |
| R-28 | `users/{uid}/reports` | user | người khác đọc / ghi; `isoWeek` khác id; tên file khác; `sizeBytes = 0`; thêm trường `url`; `savedAt` giả | Cấm |

| R-29 | 10 collection riêng của người dùng (`notes`, `private/habits`, `private/settings`, `private/onboarding`, `challengeProgress`, `customChallenges`, `groups`, `sharedStreaks`, `reports`, `stickers`) | user (chủ) | chủ đọc nốt của mình | Cho phép |
| R-29 | như trên | staff / admin | đọc, ghi, xoá từng tài liệu; truy vấn cả `notes` của người khác | Cấm |
| R-30 | `users/{uid}/sharedStreaks` | user (chủ) | tạo thẻ chuỗi hợp lệ, đọc, xoá | Cho phép |
| R-30 | `users/{uid}/sharedStreaks` | user | sửa thẻ đã tạo; `streak` là chuỗi; thêm trường lạ; ảnh > 850 000 ký tự; thiếu `createdAt`; người khác đọc / tạo | Cấm |

Kết quả lần chạy gần nhất (11/11/2026): 30/30 pass (`evidence/firestore/rules-tests.txt`).
