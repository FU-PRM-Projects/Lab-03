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

### 1.2 Phần thêm trên Figma (section 24/10 – 01/11)

Các section `AI · Nốt sắp xếp giúp (Gemini)`, `Làm quen & Tụi Nốt AI`, `Nhóm lần đầu`, `Kết nối Discord` trên page `03 Final UI`. Mỗi section có một frame `Spec` ghi dữ liệu, Remote Config và Analytics (tóm tắt ở mục 6). Section `A11y · kiểm tra 360 dp / 412 dp` không thêm màn, chỉ là tiêu chí kiểm thử bố cục (mục 2, T4).

| Mã | Màn hình (Figma) | Route | Screen widget | ViewModel | Nguồn dữ liệu | Trạng thái |
|---|---|---|---|---|---|---|
| S03b AI | Ghi nốt bước 2 · Kể tự do, đang đọc, gợi ý để xác nhận, AI nghỉ, lần đầu dùng (quyền riêng tư), gợi ý nhóm & lần đầu | `/note/new?step=2` (tab "Kể tự do") | `NoteComposerScreen` + `FreeTellPanel` | `NoteComposerViewModel`, `AiSortViewModel` | `AiService.sortNotes()` (Gemini qua Firebase AI Logic, App Check), Remote Config `ai_*`; đồng ý lần đầu lưu `users/{uid}/private/settings.aiConsent` | Planned |
| S04 nhóm | Lần đầu tiên! (nhóm mới) | `/note/saved/:id` | `NoteSavedScreen` (biến thể `isFirst`) | `NoteSavedViewModel` | Nốt có `isFirst`, nhóm `groups/{uid}/items/{groupId}` | Done (Nhóm lần đầu) |
| S05 kệ | Hũ & Nhật ký · kệ "Nhóm lần đầu" | `/jar` | `JarScreen` + `GroupShelf` | `JarViewModel`, `GroupsViewModel` | Firestore `groups/{uid}/items` | Done (Nhóm lần đầu) |
| S05e | Chi tiết nhóm (Bắt chuyện, lối vào phòng Discord) | `/jar/groups/:groupId` | `GroupDetailScreen` | `GroupDetailViewModel` | `groups/{uid}/items/{groupId}`, nốt có `groupId`; Remote Config `discord_channel_map` | Done (lối vào phòng Discord: D-30) |
| S08b | Tập nói với Tụi Nốt (AI), vai người trong #chao-hoi | `/challenges/:id/practice?role=` | `PracticeChatScreen` | `PracticeChatViewModel` | `AiService.roleplay()` (tối đa `ai_roleplay_max_turns` lượt, không lưu đoạn chat); lỗi → câu mở lời có sẵn | Planned |
| S08c | Sau thử thách · lời nhắn Tụi Nốt (AI), cần hỗ trợ | `/challenges/:id/message` | `ChallengeMessageScreen` | `ChallengeMessageViewModel` | `AiService.afterChallenge()` → `{message, needs_support}`; lưu lời nhắn kèm nốt | Planned |
| S08d | Tụi Nốt viết giúp câu chào (AI), AI nghỉ, đã sao chép / đang mở Discord | `/challenges/:id/greeting` | `GreetingScreen` | `GreetingViewModel` | `AiService.greetings()` → `{lines[3]}`; lỗi → câu có sẵn từ Remote Config; `Clipboard` + `url_launcher` | Một phần: biến thể "AI nghỉ" và đã sao chép (D-30); bản AI viết giúp chờ Tụi Nốt AI |
| S08 Discord | Thử thách cấp 3 · chào trong #chao-hoi; quay lại từ Discord | `/challenges/:id` | `ChallengeDetailScreen` | `ChallengeDetailViewModel` | Thẻ cấp 3 chặng Dũng cảm; `AppLifecycleState.resumed` sau khi mở link → "Bạn vừa ghé phòng chung" | Done (D-30) |
| S11 Hỏi Nốt | Hỏi Nốt (AI, bonus Level 3) | `/journey/ask` | `AskNotScreen` | `AskNotViewModel` | Gemini function calling `countNotes(type, month)` trên Firestore của chính người dùng; Remote Config `ai_ask_enabled` | Planned (bonus) |
| S12 thêm | Cài đặt · bật/tắt Nốt AI, làm lại khảo sát, Phòng trò chuyện | `/settings` | `SettingsScreen` | `SettingsViewModel` | `users/{uid}/private/settings.aiEnabled` (đã có), mở S13a / S14 | Một phần: "Phòng trò chuyện" (D-30); Nốt AI, làm lại khảo sát chờ Tụi Nốt AI |
| S13a–d | Làm quen 1/4 người lạ, 2/4 thói quen, 3/4 nhịp sống, 4/4 mục tiêu | `/onboarding?step=1..4` | `OnboardingScreen` | `OnboardingViewModel` | Câu trả lời `users/{uid}/private/onboarding`; điền sẵn thói quen S09 (`private/habits`) | Planned |
| S13e–g | Tụi Nốt đang đọc; hồ sơ khởi đầu + 3 thẻ (AI); AI nghỉ, thẻ mặc định | `/onboarding/plan` | `OnboardingPlanScreen` | `OnboardingViewModel` | `AiService.starterPlan()` → `StarterPlan`; lỗi / tắt → `StarterPlanRules` (bảng luật trong app); lưu cấp khởi đầu `challengeProgress`, giờ nhắc `private/settings` | Planned |
| S14 | Phòng trò chuyện (Discord), không mở được Discord | `/rooms` | `DiscordRoomsScreen` | `DiscordRoomsViewModel` | Remote Config `discord_enabled`, `discord_invite_url`, `discord_channel_map`; `url_launcher` (`externalApplication`) | Done (D-30) |

