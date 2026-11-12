# Báo cáo kiểm thử Final

## Firestore Security Rules

Ngày 10/11/2026, bộ Rules chạy trên Firestore Emulator với project `demo-prm393`. Lượt chạy dùng cổng 8180 do cổng 8080 đang bận.

| Ca | Kiểm tra | Kết quả |
|---|---|---|
| R-01 | `user` tự đổi vai trò thành `admin` bị từ chối. | Pass |
| R-20 | `user` gửi được thẻ của mình ở trạng thái `pending`. Tạo thẻ với trạng thái `approved` bị từ chối. | Pass |
| R-22 | `staff` duyệt được thẻ đang chờ. `user` tự duyệt bị từ chối. | Pass |

**Tổng bộ test hiện có:** 28 ca pass, 0 fail, 0 skip.

[Log đầy đủ của lượt chạy](../evidence/firestore/rules-final-2026-11-10.log.txt) · [Mã kiểm thử](../firebase/tests/firestore.rules.test.js)

Còn đối chiếu độ phủ ca cho phép và từ chối theo từng vai trò và collection.

## Mobile E2E bằng ARTEMIS

### Kết quả mới nhất · 12/11/2026

Đã build và cài bản code hiện tại lên `emulator-5554`, chạy thật T02 qua ARTEMIS Flash / OpenRouter. **3/3 pass (100%), 0 fail**, tổng thời gian pytest **172,32 giây**. Kịch bản: Hôm nay → Ghi nốt → Chiến thắng nhỏ → bỏ qua ảnh → chọn gợi ý Dọn phòng → Bỏ qua phần kể thêm → xác nhận Đã vào hũ cùng nội dung Dọn phòng. Ca này xác minh lưu bằng gợi ý nhanh; chưa kiểm chứng việc gõ nội dung tự do.

| Lượt | Kết quả | Thời gian JUnit | Phiên ARTEMIS |
|---|---|---|---|
| 1 | Pass | 62,359 giây | `0ba26d89-fb11-43ea-a2d0-8c8b6aa0a999` |
| 2 | Pass | 61,612 giây | `be1d97a7-d3f6-4923-8908-b116e6706e8e` |
| 3 | Pass | 48,258 giây | `03905ac0-e4e4-4914-bb2b-199e20637344` |

[Log pytest](../evidence/artemis/final-t02-2026-11-12.txt) · [JUnit ba lượt](../evidence/artemis/final-t02-2026-11-12.xml) · [Ảnh Workspace: ba phiên Completed và SAVED](../evidence/artemis/final-t02-workspace-2026-11-12.jpg)

Đã sửa kịch bản theo giao diện hiện tại, nâng timeout T02 lên 240 giây và bổ sung dừng tác vụ khi runner hết thời gian để tránh phiên chạy chồng nhau. T17–T27 mới có kịch bản, chưa chạy thực tế. Kết quả T02 này không thay cho kết quả toàn bộ Mobile E2E.

### Lịch sử các đợt trước

**Lượt chạy thật ngày 10/11/2026 trên bản Final:** smoke test trên `emulator-5554` trả **0/1**. ARTEMIS nhận tác vụ nhưng OpenRouter trả `401 User not found` trước khi model trả lời. Lỗi xác thực của lượt này đã được khắc phục trước đợt T02 ngày 12/11; smoke chưa chạy lại riêng. [JUnit lượt chạy thật](../evidence/artemis/junit-final-smoke-2026-11-10.xml)

**T02 · Ghi nốt trên bản Final:** đợt đầu cả ba lượt gặp `401 User not found`. Đợt lưu trong log hiện tại (13:09–13:22 ngày 10/11/2026) dùng kịch bản cũ với giới hạn 420 giây. Lượt 1 và 2 mất kết nối tới ARTEMIS, lượt 3 hết thời gian. Kết quả đợt này là **0/3**, chưa xác minh được thao tác lưu nốt. [Log PowerShell](../evidence/artemis/final-t02.txt) · [JUnit T02](../evidence/artemis/final-t02.xml)

