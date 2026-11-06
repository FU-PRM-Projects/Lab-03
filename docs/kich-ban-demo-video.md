# Kịch bản quay Nốt · Lab 3

**9 phút 55 giây** · **Android bên trái** · **Firebase Console bên phải**

Bám theo **Lab 3, mục 9, trang 12** và code Nốt ở `main` (`9e5e34f`). Đọc phần **Lời thoại** khi quay. Dùng các dòng **Bấm** và **Chỉ** để biết cần mở gì.

**Luồng Nốt**  
Google → Hôm nay → Ghi nốt → Hũ → Dừng lại / Stress? → Thử thách → Hành trình.

**Luồng code**  
Màn hình → ViewModel Riverpod → service → Firebase. Ví dụ **Lưu vào hũ** → `NoteComposerViewModel` → `NoteRepository` → Firestore ghi nốt theo UID.

[Bỏ qua tới lệnh chuẩn bị](#chuẩn-bị-ngoài-thời-lượng-video)

## 01 · Giới thiệu | 00:00–00:30

- **Bấm** — Mở Nốt trên Android và đặt cửa sổ cạnh Firebase Console.
- **Chỉ** — Tên dự án **Not - PRM393 Lab 3**.

**Lời thoại**

> Em chào thầy cô. Đây là Nốt, ứng dụng giúp người dùng ghi lại những việc nhỏ mình làm được trong ngày. Em sẽ đăng nhập, ghi một nốt rồi tìm lại đúng nốt đó trên Firebase. Sau đó em sẽ thử hai luồng tự chủ và thử thách, rồi mở Thẻ tuần để xem các hoạt động được tổng hợp ra sao.

## 02 · Đăng nhập Google | 00:30–01:15

- **Bấm** — **Tiếp tục với Google** → chọn tài khoản demo → **Hôm nay**.
- **Chỉ** — **Firebase → Authentication → Users**. Tìm tài khoản demo có provider Google. Che thông tin cá nhân khi quay.

**Lời thoại**

> Em bấm Tiếp tục với Google và chọn tài khoản demo. Sau khi đăng nhập, Nốt đưa em về màn Hôm nay. Trên tab Users của Firebase, đây là tài khoản em vừa dùng, với phương thức đăng nhập Google. Firebase gán cho tài khoản một UID. Lát nữa em sẽ dùng đúng UID này để tìm nốt em tạo.

## 03 · Ghi nốt và đồng bộ | 01:15–02:45

1. **Bấm** — **Hôm nay → Ghi nốt → Chiến thắng nhỏ**. Chọn tâm trạng, bấm **Tiếp**.
2. **Chỉ** — Nút **Tiếp** bị khoá khi tiêu đề trống. Nhập `Demo Lab 3 – Hoàn thành bài PRM` rồi bấm **Tiếp**.
3. **Bấm** — Ngắt mạng Android → **Lưu vào hũ** → chờ banner **Offline · đã lưu trên máy**. Bật mạng lại rồi mở nốt trong **Hũ**.
4. **Chỉ** — **Firestore → Data → users → UID demo → notes**. Mở document theo đúng tiêu đề vừa nhập, chỉ `title`, `mood`, `type` và `createdAt`.

**Lời thoại**

> Từ Hôm nay, em bấm Ghi nốt, chọn Chiến thắng nhỏ và chọn tâm trạng. Em để trống tiêu đề một chút để thầy cô thấy nút Tiếp đang khoá. Giờ em nhập “Demo Lab 3 – Hoàn thành bài PRM” và đi tới bước lưu.

**Khi thấy banner offline**

> Em đã ngắt mạng trước khi lưu. Nốt báo đã lưu trên máy. Giờ em bật mạng lại và mở Hũ để tìm nốt vừa ghi.

**Khi thấy document trên Firestore**

> Bên Firebase, em mở thư mục nốt của đúng UID lúc nãy. Đây là bản ghi có cùng tiêu đề. Mình thấy cả tâm trạng, loại nốt và thời điểm tạo.

**Nếu quay nhánh giữ nháp** — Nhập tiêu đề → quay lại → **Giữ nháp** → **Tiếp tục ghi nốt** → lưu. Thay đoạn mất mạng bằng câu dưới đây, rồi chuyển sang Firestore khi thấy bản ghi.

> Em đang nhập dở thì bấm quay lại. Nốt hỏi có muốn giữ nháp. Em chọn giữ rồi mở lại từ Hôm nay. Tiêu đề vẫn còn, nên em có thể tiếp tục và lưu vào Hũ.

## 04 · Tự chủ và bài thở | 02:45–03:30

- **Bấm** — **Hôm nay → Dừng lại → Ghi lại vừa rồi → Mình đã dừng được**. Nếu có thời gian, mở thêm nhánh **Mình lỡ lướt quá đà**.
- **Bấm** — **Hôm nay → Stress?**. Cho đồng hồ chạy vài giây rồi bấm **Cơn sóng đã hạ**.

**Lời thoại**

> Nốt vừa rồi là một việc em chủ động ghi lại. Với lúc đang lướt điện thoại và muốn dừng, em có lối tắt Dừng lại ngay ở Hôm nay. Em chọn Ghi lại vừa rồi, rồi chọn Mình đã dừng được. App ghi một lần tự chủ vào Hũ. Nếu lỡ lướt quá đà, em có thể ghi lại cảm xúc dưới dạng nhật ký.

> Cũng từ Hôm nay, em bấm Stress? để mở bài thở. Em để đồng hồ chạy vài giây rồi bấm Cơn sóng đã hạ để sang phần gợi ý tiếp theo.

## 05 · Thử thách | 03:30–04:15

- **Bấm** — **Thử thách** → thẻ **Dũng cảm** → **Nhận thử thách** → chọn mức hồi hộp → **Xong rồi → Không như ý → Lưu**.
- **Chỉ** — Nốt vừa tạo trong **Hũ**, hoặc tiến độ ở **Firestore → users → UID demo → challengeProgress**.

**Lời thoại**

> Tiếp theo em mở tab Thử thách và nhận một thẻ Dũng cảm. Em chọn mức hồi hộp, bấm Xong rồi và ghi kết quả Không như ý. Vì người dùng đã thử, app vẫn tính một lượt cho chủ đề và lưu lại kết quả thành nốt. Sau khi ghi xong, em sang Hành trình để xem các nốt trong tuần được tổng hợp thế nào.

## 06 · Xuất PDF | 04:15–05:05

- **Bấm** — **Hành trình → Thống kê → Mục tiêu tuần → Lưu thẻ tuần (PDF)**.
- **Chỉ** — Tiến độ hoặc link trong app. Nếu upload thành công, mở **Storage → Files → reports → UID demo → weekly-…pdf** và chỉ thời điểm cập nhật.

**Lời thoại khi bấm lưu**

> Trong Hành trình, em mở Thống kê rồi chạm Mục tiêu tuần để xem Thẻ tuần. Em bấm Lưu thẻ tuần để app tạo PDF và gửi tệp lên Storage.

**Khi thấy tệp trên Storage**

> Bên Storage, em mở thư mục reports của tài khoản demo. Đây là tệp PDF của tuần này. Thời điểm cập nhật khớp với lần em vừa bấm lưu.

**Nếu upload lỗi** — Quay thông báo và nút **Thử lại**. Nói “Lần tải này chưa hoàn tất. App báo lỗi và cho phép thử lại.” Phần chứng minh upload vẫn còn thiếu.

## 07 · Analytics | 05:05–05:50

- **Bấm** — **Analytics → DebugView** → chọn đúng thiết bị → mở `note_saved`.
- **Chỉ** — `mood`, `note_type` và giờ phát sinh. Có thể chỉ thêm `login`, `self_control_logged`, `challenge_completed`. Nếu chưa thấy sự kiện lúc offline, mở lại một nốt khi online để tạo `note_viewed`.

**Lời thoại**

> Nãy giờ em đã đối chiếu dữ liệu của người dùng. Giờ em mở DebugView để xem các thao tác được ghi thành sự kiện như thế nào. Em chọn thiết bị đang quay và mở sự kiện note_saved. Hai trường này cho biết loại nốt và tâm trạng đã chọn. Tiêu đề và nội dung nốt nằm trong Firestore của tài khoản.

## 08 · Push notification | 05:50–06:40

1. **Bấm** — Nhấn **Home** trên Android để đưa Nốt về nền.
2. **Bấm** — Trong **Messaging**, mở bản nháp `Nốt – Demo Lab 3` → **Send test message** → **Test**. Che token.
3. **Chỉ** — Thông báo Android. Chạm vào để mở Nốt, rồi tìm tin trong **Cài đặt → Thông báo đẩy (FCM)**.

**Lời thoại**

> Ở các bước trước, thao tác bắt đầu từ app. Lần này em đưa app về nền rồi gửi một thông báo thử từ Firebase đến thiết bị đang quay.

**Khi Android đã nhận thông báo**

> Android vừa hiện thông báo cùng tiêu đề em gửi. Em chạm để mở Nốt, rồi vào Cài đặt để tìm tin đó trong hộp thư.

Nếu muốn mở thẳng **Hũ** khi chạm, tin cần có dữ liệu `route=/jar`. [Hướng dẫn FCM](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)

## 09 · Remote Config | 06:40–07:35

1. **Chỉ** — **Cài đặt → Remote Config**. Đọc trạng thái **thẻ tự thêm** hiện tại.
2. **Bấm** — Trên Console, đổi `custom_challenges_enabled` sang giá trị đối diện → **Publish changes**.
3. **Bấm** — Về app, chạm dòng **Remote Config** để làm mới. Chỉ trạng thái trước và sau.

**Lời thoại**

> Ở Cài đặt, dòng Remote Config đang cho biết thẻ tự thêm [đang bật/đang tắt]. Em sang Firebase, đổi giá trị của cờ này và bấm Publish changes. Giờ em quay lại app và chạm Remote Config để lấy cấu hình mới.

**Khi app đổi trạng thái**

> Trên màn hình, thẻ tự thêm đã chuyển sang [tắt/bật]. App áp dụng thay đổi ngay trong phiên đang chạy, không cần build lại.

## 10 · Crashlytics | 07:35–08:10

- **Bấm** — **Cài đặt → Thử crash (dev)**.
- **Chỉ** — Trên **Crashlytics**, mở báo cáo thử và báo cáo non-fatal thực tế khi có. Chỉ key `screen` và trường user, che giá trị định danh.

**Lời thoại**

> Em bấm Thử crash để gửi một báo cáo được đánh dấu fatal. Em chuyển sang Crashlytics để xem báo cáo từ thiết bị.

**Khi mở được báo cáo có ngữ cảnh**

> Trong chi tiết lỗi, trường screen cho biết màn hình liên quan và mục user giúp nhóm đối chiếu tài khoản gặp lỗi.

**Nếu báo cáo mới chưa hiện** — Nói “Báo cáo vừa gửi đang chờ đồng bộ.” Có thể mở [ảnh non-fatal](../evidence/crashlytics/nonfatal-list.png) và [ảnh keys và user](../evidence/crashlytics/keys-and-user.png), ghi rõ là bằng chứng từ lần chạy trước.

## 11 · ARTEMIS chạy trực tiếp | 08:10–09:10

- **Bấm** — Về **Hôm nay**, chạy lệnh dưới đây trong terminal test đã chuẩn bị. Giữ Android trong khung hình để thấy agent tự thao tác.

```powershell
uv run pytest --runs 1 -k t11 -s
```

- **Chỉ** — Dòng kết quả pytest. Đọc đúng trạng thái trên màn hình.

**Lời thoại**

> Vừa rồi em tự mở Cài đặt để kiểm tra cấu hình. Bây giờ em chạy T11 để ARTEMIS tự thao tác trên cùng thiết bị. Ca test yêu cầu agent tìm dòng Remote Config và đọc lại trạng thái cờ tính năng. Pytest sẽ đối chiếu nội dung agent trả về với kết quả mong đợi.

**Khi terminal hiện PASSED**

> Terminal báo PASSED. Ca T11 vừa chạy đạt trên thiết bị đang quay.

Số liệu nếu cần đọc thêm **35/36 lượt của T01–T12 sau khi chạy lại T05 và T12**. T13–T16 và X01 chưa có kết quả trong báo cáo. [Kế hoạch và kết quả test](test-plan.md)

## 12 · Code review và kết | 09:10–09:55

- **Chỉ** — Mở [ghi nhận CodeRabbit](code-review.md), tìm **`38-bfeb007a`**. Chuyển sang commit **`736453a`** và chỉ đoạn xoá hộp thư trong luồng đăng xuất.
- **Bấm** — Nếu còn thời gian, **Cài đặt → Đăng xuất**.

**Lời thoại**

> Cuối cùng, đây là một lỗi CodeRabbit phát hiện trong luồng đăng xuất. Hộp thư vẫn còn trên máy, nên tài khoản đăng nhập sau có thể thấy thông báo của người trước. Nhóm chấp nhận góp ý vì tin nhắn có thể chứa thông tin riêng tư. Em mở commit 736453a. Đoạn này xoá hộp thư khi đăng xuất, rồi yêu cầu giao diện nạp lại danh sách.

> Em vừa đi từ thao tác trên Nốt đến dữ liệu và báo cáo trên Firebase, rồi chạy một ca kiểm thử trực tiếp. Em cảm ơn thầy cô.

---

## Chuẩn bị ngoài thời lượng video

1. Mở [Firebase Console của Nốt](https://console.firebase.google.com/project/prm393-not-lab3/overview) bằng tài khoản đã có quyền. Chuẩn bị sẵn các tab **Authentication → Users**, **Firestore Database → Data**, **Storage → Files**, **Analytics → DebugView**, **Messaging**, **Remote Config** và **Crashlytics**. Kiểm tra trước quyền xuất bản Remote Config. Ghi lại giá trị ban đầu của cờ sẽ đổi để trả về sau buổi quay.
2. Mở máy ảo rồi kiểm tra ID. Nếu AVD đã bật thì bỏ qua lệnh launch. Chờ Android vào màn hình chính trước khi chạy app. Đổi `emulator-5554` ở các lệnh nếu máy có ID khác. `RoomieMatch_API_36` là tên AVD trên máy.

   ```powershell
   Set-Location D:\Lab-03
   flutter emulators
   flutter emulators --launch RoomieMatch_API_36
   flutter devices
   adb -s emulator-5554 shell setprop debug.firebase.analytics.app com.quanphungg.lab03
   flutter run -d emulator-5554
   ```

   Dùng lệnh chạy thông thường để nối Firebase thật. Cờ `USE_FIREBASE_EMULATOR=true` chuyển Auth, Firestore và Storage sang backend cục bộ. Nếu PowerShell chưa tìm thấy `adb`, dùng `adb.exe` trong thư mục `platform-tools` của Android SDK. [Firebase DebugView](https://firebase.google.com/docs/analytics/debugview)
3. Thử đăng nhập Google trên đúng máy Android sẽ quay. Dùng tài khoản demo, sau đó đăng xuất để bắt đầu video từ màn chào. Kiểm tra quyền thông báo, thử gửi tới thiết bị và chuẩn bị token ngoài khung hình. Nếu còn lỗi Google trên Android, đối chiếu SHA-1 của build debug với app `com.quanphungg.lab03` và kiểm tra lại `android/app/google-services.json`.

   ```powershell
   adb -s emulator-5554 logcat -d -s flutter | Select-String '\[fcm\] token:'
   ```

4. Thử **Lưu thẻ tuần (PDF)** một lần và xác nhận kết quả trong Storage. Nếu bucket chưa sẵn sàng, dùng lời thoại nhánh lỗi ở dưới. Có thể gửi **Thử crash (dev)** trước khi quay vài phút để báo cáo có thời gian hiện. Khi quay, nói rõ thời điểm của báo cáo đang mở.
5. Chuẩn bị ARTEMIS trước. Chạy `uv sync` trong cả hai thư mục dưới đây một lần, chuẩn bị `OPEN_ROUTER_API_KEY` trong `D:\Lab-03\tools\artemis\.env` và để server chạy sẵn. Để sẵn lệnh pytest trong terminal thứ hai. Giữ tài khoản demo đăng nhập khi chạy test. [Hướng dẫn ARTEMIS trong repo](../e2e_test/README.md)

   **Terminal server**

   ```powershell
   Set-Location D:\Lab-03\tools\artemis
   uv run python -m artemis ui --port 8000 --no-open
   ```

   **Terminal chạy test**

   ```powershell
   Set-Location D:\Lab-03\e2e_test
   $env:ARTEMIS_DEVICE_SERIAL = 'emulator-5554'
   uv run pytest --runs 1 -k t11 -s
   ```

## Sau khi quay

- Trả `custom_challenges_enabled` về giá trị đã ghi trước buổi quay và xuất bản lại nếu đã đổi. Tắt Analytics debug bằng `adb -s emulator-5554 shell setprop debug.firebase.analytics.app .none.`.
- Rà lại video để phân biệt thao tác chạy trực tiếp với bằng chứng cũ. Giữ cảnh Firebase đủ lâu để đọc được kết quả. Với upload, thông báo, crash hay test, đọc lời thoại tương ứng với kết quả thực tế.
- Kịch bản dùng cho **Nốt Lab 3**. Các phần web admin, luồng liên vai trò và AI trong Final Assignment cần video chứng minh riêng khi có bản triển khai tương ứng.
