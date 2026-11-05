# Kế hoạch Analytics và Crashlytics (Stage 5)

Tài liệu này là đầu ra của Stage 5 cho hai dịch vụ **Google Analytics for Firebase**
và **Crashlytics**: sự kiện nào được ghi, ghi ở đâu, kiểm thử thế nào và những
ràng buộc của môi trường Lab.

Remote Config và FCM cùng thuộc Stage 5 nhưng không nằm trong tài liệu này
(xem §10).

## 1. Hạ tầng hiện có

| Thành phần | Giá trị / trạng thái |
|---|---|
| Firebase project | `prm393-not-lab3` (tên hiển thị "Not - PRM393 Lab 3") |
| Android app | `com.quanphungg.lab03` · App ID `1:1069128102779:android:b151b073a29b1e917203de` |
| Web app | App ID `1:1069128102779:web:4f900912701ead247203de` (hosting `prm393-not-lab3.web.app`) |
| `lib/firebase_options.dart` | Sinh bởi `flutterfire configure` với cả `web` và `android`, không sửa tay |
| `android/app/google-services.json` | Đã tạo |
| Gradle plugin | `com.google.gms.google-services` 4.4.4, `com.google.firebase.crashlytics` 3.0.7 (do `flutterfire configure` thêm) |
| `firebase_analytics` | `^13.0.1` |
| `firebase_crashlytics` | `^6.0.1` |
| Google Analytics property | **Chưa liên kết** — phải làm trong Console (xem §9) |
| Crashlytics | Bật khi báo cáo crash đầu tiên lên dashboard |

Lệnh đã chạy (ghi lại để tái lập):

```sh
firebase projects:create prm393-not-lab3 --display-name "Not - PRM393 Lab 3"
flutter pub add firebase_analytics firebase_crashlytics
flutterfire configure --project=prm393-not-lab3 --platforms=android,web \
  --android-package-name=com.quanphungg.lab03
```

## 2. Ràng buộc của môi trường Lab

- **Emulator không hỗ trợ Analytics và Crashlytics.** Tài liệu Firebase
  (Local Emulator Suite) chỉ hỗ trợ Firestore, Realtime Database, Storage,
  Authentication, Cloud Functions, Pub/Sub, Extensions; Analytics, Remote Config
  và Crashlytics chỉ được *mô phỏng* trong Cloud Functions shell, không có
  emulator thật. Vì vậy:
  - Chạy `--dart-define=USE_FIREBASE_EMULATOR=true` thì dùng bản
    `DebugAnalyticsService` / `NoopCrashReporter` (in ra console), không gửi
    lên Google.
  - Muốn xem số liệu thật: chạy app với project thật (không bật emulator).
- **Web chỉ có Analytics, không có Crashlytics.** `firebase_analytics` hỗ trợ
  web nên `screen_view`/sự kiện vẫn lên property; Crashlytics không có bản web
  nên `main.dart` dùng `crashEnabled = !useFirebaseEmulator && !kIsWeb` và
  `NoopCrashReporter` trên web.
- **Không ghi PII và nội dung người dùng.** Không log tiêu đề/nội dung nốt,
  email, tên nhóm. Chỉ log enum, id kỹ thuật, số đếm, thời lượng.
  `uid` chỉ dùng cho `setUserId` và `setUserIdentifier` của Crashlytics.
- **Emulator dùng cùng project id `prm393-not-lab3`** với app (script trong
  `firebase/package.json` đã đổi) để dữ liệu seed khớp namespace của Firestore
  emulator. Test Security Rules vẫn chạy với `demo-prm393` vì tự tạo dữ liệu.
- **Android cần API 24+** và emulator có Google Play (điều kiện của Firebase
  Flutter).
- **Không log từ widget.** Mọi lời gọi đi qua interface trong `services/`
  (quy tắc 1 của `docs/architecture.md`); widget/ViewModel không import
  `firebase_analytics` hay `firebase_crashlytics`.

## 3. Kiến trúc

