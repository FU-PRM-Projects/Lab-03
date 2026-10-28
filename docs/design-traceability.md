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
| S01 | Chào mừng & Đăng nhập | `/welcome?next=` | `WelcomeScreen` | `AuthViewModel` | Firebase Auth (Google, email/mật khẩu) | Skeleton |
| S02 | Hôm nay (tab 1) | `/today` | `TodayScreen` | `TodayViewModel` | Firestore `users/{uid}/notes` (nốt hôm nay, nốt cũ ngày tệ), nháp trên máy | Skeleton |
| S03 | Ghi nốt (3 bước `S03a`/`b`/`c`) | `/note/new?step=1..3` | `NoteComposerScreen` | `NoteComposerViewModel` | Firestore `users/{uid}/notes` (ghi), Remote Config `quick_win_chips`, nháp trên máy | Skeleton |
| S04 | Nốt đã vào hũ | `/note/saved/:id` | `NoteSavedScreen` | `NoteSavedViewModel` | Firestore (nốt vừa lưu, số nốt tháng), Remote Config `monthly_milestone` | Skeleton |
| S05 | Hũ & Nhật ký (tab 2) | `/jar` | `JarScreen` | `JarViewModel` | Firestore `users/{uid}/notes` (phân trang 30) | Skeleton |
| S06 | Chi tiết nốt | `/jar/:noteId` | `NoteDetailScreen` | `NoteDetailViewModel` | Firestore `users/{uid}/notes/{id}` | Skeleton |
| S07 | Thử thách (tab 3) | `/challenges` | `ChallengesScreen` | `ChallengesViewModel` | Firestore `challenges` (kho thẻ), `users/{uid}/challengeProgress` | Skeleton |
| S08 | Chi tiết thử thách | `/challenges/:id` | `ChallengeDetailScreen` | `ChallengeDetailViewModel` | Firestore `challenges/{id}`, ghi `users/{uid}/notes` | Skeleton |
| S09 | Tự chủ | `/self-control` | `SelfControlScreen` | `SelfControlViewModel` | Firestore `users/{uid}/notes` (đếm tự chủ), `users/{uid}/habits`; `local_auth` | Skeleton |
| S10 | Thở 90 giây | `/breathe` | `BreathingScreen` | `BreathingViewModel` | Không gọi mạng khi mở (tiêu chí < 2 giây); ghi nốt khi "Ghi vào hũ" | Skeleton |
| S11 | Hành trình (tab 4: `S11a` Con đường, `S11b` Thống kê, `S11c` Lịch) | `/journey?tab=path\|stats\|calendar` | `JourneyScreen` | `JourneyViewModel`, `WeeklyReportViewModel` | Firestore `users/{uid}/notes`, `challengeProgress`; PDF Thẻ tuần → Cloud Storage `reports/{uid}/` | Skeleton |
| S12 | Cài đặt (+ khu demo Firebase) | `/settings` | `SettingsScreen` | `SettingsViewModel`, `FirebaseDemoViewModel` | Firestore `users/{uid}` (cài đặt), FCM, Remote Config, Crashlytics, Storage | Skeleton · Deviation D-01 |

Tab cấp cao giữ đúng Lab 2: Hôm nay, Hũ, Thử thách, Hành trình trong `StatefulShellRoute.indexedStack` (mỗi tab giữ vị trí cuộn). Màn lồng (`S03`, `S04`, `S06`, `S08`, `S09`, `S10`, `S12`) nằm ngoài shell nên không có thanh tab, đúng mục 1.1 của `user-flow.md`.

### 1.1 Dialog, sheet và trạng thái đi kèm

| Lab 2 | Ở màn | Flutter | Trạng thái |
|---|---|---|---|
| Dialog "Giữ nốt đang ghi?" — Bỏ / Giữ nháp | S03 | `showAppDialog(kind: confirmation)` | Planned |
| Dialog "Xoá nốt này?" + snackbar Hoàn tác 5 giây | S06 → S05 | `showAppDialog(kind: destructive)` + `showUndoSnackBar` | Planned |
| Dialog "Đăng xuất khỏi Nốt?" | S12 | `showAppDialog(kind: confirmation)` | Planned |
| Dialog "Bỏ thay đổi?" | S06 (sửa) | `showAppDialog(kind: confirmation)` | Planned |
| Xin quyền thông báo Android 13+ | P1, P8 | `MessagingService.requestPermission()` (dialog hệ thống) | Planned |
| Banner "Offline · đã lưu trên máy" | S02, S04, S05 | `OfflineBanner` | Planned |
| Empty state "Hũ còn trống" | S05 | `EmptyState` | Planned |
| Loading skeleton "Đang tải lịch năng lượng…" | S05, S11c | `LoadingState.skeleton` | Planned |
| Error state "Chưa tải được hũ" + Thử lại | S05, S07, S11 | `ErrorState` | Planned |
| Sheet "Kết quả?" (Suôn sẻ / Không như ý) | S08 | `showModalBottomSheet` | Planned |
| Sheet "Lúc đó mình đang thấy gì?" | S09 | `showModalBottomSheet` | Planned |
| Sheet "Đổi kiểu thở" (4-6, 4-7-8) | S10 | `showModalBottomSheet` | Planned |
| Sheet các nốt của một ngày | S11c | `showModalBottomSheet` | Planned |
| Thẻ tuần dạng story + "Lưu thẻ tuần (PDF)" | S11b | route con toàn màn | Planned · Deviation D-06 |
| Dialog gợi ý hỗ trợ (Mệt/Rối 5 ngày liền) | S11 (P6) | `showAppDialog(kind: confirmation)` | Planned |

