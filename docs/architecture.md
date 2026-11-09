# Kiến trúc app Nốt (Lab 3)

Đầu ra của Stage 2 (Architect). Tài liệu này mô tả app mobile; kiến trúc cả hệ thống cho Final Assignment (web admin, `packages/core/`, AI) ở [`system-architecture.md`](system-architecture.md). Ánh xạ thiết kế Lab 2 sang code ở [`design-traceability.md`](design-traceability.md).

## 1. Nguyên tắc

- **MVVM + Riverpod 3.** View (`screens/`, `widgets/`) → ViewModel (`viewmodels/`) → Service (`services/`) ← hiện thực Firebase (`firebase/`). Phụ thuộc chỉ đi xuống; một lớp không bao giờ import lớp phía trên.
- **Widget không gọi SDK.** Không widget nào dùng `FirebaseAuth.instance`, `FirebaseFirestore.instance`, `FirebaseAnalytics.instance`, `http`… Mọi lời gọi ra ngoài đi qua một interface trong `services/`.
- **Logic nghiệp vụ nằm ngoài `build()`.** Lọc, đếm, gom nhóm theo ngày, kiểm tra dữ liệu nằm ở ViewModel hoặc service. `build()` chỉ đọc state và vẽ.
- **Mỗi màn tải dữ liệu có state tường minh** `ViewState<T>` (sealed: `Loading`, `Empty`, `Failure`, `Data`), do ViewModel sở hữu.
- **Service được inject.** Mỗi interface có một `Provider` khai báo trong `services/`. Hiện thực Firebase được gắn vào ở `main.dart` (composition root) bằng `ProviderScope(overrides: …)`. Test gắn bản fake theo cùng cách.
- **Không có trạng thái toàn cục thay đổi được.** Không `setState` cho state dùng chung, không singleton đọc từ widget.
- **Design system nằm một chỗ** (`lib/theme/`). Widget đọc màu, chữ, khoảng cách từ theme; mã màu, cỡ chữ hay padding viết cứng trong màn hình là lỗi.

## 2. Cấu trúc thư mục

Đi theo cấu trúc gợi ý của đề (mục 5), thêm `router/` cho go_router.

```text
lib/
├── main.dart          Composition root: khởi tạo Firebase, gắn hiện thực service vào ProviderScope, runApp
├── app.dart           MaterialApp.router: theme, locale vi, router
├── router/            Đường dẫn, GoRouter (redirect theo trạng thái đăng nhập), shell 4 tab
├── theme/             Token Lab 2: ColorScheme, TextTheme, AppColors, AppSpace, AppRadius, AppElevation, AppSize
├── models/            Dữ liệu thuần Dart, không phụ thuộc Flutter/Firebase: Note, Mood, NoteType, Challenge…
├── services/          Interface (abstract) + Provider của từng service; ViewModel chỉ biết tới lớp này
├── firebase/          Hiện thực service bằng Firebase SDK (Auth, Firestore, FCM, Analytics, Crashlytics, Remote Config)
├── viewmodels/        Notifier của Riverpod, mỗi màn một ViewModel; ViewState<T> dùng chung
├── screens/           Một thư mục mỗi màn S01–S12; chỉ dựng UI từ state của ViewModel
├── widgets/           Component Lab 2 dùng lại (nút, ô nhập, tờ nốt, thanh tab, dialog, trạng thái…)
└── utils/             Hàm thuần dùng chung: định dạng ngày tiếng Việt, kiểm tra dữ liệu nhập

assets/mascot/         SVG Tụi Nốt (8 trạng thái), chép từ repo Lab 2
test/                  Test theo cùng cây thư mục; test/support/ chứa fake service và helper
e2e_test/              (Stage 6) bộ test ARTEMIS bằng pytest
firebase/              Rules, index, Remote Config defaults, test rules trên Emulator
```

Quy tắc import giữa các thư mục (được kiểm tra khi review code):