Bảng dưới lấy từ JUnit đã lưu. Cột ba lượt dùng kết quả cùng một đợt chạy. Nếu có đợt chạy lại, kết quả được ghi riêng. Đây là minh chứng lịch sử, chưa xác nhận lại trên bản Final hiện tại.

**Đối chiếu với ARTEMIS Workspace:** phiên `8425e581-4bfc-45ee-ac21-be21387b8f11` sau đó hiện **Completed · SAVED** và màn xác nhận “Đã vào hũ!” với nốt `E2E test note`. Đây là cùng phiên lượt 3 mà pytest đã báo hết thời gian. Kết quả JUnit của đợt vẫn là **0/3**. [Ảnh Workspace và lịch sử phiên](../evidence/artemis/final-workspace-history-2026-11-10.jpg)

| Ca | Lượt 1 | Lượt 2 | Lượt 3 | Tỷ lệ pass | Minh chứng |
|---|---|---|---|---|---|
| Smoke · Mở app | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T02 · Ghi nốt | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T03 · Mở và xoá nốt trong Hũ | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T04 · Không lưu nội dung trống | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T05 · Hỏi giữ nháp khi thoát | Pass | Pass | Fail | 2/3 | [JUnit tổng hợp][full], [chạy lại 3/3][rerun] |
| T06 · Ghi nốt offline | Pass | Pass | Fail | 2/3 | [JUnit tổng hợp][full] |
| T07 · Mở màn Tự chủ | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T08 · Bắt đầu thở 90 giây | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T09 · Mở thử thách và để mai | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T10 · Chuyển giữa bốn tab | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T11 · Xem cờ tính năng trong Cài đặt | Pass | Pass | Pass | 3/3 | [JUnit tổng hợp][full] |
| T12 · Ra Home Android và quay lại | Fail | Fail | Fail | 0/3 | [JUnit tổng hợp][full], [chạy lại 3/3][rerun] |
| T13 · Ghi sự kiện Analytics khi lưu nốt | Fail | Pass | Pass | 2/3 | [JUnit T13–T14][extra], [chạy lại 3/3][rerun13] |
| T14 · Xuất Thẻ tuần theo kịch bản cũ | Pass | Pass | Pass | 3/3 | [JUnit T13–T14][extra] |
| T17–T18 · Android gửi thẻ, thấy chờ và nhận kết quả | — | — | — | Chưa chạy | [Kịch bản Final](../e2e_test/test_final_flows.py) |
| T19–T21 · AI bật, tắt và lỗi | — | — | — | Chưa chạy | [Kịch bản Final](../e2e_test/test_final_flows.py) |
| T22–T27 · Hành trình, nhật ký, Làm quen, vận động, sửa nốt, tự chủ | — | — | — | Chưa chạy | [Kịch bản Final](../e2e_test/test_final_flows.py) |