---

## 2. Flow → màn hình → kiểm thử

Mã test case (`TC-xx`) sẽ được gán trong `docs/test-plan.md` ở Stage 6.

| Flow | Màn hình theo thứ tự | Nhánh thay thế / lỗi phải chạy được | Trạng thái |
|---|---|---|---|
| F1 Ghi nốt buổi tối | S02 → S03a → S03b → S03c → S04 → S02 (hoặc thông báo 21:30 → S03a) | Bỏ qua nhật ký; tâm trạng Rối → "Sơ cứu 1 phút"; thoát giữa chừng → dialog Giữ nháp; mất mạng → lưu trên máy + banner | Planned |
| F2 Tự chủ | S02 → S09 → S04 → S02; khó dừng: S09 → S10 → S04 | Đã lỡ lướt → sheet + "Nhận ra cũng là bắt đầu tự chủ"; phần thói quen khoá bằng `local_auth` | Planned |
| F3 Thử thách | S07 → S08 → S04 → S07 | Đổi thẻ dễ hơn; để mai (Back, không trừ gì); Không như ý → "Mình đã mở lời" | Planned |
| P1 Làm quen lần đầu | S01 → (xin quyền thông báo) → S02 | Đăng nhập thất bại / huỷ → SnackBar + Thử lại | Planned |
| P2 Đăng ký email & quên mật khẩu | S01 (form email) → S02 | Lỗi dưới ô; quên mật khẩu → thông báo chung | Planned |
| P3 Ghi một lần vận động | S02 → S07 → S08 → S04 | Dừng sớm vẫn lưu số phút | Planned |
| P4 Viết nhật ký dài | S05 → S06 (sửa) | Bí ý → câu gợi ý; app bị tắt → "Tiếp tục bản nháp?" | Planned |
| P5 Xem, sửa, xoá một nốt | S05 → S06 → S05 | Dialog xoá + Hoàn tác 5 giây | Planned |
| P6 Ngày tệ: nhìn lại hành trình | S11 → S05 → S06 | Mệt/Rối 5 ngày liền → dialog hỗ trợ | Planned |
| P7 Thông báo → mở đúng màn | Thông báo → S03 / S02 / S08 | Chưa đăng nhập → S01 rồi mới tới đích (`?next=`) | Planned |
| P8 Hồ sơ & cài đặt | S02 → S12 → (đăng xuất) S01 | Từ chối quyền thông báo → banner "Mở cài đặt" | Planned |
| T1 Hũ rỗng | S05 → S03 → S04 | Empty state + "Ghi nốt đầu tiên" | Planned |
| T2 Mất mạng / tải lỗi | S05, S11 | Error state + Thử lại; có dữ liệu cũ → banner | Planned |
| T3 Đang tải → kết quả | S11c | Quá 10 giây → T2 | Planned |

---

## 3. Component (page 05) → widget

Mỗi component là **một** widget dùng lại trong `lib/widgets/`, variant và state là tham số. Màn hình chỉ dùng các widget này, không chép lại.

| Component Lab 2 | Variant / State | Widget | File | Trạng thái |
|---|---|---|---|---|
| `Button` | Filled, Tonal, Outlined, Text, Destructive × Default, Pressed, Disabled, Loading | `AppButton(variant:, loading:, onPressed:)` | `widgets/app_button.dart` | Done |
| `Text field` | Default, Focused, Filled, Error, Disabled | `AppTextField(errorText:, enabled:, maxLength:)` | `widgets/app_text_field.dart` | Done |
| `Card/Nốt` | 4 loại × Default, Pressed | `NoteCard(type:)` | `widgets/note_card.dart` | Done |
| `Note/Tờ nốt` | 4 loại | `NoteTile(type:)` | `widgets/note_tile.dart` | Done |
| `BottomNav · Nốt` | Active: 4 tab | `AppBottomNav(currentIndex:)` | `widgets/app_bottom_nav.dart` | Done |
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
| Lối tắt tròn trên S02 | — | `ShortcutButton` | `widgets/shortcut_button.dart` | Done |
| Nút nổi + | — | `AddNoteFab` | `widgets/add_note_fab.dart` | Done |
| Banner offline | — | `OfflineBanner` | `widgets/offline_banner.dart` | Done |
| Tab con (Con đường / Thống kê / Lịch, Tháng / Năm) | — | `SegmentedButton` + `SegmentedButtonThemeData` (cao 48) | `theme/app_theme.dart` | Done |
| `Illustration/Hũ chiến thắng`, `Decor/Confetti` | — | `SvgPicture` | Stage 4 (cần export SVG từ Figma) | Planned |
| Biểu đồ S11b | Line, Bar | `fl_chart` | Stage 4 | Planned |

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
| D-10 | Kho thẻ thử thách | Không nêu nguồn | Collection Firestore `challenges` chỉ đọc với người dùng; dữ liệu nạp bằng script trong `firebase/`. Final: staff quản lý ở web admin | Lab 3 cấm dữ liệu mock; Final cần một thực thể staff quản lý mà app đọc | Không cần |

Thay đổi phát sinh ở các stage sau được thêm vào bảng này cùng commit với code.