| Thư mục | Được import | Không được import |
|---|---|---|
| `models/` | `dart:*` | mọi thư mục khác, Flutter, Firebase |
| `services/` | `models/` | `firebase/`, `viewmodels/`, `screens/`, `widgets/` |
| `firebase/` | `services/`, `models/`, Firebase SDK | `viewmodels/`, `screens/`, `widgets/` |
| `viewmodels/` | `services/`, `models/`, `utils/` | `firebase/`, `screens/`, `widgets/`, Firebase SDK |
| `widgets/` | `theme/`, `models/`, `utils/` | `services/`, `firebase/`, `viewmodels/` |
| `screens/` | `viewmodels/`, `widgets/`, `theme/`, `models/`, `router/` | `services/`, `firebase/`, Firebase SDK |
| `main.dart` | tất cả (chỉ để lắp ráp) | — |

## 3. Sơ đồ lớp

```mermaid
flowchart TD
  subgraph View
    SCR["screens/<br/>S01 … S12"]
    WID["widgets/<br/>component Lab 2"]
    TH["theme/<br/>token Lab 2"]
  end
  VM["viewmodels/<br/>Notifier + ViewState&lt;T&gt;"]
  SV["services/<br/>interface + Provider"]
  FB["firebase/<br/>hiện thực bằng SDK"]
  MD["models/<br/>Dart thuần"]
  SDK[("Firebase SDK<br/>Auth · Firestore · FCM<br/>Analytics · Crashlytics · Remote Config")]
  MAIN["main.dart<br/>composition root"]

  SCR --> WID --> TH
  SCR --> VM
  VM --> SV
  FB -. implements .-> SV
  FB --> SDK
  SV --> MD
  VM --> MD
  WID --> MD
  MAIN -. overrides providers .-> FB
```

`firebase/` trỏ lên `services/` vì nó *hiện thực* interface ở đó, không phải gọi ngược lên. ViewModel không biết Firebase tồn tại, nên test ViewModel chỉ cần một fake service.

## 4. Luồng dữ liệu: F1 Ghi nốt buổi tối

Từ lúc chạm "Lưu vào hũ" ở `S03c` tới khi thấy `S04`. Đây cũng là đoạn đo tiêu chí thành công "dưới 30 giây".

```mermaid
sequenceDiagram
  actor U as Minh
  participant S3 as NoteComposerScreen (S03)
  participant VM as NoteComposerViewModel
  participant NR as NoteRepository
  participant FS as Firestore (offline cache)
  participant AN as AnalyticsService
  participant S4 as NoteSavedScreen (S04)

  U->>S3: chọn tâm trạng, chip "Đi bộ", bấm Lưu vào hũ
  S3->>VM: save()
  VM->>VM: kiểm tra: có tâm trạng, tiêu đề 1–120 ký tự, nhật ký ≤ 2000
  VM->>VM: state = saving (nút Loading)
  VM->>NR: add(NoteDraft)
  NR->>FS: users/{uid}/notes.add({type, mood, title, body, createdAt})
  FS-->>NR: ghi vào cache ngay (hasPendingWrites = true khi offline)
  NR-->>VM: SavedNote(id, pendingSync)
  VM->>AN: logEvent(note_saved, {mood, note_type, has_journal, duration_ms})
  VM-->>S3: state = saved(id, pendingSync)
  S3->>S4: context.go('/note/saved/:id')
  S4->>S4: NoteSavedViewModel đọc nốt + số nốt tháng, Remote Config monthly_milestone
  S4-->>U: "Đã vào hũ!" (+ banner Offline nếu pendingSync)
```

Khi Firestore trả lỗi quyền (`permission-denied`) hoặc lỗi khác, `NoteRepository` ném `AppException`; ViewModel chuyển state về `editing` với thông báo lỗi, ghi lỗi non-fatal qua `CrashReporter`, và giữ nguyên nháp.

## 5. ViewModel và service