| Dialog / sheet mới | Ở màn | Flutter | Trạng thái |
|---|---|---|---|
| Sheet "Nốt AI" lần đầu dùng (gửi gì, không gửi gì) | S03b | `showModalBottomSheet` | Planned |
| Sheet tạo nhóm lần đầu; lỗi trùng tên → "Xếp vào nhóm đó" | S05, S03b | `showCreateGroupSheet` + `GroupNameValidator` (bỏ dấu, không phân biệt hoa thường, 1–24 ký tự) | Planned |
| Sheet quy tắc trước khi vào Discord (lần đầu) | S14, S05e, S08 | `showDiscordRulesSheet` + cờ `discord_rules_seen` (`shared_preferences`) | Done |
| Dialog "Chưa mở được Discord" (Mở bằng web / Sao chép) | S14, S08d | `showAppDialog(kind: confirmation)` + `Clipboard` + snackbar "Đã sao chép" | Done |
| Thẻ hỗ trợ "Nói với người bạn tin" khi `needs_support` | S03b, S08c | Dùng lại dialog P6 | Planned |
| Snackbar Hoàn tác 5 giây khi xoá nhóm | S05e | `SnackBar` (nốt giữ lại, `groupId = null`) | Planned |

---

## 2. Flow → màn hình → kiểm thử

Mã test case (`TC-xx`) sẽ được gán trong `docs/test-plan.md` ở Stage 6.