| File | Nội dung |
|---|---|
| `lib/services/analytics_service.dart` | `AnalyticsService` (interface), `DebugAnalyticsService`, `analyticsServiceProvider` |
| `lib/services/analytics_events.dart` | Hằng số tên sự kiện + tên tham số, tránh gõ sai |
| `lib/services/crash_reporter.dart` | `CrashReporter` (interface), `NoopCrashReporter`, `crashReporterProvider` |
| `lib/firebase/firebase_analytics_service.dart` | Hiện thực bằng `FirebaseAnalytics` |
| `lib/firebase/firebase_crash_reporter.dart` | Hiện thực bằng `FirebaseCrashlytics` |
| `lib/firebase/crash_handlers.dart` | `FlutterError.onError` + `PlatformDispatcher.onError` |
| `lib/router/analytics_observer.dart` | `NavigatorObserver` → `AnalyticsService.logScreen` (giữ router không phụ thuộc SDK) |
| `lib/main.dart` | Gắn handler crash, override provider theo chế độ chạy |
| `lib/firebase/crash_handlers.dart` | `FlutterError.onError` + `PlatformDispatcher.onError` |
| `lib/firebase/firebase_bootstrap.dart` | Chọn host Emulator theo nền tảng (`localhost` cho web, `10.0.2.2` cho Android emulator) |

Hợp đồng tối thiểu:

```dart
abstract interface class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);
  Future<void> logScreen(String screenName);
  Future<void> setUserId(String? uid);
  Future<void> setUserProperty(String name, String? value);
  Future<void> setCollectionEnabled(bool enabled);
}

abstract interface class CrashReporter {
  Future<void> recordError(Object error, StackTrace? stack,
      {String? reason, bool fatal = false});
  Future<String> testCrash(); // trả thông báo cho UI
}
```

Chọn hiện thực trong `main.dart`:

```dart
final useEmulator = useFirebaseEmulator; // --dart-define
...
analyticsServiceProvider.overrideWithValue(
  useEmulator ? const DebugAnalyticsService() : FirebaseAnalyticsService(),
),
crashReporterProvider.overrideWithValue(
  useEmulator ? const NoopCrashReporter() : FirebaseCrashReporter(),
),
```

`DebugAnalyticsService` in `[analytics] <name> {...}` bằng `debugPrint`, để
demo Stage 5 trên emulator vẫn "thấy" sự kiện và test widget không cần plugin.

## 4. Bảng sự kiện

Quy ước: snake_case, ≤ 40 ký tự, tham số ≤ 40 ký tự, giá trị chuỗi ≤ 100 ký tự,
không dùng tiền tố `firebase_`, `google_`, `ga_`. Giá trị bool ghi dạng
`'true'`/`'false'` (Analytics chỉ nhận String và num). Không có tham số nào chứa
tiêu đề/nội dung nốt, email, tên hay tên nhóm.

| # | Sự kiện | Kích hoạt khi | Tham số (kiểu) | Gọi ở | Luồng Lab 2 · tiêu chí | Câu hỏi sản phẩm |
|---|---|---|---|---|---|---|
| 1 | `login` | Đăng nhập xong (Google/email) | `method` (String: `google`, `email`) | `AuthViewModel` | P1 · vào được app lần đầu | Người dùng chọn cách đăng nhập nào? |
| 2 | `logout` | Bấm Đăng xuất | — | `AuthViewModel` | S12 · quyền riêng tư | Bao nhiêu người đăng xuất mỗi tuần? |
| 3 | `note_saved` | Lưu nốt Chiến thắng ở bước 3 | `mood` (String), `note_type` (String), `has_journal` (String bool), `duration_ms` (int) | `NoteComposerViewModel` | F1 · ghi một nốt dưới 30 giây | Bao nhiêu phần trăm nốt được lưu dưới 30 000 ms? |
| 4 | `note_viewed` | Mở chi tiết một nốt (S06) | `note_type` (String) | `NoteDetailViewModel` | F1 · xem lại nốt cũ | Người dùng có quay lại xem nốt đã ghi không? |
| 5 | `challenge_opened` | Mở chi tiết thẻ thử thách (S08) | `challenge_id` (String, id kho), `note_type` (String: chủ đề) | `ChallengeDetailViewModel` | F3 · thử thách | Thẻ nào được mở nhiều nhưng ít được làm xong? |
| 6 | `challenge_completed` | Lưu kết quả thẻ | `challenge_id` (String), `minutes` (int, thẻ vận động) | `ChallengeDetailViewModel` | F3 · hoàn thành thẻ | Tỉ lệ hoàn thành sau khi mở thẻ là bao nhiêu? |
| 7 | `self_control_logged` | Ghi một lần tự chủ | `has_habit` (String bool) | `SelfControlViewModel` | F2 · tự chủ | Người dùng theo dõi thói quen cụ thể hay ghi chung? |
| 8 | `report_exported` | Xuất Thẻ tuần PDF xong | `format` (String: `pdf`) | `WeeklyReportViewModel` | S11b · xuất tệp | Có ai xuất báo cáo tuần không? |
| 9 | `group_viewed` | Mở chi tiết một nhóm lần đầu (S05e) | `group_source` (String: `system`, `user`, `ai_suggested`), `group_idea` (String: ý của Nốt), `note_count` (int) | `GroupDetailViewModel` | Nhóm lần đầu · xem lại tiến bộ | Nhóm nào được mở lại nhiều nhất, và người dùng có quay lại nhóm khi đã có vài nốt không? |
| 10 | `streak_extended` | Nốt đầu tiên trong ngày nối dài chuỗi (S04) | `streak_length` (int), `streak_milestone` (int, 0 khi không chạm mốc) | `NoteSavedViewModel` | F1/F2/F3 · chuỗi ngày | Người dùng có giữ chuỗi ngày không? Mốc nào giữ chân họ? |
| 11 | `streak_shared` | Chia sẻ ảnh chuỗi xong (S02 → màn chia sẻ) | `streak_length` (int), `streak_milestone` (int, 0 khi không chạm mốc), `method` (String: `image`) | `StreakShareViewModel` | F1/F2/F3 · chuỗi ngày | Người dùng có chia sẻ chuỗi ra ngoài không? Mốc nào được chia sẻ nhiều? |
| — | `screen_view` | Đổi màn | `firebase_screen` (String, mẫu route như `/note/saved/:id`) | `appRouterProvider` | mọi luồng | Luồng nào bị bỏ giữa chừng? |

