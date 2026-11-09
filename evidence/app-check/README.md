# App Check: bằng chứng

Web admin (`/admin/`) bật Firebase App Check với **reCAPTCHA Enterprise**
(Console gọi là **Fraud Defense**, loại chấm điểm, không có ô tick). Code ở
[`web_admin/lib/firebase/app_check.dart`](../../web_admin/lib/firebase/app_check.dart),
cách cài đặt ở [`web_admin/README.md`](../../web_admin/README.md#app-check).
reCAPTCHA v3 "Classic" và v2 đều không dùng được: Firebase đã ngừng nhận v3
Classic cho App Check và chưa bao giờ hỗ trợ v2.

Chụp ngày 10/11/2026, sau Deploy #87 (lần build đầu tiên có
`RECAPTCHA_SITE_KEY`).

| Ảnh | Cho thấy |
|---|---|
| [`apps-registered.webp`](apps-registered.webp) | Firebase → App Check → Apps: `lab03 (web)` **Registered** với Fraud Defense. `lab03 (android)` chưa đăng ký (xem phần "Chưa Enforce"). |
| [`firestore-metrics.webp`](firestore-metrics.webp) | App Check → APIs → Cloud Firestore, 7 ngày: **43 request Verified** (bắt đầu từ 10/11, đúng ngày deploy), 641 "outdated client", **0 unknown origin, 0 invalid**. Trạng thái **Monitoring**. |
| [`fraud-defense-key.webp`](fraud-defense-key.webp) | Google Cloud → Security → Fraud Defense → Keys: key Website `Not PRM web App Check` cho `prm393-not-lab3.web.app` và `prm393-not-lab3.firebaseapp.com`. |
| [`admin-dashboard.webp`](admin-dashboard.webp) | Web admin vẫn đăng nhập (vai trò Admin) và đọc Firestore bình thường khi App Check đã bật. |

## Đọc số liệu Firestore

- **Verified**: request có token App Check hợp lệ, tức là từ web admin.
- **Outdated client**: request từ client chưa cài App Check SDK, ở đây là app
  Android (và bản web app ở `/`). App Check cho mobile nằm ở nhánh `feat/ai`
  (Play Integrity, debug provider cho máy ảo), chưa merge.
- **Unknown origin / invalid = 0**: không có request giả mạo hay token sai.

## Chưa Enforce

Firestore đang ở chế độ **Monitoring**: App Check ghi nhận nhưng chưa chặn.
Enforce lúc này sẽ chặn 94% request (app Android), nên chỉ bật khi:

1. `feat/ai` đã merge và `lab03 (android)` đăng ký Play Integrity (cộng debug
   token cho máy ảo);
2. tab APIs cho thấy gần như mọi request là Verified.

Thiết kế ở [`docs/system-architecture.md`](../../docs/system-architecture.md)
ghi "Enforced on Firestore and AI Logic" là trạng thái đích sau hai bước trên.