| Flow | Màn hình theo thứ tự | Nhánh thay thế / lỗi phải chạy được | Trạng thái |
|---|---|---|---|
| F1 Ghi nốt buổi tối | S02 → S03a → S03b → S03c → S04 → S02 (hoặc thông báo 21:30 → S03a) | Bỏ qua phần kể thêm; tâm trạng Rối → "Sơ cứu 1 phút"; thoát giữa chừng → dialog Giữ nháp; mất mạng → lưu trên máy + banner | Done (Stage 4) |
| F2 Tự chủ | S02 → S09 → S04 → S02; khó dừng: S02 (lối tắt Stress?) → S10 → S04 | Đã lỡ lướt → sheet + "Nhận ra cũng là bắt đầu tự chủ"; phần thói quen khoá bằng `local_auth` | Done (Stage 4; bật khoá ở S12 làm cùng S12) |
| F3 Thử thách | S07 → S08 → S04 → S07 | Đổi thẻ dễ hơn; để mai (Back, không trừ gì); Không như ý → "Mình đã mở lời" | Done (Stage 4) |
| P1 Làm quen lần đầu | S01 → (xin quyền thông báo) → S02 | Đăng nhập thất bại / huỷ → SnackBar + Thử lại | Một phần: đăng nhập, huỷ, mất mạng (Stage 3); xin quyền thông báo ở Stage 5 |
| P2 Đăng ký email & quên mật khẩu | S01 (form email) → S02 | Lỗi dưới ô; quên mật khẩu → thông báo chung | Done (form email trong bottom sheet) |
| P3 Ghi một lần vận động | S02 → S07 → S08 → S04 | Dừng sớm vẫn lưu số phút | Done (Stage 4) |
| P4 Viết nhật ký dài | S05 → S06 (sửa) | Bí ý → câu gợi ý; app bị tắt → "Tiếp tục bản nháp?" | Một phần: nút "Gợi ý" (Stage 4); nháp khi app bị tắt chưa làm |
| P5 Xem, sửa, xoá một nốt | S05 → S06 → S05 | Dialog xoá + Hoàn tác 5 giây | Done (Stage 4) |
| P6 Ngày tệ: nhìn lại hành trình | S11 → S05 → S06 | Mệt/Rối 5 ngày liền → dialog hỗ trợ | Done (Stage 4) |
| P7 Thông báo → mở đúng màn | Thông báo → S03 / S02 / S08 | Chưa đăng nhập → S01 rồi mới tới đích (`?next=`) | Một phần: redirect `?next=` (Stage 3); nhận thông báo ở Stage 5 |
| P8 Hồ sơ & cài đặt | S02 → S12 → (đăng xuất) S01 | Từ chối quyền thông báo → banner "Mở cài đặt" | Một phần: giờ nhắc, Giờ tỉnh, khoá, Nốt AI, ẩn nội dung, đăng xuất (Stage 4); lời nhắc buổi tối và Giờ tỉnh bằng thông báo trên máy (D-27); banner quyền thông báo ở Stage 5 (FCM) |
| T1 Hũ rỗng | S05 → S03 → S04 | Empty state + "Ghi nốt đầu tiên" | Done (Stage 4) |
| T2 Mất mạng / tải lỗi | S05, S11 | Error state + Thử lại; có dữ liệu cũ → banner | Done (Stage 4) |
| T3 Đang tải → kết quả | S11c | Quá 10 giây → T2 | Done (Stage 4) |
| T4 Bố cục 360 dp / 412 dp | S02, S03b, S09, S11b | Nội dung giãn theo chiều ngang, bottom nav căn giữa, FAB bám phải, biểu đồ co giãn (D-09) | Planned (golden test 360 × 800 và 412 × 915) |
| A1 Nốt AI · Kể tự do | S03a → S03b (Kể tự do → đang đọc → gợi ý) → S03c → S04 | Lần đầu → sheet quyền riêng tư; hết lượt / mất mạng / quá 8 giây / `ai_enabled = false` → giữ đoạn viết, chọn tay; `needs_support` → thẻ hỗ trợ; huỷ khi đang đọc | Planned |
| A2 Làm quen & thẻ khởi đầu | S01 (đăng ký) → S13a → S13b → S13c → S13d → S13e → S13f → S02; làm lại từ S12 | Bỏ qua câu 1 → cấp 1; AI lỗi / tắt → S13g (bảng luật); chọn tối đa 2 mục tiêu | Planned |
| A3 Tập nói & lời nhắn | S07 → S08 → S08b → S08 → (Kết quả) → S08c → S04 | AI lỗi → ẩn chat, giữ câu mở lời; `needs_support` → thẻ hỗ trợ | Planned |
| G1 Nhóm lần đầu | S03b (gợi ý nhóm) → S04 "Lần đầu tiên!" → S05 kệ → S05e | Tạo nhóm: tên trùng → "Xếp vào nhóm đó", tên rỗng → nút tắt; xoá nhóm → Hoàn tác | Planned |
| D1 Phòng Discord | S05e / S12 → S14 → (S14b lần đầu) → Discord → S08 "Bạn vừa ghé phòng chung" → S04 | Mở link thất bại → dialog (Mở bằng web / Sao chép); `discord_enabled = false` → ẩn mọi lối vào | Done |
| D2 Thử thách cấp 3 #chao-hoi | S07 → S08 (cấp 3) → S08b (vai #chao-hoi) → S08d → Discord → S08 → S04 | AI nghỉ → câu chào có sẵn; mở thất bại → dialog | Một phần: S07 → S08 → S08d → Discord → S08 → S04; S08b chờ Tụi Nốt AI |

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
| D-18 | S11 | S11a: một banner chặng và một đường nút. S11b: "Bạn ghi nốt ngày nào?" là cột chồng theo loại nốt, chọn 7/30 ngày bằng Select. S11c: lề 12, không có nút đổi tháng | S11a có hàng chip chọn chủ đề ("Dũng cảm · 1/5", "Vận động · 0/5", cuộn ngang khi nhiều chủ đề), mỗi lần chỉ hiện banner + đường nút của một chủ đề, nhớ chủ đề đang xem khi đổi tab con; mỗi nút ghi tên thử thách bên cạnh (phía còn nhiều chỗ), Nốt Đợi đứng sát nút đang làm, chặng sau là thẻ viền đứt "Chặng 2 · mở khi xong 5 thẻ" thay cho dấu "?". S11b: "Năng lượng mỗi ngày" so với 7/30 ngày ngay trước ("↑ Tăng 0,4 điểm so với 30 ngày trước") thay vì "so với tháng 9"; tooltip luôn hiện ở ngày gần nhất có tâm trạng, chạm để đổi ngày; ngày không ghi được bỏ qua để đường nối liền. Cột theo thứ một màu tím nhạt mono/3 (chưa tách theo loại); không dùng primary để cột không lẫn với nút "+" nổi. S11c: giữ hai mũi tên đổi tháng quanh nhãn "Tháng N, YYYY". Dialog P6 gợi ý kể với người tin cậy hoặc phòng tư vấn tâm lý của trường, và gọi 115 khi thấy không an toàn | S11a: hai đường liền nhau trông như một chặng dài, và sẽ rối hơn khi có thêm chủ đề; Figma chỉ ghi tên nút đang làm nên không biết thử thách sắp tới là gì; dấu "?" không nói chặng sau mở khi nào. S11b: `byWeekday` hiện chỉ đếm tổng; tách theo loại cần đổi ViewModel, để lại sau. S11c: không có mũi tên thì không xem được tháng trước. 7 ô 48 dp cần 336 dp nên lề 12 như Figma. Figma không ghi số đường dây hỗ trợ; dùng số cấp cứu 115 chắc chắn đúng | Cần cập nhật |
| D-19 | S12, S09 | Bật "Khoá phần Tự chủ" cần xác thực `local_auth` một lần; tắt không nêu. Dòng "Giờ tỉnh" hiện khung giờ làm phụ đề, không có dòng chọn giờ riêng | Cả bật và tắt đều cần xác thực. Giữ phụ đề khung giờ như Figma và thêm dòng "Đổi khung giờ tỉnh" (S12) / "Đổi khung giờ" (S09) để chọn giờ. Thêm "Nốt AI sắp xếp giúp" vào nhóm Quyền riêng tư và nhóm "Khu demo Firebase" trước nút Đăng xuất | Nếu tắt khoá không cần xác thực thì người cầm máy tự gỡ được khoá, mất ý nghĩa riêng tư (DESIGN.md mục 5). Công tắc chiếm cả dòng nên cần một dòng khác để đổi giờ. Khu demo là yêu cầu Lab 3 (D-01) | Cần cập nhật |
| D-20 | Thanh tab | `BottomNav/iPhone`: nền trắng 14% trên lớp làm nhoè 12 | Nền trắng 72% trên lớp làm nhoè 12 | Trên Android nội dung cuộn dưới thanh tab (hũ, tờ nốt nhiều màu); nền 14% làm icon tab không đủ tương phản 3:1 | Cần cập nhật |
| D-21 | S06, S07 | S06: action "⋯" trên app bar. S07: chỉ có chấm trang và chữ "Vuốt để đổi thẻ" | S06: "⋯" mở menu có một mục "Xoá nốt" rồi tới dialog xoá. S07: "Vuốt để đổi thẻ" là nút chữ, chạm thì sang thẻ sau (thẻ cuối quay về thẻ đầu) | S07: người không vuốt được (trình đọc màn hình, một tay) vẫn đổi được thẻ; trình đọc màn hình còn có thao tác cuộn trên chồng thẻ | Cần cập nhật |
| D-22 | Nhóm lần đầu (S05, S05e, S04) | Spec lưu nhóm ở `groups/{uid}/items/{groupId}` | Lưu ở `users/{uid}/groups/{groupId}`; id nhóm hệ thống cố định (`bat-chuyen`, …), id nhóm tự tạo lấy từ tên bỏ dấu. Nhóm hệ thống chỉ được lưu khi có nốt đầu tiên hoặc khi đổi tên | Mọi dữ liệu riêng của người dùng đều nằm dưới `users/{uid}`, dùng chung luật `isOwner(uid)` và xoá tài khoản một chỗ. Không lưu sẵn 8 nhóm gợi ý cho người chưa dùng | Cần cập nhật |
| D-23 | Nhóm lần đầu | Kệ có ở S05; S05e có "Đổi tên hoặc gộp nhóm"; gợi ý nhóm đến từ Nốt AI ở S03b | Kệ chỉ hiện khi hũ đã có nốt (hũ rỗng vẫn là Empty state). Nút là "Đổi tên nhóm" (chưa gộp nhóm). Khi chưa có Nốt AI, nốt vào nhóm qua "Ghi lần đầu" / "Thử lần nữa" ở S05e: S03 mở với `?group=` và bước 2 có dòng "Lần đầu cho nhóm …" (bỏ được bằng ✕). Thẻ nhóm hiện tên 1 dòng | Gộp nhóm cần chuyển `groupId` của nhiều nốt và cộng số đếm, để làm cùng Nốt AI. Không có AI vẫn phải có đường vào nhóm. Tên 1 dòng giữ kệ thấp như Figma (136 dp) | Cần cập nhật |
| D-24 | S05 | Lưới tờ nốt liền một khối, tờ cao tối thiểu 120, mỗi tờ ghi "Hôm nay · Ổn" | Hàng chip lọc loại (Tất cả, Chiến thắng, Tự chủ, Thử thách, Nhật ký) và nút đổi lưới / danh sách gọn (`Card/Nốt`). Tờ nốt gom theo "Hôm nay", "Hôm qua", "Tuần này", "Tuần trước" rồi từng tháng, mỗi nhóm có số nốt; trong "Hôm nay" / "Hôm qua" tờ chỉ ghi tâm trạng, không có tâm trạng thì bỏ dòng này. Tờ cao tối thiểu 96 | Lưới dài toàn màu cam (đa số là Chiến thắng) khó đọc lướt; nhóm theo thời gian tạo điểm dừng mắt và bớt chữ lặp. Lọc chỉ áp lên các nốt đã tải (trang 30 nốt) | Cần cập nhật |
| D-25 | S02 | Lối tắt dùng icon clock (Dừng lại), refresh (Thở 90 giây), phase (Thử thách), chỉ có nhãn. Thẻ "Nhớ lại lần này nhé" lấy ngẫu nhiên một chiến thắng trong 20 nốt gần nhất, cao cố định | Icon bàn tay dừng, luồng gió, lá cờ (trùng icon tab Thử thách) và nhãn và dòng phụ "Dừng lại / ghi 1 lần tự chủ", "Stress? / Thở 90 giây để thả lỏng", "Thử thách / thẻ hôm nay". Thẻ "Nhớ lại" ưu tiên chiến thắng đáng nhớ (lần đầu của một nhóm > thử thách đã làm > có nhật ký > thường) trong 40 nốt, nhãn thêm "· Lần đầu", có trích nhật ký 2 dòng và tâm trạng, cao theo nội dung | Đồng hồ và mũi tên vòng đọc thành "hẹn giờ" và "làm mới", không nói được mục đích. Sau một ngày mệt, một chiến thắng có ý nghĩa (và lời mình viết hôm đó) nâng tinh thần tốt hơn "Uống đủ nước" | Cần cập nhật |
| D-26 | S09 | "Mình vừa dừng lại" lưu nốt "Dừng lại lúc 23:15"; "Mình đã lỡ lướt quá đà" là nút chữ dưới các chip; màn cảm ơn chỉ có câu động viên | "Mình vừa dừng lại" gắn với thói quen: theo dõi 0–1 thói quen thì ghi luôn ("Dừng Video ngắn lúc 23:15", vẫn 2 chạm từ S02), từ 2 thói quen thì sheet "Bạn vừa dừng gì?" (chạm chip là ghi). Gộp "Mình vừa dừng lại" và "Lỡ lướt quá đà" thành một nút "Ghi lại vừa rồi": sheet "Vừa rồi thế nào?" có hai lựa chọn "Mình đã dừng được" (+1 lần tự chủ) và "Mình lỡ lướt quá đà" (dòng phụ "Không sao. Ghi lại cảm giác…"). Dòng giải thích dưới "THÓI QUEN MUỐN BỚT". Màn cảm ơn hiện tờ nốt Nhật ký vừa lưu, "Đã lưu vào Nhật ký trong hũ của bạn." và nút "Xem trong hũ" (mở hũ ở bộ lọc Nhật ký). Bỏ nút "Khó dừng? Thở 90 giây" ở S09: thở 90 giây vào từ lối tắt "Stress?" ở S02 | Người dùng không thấy liên hệ giữa nút dừng và các chip thói quen, không nhận ra nhánh phục hồi, và không biết nốt cảm giác được lưu ở đâu. Hai nút ngang hàng cho hai kết quả trái ngược làm người dùng phân vân; một nút rồi hỏi kết quả thì rõ hơn. Đường dừng được thành 3 chạm từ S02 (4 khi theo dõi nhiều thói quen) | Cần cập nhật |
| D-10 | Kho thẻ thử thách | Không nêu nguồn | Collection Firestore `challenges` chỉ đọc với người dùng; dữ liệu nạp bằng `firebase/scripts/seed-challenges.js` từ `firebase/seed/challenges.json` (22 thẻ: 2 chủ đề × 2 cấp × 5 thẻ, thêm 2 thẻ cấp 3 Dũng cảm). Final: staff quản lý ở web admin | Lab 3 cấm dữ liệu mock; Final cần một thực thể staff quản lý mà app đọc | Không cần |
| D-27 | S09, S12 | "Giờ tỉnh" là một cài đặt (bật/tắt, khung giờ); handout chưa nói app làm gì với nó. "Nhắc ghi nốt buổi tối" mở S03a (flow F1) qua thông báo đẩy ở Stage 5 | "Nhắc ghi nốt buổi tối" làm bằng thông báo trên máy luôn: "Hôm nay bạn làm được gì? · Ghi một nốt nhỏ trước khi ngủ nhé." mỗi ngày lúc giờ đã chọn (mặc định 21:30), chạm vào mở S03a; đổi giờ ở S12 thì hẹn lại. "Giờ tỉnh": Thông báo trên máy "Đến giờ tỉnh rồi · Đang lướt à? Chạm để dừng lại và ghi 1 lần tự chủ." mỗi ngày lúc bắt đầu khung giờ (mặc định 23:00); chạm vào mở S09, Back về S02. Tắt Giờ tỉnh hoặc đăng xuất thì huỷ; đổi giờ thì hẹn lại. Xin quyền thông báo (Android 13+) lần đầu lời nhắc có tác dụng. Hẹn kiểu không chính xác: Android có thể nhắc trễ tối đa khoảng 1 giờ, vẫn trong khung giờ 2 tiếng | Cài đặt không có tác dụng thì người dùng bật mà không thấy gì. Thông báo cục bộ chạy cả khi app tắt, không cần FCM; không xin quyền báo thức chính xác vì lời nhắc nhẹ lệch vài phút không sao | Cần cập nhật |
| D-28 | S03b, S03c, S06 | Phần viết thêm của nốt gọi là "nhật ký": nút "Bỏ qua nhật ký" (S03b), ô "Nhật ký hôm nay" (S03c), ô "Nhật ký" (S06) | Đổi thành "Bỏ qua phần kể thêm", ô "Kể thêm" (S03c, S06); tiêu đề bước giữ "Viết thêm vài dòng?". Chữ "Nhật ký" chỉ còn là tên loại nốt (nốt "Lỡ lướt quá đà" ở S09) | Người dùng tưởng viết ở bước 3 tạo ra nốt loại Nhật ký, trong khi nốt từ "Ghi nốt" luôn là Chiến thắng; phần viết thêm chỉ là lời kể đi kèm | Cần cập nhật |
| D-29 | S02, S03, màn Viết nhật ký (mới) | "Ghi nốt" và nút + mở thẳng S03 (nốt Chiến thắng). Nốt loại Nhật ký chưa có đường tạo riêng (chỉ từ "Lỡ lướt quá đà" ở S09) | "Ghi nốt" (khi chưa có nháp) và nút + mở sheet "Hôm nay bạn muốn ghi gì?": "Chiến thắng nhỏ" → S03 như cũ, "Viết nhật ký" → màn mới `/journal`. Màn viết: tiêu đề "Viết ra những suy nghĩ trong tâm trí bạn", ô viết tự do với đồng hồ đếm lên (không ép giờ), nút "Bí rồi? Hỏi mình đi" mở các câu hỏi gợi ý (chạm là chèn vào trang). "Xong" tách bài thành từng câu, chọn một câu làm tiêu đề ("Điều rõ ràng nhất là gì?"), cả bài là phần kể; lưu thành nốt Nhật ký rồi tới S04. Đóng khi đã viết thì hỏi "Bỏ trang đang viết?" | Viết ra giúp suy nghĩ rõ ràng hơn; một ô trống thì khó bắt đầu, nên có câu hỏi đỡ khi bí, và bước chọn câu buộc người viết đọc lại. Gộp viết tự do, câu hỏi gợi ý và câu hỏi dẫn đường vào một màn để người dùng không phải chọn cách viết | Cần cập nhật |
| D-30 | S14, S14b, S05e, S08 cấp 3, S08d, S12 | Spec "Kết nối Discord" | Làm theo Figma, khác ở: (1) S08 quay lại từ Discord có ô "Kể một câu (không bắt buộc)" với gợi ý "Ví dụ: Mình đã chào, có 2 người chào lại."; mức "Sau đó bạn thấy sao?" lưu thành `anxietyAfter` trên nốt (rules cho phép 1–5). (2) S08d chỉ có biến thể "AI nghỉ" (câu chào có sẵn từ Remote Config `discord_greetings`), dòng chú thích đổi thành "Bạn tự dán câu này lên Discord. Nốt không gửi gì thay bạn."; quay lại app sau khi mở Discord (`AppLifecycleListener.onResume`) thì về S08. (3) S12 có nhóm "CỘNG ĐỒNG" với dòng "Phòng trò chuyện". (4) S14 xếp phòng của nhóm đã có nốt lên trước ("Nhóm Hỏi thầy cô · 2 nốt"), phòng còn lại là "Tụi Nốt gợi ý cho bạn". (5) "Quy tắc phòng" mở lại S14b với một nút "Mình hiểu". (6) `discord_invite_url` mặc định là link mẫu, `discord_channel_map` rỗng nên mọi phòng mở link mời | Figma chỉ có chữ ví dụ mà không có chỗ ghi; chú thích "Câu có sẵn lấy từ Remote Config" là ghi chú cho dev. Chưa có server Discord thật nên link đổi bằng Remote Config, không cần build lại | Cần cập nhật |

