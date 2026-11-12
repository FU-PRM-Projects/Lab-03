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
| [`fraud-defense-key.webp`](fraud-defense-key.webp) | Google Cloud → Security → Fraud Defense → Keys: key Website `Not PRM web App Check` cho `prm393-not-lab3.web.app` và `prm393-not-lab3.firebaseapp.com`, ID là site key (công khai), trạng thái **Protected** (key đã nhận lượt xác minh thật). |
| [`auth-metrics.webp`](auth-metrics.webp) | App Check → APIs → Authentication (preview), 7 ngày: **6 / 20 request Verified** (đăng nhập từ web admin), 14 "unknown origin", 0 invalid. Trạng thái **Monitoring**. |
| [`deploy-run.webp`](deploy-run.webp) | GitHub Actions → Deploy #87 (chạy tay trên `main`, commit `325d560`): build web admin kèm site key và deploy thành công. |
| [`admin-dashboard.webp`](admin-dashboard.webp) | Web admin vẫn đăng nhập (vai trò Admin) và đọc Firestore bình thường khi App Check đã bật. |

## Đọc số liệu Firestore

- **Verified**: request có token App Check hợp lệ, tức là từ web admin.
- **Outdated client**: request từ client chưa cài App Check SDK, ở đây là app
  Android (và bản web app ở `/`). App Check cho mobile nằm ở nhánh `feat/ai`
  (Play Integrity, debug provider cho máy ảo), chưa merge.
- **Unknown origin / invalid = 0**: không có request giả mạo hay token sai.

Với **Authentication**, 14 request "unknown origin" là đăng nhập từ client
không gửi kèm thông tin App Check (app Android và bản web app ở `/`, cùng các
lần làm mới phiên). Số này sẽ chuyển sang Verified khi mobile có App Check.

## Enforce cho Firestore (12/11/2026)

Bật Enforce cho **Cloud Firestore** sau khi:

- `lab03 (android)` đã đăng ký Play Integrity và `lab03 (web)` Fraud Defense
  (tab Apps: cả hai **Registered**);
- bản release cài tay trên Galaxy A70 gọi được Gemini qua Firebase AI Logic (đã
  Enforced từ trước), tức là token Play Integrity hợp lệ.

Hộp xác nhận báo 45% request trong 7 ngày đến từ bản cũ chưa có App Check (và
bản debug dùng để chạy ARTEMIS hôm đó): các request này giờ bị chặn, đúng mục đích.
Unknown origin vẫn là 0.

| Ảnh | Cho thấy |
|---|---|
| [`final-firestore-enforced.png`](final-firestore-enforced.png) | App Check → APIs: **Cloud Firestore Enforced**, Firebase AI Logic Enforced (Basic), Authentication Monitoring |
| [`final-web-admin-after-enforce.png`](final-web-admin-after-enforce.png) | Sau khi Enforce, tải lại web admin: vẫn đọc được vai trò từ Firestore (màn từ chối cho tài khoản `user`, không phải lỗi "Chưa kiểm tra được tài khoản"). Đã che email |
| [`final-mobile-after-enforce.png`](final-mobile-after-enforce.png) | Bản release trên Galaxy A70, mở lại sau khi Enforce: màn Hôm nay đọc được Tường nốt và chuỗi ngày |

Bản **debug** chỉ đọc được Firestore nếu debug token của máy đã đăng ký ở App
Check → Apps → `lab03 (android)` → Manage debug tokens. Chạy lại ARTEMIS bằng bản
debug cần kiểm tra điều này trước.

## Trước khi Enforce (lịch sử)


Firestore đang ở chế độ **Monitoring**: App Check ghi nhận nhưng chưa chặn.
Enforce lúc này sẽ chặn 94% request (app Android), nên chỉ bật khi:

1. `feat/ai` đã merge và `lab03 (android)` đăng ký Play Integrity (cộng debug
   token cho máy ảo);
2. tab APIs cho thấy gần như mọi request là Verified.

Thiết kế ở [`docs/system-architecture.md`](../../docs/system-architecture.md)
ghi "Enforced on Firestore and AI Logic" là trạng thái đích sau hai bước trên.