Có 11 sự kiện tuỳ chỉnh (yêu cầu tối thiểu 7) cộng `screen_view`; mỗi loại màn chi tiết có một sự kiện mở riêng (`note_viewed`, `challenge_opened`, `group_viewed`). User ID đặt
bằng `setUserId(uid)` khi đăng nhập hoặc khôi phục phiên, xoá khi đăng xuất.

Giới hạn cần nhớ: tối đa **500 loại sự kiện**, **25 user property**; Crashlytics
giữ **8 non-fatal** gần nhất, **64 custom key** (1 kB/key), log tối đa 64 kB.

## 5. User properties

| Tên | Giá trị | Khi nào |
|---|---|---|
| `has_group` | `'true'` / `'false'` | Sau khi tạo/join/rời nhóm |
| `self_control_enabled` | `'true'` / `'false'` | S13 |
| `notification_enabled` | `'true'` / `'false'` | S12, sau khi xin quyền |

Gắn `setUserId(uid)` sau đăng nhập và `setUserId(null)` khi đăng xuất.

## 6. Crashlytics

Handler trong `main.dart`, đặt **trước** `runApp`:

```dart
// main.dart — bỏ qua Emulator và web (Crashlytics không hỗ trợ web).
final crashEnabled = !useFirebaseEmulator && !kIsWeb;
installCrashHandlers(enabled: crashEnabled);
```

- `CrashReporter.recordError(...)` gọi ở các nhánh lỗi đã bắt (lưu nốt, tải PDF,
  đồng bộ settings) — tương ứng ghi chú ở `docs/architecture.md` §4.
- Custom key: `screen` (route hiện tại), `online` (`'true'`/`'false'`),
  `pending_writes` (số nguyên). Không đặt uid vào message.
- `setUser(uid)` sau đăng nhập; xoá bằng chuỗi rỗng khi đăng xuất.
- Nút **"Thử crash (dev)"** chỉ hiện ở `!kReleaseMode`, đặt trong S12 khu demo,
  gọi `CrashReporter.testCrash()` (record fatal không làm tắt app) để gửi báo
  cáo đầu tiên; trên web/Emulator nó dùng bản no-op và chỉ ghi log.
- Báo cáo fatal của Flutter được gửi ngay; non-fatal gửi kèm fatal kế tiếp hoặc
  lần mở app sau.
- Bản release có `--split-debug-info`/`--obfuscate` phải upload symbol **trước**
  khi crash:

```sh
flutter build appbundle --obfuscate --split-debug-info=build/symbols
firebase crashlytics:symbols:upload \
  --app=1:1069128102779:android:b151b073a29b1e917203de build/symbols
```

## 7. Các bước triển khai