Thay đổi phát sinh ở các stage sau được thêm vào bảng này cùng commit với code.

## 6. Remote Config, dữ liệu và Analytics của phần mới (frame `Spec` trên Figma)

| Phần | Remote Config | Dữ liệu Firestore / máy | Analytics |
|---|---|---|---|
| Nốt AI (S03b, S11 Hỏi Nốt) | `ai_enabled` (true), `ai_model`, `ai_prompt_sort`, `ai_timeout_ms` (8000), `ai_max_chars` (500), `ai_ask_enabled` (false) | Không lưu đoạn kể; nốt lưu như cũ. JSON `{notes[{type, subtype, title ≤ 40, time_of_day, group, new_group_name, is_first}], mood, needs_support}` → `AiSortResult.fromJson()` | `ai_request {feature, char_count}`, `ai_result_accepted {feature, item_count, edited_count}`, `ai_error {feature, reason: quota \| network \| timeout \| disabled \| parse}` |
| Làm quen & Tụi Nốt AI (S13, S08b–d) | `ai_onboarding_enabled`, `ai_prompt_onboarding`, `ai_prompt_roleplay`, `ai_roleplay_max_turns` (6), câu chào có sẵn | `users/{uid}/private/onboarding` (câu trả lời, giữ làm giá trị chọn sẵn khi làm lại). IN `{stranger_level, habits, move, free_slot, goals}` → OUT `StarterPlan {profile_label ≤ 30, cards[3], remind_time}` | `onboarding_step {step, skipped}`, `ai_request {feature: onboarding \| roleplay \| note \| greeting}`, `ai_result_accepted`, `ai_error` |
| Nhóm lần đầu (S05, S05e, S04) | — | `groups/{uid}/items/{groupId}` `{name 1–24, idea, source: system \| user \| ai_suggested, firstNoteId, noteCount, createdAt}`; nốt thêm `groupId` (nullable), `isFirst`. 8 nhóm hệ thống: Bắt chuyện, Hỏi thầy cô, Lên tiếng trong nhóm, Vận động một mình, Dừng lướt đêm, Ngủ trước 1h, Viết nhật ký dài, Tự đi nơi mới. Mốc 1 → 3 → 10 | `group_created {source, idea}`, `note_grouped {source: ai \| user, is_first}`, `first_time_milestone {group_source, level}` |
| Kết nối Discord (S14, S05e, S08) | `discord_enabled`, `discord_invite_url`, `discord_channel_map` (JSON mã nhóm → link) | Cờ `discord_rules_seen` (`shared_preferences`). App không gửi gì cho Discord, không đọc tin nhắn, không bot (Final cấm Cloud Functions) | `discord_open {channel, source: group \| rooms \| challenge}`, `discord_open_failed {channel, reason}`, `discord_return_note {posted}` |

Việc cần thêm khi làm các phần này:

- Package: `firebase_ai` (Firebase AI Logic), `firebase_app_check`, `url_launcher`. Firebase AI Logic và App Check không có trên Emulator, nên phần AI chỉ chạy được trên project Firebase thật; khi chạy Emulator, `AiService` trả lỗi `disabled` và mọi flow đi nhánh dự phòng.
- `firestore.rules`: thêm `match /groups/{uid}/items/{groupId}` (chỉ chủ tài khoản), cho phép `groupId`, `isFirst`, `aiMessage` trong `validNote`, thêm `aiConsent` vào `private/settings`, thêm `private/onboarding`.
- Kho thẻ `challenges` có thẻ cấp 3 Dũng cảm "Chào 1 câu ở phòng chung" (`discordRoom: chao_hoi`, ẩn khi `discord_enabled = false`) và thẻ ngoài đời "Hỏi một bạn mới về sở thích của bạn ấy" cùng cấp.