| ViewModel | Màn | State | Service dùng |
|---|---|---|---|
| `AuthViewModel` | S01, redirect của router | `AuthState` (signedOut, signingIn, signedIn, failure) | `AuthService`, `UserRepository`, `AnalyticsService`, `CrashReporter`, `MessagingService` |
| `TodayViewModel` | S02 | `ViewState<TodaySummary>` | `NoteRepository`, `DraftStore`, `Clock` |
| `NoteComposerViewModel` | S03 | `NoteComposerState` (bước, tâm trạng, tiêu đề, nhật ký, saving, lỗi) | `NoteRepository`, `DraftStore`, `RemoteConfigService`, `AnalyticsService`, `CrashReporter`, `Clock` |
| `NoteSavedViewModel` | S04 | `ViewState<SavedNoteSummary>` | `NoteRepository`, `RemoteConfigService` |
| `JarViewModel` | S05 | `ViewState<JarData>` (nốt, số nốt tháng, nhãn dán, phân trang) | `NoteRepository`, `Clock`, `AnalyticsService` |
| `NoteDeleter` | S06 → S05 | `PendingDelete` (nốt chờ xoá, lỗi xoá) | `NoteRepository` |
| `NoteDetailViewModel` | S06 | `NoteDetailState` (`ViewState<Note>` + chế độ sửa, ô nhập, đang lưu) | `NoteRepository`, `AnalyticsService` |
| `ChallengesViewModel` | S07 | `ViewState<List<DeckCard>>` (dựng bằng hàm thuần `ChallengeDeck`) | `ChallengeRepository`, `NoteRepository` (tâm trạng hôm qua), `Clock`, `AnalyticsService` |
| `ChallengeDetailViewModel` | S08 | `ChallengeDetailState` (`ViewState<Challenge>` + mức hồi hộp, số phút, đang lưu) | `ChallengeRepository`, `NoteRepository`, `Clock`, `AnalyticsService` |
| `SelfControlViewModel` | S09 | `SelfControlState` (`ViewState<SelfControlSummary>` + khoá, đang lưu) | `NoteRepository`, `HabitRepository`, `SettingsRepository`, `LocalAuthService`, `ScreenGuard`, `Clock` |
| `BreathingViewModel` | S10 | `BreathingState` (kiểu thở, giây đã thở, màn sau khi thở) | `NoteRepository` (chỉ sau khi thở), `ScreenGuard`, `Clock` |
| `JourneyViewModel` | S11a/b/c | `JourneyState` (`ViewState<JourneyData>` cho Thống kê / Lịch, `ViewState<List<PathStage>>` cho Con đường, khoảng biểu đồ, tháng đang xem, dialog P6) | `NoteRepository`, `ChallengeRepository`, `Clock`, `JourneyStats` (hàm thuần trong `utils/`) |
| `SettingsViewModel` | S12 | `SettingsState` (`ViewState<UserSettings>` + đang xác thực) | `SettingsRepository`, `LocalAuthService`; Stage 5: `MessagingService`, `AnalyticsService` (đăng xuất ở `AuthViewModel`) |
| `FirebaseDemoViewModel` | S12 khu demo | `FirebaseDemoState` (thông báo đã nhận, giá trị RC) | `NotificationInbox`, `RemoteConfigService`, `CrashReporter` |

