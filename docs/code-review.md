# AI code review

Mỗi PR vào `main` đều được CodeRabbit review tự động. File này gom mọi góp ý của nó và
ghi lại nhóm đánh giá từng góp ý đúng hay sai.

Phần bảng sinh bằng `python tools/export_coderabbit.py`. Chạy lại khi có PR mới; cột
**Kết luận** và **Ghi chú** đã điền được giữ nguyên.

Giá trị cho cột Kết luận:

- `Đúng, đã sửa`: lỗi thật, ghi commit sửa ở cột Ghi chú.
- `Đúng, chưa sửa`: lỗi thật nhưng để lại, ghi lý do.
- `Sai`: AI hiểu nhầm code hoặc yêu cầu, ghi vì sao.
- `Không cần`: đúng về kỹ thuật nhưng không đáng sửa trong phạm vi Lab.

<!-- coderabbit:start -->

## Tổng hợp

52 góp ý trên 3 PR (#38: 32, #29: 13, #28: 7).

| Mức độ | Số góp ý |
|---|---|
| Major | 3 |
| Minor | 45 |
| Trivial | 4 |

| Loại | Số góp ý |
|---|---|
| Functional Correctness | 33 |
| Stability & Availability | 10 |
| Maintainability & Code Quality | 4 |
| Security & Privacy | 3 |
| Data Integrity & Integration | 2 |

| Kết luận | Số góp ý |
|---|---|
| Đúng, chưa sửa | 37 |
| Không cần | 11 |
| Đúng, đã sửa | 3 |
| Sai | 1 |

## Từng góp ý

| ID | PR | Vị trí | Mức độ | Loại | Công sức | Góp ý của AI | Kết luận | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| 38-bfeb007a | #38 | `lib/firebase/firebase_messaging_service.dart:12-18` | Major | Security & Privacy | Quick win | [Clear the notification inbox on sign-out.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517565) | Đúng, đã sửa | 736453a: `signOut` xoá `fcm_inbox` và bump `inboxRevisionProvider`; có test ở `auth_view_model_test.dart` và `firebase_messaging_service_test.dart`. |
| 38-cfffb9a5 | #38 | `lib/firebase/firebase_messaging_service.dart:66-70` | Major | Functional Correctness | Quick win | [Pass Darwin settings to `initialize` in `start()`.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517594) | Không cần | Đúng với iOS, nhưng app chỉ chạy Android và web (`firebase_options.dart` không có iOS). Gắn mức Major là quá tay. |
| 38-042626b5 | #38 | `evidence/artemis/capture_loop.sh:4` | Minor | Functional Correctness | Quick win | [Create the screenshot output directory before the capture loop starts.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4447174005) | Không cần | Script phụ để chụp bằng chứng, không thuộc app. AI bỏ sót lỗi lớn hơn: đường dẫn cứng `/e/PRM-Lab03/...` của máy cá nhân. |
| 38-98a589d3 | #38 | `evidence/artemis/capture_loop.sh:5` | Minor | Stability & Availability | Quick win | [Bound the capture loop with a deadline or a run-process check.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4447174032) | Không cần | Cùng script phụ chụp bằng chứng; chạy tay rồi tắt. |
| 38-bac00548 | #38 | `evidence/artemis/capture_loop.sh:6` | Minor | Stability & Availability | Quick win | [Add the date to screenshot filenames so reruns do not overwrite earlier captures.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4447174042) | Không cần | Cùng script phụ. Comment này còn gộp thêm một góp ý thứ hai (file PNG rỗng khi `adb` lỗi), cũng không cần. |
| 38-70fbc6ae | #38 | `lib/firebase/firebase_messaging_service.dart:17-22` | Minor | Data Integrity & Integration | Low value | [Serialize the inbox read-modify-write in `_saveToInbox`.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517581) | Không cần | Đúng về lý thuyết (hai tin foreground đến cùng lúc). AI tự đánh "Low value"; hộp thư chỉ để demo. |
| 38-df26118d | #38 | `lib/firebase/firebase_messaging_service.dart:70-71` | Minor | Functional Correctness | Quick win | [Notify the open inbox after a foreground message is saved.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517670) | Đúng, chưa sửa | Không chỗ nào bump `inboxRevisionProvider`; sheet đang mở không tự cập nhật. Ảnh hưởng nhỏ. |
| 38-75b5e00c | #38 | `lib/firebase/firebase_messaging_service.dart:83-85` | Minor | Functional Correctness | Quick win | [Set the route as the payload of foreground notifications.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377398) | Đúng, đã sửa | 5e13651: thông báo foreground gắn `payload` là màn đích (`routeFromData`), bộ nghe chạm của FCM cũng mở màn theo payload; có test ở `firebase_messaging_service_test.dart`. |
| 38-66b21d84 | #38 | `lib/firebase/firebase_messaging_service.dart:84-85` | Minor | Functional Correctness | Quick win | [Emit the route before awaiting the inbox write.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377412) | Đúng, chưa sửa | Thứ tự `await` có thật; chỉ lỗi khi SharedPreferences hỏng. |
| 38-984d603f | #38 | `lib/firebase/firebase_remote_config_service.dart:49-78` | Minor | Functional Correctness | Quick win | [Fall back to in-app booleans when `setDefaults` fails.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517688) | Đúng, chưa sửa | Bốn getter bool không có fallback; chỉ xảy ra khi `setDefaults` lỗi (hiếm). |
| 38-53c2130e | #38 | `lib/firebase/firebase_remote_config_service.dart:66-70` | Minor | Functional Correctness | Heavy lift | [Make the explicit Remote Config refresh bypass the release fetch throttle.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517706) | Đúng, chưa sửa | Chỉ ảnh hưởng bản release (fetch 1 giờ, chưa dùng `onConfigUpdated`). Bản debug dùng để demo có interval 0. |
| 38-322a383f | #38 | `lib/main.dart:76-80` | Minor | Functional Correctness | Quick win | [Sync the analytics user ID when a session is restored at startup.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517711) | Đúng, đã sửa | 211a4d5: router đặt `setUserId` mỗi khi `authUserProvider` đổi, kể cả phiên khôi phục lúc mở app. |
| 38-3b4a994a | #38 | `lib/router/app_router.dart:215-217` | Minor | Stability & Availability | Quick win | [Handle rejected telemetry futures in the screen listener.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377442) | Đúng, chưa sửa | `setKey` gọi `unawaited`, không bắt lỗi. |
| 38-f0574c79 | #38 | `lib/router/app_router.dart:215` | Minor | Stability & Availability | Quick win | [Catch the error from the screen_view call.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517727) | Đúng, chưa sửa | `logScreen` gọi thẳng SDK, không qua `track` nên không nuốt lỗi. |
| 38-ec03d165 | #38 | `lib/screens/challenges/challenges_screen.dart:106-108` | Minor | Functional Correctness | Quick win | [Watch the Remote Config revision in the Challenges screen.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377464) | Đúng, chưa sửa | Tab giữ state nên cờ đổi chỉ thấy khi màn dựng lại. |
| 38-72e33892 | #38 | `lib/screens/challenges/challenges_screen.dart:133-134` | Minor | Functional Correctness | Quick win | [Hide the message's add instruction when the add action is disabled.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377469) | Đúng, chưa sửa | Câu "bạn có thể tự thêm…" vẫn hiện khi cờ tắt. |
| 38-93a4da9c | #38 | `lib/screens/groups/group_shelf.dart:33-35` | Minor | Functional Correctness | Quick win | [Rebuild `GroupShelf` when the Remote Config revision changes.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377486) | Đúng, chưa sửa | Cùng gốc với 38-ec03d165. |
| 38-3c797d6d | #38 | `lib/screens/settings/settings_screen.dart:265-271` | Minor | Stability & Availability | Quick win | [Add a `context.mounted` check after the Remote Config refresh.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517746) | Đúng, chưa sửa | Thiếu `context.mounted` sau `refresh()`, trong khi hàm mở hộp thư ngay trên có kiểm tra. |
| 38-b026cfb5 | #38 | `lib/screens/settings/settings_screen.dart:338-366` | Minor | Functional Correctness | Quick win | [Present the inbox sheet with `isScrollControlled: true`, and make its content scrollable.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517758) | Đúng, chưa sửa | `Column` không cuộn; nội dung dài thì tràn. |
| 38-01eec050 | #38 | `lib/screens/settings/settings_screen.dart:347-376` | Minor | Functional Correctness | Quick win | [Show an error state when the inbox fails to load.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517777) | Đúng, chưa sửa | Nhánh `_` nuốt `AsyncError`, hiện "Đang tải…" mãi. |
| 38-0f823abd | #38 | `lib/viewmodels/auth_view_model.dart:116-119` | Minor | Functional Correctness | Quick win | [Move the logout event and user-ID reset after `_auth.signOut()` succeeds.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517799) | Đúng, chưa sửa | `logout` và `setUserId(null)` chạy trước `_auth.signOut()`. |
| 38-75500a3a | #38 | `lib/viewmodels/auth_view_model.dart:117-119` | Minor | Stability & Availability | Quick win | [Do not await the logout analytics calls before `_auth.signOut()`.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517815) | Không cần | `track` đã bắt lỗi, `setUserId` có `onError`; chỉ kẹt khi plugin treo hẳn. |
| 38-e1da2cab | #38 | `lib/viewmodels/note_composer_view_model.dart:106-115` | Minor | Functional Correctness | Quick win | [Use a monotonic timer for `duration_ms`.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517836) | Không cần | Đúng về lý thuyết; đổi giờ máy giữa lúc soạn nốt rất hiếm, `duration_ms` chỉ để thống kê. |
| 38-55477f01 | #38 | `lib/viewmodels/weekly_report_view_model.dart:88-92` | Minor | Stability & Availability | Quick win | [Handle the Crashlytics failure in the export catch block.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377502) | Đúng, chưa sửa | `recordError` gọi `unawaited`, không bắt lỗi. |
| 38-49575228 | #38 | `slide/README.md:17-20` | Minor | Functional Correctness | Quick win | [Correct the README's Dracula theme claim for the React deck.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517855) | Đúng, chưa sửa | README slide nói bản React dùng `dracula`, nhưng `App.tsx` không import theme. |
| 38-8559d564 | #38 | `slide/README.md:60-61` | Minor | Functional Correctness | Quick win | [Register the Zoom and Search plugins, or remove their shortcuts from the README.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#pullrequestreview-5739302136) | Đúng, chưa sửa | Đã bỏ dòng Search; dòng Zoom (`Alt + Click`) vẫn còn. |
| 38-1ce4cf67 | #38 | `slide/index-standalone.html:214` | Minor | Functional Correctness | Quick win | [Update the standalone ViewState example to match `lib/viewmodels/view_state.dart`.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4444517845) | Đúng, chưa sửa | Bản standalone dùng `ViewLoading`/`ViewEmpty`…, app dùng `Loading`/`Empty`/`Failure`/`Data`. |
| 38-1721f449 | #38 | `slide/src/App.tsx:597` | Minor | Functional Correctness | Quick win | [Correct the Remote Config slide: a failed fetch does not restore a disabled flag.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377542) | Đúng, chưa sửa | Ghi chú slide vẫn nói "failed fetch keeps every feature available"; thực tế giá trị đã kích hoạt trước đó được giữ. |
| 38-7aebfd55 | #38 | `test/firebase/remote_config_parsing_test.dart:36-44` | Minor | Functional Correctness | Quick win | [Fall back to in-app defaults for the four Boolean flags.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#discussion_r4445377567) | Đúng, chưa sửa | Trùng 38-984d603f: AI nêu lại ở lần review sau. |
| 38-b3230edc | #38 | `test/viewmodels/auth_view_model_test.dart:155-157` | Minor | Maintainability & Code Quality | Quick win | [Add a failed sign-out case to the logout test and a failure hook to the fake.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#pullrequestreview-5739302136) | Đúng, chưa sửa | Fake chưa có `signOutError`; đi cùng 38-0f823abd. |
| 38-782e16ab | #38 | `test/screens/group_flow_test.dart:38-53` | Trivial | Maintainability & Code Quality | Quick win | [Cover a Groups flag change on an already mounted jar.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#pullrequestreview-5740374047) | Đúng, chưa sửa | Đi cùng 38-93a4da9c; test chỉ phủ trường hợp cờ tắt từ đầu. |
| 38-d3188820 | #38 | `test/viewmodels/note_composer_view_model_test.dart:89-98` | Trivial | Functional Correctness | Quick win | [Add an analytics assertion for the `skipJournal` save path.](https://github.com/FU-PRM-Projects/Lab-03/pull/38#pullrequestreview-5739302136) | Đúng, chưa sửa | Test `skipJournal` chưa kiểm tra event `note_saved`. |
| 29-a776d113 | #29 | `lib/firebase/firestore_challenge_repository.dart:176-180` | Minor | Functional Correctness | Quick win | [Look up the custom card when the catalog read fails.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083148) | Đúng, chưa sửa | Chỉ xảy ra khi offline và tài liệu catalog chưa có trong cache. |
| 29-513e5e9e | #29 | `lib/firebase/firestore_challenge_repository.dart:179-180` | Minor | Functional Correctness | Poor tradeoff | [Resolve custom-card detail routes by origin, not by bare ID.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083156) | Không cần | Rules chỉ cho chủ tài khoản ghi `customChallenges` của mình, nên ID trùng chỉ tự hại mình. AI tự đánh "Poor tradeoff". |
| 29-c0bdd08c | #29 | `lib/screens/challenges/create_challenge_sheet.dart:75-83` | Minor | Functional Correctness | Quick win | [Guard `_submit` against re-entry.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083170) | Sai | `_saving` có được đọc: `canSubmit = !_saving && …` (dòng 98) tắt nút khi đang lưu. AI đọc sót; chỉ còn khả năng hai lần chạm trong cùng một frame. |
| 29-1458bb82 | #29 | `lib/viewmodels/challenge_detail_view_model.dart:159-161` | Minor | Functional Correctness | Quick win | [Make the result sheet copy match custom cards.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083183) | Đúng, chưa sửa | Câu ở màn kết quả chỉ xét `isMovement`, không xét `mine`. |
| 29-1b2a575a | #29 | `lib/viewmodels/challenge_detail_view_model.dart:205-206` | Minor | Functional Correctness | Quick win | [Clear the pinned easier card when a custom card is completed.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083195) | Đúng, chưa sửa | `if (challenge.mine) return;` nằm trước `clearEasier()`. |
| 29-5bfc8cca | #29 | `lib/viewmodels/challenges_view_model.dart:222-225` | Minor | Functional Correctness | Quick win | [Reset the done-today set when the day changes.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083202) | Đúng, chưa sửa | `now` lấy một lần trong `build()`; chỉ lệch khi app mở qua nửa đêm. |
| 29-bdf05a46 | #29 | `lib/viewmodels/challenges_view_model.dart:276-279` | Minor | Functional Correctness | Quick win | [Load the deck without custom cards until `watchMine` emits.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083212) | Đúng, chưa sửa | `_emit` chờ `_mine`; nếu stream chậm quá 10 giây thì báo lỗi tạm. |
| 29-1c9b31b6 | #29 | `lib/viewmodels/challenges_view_model.dart:329-335` | Minor | Functional Correctness | Poor tradeoff | [Enforce the 20-card limit on the server, not only in `addMine`.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083221) | Không cần | Giới hạn 20 thẻ để giữ giao diện gọn, không phải bảo mật; vượt bằng hai máy offline không gây hại. AI tự đánh "Poor tradeoff". |
| 29-d8bd26d1 | #29 | `lib/viewmodels/challenges_view_model.dart:360-364` | Minor | Functional Correctness | Quick win | [Recompute the banner day on each emission and refresh it at midnight.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083230) | Đúng, chưa sửa | Cùng gốc với 29-5bfc8cca. |
| 29-10700449 | #29 | `test/support/fakes.dart:627-628` | Minor | Maintainability & Code Quality | Quick win | [Use a monotonic counter for fake custom-card IDs.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#discussion_r4442083238) | Đúng, chưa sửa | Fake dùng `mine.length + 1`; chỉ ảnh hưởng test. |
| 29-f657ae23 | #29 | `test/viewmodels/challenges_test.dart:240-247` | Minor | Functional Correctness | Quick win | [Add a concurrent `addMine` test at the card limit.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#pullrequestreview-5736177647) | Không cần | Nút Thêm đã khoá khi đang lưu; hai lời gọi cùng lúc chỉ đến từ hai máy, gắn với 29-1c9b31b6. |
| 29-54ec6d08 | #29 | `firebase/tests/firestore.rules.test.js:125-128` | Trivial | Security & Privacy | Quick win | [Add a cross-user delete assertion to R-15.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#pullrequestreview-5736177647) | Đúng, chưa sửa | R-15 chưa thử Bob xoá thẻ của Alice. |
| 29-c68a9ac1 | #29 | `test/viewmodels/challenges_test.dart:191-193` | Trivial | Maintainability & Code Quality | Quick win | [Add a test for a custom card saved with “not as hoped”.](https://github.com/FU-PRM-Projects/Lab-03/pull/29#pullrequestreview-5736177647) | Đúng, chưa sửa | Chưa có test `notAsHoped` cho thẻ tự thêm. |
| 28-f26b506b | #28 | `.github/workflows/deploy.yml:49-52` | Major | Stability & Availability | Heavy lift | [Gate the production deploy on CI results for the same commit.](https://github.com/FU-PRM-Projects/Lab-03/pull/28#discussion_r4441061524) | Đúng, chưa sửa | `deploy` chạy theo `push`/`workflow_dispatch`, không chờ CI. Rủi ro thật nếu push thẳng `main` hoặc chạy tay trên nhánh khác. |
| 28-98569a60 | #28 | `.github/workflows/release.yml:90-100` | Minor | Stability & Availability | Quick win | [Move the Crashlytics symbol upload after the artifact uploads.](https://github.com/FU-PRM-Projects/Lab-03/pull/28#discussion_r4441061539) | Đúng, chưa sửa | Bước upload symbol nằm trước bước lưu artifact. |
| 28-341b3463 | #28 | `docs/analytics-plan.md:98-104` | Minor | Functional Correctness | Quick win | [Fix the Crashlytics provider example so it uses the web guard.](https://github.com/FU-PRM-Projects/Lab-03/pull/28#discussion_r4441061557) | Đúng, chưa sửa | Ví dụ trong `analytics-plan.md` thiếu điều kiện `kIsWeb`. |
| 28-5f2af2d9 | #28 | `firebase/scripts/seed-challenges.js:12` | Minor | Data Integrity & Integration | Quick win | [Do not default the seeder to the real project.](https://github.com/FU-PRM-Projects/Lab-03/pull/28#discussion_r4441061581) | Đúng, chưa sửa | Không truyền tham số thì mặc định ghi vào project thật `prm393-not-lab3`. |
| 28-8c15c353 | #28 | `lib/main.dart:44-46` | Minor | Security & Privacy | Quick win | [Set Analytics collection from the emulator flag on every launch.](https://github.com/FU-PRM-Projects/Lab-03/pull/28#discussion_r4441061591) | Đúng, chưa sửa | Không có `setAnalyticsCollectionEnabled`; chạy emulator vẫn có thể gửi sự kiện tự động lên project thật. |
| 28-72558ec0 | #28 | `lib/main.dart:84-88` | Minor | Functional Correctness | Heavy lift | [Native Crashlytics collection stays on in emulator builds.](https://github.com/FU-PRM-Projects/Lab-03/pull/28#discussion_r4441061604) | Không cần | Cần cấu hình native; chế độ emulator chỉ dùng khi dev, crash native hiếm. |
| 28-d3e86e35 | #28 | `lib/screens/settings/settings_screen.dart:227-230` | Minor | Stability & Availability | Quick win | [Guard the async test-crash callback with `context.mounted` before showing the snack.](https://github.com/FU-PRM-Projects/Lab-03/pull/28#discussion_r4441061610) | Đúng, chưa sửa | Thiếu `context.mounted` trước `snack`; vẫn còn trên nhánh của #38. |

<!-- coderabbit:end -->

## Nhận xét về CodeRabbit

Mỗi góp ý ở bảng trên được đối chiếu với code hiện tại: `main` cho #28 và #29, nhánh
`feat/firebase-remote-fcm-analytics` cho #38 (PR chưa merge, kiểm tra ngày 03/11/2026).

### Độ chính xác

- **51/52 góp ý đúng về kỹ thuật.** 40 góp ý là lỗi thật trong phạm vi app; 11 góp ý đúng
  nhưng không đáng sửa trong phạm vi Lab.
- **1 góp ý sai** (29-c0bdd08c): AI nói `_saving` "không bao giờ được đọc", nhưng
  `canSubmit = !_saving && …` đã tắt nút khi đang lưu. AI đọc sót đúng dòng nó cần đọc.
- Mỗi góp ý kèm các lệnh AI đã chạy (`rg`, `sed`, `git grep`) để kiểm chứng trước khi viết,
  nên ít khi nói về code không tồn tại. Đây là lý do tỉ lệ đúng cao.

### AI bắt tốt

- **Lỗi bất đồng bộ trong Flutter:** thiếu `context.mounted` sau `await` (38-3c797d6d,
  28-d3e86e35), future bị `unawaited` không bắt lỗi rồi bị Crashlytics ghi thành fatal
  (38-f0574c79, 38-3b4a994a, 38-55477f01), thứ tự `await` làm mất điều hướng (38-66b21d84).
  Loại lỗi này test widget khó bắt và người review dễ bỏ qua.
- **Quyền riêng tư:** hộp thư FCM không bị xoá khi đăng xuất (38-bfeb007a); emulator vẫn có
  thể gửi Analytics lên project thật (28-8c15c353).
- **Tài liệu lệch với code:** ví dụ trong `analytics-plan.md`, README và ghi chú slide nói
  khác với code thật (28-341b3463, 38-49575228, 38-1ce4cf67, 38-1721f449).
- **Khoảng trống của test:** chỉ ra đúng nhánh nào chưa có test, kèm đoạn code gợi ý
  (38-b3230edc, 38-d3188820, 29-54ec6d08, 29-c68a9ac1).
- **Lỗi chỉ thấy khi chạy lâu:** cache theo ngày không đổi sau nửa đêm (29-5bfc8cca,
  29-d8bd26d1), cờ Remote Config đổi mà màn không dựng lại (38-ec03d165, 38-93a4da9c).

### AI làm chưa tốt

- **Không biết phạm vi dự án.** Gắn Major cho lỗi chỉ xảy ra trên iOS, trong khi app chỉ
  build Android và web (38-cfffb9a5). Góp ý 4 lần cho một script phụ chụp ảnh bằng chứng,
  nhưng bỏ sót lỗi rõ nhất của chính script đó: đường dẫn cứng theo máy cá nhân
  (`/e/PRM-Lab03/...`).
- **Mức độ chưa phân biệt được.** 45/52 góp ý là Minor, gồm cả lỗi chạm thông báo không mở
  đúng màn (38-75b5e00c), vốn chạm vào một yêu cầu bắt buộc của FCM. Nhóm phải tự xếp lại
  thứ tự ưu tiên.
- **Lặp lại.** 38-7aebfd55 trùng 38-984d603f ở lần review sau; nhiều cặp góp ý cùng một
  gốc (38-ec03d165 và 38-93a4da9c, 29-5bfc8cca và 29-d8bd26d1).
- **Không review PR quá lớn.** PR #39 (ARTEMIS, 826 file) không có góp ý inline nào, nên
  phần test E2E chưa được AI xem.
- **Chỉ xem phần diff.** Mọi góp ý đều nằm trong các file PR thay đổi; AI không nêu vấn đề
  thiết kế chung, ví dụ có nên dùng `onConfigUpdated` cho mọi màn thay vì bump revision tay.

### Nhóm đã dùng kết quả thế nào

Lúc merge, chỉ 1/40 lỗi thật đã được sửa (38-322a383f); #28 và #29 đã merge mà chưa xử lý
góp ý nào. Đây là điểm yếu trong quy trình của nhóm, không phải của AI: góp ý có sẵn nhưng
không ai đọc trước khi merge.

Sau khi tổng hợp file này, nhóm sửa hai lỗi nặng nhất, mỗi lỗi một commit kèm test, nâng
lên 3/40:

- 38-bfeb007a (736453a): xoá hộp thư FCM khi đăng xuất (quyền riêng tư).
- 38-75b5e00c (5e13651): gắn màn đích cho thông báo foreground để chạm vào mở đúng màn
  (yêu cầu FCM).

Nên sửa tiếp, theo thứ tự:

1. 38-0f823abd: chỉ ghi `logout` và xoá user ID sau khi đăng xuất thành công.
2. 38-3c797d6d, 28-d3e86e35: thêm `context.mounted` trong màn Cài đặt.
3. 38-01eec050: hiện trạng thái lỗi khi hộp thư không tải được.
4. 28-5f2af2d9, 28-f26b506b: seeder không mặc định ghi vào project thật; deploy chờ CI.

### Có nên tin CodeRabbit không

Tin được như **một người review thứ hai cho lỗi cục bộ**: khi nó nói một dòng code có vấn đề
thì gần như luôn đúng (51/52). Không tin được ở hai điểm: **mức độ ưu tiên** (phải tự xếp
lại) và **độ phủ** (không thấy lỗi ngoài diff, bỏ qua PR quá lớn, không biết phạm vi dự
án). Vì vậy mỗi góp ý vẫn cần người đối chiếu với code trước khi sửa hoặc bỏ qua, như đã
làm trong bảng trên, và nó không thay được việc người trong nhóm review PR.