| # | Việc | Xong khi |
|---|---|---|
| 1 | Tạo project + package + `flutterfire configure` | `flutter build apk --debug` chạy được, có `google-services.json` (§1) |
| 2 | Liên kết Google Analytics property trong Console | Analytics → DebugView thấy `screen_view` |
| 3 | Thêm interface + bản debug/noop + provider | `flutter analyze` sạch, test cũ vẫn xanh |
| 4 | Thêm observer vào `appRouterProvider` | Mỗi lần đổi tab/màn thấy `screen_view` (debug log) |
| 5 | Gắn `note_saved` ở F1 (đo `duration_ms`) | Debug log đúng tham số; có test viewmodel |
| 6 | Gắn các sự kiện còn lại theo bảng §4 | Mỗi ViewModel có ít nhất 1 test assert event |
| 7 | Crash handler + `CrashReporter` + nút thử crash | Crash test lên dashboard trong ~5 phút |
| 8 | Test + cập nhật README/architecture | `flutter test`, `flutter analyze` xanh; README Stage 5 = "Đang làm/Xong" |

Ước lượng: mỗi bước 3–7 là một PR nhỏ; bước 1–2 không đụng code.

## 8. Kiểm thử và xác minh

```sh
flutter analyze
flutter test

# Analytics (project thật, bản debug)
adb shell setprop debug.firebase.analytics.app com.quanphungg.lab03
# Console → Analytics → DebugView

# Crashlytics
adb shell setprop log.tag.FirebaseCrashlytics DEBUG
adb logcat -s FirebaseCrashlytics      # "Crashlytics report upload complete" / 204
```

Bằng chứng DebugView cho từng sự kiện: chạy app với `debug.firebase.analytics.app`,
thực hiện từng hành động ở bảng §4, mở **Analytics → DebugView** và chụp dòng sự
kiện cùng bảng tham số (xem ảnh trong `evidence/analytics/`).

Test tự động: thêm `FakeAnalyticsService`/`FakeCrashReporter` vào
`test/support/fakes.dart`, override trong `pumpApp`, assert danh sách event.
Không để test nào gọi plugin thật.

## 9. Việc cần làm trong Firebase Console

1. **Project settings → Integrations → Google Analytics → Link/Create property**
   (bắt buộc để `firebase_analytics` có nơi nhận dữ liệu và để Crashlytics có
   breadcrumb).
2. **Crashlytics**: mở dashboard, làm theo hướng dẫn "Enable Crashlytics";
   dashboard có dữ liệu sau crash thử đầu tiên.
3. (Sau này) **Authentication**: bật Email/Password + Google, thêm SHA-1 debug
   keystore để Google Sign-In chạy trên máy thật.
4. (Nếu deploy) `.firebaserc` đã trỏ `prm393-not-lab3`; test Security Rules vẫn
   dùng `demo-prm393` trong `firebase/package.json` để không cần đăng nhập.

## 10. Remote Config và FCM (đã làm cùng Stage 5)

- **Remote Config**: `lib/firebase/firebase_remote_config_service.dart` hiện thực
  `RemoteConfigService`; mặc định lấy từ `InAppRemoteConfig`, tải thất bại thì dùng
  mặc định. Mẫu tham số: `firebase/remoteconfig.template.json`, đưa lên bằng
  `firebase deploy --only remoteconfig`. S12 khu demo có dòng Remote Config (chạm để tải lại).
- **FCM**: `lib/firebase/firebase_messaging_service.dart`. Xin quyền, nhắc mở cài đặt khi bị
  từ chối, hộp thư lưu thông báo kèm trạng thái nhận (đang mở / nền / đã tắt). Gửi thử bằng
  FCM HTTP v1 tới token in ra log (`[fcm] token`).

## 11. Rủi ro

| Rủi ro | Xử lý |
|---|---|
| Emulator không có Analytics/Crashlytics | Bản debug/noop + ghi rõ trong README; demo thật khi có mạng/project thật |
| Analytics property chưa liên kết → event bị bỏ | Kiểm tra DebugView trước khi instrument hàng loạt |
| Log lỡ chứa nội dung nốt | Chỉ dùng hằng số trong `analytics_events.dart`; review PR theo bảng §4 |
| `note_saved` bị gọi 2 lần (retry/offline) | Chỉ log trong nhánh `success` của ViewModel, test double-tap |
| Quên upload symbol ở bản release | Đưa lệnh vào checklist phát hành, ghi trong README |