| Service (interface) | Hiện thực | Việc làm |
|---|---|---|
| `AuthService` | `FirebaseAuthService` | Google Sign-In, email/mật khẩu, đăng xuất, luồng trạng thái đăng nhập |
| `UserRepository` | `FirestoreUserRepository` | `users/{uid}` (tạo lần đầu với `role = user`, cài đặt) |
| `NoteRepository` | `FirestoreNoteRepository` | `users/{uid}/notes`: theo dõi nốt từ một ngày, đọc theo trang, đếm theo khoảng ngày, thêm nốt; nhãn dán tháng `users/{uid}/stickers` |
| `ChallengeRepository` | `FirestoreChallengeRepository` | Đọc kho `challenges` (chỉ đọc); tiến độ `users/{uid}/challengeProgress/{topic}` (`level`, `completed`) |
| `HabitRepository`, `SettingsRepository` | `FirestoreHabitRepository`, `FirestoreSettingsRepository` | `users/{uid}/private/habits` (thói quen muốn bớt), `users/{uid}/private/settings` (Giờ tỉnh, khoá Tự chủ; S12 thêm giờ nhắc) |
| `NudgeService` | `LocalNudgeService` (`flutter_local_notifications`, `timezone`) | Lời nhắc trên máy (`Nudge`): "Nhắc ghi nốt buổi tối" mỗi ngày lúc giờ đã chọn (chạm vào mở S03a) và "Giờ tỉnh" lúc bắt đầu khung giờ (chạm vào mở S09). `nudgeSyncProvider` theo dõi cài đặt để hẹn lại hoặc huỷ; đăng xuất thì huỷ hết |
| `DraftStore` | `PrefsDraftStore` (`shared_preferences`) | Nháp S03 trên máy; xoá khi đăng xuất |
| `AnalyticsService` | `FirebaseAnalyticsService` | Sự kiện theo `analytics-plan.md`, `setUserId` sau đăng nhập |
| `CrashReporter` | `FirebaseCrashReporter` | Lỗi non-fatal, crash thử, user ID, custom key |
| `RemoteConfigService` | `InAppRemoteConfig` (Stage 4, giá trị mặc định) → `FirebaseRemoteConfigService` (Stage 5) | Giá trị mặc định trong app, fetch + activate, lắng nghe cập nhật realtime |
| `MessagingService`, `NotificationInbox` | FCM + `flutter_local_notifications` | Xin quyền, nhận ở 3 trạng thái app, lưu danh sách, điều hướng khi chạm |
| `LocalAuthService` | `DeviceLocalAuthService` (`local_auth`) | Mở khoá phần Tự chủ bằng vân tay, khuôn mặt hoặc mã máy |
| `ScreenGuard` | `MethodChannelScreenGuard` (kênh `lab03/window` trong `MainActivity.kt`) | `FLAG_SECURE` ở S09, giữ màn hình sáng ở S10 |
| `Clock` | `SystemClock` | Giờ hiện tại (test dùng giờ cố định) |

Đã có: `AuthService`, `UserRepository`, `AuthViewModel` (Stage 3); `NoteRepository`, `DraftStore`, `Clock`, `RemoteConfigService` (giá trị mặc định), `TodayViewModel`, `NoteComposerViewModel`, `NoteSavedViewModel` (Stage 4, F1); `JarViewModel`, `NoteDetailViewModel`, `NoteDeleter` (Stage 4, P4/P5); `HabitRepository`, `SettingsRepository`, `LocalAuthService`, `ScreenGuard`, `SelfControlViewModel`, `BreathingViewModel` (Stage 4, F2); `ChallengeRepository`, `ChallengesViewModel`, `ChallengeDetailViewModel` (Stage 4, F3); `ReportService`, `StorageService`, `JourneyViewModel`, `WeeklyReportViewModel` (Stage 4, S11); `SettingsViewModel` (Stage 4, S12). Các dòng còn lại được dựng ở Stage 4–5.

`PrefsDraftStore` nằm trong `firebase/` dù không dùng Firebase: thư mục này là nơi duy nhất được gọi SDK bên ngoài (Firebase, `shared_preferences`), nên quy tắc import ở mục 2 vẫn giữ nguyên.

**Android:** `MainActivity` kế thừa `FlutterFragmentActivity` vì `local_auth` cần hộp xác thực sinh trắc học. `LaunchTheme` vẫn là theme mặc định của Flutter; tài liệu `local_auth_android` khuyên dùng `Theme.AppCompat` để tránh lỗi trên Android 8 trở xuống, nên trên các máy đó hãy kiểm tra lại nút Mở khoá.

**Xoá có hoàn tác:** `NoteDeleter` (không gắn với màn nào) ẩn nốt ngay, giữ hẹn giờ 5 giây và chỉ gọi `NoteRepository.delete` khi hết giờ mà người dùng không bấm Hoàn tác. Nó nằm ngoài ViewModel của S06 vì S06 đã đóng khi hẹn giờ chạy; `JarViewModel` nghe nó để ẩn và hiện lại nốt trong lưới. Nếu app bị tắt trong 5 giây đó thì nốt không bị xoá.

