# Bàn giao Stage 5 · Instrumentation

Ghi chú cho thành viên làm Stage 5: đề yêu cầu gì, code đã có sẵn gì, cần thêm gì và
gắn vào đâu. Đọc cùng `docs/architecture.md` (quy tắc tầng) và mục 6 của đề Lab 3.

## 1. Trạng thái hiện tại (`main`, 02/11/2026)

- Stage 1–4 xong: đủ 12 màn S01–S12 và phần mở rộng Final (Nhóm lần đầu, mốc tháng,
  Viết nhật ký, lời nhắc Giờ tỉnh / buổi tối, Kết nối Discord). 214 test pass.
- App vẫn chạy trên **project giả `demo-prm393`** với Firebase Emulator
  (`lib/firebase_options.dart` là cấu hình tạm). Analytics, Crashlytics, Remote Config
  và FCM **không chạy trên Emulator**, nên việc đầu tiên của Stage 5 là nối project thật.
- Chưa có: `docs/analytics-plan.md`, service Analytics / Crashlytics / Messaging, bản
  Firebase của Remote Config, trung tâm thông báo trong khu demo S12.

## 2. Đề yêu cầu (mục 6, Phụ lục A, checklist nộp bài)

| Phần | Tối thiểu | Bằng chứng nộp |
|---|---|---|
| `docs/analytics-plan.md` | ≥ 7 event phủ: đăng nhập, đăng xuất, hành động chính, mở **từng loại** màn chi tiết, xuất/tải lên file. Dùng tên event khuyến nghị của Firebase khi có (`login`…), còn lại `snake_case`. Mỗi event: trigger, tham số **có kiểu**, câu hỏi sản phẩm nó trả lời. **Không dữ liệu cá nhân** (email, tên) | File trong repo |
| Analytics | Ghi đủ event trong plan kèm tham số; `setUserId` sau khi đăng nhập | Ảnh **DebugView cho từng event** |
| Crashlytics | 1 lỗi non-fatal từ **đường lỗi thật** + 1 crash thử; gắn user ID và ≥ 1 custom key | Ảnh dashboard có cả hai, có key |
| Remote Config | ≥ 2 tham số làm đổi thứ người dùng thấy; có giá trị mặc định trong app; đổi trên console thì app đổi **không cần build lại** | Ảnh trước/sau + giá trị trên console |
| FCM | Nhận ở foreground, background, terminated; xin quyền (Android 13+); **danh sách thông báo đã nhận** trong app; chạm vào mở đúng màn | Tin thử từ console nhận được ở từng trạng thái |
| Khu demo (S12) | Trung tâm thông báo, xuất & tải lên file, giá trị Remote Config, nút test Crashlytics | Thấy được trong app |

Quy tắc chấm (mục 5): **không widget nào gọi SDK trực tiếp** (`FirebaseAnalytics.instance`,
`FirebaseCrashlytics.instance`…). Mọi lời gọi đi qua một service.

## 3. Bước 0 · Nối project Firebase thật

Làm theo mục "Nối project thật" trong `README.md`:

1. Firebase Console: tạo project, bật **Google Analytics**.
2. Authentication: bật **Google** và **Email/Password**. Thêm SHA-1 debug
   (`cd android; ./gradlew signingReport`).
3. Tạo Firestore (`asia-southeast1`) và bật Storage.
4. `flutterfire configure --platforms=android` → ghi đè `lib/firebase_options.dart`, tạo
   `android/app/google-services.json`.
5. Trong `firebase/`: `npx firebase deploy --only firestore:rules,firestore:indexes,storage --project <id>`,
   rồi nạp kho thẻ: đặt `GOOGLE_APPLICATION_CREDENTIALS` trỏ tới khoá service account
   **để ngoài repo**, chạy `npm run seed -- <id>`.
6. Chạy `flutter run` **không** có `--dart-define=USE_FIREBASE_EMULATOR=true`.

Không commit file khoá service account. `google-services.json` và `firebase_options.dart`
của project thật có thể commit (đó là cấu hình client, không phải bí mật).

## 4. Cách thêm một service (theo mẫu có sẵn)

