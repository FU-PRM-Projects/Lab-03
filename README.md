# Nốt — PRM393 Lab 3

[![CI](https://github.com/FU-PRM-Projects/Lab-03/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/FU-PRM-Projects/Lab-03/actions/workflows/ci.yml)

**Nốt — mỗi ngày một nốt tích cực.** App ghi chú hằng ngày cho sinh viên năm cuối đang kiệt sức: mỗi tối ghi một "chiến thắng nhỏ" vào hũ thay vì nhìn danh sách việc chưa xong. Đây là bản Flutter của thiết kế Lab 2 ([FU-PRM-Projects/prm393-lab2-group9](https://github.com/FU-PRM-Projects/prm393-lab2-group9)), chạy trên Firebase.

- **Persona:** Minh, 22 tuổi, sinh viên năm 4.
- **Tiêu chí thành công:** ghi xong một chiến thắng nhỏ (tâm trạng + 1 chiến thắng) trong dưới 30 giây kể từ khi chạm thông báo buổi tối.
- **Nguồn dữ liệu:** Cloud Firestore (dữ liệu của chính người dùng).
- **Nền tảng:** Android, Web và Discord DM Bot (Rust / Poise).

## Hướng dẫn sử dụng hệ thống

1. **Đăng nhập & Khởi tạo:** Mở ứng dụng **Nốt** (Android hoặc Web tại `https://prm393-not-lab3.web.app`), đăng nhập bằng Google hoặc Email/Mật khẩu.
2. **Ghi Nốt mỗi ngày (Tab Hôm nay & Hũ):**
   - Chọn tâm trạng và ghi lại một **Chiến thắng nhỏ**, **Nhật ký**, **Tự chủ**, hoặc **Thử thách** trong chưa đầy 30 giây.
   - Đính kèm ảnh kỷ niệm, phân loại vào kệ **Nhóm lần đầu**, và xem lại toàn bộ nốt trong **Hũ**.
3. **Thử thách & Tự chủ (Tab Thử thách):**
   - Thực hiện các thẻ thử thách theo cấp độ (*Dũng cảm*, *Vận động*) hoặc tự tạo thẻ riêng.
   - Ghi nhận những lần dừng lại thành công và tập thở ở màn **Tự chủ** (hỗ trợ khoá sinh trắc học/PIN).
4. **Hành trình & Thẻ tuần (Tab Hành trình):**
   - Theo dõi chuỗi ngày (streak), lịch tâm trạng, biểu đồ năng lượng, chia sẻ ảnh thẻ streak hoặc xuất báo cáo **Thẻ tuần (PDF)**.
5. **Kết nối Discord Bot (Remote Agent qua DM):**
   - Nhắn tin riêng (DM) cho **Nốt Bot** trên Discord với lệnh `/connect` (hoặc `!connect`) để nhận mã liên kết 6 ký tự (hiệu lực 10 phút).
   - Trong ứng dụng Nốt, vào **Cài đặt → Cộng đồng → Liên kết Discord** (hoặc **Phòng trò chuyện → Liên kết tài khoản Discord**) và nhập mã 6 ký tự.
   - Hệ thống đảm bảo ràng buộc **1-1**: mỗi tài khoản Nốt chỉ liên kết với duy nhất 1 tài khoản Discord.

## Tiến độ theo stage

| # | Stage | Trạng thái | Đầu ra |
|---|---|---|---|
| 1 | Design traceability | Xong | [`docs/design-traceability.md`](docs/design-traceability.md) |
| 2 | Kiến trúc và theme | Xong | [`docs/architecture.md`](docs/architecture.md), `lib/theme/`, `lib/widgets/`, khung route 12 màn |
| 3 | Firebase và đăng nhập | Xong (code + test; chờ project Firebase thật để chạy Google Sign-In trên máy) | `lib/services/`, `lib/firebase/`, S01, đăng xuất ở S12 |
| 4 | Tính năng | Xong (code + test; chờ chạy thử trên máy với project Firebase thật): đủ 12 màn, 3 flow F1–F3 và các flow phụ, PDF Thẻ tuần lên Storage | Đủ 12 màn với mọi trạng thái, xuất và tải PDF |
| 5 | Analytics, Crashlytics, Remote Config, FCM | Đang làm (Analytics + Crashlytics) | [`docs/analytics-plan.md`](docs/analytics-plan.md) |
| 6 | Test plan và ARTEMIS | Chưa làm | `docs/test-plan.md`, `e2e_test/` |
| 7 | AI code review | Chưa làm | `docs/code-review.md` |
| 8 | Báo cáo, slide, video | Chưa làm | `report/`, `slides/` |

## Chạy app

```sh
flutter pub get
flutter run                 # chọn thiết bị Android đang kết nối
flutter run -d chrome       # bản web (dùng Firebase web app cùng project)
flutter test                # unit + widget test (gồm kiểm tra accessibility ở 360/412 dp)
flutter analyze
```

Ở bản debug và profile, **Cài đặt → Thư viện component (dev)** mở trang `/dev/components` để đối chiếu component với Figma page `05 Components`. Bản release không có route này.

Test Security Rules trên Firebase Emulator: chạy `npm run test:rules` trong `firebase/` (cần Java và Firebase CLI).

Kho thẻ thử thách (`challenges`, chỉ đọc với người dùng) nạp từ `firebase/seed/challenges.json`:

- Emulator: `npm run seed:emulator` trong `firebase/` khi `npm run emulators` đang chạy.
- Thẻ cấp 3 "Chào 1 câu ở phòng chung" mở phòng Discord: link lấy từ Remote Config `discord_invite_url` / `discord_channel_map` (mặc định là link mẫu trong `InAppRemoteConfig`).
- Project thật: đặt `GOOGLE_APPLICATION_CREDENTIALS` trỏ tới file khoá service account để **ngoài** repo, rồi `npm run seed -- <project-id>`.

### Firebase

Project thật: **`prm393-not-lab3`** — Android app `com.quanphungg.lab03` và web app `1:1069128102779:web:4f900912701ead247203de`. `flutterfire configure` đã sinh `lib/firebase_options.dart` (có cả `web` và `android`) và `android/app/google-services.json`; không sửa tay hai file này — cần đổi cấu hình thì chạy lại lệnh đó.

Emulator vẫn dùng được (Auth 9099, Firestore 8080, Storage 9199, UI 4000) và ghi vào cùng project id với app:

```sh
cd firebase && npm run emulators          # cửa sổ 1
flutter run --dart-define=USE_FIREBASE_EMULATOR=true            # Android emulator
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATOR=true  # web (localhost)
```

Điện thoại thật thì thêm `--dart-define=FIREBASE_EMULATOR_HOST=<IP máy tính>`. Trên Emulator chỉ đăng nhập bằng email được; Google Sign-In cần project thật.

**Analytics và Crashlytics không có emulator** (Firebase Emulator Suite không hỗ trợ hai dịch vụ này). Khi chạy `USE_FIREBASE_EMULATOR=true`, app dùng bản ghi log ra console thay vì gửi lên Google; muốn thấy số liệu thì chạy với project thật. Kế hoạch chi tiết ở [`docs/analytics-plan.md`](docs/analytics-plan.md).

#### Dữ liệu demo để test

Emulator mới mở thì trống. Để các màn có dữ liệu mà xem (biểu đồ năng lượng S11b, lịch tâm trạng, thẻ "Nhớ lại lần này nhé" ở S02, kệ Nhóm lần đầu), trong `firebase/`:

1. Mở app, **đăng ký** một tài khoản email (ví dụ `demo@test.dev`).
2. `npm run seed:emulator`: nạp kho thẻ thử thách.
3. `npm run seed:demo -- demo@test.dev`: nạp cho tài khoản đó khoảng 48 ngày nốt có tâm trạng trong 60 ngày gần đây, 3 chiến thắng đáng nhớ và 2 nhóm lần đầu. Ngày tính theo hôm nay; chạy lại thì làm mới đúng các nốt đó, không nhân đôi.

Mặc định tắt Emulator là mất hết dữ liệu. Muốn giữ lại giữa các lần chạy thì dùng `npm run emulators:keep` thay cho `npm run emulators`: dữ liệu lưu vào `firebase/emulator-data/` (đã có trong `.gitignore`) khi dừng bằng **Ctrl+C**, lần sau tự nạp lại. Xoá thư mục đó để về trống.

Console còn phải làm (một lần):

1. **Project settings → Integrations → Google Analytics**: liên kết hoặc tạo property — Analytics không có nơi nhận dữ liệu nếu bỏ qua bước này.
2. **Crashlytics**: mở dashboard và làm theo hướng dẫn; số liệu xuất hiện sau crash thử đầu tiên.
3. **Authentication**: bật **Google** và **Email/Password**.
4. Thêm SHA-1 của debug keystore (`cd android; ./gradlew signingReport`) vào Project settings → Android app để Google Sign-In chạy trên máy thật.

### Discord Bot (`discord_bot/`)

Bot trợ lý viết bằng **Rust** (framework **Poise**), chỉ hoạt động qua tin nhắn riêng (DM) và giao tiếp trực tiếp với Cloud Firestore REST API:

- `src/main.rs`: Khởi tạo bot với `DIRECT_MESSAGES` intent.
- `src/firebase.rs`: Lớp client mỏng gọi Cloud Firestore (`discordConnectCodes` và `discordLinks`).
- `src/commands/`: Các lệnh DM (`/connect`, `/ping`).

Chạy local:

```sh
cd discord_bot
cp .env.example .env        # điền DISCORD_TOKEN và FIREBASE_PROJECT_ID
cargo run
```

Triển khai trên VPS (Dokploy) bằng Docker Compose với file `compose.dokploy.yml`.

## CI/CD

Workflow nằm trong `.github/workflows/`:

| Workflow | Chạy khi | Việc làm |
|---|---|---|
| `ci.yml` | push `main`, mọi PR, bấm tay | format → analyze → test (kèm coverage), build web release, build APK debug, chạy test Security Rules trên Emulator |
| `deploy.yml` | push `main` (đường dẫn liên quan), bấm tay | build web → `firebase deploy` Hosting + Firestore rules/indexes + Storage rules |
| `deploy.yml` (PR) | mọi PR | build web → Hosting preview 7 ngày, URL được comment vào PR |
| `release.yml` | tag `v*`, bấm tay | build AAB `--obfuscate --split-debug-info`, upload symbol lên Crashlytics, lưu AAB/mapping/symbol làm artifact |

Secret duy nhất cần đặt (Settings → Secrets and variables → Actions):

- **`FIREBASE_SERVICE_ACCOUNT`** — JSON của service account thuộc project `prm393-not-lab3`, cấp role **Firebase Develop Admin** (đủ deploy Hosting/rules và upload symbol). Tạo ở Google Cloud Console → IAM & Admin → Service Accounts → Keys → Add key → JSON. Không commit file này.

Khi secret chưa được đặt, `deploy.yml` và `release.yml` chỉ ghi cảnh báo rồi bỏ qua các bước cần quyền; AAB và bản build vẫn được tạo. Bản web công khai ở https://prm393-not-lab3.web.app sau lần deploy đầu tiên.

`ci.yml` pin Flutter **3.47.2** (khớp máy dev). Bản release hiện ký bằng debug key vì `android/app/build.gradle.kts` chưa có `signingConfigs.release` — cần cấu hình chữ ký thật trước khi phát hành lên store.

## Phiên bản

| Thành phần | Phiên bản |
|---|---|
| Flutter | 3.47.2 (stable) · Dart 3.13.2 |
| flutter_riverpod | ^3.4.3 |
| go_router | ^18.1.1 |
| material_ui | ^1.8.0 |
| google_fonts | ^6.3.3 (Be Vietnam Pro) |
| flutter_svg | ^2.3.0 |
| firebase_core · firebase_auth · cloud_firestore | ^5.1.0 · ^7.0.1 · ^7.1.0 |
| firebase_analytics · firebase_crashlytics | ^13.0.1 · ^6.0.1 |
| google_sign_in | ^7.2.0 |
| firebase_storage | ^14.0.1 |
| fl_chart | ^1.3.0 |
| pdf · printing | ^3.13.1 · ^5.15.1 |
| shared_preferences | ^2.5.6 |
| local_auth | ^3.0.2 |
| fake_async (dev) | ^1.3.3 |

Phiên bản chính xác của các gói nằm trong `pubspec.lock`.

## Cấu trúc

MVVM + Riverpod; chi tiết và quy tắc import ở [`docs/architecture.md`](docs/architecture.md).

```text
lib/
├── main.dart     composition root
├── app.dart      MaterialApp.router
├── router/       route, shell 4 tab
├── theme/        token Lab 2 → ThemeData
├── models/       Dart thuần
├── services/     interface service (Stage 3)
├── firebase/     hiện thực Firebase (Stage 3)
├── viewmodels/   Notifier + ViewState<T>
├── screens/      S01–S12
├── widgets/      component Lab 2
└── utils/        hàm thuần
```

## Tài liệu

| Tài liệu | Nội dung |
|---|---|
| [`docs/design-traceability.md`](docs/design-traceability.md) | Màn, flow, component Lab 2 → route, widget, dữ liệu; các thay đổi so với thiết kế |
| [`docs/architecture.md`](docs/architecture.md) | Lớp MVVM, sơ đồ, luồng F1, bảng ViewModel–service |
| [`docs/analytics-plan.md`](docs/analytics-plan.md) | Sự kiện Analytics, Crashlytics, quy ước dữ liệu và kế hoạch Stage 5 |
| [`docs/system-architecture.md`](docs/system-architecture.md) | Kiến trúc cả hệ thống cho Final Assignment |

## Công cụ AI đã dùng

| Công cụ | Dùng để làm gì |
|---|---|
| Claude (Claude Code) | Đọc đề Lab 3 và tài liệu Lab 2, viết `design-traceability.md` và `architecture.md`, dựng theme, thư viện widget, khung route và test (Stage 1–2); tầng service Firebase, đăng nhập, redirect và test (Stage 3) |

Danh sách đầy đủ được cập nhật ở mỗi stage. Link video demo sẽ được thêm ở Stage 8.