Ba lượt đo trên hệ thống đã deploy nằm trong [báo cáo luồng liên vai trò](cross-role-flow.md#đo-thời-gian). Các lượt đó được ghi riêng với ARTEMIS T17–T18.

Cần đối chiếu với danh sách luồng Lab 2 để xác nhận độ phủ. Chưa thấy kết quả ba lượt cho T15–T16 (đăng nhập email). Ca khám phá X01 có [một lượt fail][exploratory].

[full]: ../evidence/artemis/junit-full-run.xml
[rerun]: ../evidence/artemis/junit-rerun-t05-t12.xml
[extra]: ../evidence/artemis/junit-t13-t14.xml
[rerun13]: ../evidence/artemis/junit-rerun-t13.xml
[exploratory]: ../evidence/artemis/junit-x01.xml

## Checklist Web Admin

Đường dẫn dưới đây trỏ tới code triển khai. Điền ảnh minh chứng sau khi kiểm tra trên giao diện.

| Mục | Code liên quan | Ảnh cần lưu |
|---|---|---|
| Sai quyền | [Kiểm tra vai trò](../web_admin/lib/viewmodels/session_view_model.dart#L48), [thông báo từ chối](../web_admin/lib/screens/sign_in_screen.dart#L36) | Tài khoản `user` bị từ chối. |
| Tổng quan | [Dashboard và biểu đồ](../web_admin/lib/screens/dashboard_screen.dart#L20), [truy vấn đếm Firestore](../packages/core/lib/firebase/firestore_repositories.dart#L470) | Số liệu và biểu đồ hiển thị. |
| Kho thẻ | [Màn tìm, thêm, sửa và lưu trữ thẻ](../web_admin/lib/screens/catalog_screen.dart) | Kết quả tìm và trạng thái thẻ sau từng thao tác. |
| Hàng chờ duyệt | [Thao tác duyệt và từ chối](../web_admin/lib/screens/review_screen.dart#L168), [ghi duyệt và tin hộp thư](../packages/core/lib/firebase/firestore_repositories.dart#L136), [ghi từ chối và lý do](../packages/core/lib/firebase/firestore_repositories.dart#L180) | Một thẻ đã duyệt và một thẻ bị từ chối có lý do. |
| Thông báo | [Form gửi trên web](../web_admin/lib/screens/announcements_screen.dart), [ghi Firestore](../packages/core/lib/firebase/firestore_repositories.dart#L350), [hộp thư trên Android](../lib/viewmodels/community_view_model.dart#L121) | Cùng tiêu đề thông báo trên web và trong hộp thư app. |
| Người dùng | [Route chỉ cho admin](../web_admin/lib/router.dart#L34), [thao tác đổi vai trò](../web_admin/lib/screens/users_screen.dart#L125), [ghi vai trò](../packages/core/lib/firebase/firestore_repositories.dart#L458) | Vai trò mới của tài khoản test. |
| Trạng thái rỗng | [Kho thẻ](../web_admin/lib/screens/catalog_screen.dart#L71), [Hàng chờ duyệt](../web_admin/lib/screens/review_screen.dart#L64), [Thông báo](../web_admin/lib/screens/announcements_screen.dart#L109), [Người dùng](../web_admin/lib/screens/users_screen.dart#L64) | Màn danh sách rỗng hoặc không có kết quả tìm kiếm. |
| Trạng thái lỗi | [Giao diện lỗi và nút Thử lại](../web_admin/lib/widgets/admin_widgets.dart#L181), [ví dụ tải lại Kho thẻ](../web_admin/lib/screens/catalog_screen.dart#L83) | Thông báo lỗi và nút Thử lại. |

### Minh chứng đã lưu

- Chạy lại `flutter test --no-pub --reporter expanded` trong `web_admin/` ngày 10/11/2026: **10/10 pass**. Có ca từ chối tài khoản sai vai trò, duyệt trước khi mở Kho thẻ và báo lỗi khi hết thời gian chờ. [Log lượt chạy](../evidence/web-admin/flutter-test-2026-11-10.txt) · [Ca phiên đăng nhập và duyệt](../web_admin/test/session_test.dart) · [Ca App Check](../web_admin/test/app_check_test.dart)
- [Checklist Web Admin và 13 ảnh trên bản deploy](../evidence/web-admin/README.md), gồm [sai quyền](../evidence/web-admin/02-rejected-user-account.png), [dashboard](../evidence/web-admin/03-dashboard.png), [hàng chờ trống](../evidence/web-admin/07-review-empty.png), [ba thẻ đã duyệt](../evidence/web-admin/08-review-approved.png) và [tin trên Android](../evidence/web-admin/11-app-inbox-announcement.png). Checklist ghi rõ ảnh trạng thái lỗi sau bản sửa còn thiếu. Ảnh danh sách người dùng chưa chứng minh đã đổi vai trò.
- [Nốt AI trả gợi ý](../evidence/mobile-final/05-ai-free-tell-result.png), [nốt đã lưu](../evidence/mobile-final/06-ai-notes-saved.png) và [AI tắt qua Remote Config](../evidence/mobile-final/11-ai-off-remote-config.png) là minh chứng thao tác trên app. Các ảnh này được ghi riêng với kết quả ARTEMIS.

## Luồng liên vai trò trên bản deploy

Ba lượt ngày 10/11/2026 dùng Web Admin đã deploy và app Android kết nối Firebase thật. Thời gian tính từ lúc staff bấm Duyệt đến lần đầu quan sát được trạng thái mới trên app.

| Lượt | Thẻ | Web → app | Minh chứng |
|---|---|---|---|
| D-1 | Dọn một góc nhỏ | 21–23 giây, sau khi xử lý lỗi ở bước duyệt | [App hiện đã duyệt](../evidence/cross-role/03-phone-approved-run1.png) |
| D-2 | Giãn cơ 5 phút | ≤ 3,4 giây | [App hiện đã duyệt](../evidence/cross-role/04-phone-approved-run2.png) |
| D-3 | Đi bộ 10 phút | ≤ 2,3 giây | [App hiện đã duyệt](../evidence/cross-role/05-phone-approved-run3.png) |

[Hộp thư có đủ ba tin](../evidence/cross-role/06-phone-inbox-3-messages.png) · [Phương pháp đo và lỗi ở D-1](cross-role-flow.md)

## AI review code mới của Final

Review tĩnh bằng OpenAI Codex ngày 10/11/2026 trên code Nốt AI của nhánh `main` tại `f8aa231`. Đây là góp ý của Codex. Cả ba góp ý đã được xử lý trong commit `aa88f70`. Flutter Analyze sạch và 15/15 ca trong `free_tell_flow_test.dart` và `onboarding_flow_test.dart` pass, gồm hai ca hồi quy mới.

| ID | Vị trí | Vấn đề | Quyết định và lý do |
|---|---|---|---|
| CR-F01 | [`FirebaseAiService._ask`](../lib/firebase/firebase_ai_service.dart#L53) | Lệnh ghi `ai_request` được chờ trước khối `try`. Nếu Analytics ném lỗi, lệnh gọi Gemini bị bỏ qua, trong khi ViewModel chỉ bắt `AiException`. Ghi `ai_error` cũng có thể che lỗi AI ban đầu. | **Đã sửa — `aa88f70`.** Ghi Analytics theo cơ chế best effort để lỗi đo lường không chặn Gemini hoặc che nguyên nhân fallback. |
| CR-F02 | [`FirebaseAiService.sortNotes`](../lib/firebase/firebase_ai_service.dart#L130) | Ép kiểu trực tiếp `type`, `title` và `mood` sang `String?` sau khi ra khỏi khối bắt lỗi của `_ask`. Nếu dữ liệu trả về sai kiểu, `TypeError` có thể thoát khỏi nhánh fallback và để màn ở trạng thái đang đọc. | **Đã sửa — `aa88f70`.** Kiểm tra kiểu trước khi tạo model và chuyển dữ liệu sai sang `AiException(parse)`. |
| CR-F03 | [`FreeTellViewModel.save`](../lib/viewmodels/free_tell_view_model.dart#L189) | Sau mỗi lần chờ ghi Firestore, lượt kế tiếp đọc lại `state.mood`. Sau khi ghi xong còn đọc Analytics provider trước khi kiểm tra `ref.mounted`. Rời màn giữa lúc ghi có thể làm gián đoạn lượt lưu nhiều nốt hoặc bỏ mất số lượng đã lưu trên giao diện. | **Đã sửa — `aa88f70`.** Giữ nguyên tâm trạng của lượt lưu và dừng trước lần ghi tiếp theo nếu màn đã đóng. Lần ghi đang chờ có thể hoàn tất. |
