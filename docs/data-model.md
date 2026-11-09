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

Chỉ admin đổi vai trò, không ai đổi vai trò của chính mình. Web admin từ chối
tài khoản `user` với lời giải thích; app không có màn nào riêng cho staff.

## Collection

Chỉ liệt kê collection mà Final thêm hoặc đổi quyền; các collection riêng của
người dùng từ Lab 3 (`notes`, `private/*`, `challengeProgress`, `groups`,
`stickers`, …) giữ nguyên: chỉ chủ sở hữu đọc / ghi.

| Collection | Trường chính (kiểu) | Tạo | Đọc | Sửa | Xoá | Màn dùng |
|---|---|---|---|---|---|---|
| `users/{uid}` | `role` (`user`/`staff`/`admin`), `displayName`, `email`?, `photo`? | Chính mình, `role = user` | Chính mình; staff, admin | Admin: chỉ `role`, không phải của mình. Chủ: chỉ `photo` | — | App: hồ sơ, ảnh đại diện. Web: đăng nhập, Người dùng, Tổng quan |
| `challenges/{id}` | `topic` (`dung_cam`/`van_dong`), `level` (1–10), `order` (0–999), `title` (1–80), `minutes` (1–600), `tip` (≤120), `script` (≤300), `discordRoom`?, `status` (`active`/`archived`), `source` (`seed`/`staff`/`community`), `submissionId`?, `updatedBy`, `updatedAt` | Staff, admin (kèm `updatedBy` = mình, `updatedAt` = giờ server) | Mọi người đã đăng nhập (app ẩn thẻ `archived`) | Staff, admin, cùng điều kiện | — (lưu trữ thay vì xoá) | App: Thử thách, chi tiết thẻ. Web: Kho thẻ, Tổng quan |
| `challengeSubmissions/{id}` | `uid`, `topic`, `title` (1–80), `minutes` (1–600), `tip` (≤120), `customId`?, `status` (`pending`/`approved`/`rejected`), `reason` (≤200), `createdAt`, `reviewedBy`, `reviewedAt`, `challengeId`? | Người dùng, cho chính mình, `status = pending`, `createdAt` = giờ server | Người gửi; staff, admin | Staff, admin: chỉ `pending → approved` hoặc `pending → rejected` (cần `reason`), chỉ các trường duyệt, `reviewedBy` = mình | Người gửi, khi còn `pending` | App: thẻ tự thêm ("Gửi cho mọi người", trạng thái). Web: Hàng chờ duyệt, Tổng quan |
| `users/{uid}/reports/{isoWeek}` | `kind` (`weekly_card`), `isoWeek` (`YYYY-Www`, bằng id), `fileName` (`weekly-{isoWeek}.pdf`), `sizeBytes` (int, 1–5 000 000), `noteCount` (int ≥ 0), `savedAt` = giờ server | Chủ tài khoản | Chủ tài khoản | Chủ tài khoản (ghi đè khi lưu lại cùng tuần) | Chủ tài khoản | App: Thẻ tuần (S11b) hiện "Đã lưu tuần này lúc…". File PDF nằm trên máy, Firestore chỉ giữ metadata (đề Final, mục 4) |
| `users/{uid}/inbox/{id}` | `kind` (`submission_approved`/`submission_rejected`), `title` (1–80), `body` (1–500), `submissionId`?, `read` (bool), `createdAt` | Staff, admin, `read = false`, `createdAt` = giờ server | Chủ hộp thư | Chủ hộp thư: chỉ `read` | Chủ hộp thư | App: hộp thư (chuông). Web: tạo khi duyệt / từ chối |
| `users/{uid}/private/onboarding` | `strangerLevel` (1–4 hoặc null), `habits` (≤ 20), `move` (`it_khi`/`thinh_thoang`/`thuong_xuyen`/null), `freeSlot` (`sang`/`chieu`/`toi`/`khuya`/null), `goals` (≤ 2), `profileLabel` (≤ 30), `planSource` (`ai`/`rules`), `done` (true), `completedAt` | Chủ tài khoản | Chủ tài khoản | Chủ tài khoản, cùng điều kiện | — | App: S13a–g, S12 "Làm lại khảo sát" |
| `announcements/{id}` | `title` (1–80), `body` (1–1000), `authorUid`, `createdAt` | Staff, admin, `authorUid` = mình, `createdAt` = giờ server | Mọi người đã đăng nhập | — | Staff, admin | App: hộp thư. Web: Thông báo, Tổng quan |

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
Lab 3; R-19…R-28 thêm cho Final, mỗi vai trò và collection mới có ít nhất một
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

Kết quả lần chạy gần nhất (10/11/2026): 28/28 pass (`evidence/firestore/rules-tests.txt`).