Mẫu tham khảo: `NudgeService` (interface `lib/services/nudge_service.dart`, bản thật
`lib/firebase/local_nudge_service.dart`, bản giả `FakeNudgeService` trong
`test/support/fakes.dart`).

1. Interface + provider ném `UnimplementedError` ở `lib/services/<tên>_service.dart`.
2. Bản Firebase ở `lib/firebase/<tên>.dart` (chỉ tầng này được import SDK).
3. Gắn trong `lib/main.dart` bằng `overrideWithValue(...)` như các service khác.
4. Bản giả trong `test/support/fakes.dart` và thêm vào `TestServices.overrides` trong
   `test/support/pump.dart`, để test không gọi Firebase.
5. ViewModel gọi service qua `ref.read(<tên>ServiceProvider)`.

Package cần thêm: `firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`,
`firebase_messaging`. Crashlytics cần plugin Gradle (`com.google.firebase.crashlytics`)
theo hướng dẫn của FlutterFire.

## 5. Chỗ đã đánh dấu sẵn trong code

Tìm bằng `grep -rn "Stage 5" lib`.

### Analytics (`logEvent`)

| File | Chỗ | Event gợi ý |
|---|---|---|
| `lib/viewmodels/note_composer_view_model.dart` (`save`) | Lưu nốt xong | `note_saved` (`type`, `mood`, `has_body`, `in_group`) — hành động chính |
| `lib/viewmodels/challenge_detail_view_model.dart` (`save`) | Lưu kết quả thử thách | `challenge_completed` (`topic`, `level`, `outcome`, `on_discord`) |
| `lib/viewmodels/self_control_view_model.dart` (`recordStop`) | Ghi một lần tự chủ | `self_control_logged` (`with_habit`) |
| `lib/viewmodels/weekly_report_view_model.dart` | Xuất & tải PDF xong | `export_report` (`week`, `size_kb`) — xuất/tải file |

Chưa đánh dấu, cần thêm để đủ yêu cầu "đăng nhập, đăng xuất, mở từng loại màn chi tiết":

| Chỗ | Event gợi ý |
|---|---|
| `AuthViewModel._afterSignIn` (`lib/viewmodels/auth_view_model.dart`) | `login` (`method`: `google` / `password`) + `setUserId(uid)` |
| `AuthViewModel.signOut` | `sign_out`; xoá user ID |
| `NoteDetailViewModel._load` | `view_note` (`type`) — S06 |
| `ChallengeDetailViewModel._load` | `view_challenge` (`topic`, `level`) — S08 |
| `GroupDetailViewModel` | `view_group` (`group_source`) — S05e |
| `openDiscordRoom` (`lib/screens/discord/discord_launcher.dart`) | `discord_open` (`room`, `source`) — đã có trong spec Discord; gọi qua ViewModel hoặc service, không gọi SDK trong widget |

Không đưa tiêu đề nốt, nội dung nhật ký, tên nhóm do người dùng tự đặt, email vào
tham số.

### Crashlytics (non-fatal từ đường lỗi thật)

| File | Đường lỗi |
|---|---|
| `lib/viewmodels/auth_view_model.dart:130` | Tạo hồ sơ `users/{uid}` thất bại sau khi đăng nhập |
| `lib/viewmodels/note_composer_view_model.dart:235` | Ghi nốt vào nhóm thất bại (nốt đã lưu) |
| `lib/viewmodels/note_deleter.dart:62` | Xoá nốt thất bại |
| `lib/viewmodels/note_detail_view_model.dart:168` | Sửa nốt thất bại |
| `lib/viewmodels/challenge_detail_view_model.dart:218` | Cập nhật tiến độ thử thách thất bại |
| `lib/viewmodels/weekly_report_view_model.dart:78` | Xuất / tải PDF thất bại |

Custom key gợi ý: `screen`, `app_stage`, `is_emulator`. User ID đặt cùng lúc với Analytics.
Crash thử: nút trong khu demo S12 (chỉ hiện ở debug, hoặc sau một dialog xác nhận).

### Remote Config

Interface đã có: `lib/services/remote_config_service.dart`. Hiện chỉ có
`InAppRemoteConfig` (giá trị mặc định). Cần thêm `FirebaseRemoteConfigService` trong
`lib/firebase/`: `setDefaults` bằng đúng các giá trị của `InAppRemoteConfig`,
`fetchAndActivate` khi mở app, lắng nghe `onConfigUpdated` để đổi **không cần build lại**.