**Ghi khi offline:** `FirestoreNoteRepository.add` gửi lệnh ghi rồi chờ server tối đa 2 giây. Quá thời gian thì trả nốt với `pendingSync = true` (lệnh ghi đã nằm trong bộ nhớ đệm, Firestore tự gửi lại khi có mạng), để S03 không treo khi mất mạng. Ngày tạo nốt là giờ trên máy, không dùng `serverTimestamp`, vì giá trị server là `null` cho tới khi đồng bộ và nốt offline sẽ không hiện trong truy vấn theo ngày.

**Khởi tạo Firebase** (`firebase/firebase_bootstrap.dart`): `main.dart` gọi `initFirebase()` trước `runApp`. Chạy với `--dart-define=USE_FIREBASE_EMULATOR=true` thì Auth và Firestore trỏ vào Emulator của `firebase/` (máy `10.0.2.2`, đổi bằng `FIREBASE_EMULATOR_HOST`). Cấu hình project nằm ở `lib/firebase_options.dart`, do `flutterfire configure` sinh ra.

## 6. Design system trong code

| Lab 2 | Code |
|---|---|
| Color variables | `theme/app_colors.dart`: `ColorScheme` (vai trò M3) + `AppColors` (`ThemeExtension`) cho màu riêng (tâm trạng, loại nốt, biểu đồ, `success`, `warning`…) |
| Text Styles | `theme/app_typography.dart`: `TextTheme` theo bảng handout 1.2 + `AppTextStyles` (`ThemeExtension`) cho 4 kiểu không có trong M3 |
| Size, radius, elevation | `theme/app_tokens.dart`: `AppSpace`, `AppRadius`, `AppElevation`, `AppSize` |
| Component theme | `theme/app_theme.dart`: nút cao 48 / rộng ≥ 64, `AppBar` 48, `NavigationBar` 64, `Switch` tắt màu `switch-off`, `SegmentedButton` 48, `materialTapTargetSize.padded` |
| Component | `widgets/`, bảng đầy đủ ở `design-traceability.md` mục 3 |

Cách đọc token trong widget: `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`, `AppColors.of(context)`, `AppTextStyles.of(context)`, hằng `AppSpace.*` / `AppRadius.*`.

Font Be Vietnam Pro được gắn qua tham số `fontBuilder` của `AppTheme.light()`: app thật truyền `GoogleFonts.beVietnamPro`, test dùng font mặc định để không gọi mạng.

Accessibility (checklist Lab 2): vùng chạm ≥ 48 dp do theme và kích thước component đảm bảo; chữ nội dung ≥ 14 sp (`bodySmall` trở lên); tâm trạng luôn có màu + mặt mascot + chữ; widget chính có `Semantics` label (ARTEMIS đọc cây accessibility trước). Kiểm tra bố cục ở 360 dp và 412 dp bằng widget test.

## 7. Điều hướng

`router/app_router.dart` dựng `GoRouter` trong một Provider. Bốn tab nằm trong `StatefulShellRoute.indexedStack`; màn lồng là route cấp cao để che thanh tab. Bảng route ở `design-traceability.md` mục 1.

- **Redirect theo đăng nhập (Stage 3):** chưa đăng nhập → `/welcome?next=<đích>`; đã đăng nhập mà ở `/welcome` → `next` hoặc `/today`. Router lắng nghe `AuthService.authStateChanges()` qua `refreshListenable`.
- **Back:** tab khác Hôm nay → về Hôm nay; ở Hôm nay → thoát app (theo handout mục 3).
- **Thông báo:** dữ liệu `route` trong payload FCM được map sang đường dẫn (S03, S02, S08) rồi `go()`.

## 8. Xử lý lỗi

- Service đổi lỗi SDK sang `AppException` (`network`, `permissionDenied`, `cancelled`, `notFound`, `unknown`) để ViewModel không phụ thuộc kiểu lỗi Firebase.
- ViewModel đổi `AppException` thành state có thông báo tiếng Việt theo tone Lab 2 ("Chưa tải được hũ. Kiểm tra Wi-Fi rồi thử lại.").
- Lỗi trên đường xử lý thật (lưu nốt) được ghi non-fatal qua `CrashReporter`.
- Tải dữ liệu quá 10 giây → `Failure` (flow T3 → T2).
