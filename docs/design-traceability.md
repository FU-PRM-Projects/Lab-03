# Design traceability — Nốt (Lab 2 → Lab 3)

Ánh xạ từng màn hình, flow và component của Lab 2 sang route, widget, ViewModel và nguồn dữ liệu trong app Flutter. Đây là đầu ra của Stage 1 (Plan), viết trước khi làm tính năng.

- **Nguồn thiết kế:** repo [FU-PRM-Projects/prm393-lab2-group9](https://github.com/FU-PRM-Projects/prm393-lab2-group9) (commit `6e88d5e`, 24–27/10/2026): `design/DESIGN.md`, `design/screen-spec.md`, `ux/user-flow.md`, `handoff/flutter-handoff.md`; file Figma [PRM393-LAB2-Study-Planner](https://www.figma.com/design/OkTRYkrsoJ0nkluNO4mrHz/PRM393-LAB2-Study-Planner), page `03 Final UI`, section **Final UI · Nốt tích cực (24/10)**.
- **Kiến trúc:** xem [`architecture.md`](architecture.md).
- **Trạng thái:** `Planned` (đã ánh xạ, chưa dựng) · `Skeleton` (có route và màn khung) · `Done` (đủ nội dung, trạng thái và dữ liệu thật) · `Deviation` (khác thiết kế, xem mục 5).

Cột trạng thái được cập nhật ở cuối mỗi stage.

---

## 1. Màn hình → route, widget, ViewModel, dữ liệu

| Mã | Màn hình (Lab 2) | Route | Screen widget | ViewModel | Nguồn dữ liệu | Trạng thái |
|---|---|---|---|---|---|---|
| S01 | Chào mừng & Đăng nhập | `/welcome?next=` | `WelcomeScreen` | `AuthViewModel` | Firebase Auth (Google, email/mật khẩu), tạo `users/{uid}` lần đầu | Done (Stage 3; Google Sign-In cần project thật để chạy trên máy) |
| S02 | Hôm nay (tab 1) | `/today` | `TodayScreen` | `TodayViewModel` | Firestore `users/{uid}/notes` (nốt hôm nay, nốt cũ ngày tệ), nháp trên máy | Done (Stage 4) · Deviation D-14 |
| S03 | Ghi nốt (3 bước `S03a`/`b`/`c`) | `/note/new?step=1..3` | `NoteComposerScreen` | `NoteComposerViewModel` | Firestore `users/{uid}/notes` (ghi), Remote Config `quick_win_chips`, nháp trên máy | Done (Stage 4; Remote Config dùng giá trị mặc định tới Stage 5) |
| S04 | Nốt đã vào hũ | `/note/saved/:id` | `NoteSavedScreen` | `NoteSavedViewModel` | Firestore (nốt vừa lưu, số nốt tháng), `users/{uid}/stickers`, Remote Config `monthly_milestone` | Done (Stage 4) · Deviation D-14 |
| S05 | Hũ & Nhật ký (tab 2) | `/jar` | `JarScreen` | `JarViewModel` | Firestore `users/{uid}/notes` (trang đầu theo dõi trực tiếp, các trang sau 30 nốt/lần), `users/{uid}/stickers` | Done (Stage 4) |
| S06 | Chi tiết nốt | `/jar/:noteId` | `NoteDetailScreen` | `NoteDetailViewModel` | Firestore `users/{uid}/notes/{id}` | Done (Stage 4) · Deviation D-15 |
| S07 | Thử thách (tab 3) | `/challenges` | `ChallengesScreen` | `ChallengesViewModel` | Firestore `challenges` (kho thẻ), `users/{uid}/challengeProgress`, nốt hôm qua (thứ tự chủ đề) | Done (Stage 4) · Deviation D-17 |
| S08 | Chi tiết thử thách | `/challenges/:id` | `ChallengeDetailScreen` | `ChallengeDetailViewModel` | Firestore `challenges/{id}`, ghi `users/{uid}/notes` và `challengeProgress` | Done (Stage 4) · Deviation D-17 |
| S09 | Tự chủ | `/self-control` | `SelfControlScreen` | `SelfControlViewModel` | Firestore `users/{uid}/notes` (đếm tự chủ), `users/{uid}/private/habits`, `users/{uid}/private/settings`; `local_auth`; `FLAG_SECURE` | Done (Stage 4) · Deviation D-16 |
| S10 | Thở 90 giây | `/breathe` | `BreathingScreen` | `BreathingViewModel` | Không gọi mạng khi mở (tiêu chí < 2 giây); ghi nốt khi "Ghi vào hũ"; giữ màn hình sáng khi thở | Done (Stage 4) · Deviation D-16 |
| S11 | Hành trình (tab 4: `S11a` Con đường, `S11b` Thống kê, `S11c` Lịch) | `/journey?tab=path\|stats\|calendar` | `JourneyScreen` | `JourneyViewModel`, `WeeklyReportViewModel` | Firestore `users/{uid}/notes`, `challengeProgress`; PDF Thẻ tuần → Cloud Storage `reports/{uid}/` | Done (Stage 4) · Deviation D-06, D-18 |
| S12 | Cài đặt (+ khu demo Firebase) | `/settings` | `SettingsScreen` | `SettingsViewModel`, `FirebaseDemoViewModel` | Firestore `users/{uid}/private/settings`, `local_auth`; khu demo: Storage (Stage 4), FCM, Remote Config, Crashlytics (Stage 5) | Done (Stage 4: Nhắc nhở, Quyền riêng tư, Tài khoản, Xuất & tải lên PDF); khu demo còn FCM, Remote Config, Crashlytics ở Stage 5 · Deviation D-01, D-19 |

Tab cấp cao giữ đúng Lab 2: Hôm nay, Hũ, Thử thách, Hành trình trong `StatefulShellRoute.indexedStack` (mỗi tab giữ vị trí cuộn). Màn lồng (`S03`, `S04`, `S06`, `S08`, `S09`, `S10`, `S12`) nằm ngoài shell nên không có thanh tab, đúng mục 1.1 của `user-flow.md`.

### 1.1 Dialog, sheet và trạng thái đi kèm

| Lab 2 | Ở màn | Flutter | Trạng thái |
|---|---|---|---|
| Dialog "Giữ nốt đang ghi?" — Bỏ / Giữ nháp | S03 | `showAppDialog(kind: confirmation)` | Done |
| Dialog "Xoá nốt này?" + snackbar Hoàn tác 5 giây | S06 → S05 | `showAppDialog(kind: destructive)` + `SnackBar` 5 giây có "Hoàn tác" (`NoteDeleter`) | Done |
| Dialog "Đăng xuất khỏi Nốt?" | S12 | `showAppDialog(kind: confirmation)` | Done |
| Dialog "Bỏ thay đổi?" | S06 (sửa) | `showAppDialog(kind: confirmation)` | Done |
| Xin quyền thông báo Android 13+ | P1, P8 | `MessagingService.requestPermission()` (dialog hệ thống) | Planned |
| Banner "Offline · đã lưu trên máy" | S02, S04, S05 | `OfflineBanner` | Done |
| Empty state "Hũ còn trống" | S05 | `EmptyState` | Done |
| Loading skeleton "Đang tải lịch năng lượng…" | S05, S11c | `LoadingState.skeleton` | Done |
| Error state "Chưa tải được hũ" + Thử lại | S05, S07, S11 | `ErrorState` | Done |
| Sheet "Kết quả?" (Suôn sẻ / Không như ý) | S08 | `showModalBottomSheet` | Done |
| Sheet "Lúc đó mình đang thấy gì?" | S09 | `showModalBottomSheet` | Done |
| Sheet "Đổi kiểu thở" (4-6, 4-7-8) | S10 | `showModalBottomSheet` | Done |
| Sheet các nốt của một ngày | S11c | `showModalBottomSheet` | Done |
| Thẻ tuần dạng story + "Lưu thẻ tuần (PDF)" | S11b | `WeeklyCardPage` (route toàn màn, `fullscreenDialog`) | Done · Deviation D-06 |
| Dialog gợi ý hỗ trợ (Mệt/Rối 5 ngày liền) | S11 (P6) | `showAppDialog(kind: confirmation)` | Done |

---

## 2. Flow → màn hình → kiểm thử

Mã test case (`TC-xx`) sẽ được gán trong `docs/test-plan.md` ở Stage 6.

| Flow | Màn hình theo thứ tự | Nhánh thay thế / lỗi phải chạy được | Trạng thái |
|---|---|---|---|
| F1 Ghi nốt buổi tối | S02 → S03a → S03b → S03c → S04 → S02 (hoặc thông báo 21:30 → S03a) | Bỏ qua nhật ký; tâm trạng Rối → "Sơ cứu 1 phút"; thoát giữa chừng → dialog Giữ nháp; mất mạng → lưu trên máy + banner | Done (Stage 4) |
| F2 Tự chủ | S02 → S09 → S04 → S02; khó dừng: S09 → S10 → S04 | Đã lỡ lướt → sheet + "Nhận ra cũng là bắt đầu tự chủ"; phần thói quen khoá bằng `local_auth` | Done (Stage 4; bật khoá ở S12 làm cùng S12) |
| F3 Thử thách | S07 → S08 → S04 → S07 | Đổi thẻ dễ hơn; để mai (Back, không trừ gì); Không như ý → "Mình đã mở lời" | Done (Stage 4) |
| P1 Làm quen lần đầu | S01 → (xin quyền thông báo) → S02 | Đăng nhập thất bại / huỷ → SnackBar + Thử lại | Một phần: đăng nhập, huỷ, mất mạng (Stage 3); xin quyền thông báo ở Stage 5 |
| P2 Đăng ký email & quên mật khẩu | S01 (form email) → S02 | Lỗi dưới ô; quên mật khẩu → thông báo chung | Done (form email trong bottom sheet) |
| P3 Ghi một lần vận động | S02 → S07 → S08 → S04 | Dừng sớm vẫn lưu số phút | Done (Stage 4) |
| P4 Viết nhật ký dài | S05 → S06 (sửa) | Bí ý → câu gợi ý; app bị tắt → "Tiếp tục bản nháp?" | Một phần: nút "Gợi ý" (Stage 4); nháp khi app bị tắt chưa làm |
| P5 Xem, sửa, xoá một nốt | S05 → S06 → S05 | Dialog xoá + Hoàn tác 5 giây | Done (Stage 4) |
| P6 Ngày tệ: nhìn lại hành trình | S11 → S05 → S06 | Mệt/Rối 5 ngày liền → dialog hỗ trợ | Done (Stage 4) |
| P7 Thông báo → mở đúng màn | Thông báo → S03 / S02 / S08 | Chưa đăng nhập → S01 rồi mới tới đích (`?next=`) | Một phần: redirect `?next=` (Stage 3); nhận thông báo ở Stage 5 |
| P8 Hồ sơ & cài đặt | S02 → S12 → (đăng xuất) S01 | Từ chối quyền thông báo → banner "Mở cài đặt" | Một phần: giờ nhắc, Giờ tỉnh, khoá, Nốt AI, ẩn nội dung, đăng xuất (Stage 4); banner quyền thông báo ở Stage 5 (FCM) |
| T1 Hũ rỗng | S05 → S03 → S04 | Empty state + "Ghi nốt đầu tiên" | Done (Stage 4) |
| T2 Mất mạng / tải lỗi | S05, S11 | Error state + Thử lại; có dữ liệu cũ → banner | Done (Stage 4) |
| T3 Đang tải → kết quả | S11c | Quá 10 giây → T2 | Done (Stage 4) |

---

## 3. Component (page 05) → widget

Mỗi component là **một** widget dùng lại trong `lib/widgets/`, variant và state là tham số. Màn hình chỉ dùng các widget này, không chép lại.

| Component Lab 2 | Variant / State | Widget | File | Trạng thái |
|---|---|---|---|---|
| `Button` | Filled, Tonal, Outlined, Text, Destructive × Default, Pressed, Disabled, Loading | `AppButton(variant:, loading:, onPressed:)` | `widgets/app_button.dart` | Done |
| `Text field` | Default, Focused, Filled, Error, Disabled | `AppTextField(errorText:, enabled:, maxLength:)` | `widgets/app_text_field.dart` | Done |
| `Card/Nốt` | 4 loại × Default, Pressed | `NoteCard(type:)` | `widgets/note_card.dart` | Done |
| `Note/Tờ nốt` | 4 loại | `NoteTile(type:)` | `widgets/note_tile.dart` | Done |
| `BottomNav/iPhone` (Final UI) | Active: 4 tab | `AppBottomNav(currentIndex:)`: thanh kính nổi, tab đang chọn có icon + nhãn, tab khác chỉ có icon (nhãn qua tooltip và trình đọc màn hình); icon SVG `assets/icons/tab-*.svg` | `widgets/app_bottom_nav.dart` | Done · Deviation D-20 |
| `App bar` | Default, With actions | `AppTopBar(actions:)` (màn lồng), `TabHeader` (4 màn tab: tiêu đề + chuông + avatar) | `widgets/app_top_bar.dart` | Done |
| `Dialog` | Confirmation, Destructive | `showAppDialog(kind:)` | `widgets/app_dialog.dart` | Done |
| `Loading state` | Skeleton list, Spinner | `LoadingState.skeleton()`, `LoadingState.spinner()` | `widgets/state_views.dart` | Done |
| `Empty state` | — | `EmptyState` | `widgets/state_views.dart` | Done |
| `Error state` | Offline, Load failed | `ErrorState(kind:)` | `widgets/state_views.dart` | Done |
| `MoodOption` | Default, Selected | `MoodOption(mood:, selected:)` | `widgets/mood_option.dart` | Done |
| `Chip/Chiến thắng nhanh` | Default, Selected | `QuickWinChip(selected:)` | `widgets/quick_win_chip.dart` | Done |
| `Cell/Ngày năng lượng` | 5 mood + Chưa ghi + Khác tháng | `MoodDayCell(mood:, inMonth:)` | `widgets/mood_cells.dart` | Done |
| `Cell/Pixel năm` | 5 mood + Không có ngày | `MoodPixel(mood:)` | `widgets/mood_cells.dart` | Done |
| `Sticker/Mốc` | Đã mở, Chưa mở | `MilestoneSticker(unlocked:)` | `widgets/milestone_sticker.dart` | Done |
| `SettingRow` | Trailing: Value, Switch | `SettingRow.value()`, `SettingRow.toggle()` | `widgets/setting_row.dart` | Done |
| `Switch` | On, Off | `Switch` + `SwitchThemeData` (màu tắt `switch-off`) | `theme/app_theme.dart` | Done |
| `Mascot` | 8 trạng thái | `Mascot(state:)` | `widgets/mascot.dart` | Done |
| `MascotAnim` | Phase A, B, C | `Mascot` + `AnimatedSwitcher` | Stage 4 | Planned |
| `lối tắt` trên S02 | — | `ShortcutButton(iconAsset:)`: rộng 96, vòng 56 `surface-variant`, icon `clock` / `refresh` / `phase` | `widgets/shortcut_button.dart` | Done |
| Nút nổi + | — | `AddNoteFab` | `widgets/add_note_fab.dart` | Done |
| Banner offline | — | `OfflineBanner` | `widgets/offline_banner.dart` | Done |
| Tab con (Con đường / Thống kê / Lịch, Tháng / Năm) | — | `SegmentedButton` + `SegmentedButtonThemeData` (cao 48) | `theme/app_theme.dart` | Done |
| `Illustration/Hũ chiến thắng`, `Decor/Confetti` | — | `JarIllustration` chỉ vẽ hũ (SVG Figma + tờ nốt theo dữ liệu); mỗi màn tự đặt cảnh: S02 nền tròn 230 + mascot đứng trước, S04 mascot bên trái + confetti, S05 hũ 126 × 147 cạnh số nốt | `widgets/jar_illustration.dart`, `assets/illustrations/` | Done · Deviation D-14 |
| Biểu đồ S11b | Area, Radar, Bar | `fl_chart` `LineChart` có vùng tô (năng lượng), `RadarChart` (cân bằng 5 điều tốt); cột theo thứ bằng `Container` | `screens/journey/journey_stats_tab.dart` | Done · Deviation D-18 |

## 4. Token → theme

| Lab 2 (Figma) | Flutter | File |
|---|---|---|
| Color variables (`primary` … `success`) | `ColorScheme` + `AppColors` (`ThemeExtension`: `primaryDark`, `onSurfaceMuted`, `warning`, `success`, `switchOff`, `tintGray`, `tintLavender`) | `theme/app_colors.dart` |
| `heat/1` … `heat/5` (tâm trạng) | `AppColors.mood(Mood)` | `theme/app_colors.dart` |
| `tint/orange`, `violet`, `green`, `blue` (loại nốt) | `AppColors.noteTint(NoteType)` | `theme/app_colors.dart` |
| `mono/1` … `mono/5` (biểu đồ) | `AppColors.chart` | `theme/app_colors.dart` |
| Text Styles (Be Vietnam Pro) | `TextTheme` + `AppTextStyles` (`title20`, `title17Bold`, `body17`, `overline`) | `theme/app_typography.dart` |
| `space/2` … `space/24`, lề 16, lưới 12 | `AppSpace` | `theme/app_tokens.dart` |
| `radius/4` … `radius/12`, 14, 16, 32, tròn | `AppRadius` | `theme/app_tokens.dart` |
| `Elevation/0 Flat`, `Elevation/2 FAB` | `AppElevation.flat`, `AppElevation.fab(color)` | `theme/app_tokens.dart` |
| Vùng chạm 48, nút 48 × 64, app bar 48, thanh tab 64 | `AppSize` + component themes | `theme/app_tokens.dart`, `theme/app_theme.dart` |

## 5. Thay đổi so với thiết kế Lab 2

Mỗi dòng là một chỗ app khác Figma, kèm lý do. Cột "Figma" cho biết đã cập nhật file Figma chưa; dòng nào còn `Cần cập nhật` phải được sửa trong Figma trước khi nộp, nếu không sẽ bị tính là lỗi.

| ID | Màn / phần | Thiết kế Lab 2 | App Lab 3 | Lý do | Figma |
|---|---|---|---|---|---|
| D-01 | S12 Cài đặt | Chỉ có Nhắc nhở, Quyền riêng tư, Tài khoản | Thêm nhóm **"Khu demo Firebase"** ở cuối S12: danh sách thông báo đã nhận, Xuất & tải lên PDF, giá trị Remote Config hiện tại, 2 nút thử Crashlytics (lỗi non-fatal, crash thử). Ẩn được bằng cờ Remote Config `firebase_demo_enabled` | Lab 3 mục 3 yêu cầu khu demo Firebase, "thường ở màn Profile". S12 là màn hồ sơ duy nhất | Cần cập nhật |
| D-02 | Nhiều màn | Không có trong Figma | Dùng các giá trị handoff tự đặt: chiến thắng ≤ 120, nhật ký ≤ 2000, thói quen ≤ 40 ký tự; snackbar Hoàn tác 5 giây; quá 10 giây thì chuyển sang lỗi; dialog "Đăng xuất khỏi Nốt?" | `flutter-handoff.md` ghi rõ các giá trị này "do đặc tả đặt" và yêu cầu ghi vào đây | Cần cập nhật |
| D-03 | Toàn app | Không có dark theme (`DESIGN.md` mục 11) | Bỏ chế độ tối và nút chọn theme của bản khung cũ; app chỉ có light theme | Giữ đúng thiết kế; dark theme không có token | Không cần |
| D-04 | Toàn app | Thanh trạng thái kiểu iPhone ("9:41") | Thanh trạng thái Android, nội dung bọc `SafeArea` | Ràng buộc nền tảng (Android); handoff đã ghi | Không cần |
| D-05 | Chữ | Be Vietnam Pro trong Figma | Be Vietnam Pro qua `google_fonts` (tải lúc chạy, lưu cache). Lần mở đầu tiên khi không có mạng sẽ dùng font hệ thống | Ràng buộc thời gian; sẽ đóng gói font vào `assets/fonts/` nếu bị chấm lệch so với Figma | Không cần |
| D-06 | S11b Thẻ tuần | "Lưu thẻ tuần (PDF)" mở hộp chia sẻ | Tạo PDF, **tải lên Cloud Storage** `reports/{uid}/weekly-<tuần>.pdf` có thanh tiến độ và hiện link tải về, sau đó mới mở hộp chia sẻ | Lab 3 yêu cầu tạo ít nhất 1 file và tải lên cloud, hiện tiến độ và URL | Cần cập nhật |
| D-07 | Chuông ở 4 màn tab | Chuông mở S12 (mục Nhắc nhở) | Giữ nguyên; danh sách thông báo đã nhận nằm trong khu demo ở S12 (D-01) | Lab 3 yêu cầu lưu danh sách thông báo trong app; đặt cùng chỗ chuông dẫn tới | Cần cập nhật (cùng D-01) |
| D-08 | "Lưu trên máy" khi mất mạng | Ghi vào bộ nhớ máy, cờ `pendingSync` | Dùng bộ nhớ đệm offline của Firestore: ghi xong ngay trên máy, tự đồng bộ khi có mạng; banner dựa trên `hasPendingWrites` | Cùng hành vi với thiết kế, ít code hơn và không mất dữ liệu | Không cần |
| D-09 | S11b biểu đồ | Vẽ cố định 294 px | `fl_chart` co giãn theo chiều rộng thẻ | `design-decisions.md` mục 2 đã ghi | Không cần |
| D-11 | `Note/Tờ nốt` (S04, S05) | `DESIGN.md` mục 10: tiêu đề tối đa 2 dòng; `flutter-handoff.md` (component, S05): tối đa 3 dòng | Tối đa **2 dòng** rồi "…" | Hai tài liệu Lab 2 mâu thuẫn. Ô lưới 158 × 137 dp chỉ chứa vừa nhãn loại + 2 dòng tiêu đề + ngày; dòng thứ 3 bị cắt ngang khi chạy thật ở 360 dp | Không cần (Figma vẽ 2 dòng); sửa handout |
| D-12 | Mở app | Không có màn chờ | Màn chờ `/splash` (vòng xoay trên nền `surface`) trong lúc Firebase cho biết đã đăng nhập chưa, rồi chuyển tới S01 hoặc đích ban đầu | Tránh hiện S01 chớp nhoáng với người đã đăng nhập; giữ đích khi mở từ thông báo (P7) | Không cần (màn kỹ thuật, không có nội dung thiết kế) |
| D-13 | S01 form email | Handoff: "Email / Đăng ký mở form email", không vẽ form | Form email là bottom sheet trên S01 (Email, Mật khẩu, nút chính, "Quên mật khẩu?"), lỗi hiện dưới ô | Figma không có frame cho form này; dùng component `Text field` và `Button` có sẵn | Cần cập nhật |
| D-14 | S02, S05 hình hũ | `Illustration/Hũ chiến thắng`: 8 tờ nốt màu cố định | Thân hũ là SVG export từ Figma (`assets/illustrations/jar-empty.svg`); tờ nốt đặt đúng 8 ô của Figma nhưng tô màu theo loại của 8 nốt mới nhất tháng này, hũ trống khi chưa có nốt. S04 vẽ hũ với các nốt của tháng chứa nốt vừa lưu | Hũ cho thấy đúng các nốt thật của người dùng thay vì hình tĩnh | Không cần (hình và vị trí giống Figma, chỉ màu tờ nốt đổi theo dữ liệu) |
| D-15 | S06 chế độ sửa | Chỉ có nút "Lưu" cố định cuối màn; dialog "Bỏ thay đổi?" không ghi tên nút | Thêm nút chữ "Huỷ" dưới "Lưu" để thoát chế độ sửa mà không rời màn; dialog dùng "Bỏ thay đổi" / "Sửa tiếp". S05 có thêm nút "Chưa tải thêm được · Thử lại" cuối lưới khi tải trang sau lỗi | Handout chỉ có Back để thoát chế độ sửa, nên muốn xem lại nốt phải rời màn. Tải trang sau lỗi cần có cách thử lại (Lab 3: mọi lỗi tải có thông báo) | Cần cập nhật |
| D-16 | S09, S10 | S09: Giờ tỉnh là một `SettingRow` có công tắc, chạm giờ để đổi; trạng thái "Đã lỡ lướt" không vẽ nút mở. S10: sóng thở `CustomPaint` | S09: tách thành 2 dòng (công tắc "Giờ tỉnh" và "Khung giờ 23:00 – 01:00" chạm để chọn giờ); thêm nút chữ "Mình đã lỡ lướt quá đà" dưới các chip thói quen, ghi lại thành một nốt Nhật ký "Nhận ra mình đã lướt quá đà" (không tính là lần tự chủ). S10: vòng tròn có mascot to ra khi hít vào, nhỏ lại khi thở ra, đúng nhịp từng bước; kiểu 4-7-8 có thêm bước "Giữ hơi…" | `SettingRow` chỉ có một kiểu trailing (công tắc hoặc giá trị). Figma không có lối vào nhánh phục hồi. Vòng tròn co giãn đọc được ở cả chế độ giảm chuyển động (đổi kích thước theo bước) | Cần cập nhật |
| D-17 | S07, S08 | S07: một chủ đề trên đầu màn ("Dũng cảm · cấp 2"), chồng thẻ cùng cấp. S08: "Kết quả?" có Suôn sẻ / Không như ý; P3 "có thêm ô số phút" | S07: chồng thẻ gồm thẻ chưa làm của cả hai chủ đề (Dũng cảm, Vận động), dòng đầu đổi theo thẻ đang xem; hôm qua Mệt / Rối thì Vận động lên trước; có thêm nút mũi tên Thẻ trước / Thẻ sau bên cạnh chấm trang. S08: thẻ Vận động dùng nhãn "Xong trọn" / "Dừng sớm" và ô số phút dạng nút − / +; không còn thẻ dễ hơn thì báo "Đây đã là thẻ nhẹ nhất rồi." | Flow F3 cần gợi ý thẻ "hợp tâm trạng hôm qua" và P3 cần thẻ vận động trên cùng màn. Nút mũi tên là cách đổi thẻ cho người dùng trình đọc màn hình (handout S07, mục Constraints) | Cần cập nhật |
| D-18 | S11 | S11a: một banner chặng và một đường nút. S11b: "Bạn ghi nốt ngày nào?" là cột chồng theo loại nốt, chọn 7/30 ngày bằng Select. S11c: lề 12, không có nút đổi tháng | S11a có hàng chip chọn chủ đề ("Dũng cảm · 1/5", "Vận động · 0/5", cuộn ngang khi nhiều chủ đề), mỗi lần chỉ hiện banner + đường nút của một chủ đề, nhớ chủ đề đang xem khi đổi tab con; mỗi nút ghi tên thử thách bên cạnh (phía còn nhiều chỗ), Nốt Đợi đứng sát nút đang làm, chặng sau là thẻ viền đứt "Chặng 2 · mở khi xong 5 thẻ" thay cho dấu "?". S11b: cột theo thứ một màu primary (chưa tách theo loại). S11c: giữ hai mũi tên đổi tháng quanh nhãn "Tháng N, YYYY". Dialog P6 gợi ý kể với người tin cậy hoặc phòng tư vấn tâm lý của trường, và gọi 115 khi thấy không an toàn | S11a: hai đường liền nhau trông như một chặng dài, và sẽ rối hơn khi có thêm chủ đề; Figma chỉ ghi tên nút đang làm nên không biết thử thách sắp tới là gì; dấu "?" không nói chặng sau mở khi nào. S11b: `byWeekday` hiện chỉ đếm tổng; tách theo loại cần đổi ViewModel, để lại sau. S11c: không có mũi tên thì không xem được tháng trước. 7 ô 48 dp cần 336 dp nên lề 12 như Figma. Figma không ghi số đường dây hỗ trợ; dùng số cấp cứu 115 chắc chắn đúng | Cần cập nhật |
| D-19 | S12, S09 | Bật "Khoá phần Tự chủ" cần xác thực `local_auth` một lần; tắt không nêu. Dòng "Giờ tỉnh" hiện khung giờ làm phụ đề, không có dòng chọn giờ riêng | Cả bật và tắt đều cần xác thực. Giữ phụ đề khung giờ như Figma và thêm dòng "Đổi khung giờ tỉnh" (S12) / "Đổi khung giờ" (S09) để chọn giờ. Thêm "Nốt AI sắp xếp giúp" vào nhóm Quyền riêng tư và nhóm "Khu demo Firebase" trước nút Đăng xuất | Nếu tắt khoá không cần xác thực thì người cầm máy tự gỡ được khoá, mất ý nghĩa riêng tư (DESIGN.md mục 5). Công tắc chiếm cả dòng nên cần một dòng khác để đổi giờ. Khu demo là yêu cầu Lab 3 (D-01) | Cần cập nhật |
| D-20 | Thanh tab | `BottomNav/iPhone`: nền trắng 14% trên lớp làm nhoè 12 | Nền trắng 72% trên lớp làm nhoè 12 | Trên Android nội dung cuộn dưới thanh tab (hũ, tờ nốt nhiều màu); nền 14% làm icon tab không đủ tương phản 3:1 | Cần cập nhật |
| D-21 | S06, S07 | S06: action "⋯" trên app bar. S07: chỉ có chấm trang và chữ "Vuốt để đổi thẻ" | S06: "⋯" mở menu có một mục "Xoá nốt" rồi tới dialog xoá. S07: "Vuốt để đổi thẻ" là nút chữ, chạm thì sang thẻ sau (thẻ cuối quay về thẻ đầu) | S07: người không vuốt được (trình đọc màn hình, một tay) vẫn đổi được thẻ; trình đọc màn hình còn có thao tác cuộn trên chồng thẻ | Cần cập nhật |
| D-22 | Nhóm lần đầu (S05, S05e, S04) | Spec lưu nhóm ở `groups/{uid}/items/{groupId}` | Lưu ở `users/{uid}/groups/{groupId}`; id nhóm hệ thống cố định (`bat-chuyen`, …), id nhóm tự tạo lấy từ tên bỏ dấu. Nhóm hệ thống chỉ được lưu khi có nốt đầu tiên hoặc khi đổi tên | Mọi dữ liệu riêng của người dùng đều nằm dưới `users/{uid}`, dùng chung luật `isOwner(uid)` và xoá tài khoản một chỗ. Không lưu sẵn 8 nhóm gợi ý cho người chưa dùng | Cần cập nhật |
| D-23 | Nhóm lần đầu | Kệ có ở S05; S05e có "Đổi tên hoặc gộp nhóm"; gợi ý nhóm đến từ Nốt AI ở S03b | Kệ chỉ hiện khi hũ đã có nốt (hũ rỗng vẫn là Empty state). Nút là "Đổi tên nhóm" (chưa gộp nhóm). Khi chưa có Nốt AI, nốt vào nhóm qua "Ghi lần đầu" / "Thử lần nữa" ở S05e: S03 mở với `?group=` và bước 2 có dòng "Lần đầu cho nhóm …" (bỏ được bằng ✕). Thẻ nhóm hiện tên 1 dòng | Gộp nhóm cần chuyển `groupId` của nhiều nốt và cộng số đếm, để làm cùng Nốt AI. Không có AI vẫn phải có đường vào nhóm. Tên 1 dòng giữ kệ thấp như Figma (136 dp) | Cần cập nhật |
| D-10 | Kho thẻ thử thách | Không nêu nguồn | Collection Firestore `challenges` chỉ đọc với người dùng; dữ liệu nạp bằng `firebase/scripts/seed-challenges.js` từ `firebase/seed/challenges.json` (20 thẻ: 2 chủ đề × 2 cấp × 5 thẻ). Final: staff quản lý ở web admin | Lab 3 cấm dữ liệu mock; Final cần một thực thể staff quản lý mà app đọc | Không cần |

Thay đổi phát sinh ở các stage sau được thêm vào bảng này cùng commit với code.