Tham số đã dùng trong app (chọn ≥ 2 để chụp trước/sau):

| Khoá | Mặc định | Đổi thì thấy gì |
|---|---|---|
| `monthly_milestone` | 25 | S04: mốc tháng và thanh tiến độ "N/25 nốt" |
| `quick_win_chips` | 6 chip | S03 bước 2: các chip "Hoặc chọn nhanh" |
| `discord_enabled` | `true` | Ẩn/hiện S14, lối vào ở Cài đặt và S05e, thẻ cấp 3 Discord |
| `discord_invite_url` | link mẫu | Link mở ở S14 |
| `discord_channel_map` | `{}` (JSON) | Link riêng từng phòng |
| `discord_greetings` | 2 câu | Câu chào có sẵn ở S08d |

Lưu ý: `remoteConfigServiceProvider` hiện là `Provider` trả giá trị cố định. Để màn hình
đổi ngay khi console đổi, bản Firebase cần báo thay đổi (ví dụ đổi provider thành
`Notifier` hoặc `StreamProvider` phát lại khi `onConfigUpdated`).

### FCM

- Đã có: `NudgeService` dùng `flutter_local_notifications` cho lời nhắc trên máy, kênh
  Android, xin quyền Android 13+ (`requestPermission`), và đường mở màn khi chạm thông báo
  (`openedRoutes` / `launchRoute` trong `lib/app.dart`). FCM nên dùng lại đường mở màn này.
- Cần thêm: `MessagingService` (token, `onMessage`, `onMessageOpenedApp`,
  `getInitialMessage`, handler nền `@pragma('vm:entry-point')`). Ở foreground, FCM không tự
  hiện thông báo: hiện bằng `flutter_local_notifications` (đã có trong project).
- Payload gợi ý: `data.route` (ví dụ `/note/new`, `/challenges/dc-1-1`, `/today`). Router
  đã giữ đích qua đăng nhập bằng `?next=` (flow P7, `lib/router/auth_redirect.dart`).
- **Danh sách thông báo đã nhận**: lưu ở `users/{uid}/notifications` (cần thêm rule) hoặc
  `shared_preferences`; hiện ở khu demo S12 (`lib/screens/settings/settings_screen.dart`,
  nhóm "KHU DEMO FIREBASE"), chạm một dòng thì mở `route` của nó.

## 6. Việc cần làm, theo thứ tự

1. Bước 0 (mục 3): nối project thật, deploy rules, seed kho thẻ.
2. Viết `docs/analytics-plan.md` theo Phụ lục A (bảng Event · Trigger · Parameters (type)
   · Question it answers), ≥ 7 event.
3. `AnalyticsService` + `CrashReporter`; gắn vào các chỗ ở mục 5; `setUserId` sau đăng nhập.
4. `FirebaseRemoteConfigService` + màn hình đổi theo khi console đổi.
5. `MessagingService` + trung tâm thông báo trong khu demo S12.
6. Khu demo S12: thêm dòng xem giá trị Remote Config hiện tại và nút test Crashlytics.
7. Cập nhật `docs/design-traceability.md` (cột trạng thái, deviation nếu khác Figma) và
   `docs/architecture.md` (bảng service).
8. Chụp ảnh bằng chứng (DebugView, Crashlytics, Remote Config trước/sau, FCM 3 trạng thái),
   lưu ở `docs/evidence/stage5/`.

## 7. Quy ước của repo

- Nhánh mới tách từ `main` cho mỗi phần (`feat/analytics`, `feat/fcm`…), mở PR vào `main`.
- Commit **tiếng Anh**, có tiền tố `feat:` / `fix:` / `docs:` / `test:`.
- CI chạy `dart format --set-exit-if-changed .`, `flutter analyze` (info cũng làm fail),
  `flutter test`, rồi build web. Chạy cả ba lệnh trên máy trước khi push.
- Code chú thích bằng tiếng Việt như phần còn lại của repo.
- Bỏ qua nhánh `feat/awake-nudge` (commit còn lại đã vào `main` theo đường khác) và các
  nhánh `dependabot/...`.
