# Nốt · Web admin

Web admin cho **staff** và **admin** của Nốt (PRM393 Final Assignment). Cùng
project Firebase `prm393-not-lab3`, cùng Firestore và cùng design system Lab 2
với app mobile (`packages/core`, package `not_core`). Không có server riêng:
quyền do Security Rules (`firebase/firestore.rules`) quyết định.

Bản deploy: `https://prm393-not-lab3.web.app/admin/` (workflow `Deploy` build
và chép vào `build/web/admin` khi merge vào `main`).

## Màn hình

| Màn | Việc chính | Ghi vào |
|---|---|---|
| Đăng nhập | Google Sign-In; tài khoản `role = user` bị từ chối kèm lời giải thích | `users/{uid}` (hồ sơ `role = user` khi đăng nhập lần đầu) |
| Tổng quan | 5 con số từ truy vấn `count()` và 2 biểu đồ cột (fl_chart) | — |
| Kho thẻ | Tìm, lọc chủ đề, thêm, sửa, lưu trữ / khôi phục thẻ mà app đọc | `challenges/{id}` |
| Hàng chờ duyệt | Duyệt (chọn cấp) hoặc từ chối kèm lý do thẻ người dùng gửi; app cập nhật ngay | `challengeSubmissions/{id}`, `challenges/cm-{id}`, `users/{uid}/inbox/{id}` (một batch) |
| Thông báo | Gửi thông báo tới hộp thư của mọi người dùng app | `announcements/{id}` |
| Người dùng (chỉ admin) | Đổi vai trò user / staff / admin; không đổi được vai trò của chính mình | `users/{uid}.role` |

Mỗi màn có trạng thái đang tải, trống và lỗi (mascot Tụi Nốt). Bố cục màn rộng:
NavigationRail bên trái, nội dung tối đa 1200 px; dưới 900 px thanh điều hướng
thu gọn chỉ còn icon.

## Kiến trúc

MVVM như app mobile: `screens/` (View) → `viewmodels/` (Riverpod) →
`services/admin_services.dart` (giao diện) → hiện thực Firebase ở `firebase/`
và repository Firestore dùng chung ở `package:not_core`. Remote Config
`challenge_submissions_enabled` (cùng cờ với app) hiện cảnh báo ở hàng chờ khi
app đang tắt việc gửi thẻ. Analytics ghi `admin_sign_in`, `admin_access_denied`,
`admin_card_saved`, `admin_card_archived`, `admin_submission_reviewed`,
`admin_announcement_posted`, `admin_role_changed` (tham số không có dữ liệu cá
nhân).

## Chạy

```bash
cd web_admin
flutter pub get
flutter run -d chrome                     # project thật
```

Chạy với Emulator (không đụng dữ liệu thật):

```bash
cd firebase
npm run emulators                          # cửa sổ 1 (cần JDK 17+)
npm run seed:emulator                      # nạp kho thẻ
cd ../web_admin
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATOR=true
```

Bản Emulator có thêm ô "Tài khoản thử trên Emulator" (email + mật khẩu) vì
cửa sổ Google của Auth Emulator không chạy trong mọi trình duyệt nhúng. Tạo tài
khoản trong Emulator UI (`http://localhost:4000/auth`), rồi cấp vai trò:

```bash
cd firebase
npm run role:emulator -- staff@example.test admin
npm run seed:submissions -- user@example.test   # thêm 3 thẻ chờ duyệt mẫu
```

## App Check

Web admin bật App Check (reCAPTCHA v3) cho Firestore khi build có site key.
Không có key thì chạy bình thường, chỉ không có App Check; bản Emulator luôn
bỏ qua App Check.

1. Firebase Console → App Check → Apps → web app → đăng ký **reCAPTCHA v3**
   (tạo key ở Google reCAPTCHA admin, domain `prm393-not-lab3.web.app`,
   `prm393-not-lab3.firebaseapp.com`; dán secret key vào Console).
2. GitHub → Settings → Secrets and variables → Actions → **Variables** → thêm
   `RECAPTCHA_SITE_KEY` = site key. Workflow Deploy truyền nó vào build.
3. Chạy trên máy với Firebase thật: Console → App Check → web app → Manage
   debug tokens → thêm token, rồi

   ```bash
   flutter run -d chrome --dart-define=APP_CHECK_DEBUG_TOKEN=<token>
   ```

4. Xem tab App Check → Firestore: khi gần như mọi request là "Verified" thì
   bấm **Enforce**. Trước khi Enforce, request không có token vẫn qua.

## Admin đầu tiên

Rules chỉ cho admin đổi vai trò, nên admin đầu tiên phải đặt bằng quyền quản
trị: Firebase Console → Firestore → `users/{uid}` → sửa `role` thành `admin`,
hoặc chạy `npm run role -- <email> admin` với service account (giữ key ngoài
repo).

## Test

```bash
flutter analyze
flutter test        # phiên đăng nhập, từ chối sai vai trò, bộ lọc, thứ tự thẻ
```
