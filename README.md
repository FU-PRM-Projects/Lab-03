# Nốt — PRM393 Lab 3

[![CI](https://github.com/FU-PRM-Projects/Lab-03/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/FU-PRM-Projects/Lab-03/actions/workflows/ci.yml)

**Nốt — mỗi ngày một nốt tích cực.** App ghi chú hằng ngày cho sinh viên năm cuối đang kiệt sức: mỗi tối ghi một "chiến thắng nhỏ" vào hũ thay vì nhìn danh sách việc chưa xong. Đây là bản Flutter của thiết kế Lab 2 ([FU-PRM-Projects/prm393-lab2-group9](https://github.com/FU-PRM-Projects/prm393-lab2-group9)), chạy trên Firebase.

- **Persona:** Minh, 22 tuổi, sinh viên năm 4.
- **Tiêu chí thành công:** ghi xong một chiến thắng nhỏ (tâm trạng + 1 chiến thắng) trong dưới 30 giây kể từ khi chạm thông báo buổi tối.
- **Nguồn dữ liệu:** Cloud Firestore (dữ liệu của chính người dùng).
- **Nền tảng:** Android.

## Tiến độ theo stage

| # | Stage | Trạng thái | Đầu ra |
|---|---|---|---|
| 1 | Design traceability | Xong | [`docs/design-traceability.md`](docs/design-traceability.md) |
| 2 | Kiến trúc và theme | Xong | [`docs/architecture.md`](docs/architecture.md), `lib/theme/`, `lib/widgets/`, khung route 12 màn |
| 3 | Firebase và đăng nhập | Đang làm: code xong, chờ project Firebase thật | `lib/services/`, `lib/firebase/`, S01, đăng xuất ở S12 |
| 4 | Tính năng | Đang làm: F1 (S02, S03, S04), Hũ và Chi tiết nốt (S05, S06), F2 (S09, S10), F3 (S07, S08) xong | Đủ 12 màn với mọi trạng thái, xuất và tải PDF |
| 5 | Analytics, Crashlytics, Remote Config, FCM | Chưa làm | `docs/analytics-plan.md` |
| 6 | Test plan và ARTEMIS | Chưa làm | `docs/test-plan.md`, `e2e_test/` |
| 7 | AI code review | Chưa làm | `docs/code-review.md` |
| 8 | Báo cáo, slide, video | Chưa làm | `report/`, `slides/` |

## Chạy app

```sh
flutter pub get
flutter run                 # chọn thiết bị Android đang kết nối
flutter test                # unit + widget test (gồm kiểm tra accessibility ở 360/412 dp)
flutter analyze
```

Ở bản debug và profile, **Cài đặt → Thư viện component (dev)** mở trang `/dev/components` để đối chiếu component với Figma page `05 Components`. Bản release không có route này.

Test Security Rules trên Firebase Emulator: chạy `npm run test:rules` trong `firebase/` (cần Java và Firebase CLI).

Kho thẻ thử thách (`challenges`, chỉ đọc với người dùng) nạp từ `firebase/seed/challenges.json`:

- Emulator: `npm run seed:emulator` trong `firebase/` khi `npm run emulators` đang chạy.
- Project thật: đặt `GOOGLE_APPLICATION_CREDENTIALS` trỏ tới file khoá service account để **ngoài** repo, rồi `npm run seed -- <project-id>`.

### Firebase

`lib/firebase_options.dart` hiện là cấu hình **tạm** cho project giả `demo-prm393`, chỉ chạy được với Emulator:

```sh
cd firebase && npm run emulators          # cửa sổ 1: Auth 9099, Firestore 8080, UI 4000
flutter run --dart-define=USE_FIREBASE_EMULATOR=true   # cửa sổ 2, Android emulator
```

Điện thoại thật thì thêm `--dart-define=FIREBASE_EMULATOR_HOST=<IP máy tính>`. Trên Emulator chỉ đăng nhập bằng email được; Google Sign-In cần project thật.

Nối project thật (một lần, khi đã tạo project trên Firebase Console):

1. `flutterfire configure --platforms=android`: ghi đè `lib/firebase_options.dart` và tạo `android/app/google-services.json`.
2. Console → Authentication: bật **Google** và **Email/Password**.
3. Thêm SHA-1 của debug keystore (`cd android; ./gradlew signingReport`) vào Project settings → Android app.
4. `flutter run` (không cần `--dart-define`).

## Phiên bản

| Thành phần | Phiên bản |
|---|---|
| Flutter | 3.47.4 (stable) · Dart 3.13.3 |
| flutter_riverpod | ^3.4.3 |
| go_router | ^18.1.1 |
| material_ui | ^1.8.0 |
| google_fonts | ^6.3.3 (Be Vietnam Pro) |
| flutter_svg | ^2.3.0 |
| firebase_core · firebase_auth · cloud_firestore | ^5.1.0 · ^7.0.1 · ^7.1.0 |
| google_sign_in | ^7.2.0 |
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
| [`docs/system-architecture.md`](docs/system-architecture.md) | Kiến trúc cả hệ thống cho Final Assignment |

## Công cụ AI đã dùng

| Công cụ | Dùng để làm gì |
|---|---|
| Claude (Claude Code) | Đọc đề Lab 3 và tài liệu Lab 2, viết `design-traceability.md` và `architecture.md`, dựng theme, thư viện widget, khung route và test (Stage 1–2); tầng service Firebase, đăng nhập, redirect và test (Stage 3) |

Danh sách đầy đủ được cập nhật ở mỗi stage. Link video demo sẽ được thêm ở Stage 8.
