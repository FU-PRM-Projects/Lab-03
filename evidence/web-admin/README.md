# Web admin: checklist

Đề Final mục 9: *"Main action of each screen, role rejection, empty and error
states; a screenshot each"*. Chụp ngày 10/11/2026 trên bản deploy
`https://prm393-not-lab3.web.app/admin/` (Chrome, màn rộng 1920 px), tài khoản
admin "Thị Kim Thúy Đoàn".

| # | Màn | Kiểm tra | Kết quả | Ảnh |
|---|---|---|---|---|
| 1 | Đăng nhập | Nền hoạ tiết, nút Google chuẩn | Đạt | [`01-sign-in.png`](01-sign-in.png) |
| 2 | Đăng nhập | **Từ chối sai vai trò**: đăng nhập bằng tài khoản `role = user` → "Tài khoản này không có quyền vào web admin", nút đăng nhập tài khoản khác (đã che email) | Đạt | [`02-rejected-user-account.png`](02-rejected-user-account.png) |
| 3 | Tổng quan | 5 số liệu từ truy vấn `count()` (4 người dùng, 25 thẻ, 0 chờ duyệt, 3 đã xử lý, 0 thông báo) và 3 biểu đồ | Đạt | [`03-dashboard.png`](03-dashboard.png) |
| 4 | Kho thẻ | **Tìm kiếm** "đi bộ": còn 5 thẻ khớp, có thẻ "Người dùng đề xuất" vừa duyệt | Đạt | [`04-catalog-search.png`](04-catalog-search.png) |
| 5 | Kho thẻ | **Sửa** thẻ: form chủ đề, tên, mẹo, câu mẫu, số phút, cấp, thứ tự có đếm ký tự | Đạt | [`05-catalog-edit.png`](05-catalog-edit.png) |
| 6 | Kho thẻ | **Hiện thẻ đã lưu trữ** (lưu trữ thay cho xoá), danh sách theo chủ đề, cấp | Đạt | [`06-catalog-show-archived.png`](06-catalog-show-archived.png) |
| 7 | Hàng chờ duyệt | **Trạng thái trống**: "Không còn thẻ nào chờ duyệt" kèm Tụi Nốt | Đạt | [`07-review-empty.png`](07-review-empty.png) |
| 8 | Hàng chờ duyệt | **Đã duyệt**: 3 thẻ của luồng liên vai trò D-1…D-3, giờ gửi, giờ xử lý, mã thẻ trong kho | Đạt | [`08-review-approved.png`](08-review-approved.png) |
| 9 | Thông báo | **Trạng thái trống** ("Chưa có thông báo nào") và form đang soạn | Đạt | [`09-announcement-form.png`](09-announcement-form.png) |
| 10 | Thông báo | **Gửi** "Bạn đã vận động chưa ?": hiện trong danh sách lúc 10:56, form được xoá | Đạt | [`10-announcement-sent.png`](10-announcement-sent.png) |
| 11 | App (Galaxy A70) | Thông báo vừa gửi tới **hộp thư của app theo thời gian thực** (Thông báo chung · 10:56; chụp lại đủ độ phân giải 1080×2400 ngày 11/11 nên hiện "Hôm qua") | Đạt | [`11-app-inbox-announcement.png`](11-app-inbox-announcement.png) |
| 12 | Người dùng | Danh sách người dùng có tìm kiếm; chỉ admin đổi vai trò; vai trò của chính mình bị khoá ("(bạn)", ô mờ). Đã che email | Đạt | [`12-users.png`](12-users.png) |
| 13 | Tổng quan | **Trạng thái đang tải**: "Đang đếm số liệu…", nút Làm mới mờ | Đạt | [`13-dashboard-loading.png`](13-dashboard-loading.png) |
| 14 | Đổi vai trò khi đang mở | Tab đang ở màn từ chối; đổi `role` của tài khoản đó thành `staff` trên Console → tab **tự vào Tổng quan**, nhãn "Staff", không tải lại trang | Đạt | [`14-live-role-user-to-staff.png`](14-live-role-user-to-staff.png) |
| 15 | Đổi vai trò khi đang mở | Đổi lại `role = user` → tab đang ở Tổng quan **tự về màn từ chối** (góp ý CR-F1). Đã che email | Đạt | [`15-live-role-staff-to-user.png`](15-live-role-staff-to-user.png) |

## Trạng thái lỗi

Năm màn dữ liệu (Tổng quan, Kho thẻ, Hàng chờ duyệt, Thông báo, Người dùng)
dùng chung `MessageView.error` khi tải lỗi (Tụi Nốt "lạc" + câu báo + nút thử
lại); màn đăng nhập có nhánh lỗi riêng "Chưa kiểm tra được tài khoản". Lỗi
thật gặp trên bản deploy khi chạy luồng liên vai trò: bấm Duyệt hiện *"Có lỗi
xảy ra. Thử lại sau ít phút."* và giữ thẻ ở hàng chờ (đã sửa ở PR #70, xem
[`docs/cross-role-flow.md`](../../docs/cross-role-flow.md)). Chưa có ảnh chụp
trạng thái lỗi.

## Phát hiện khi chụp trạng thái lỗi

Tắt mạng rồi bấm Làm mới ở Tổng quan: màn quay vòng mãi ở "Đang đếm số
liệu…" (ảnh 13) thay vì báo lỗi, vì truy vấn `count()` của Firestore chờ máy
chủ không giới hạn. Đã sửa: Tổng quan chờ tối đa 15 giây rồi hiện trạng thái
lỗi *"Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại."*, và mọi lỗi hết
giờ khác (như bước Duyệt) cũng báo như lỗi mạng thay vì "Có lỗi xảy ra". Ảnh
trạng thái lỗi chụp sau khi bản sửa được deploy.

### Phát hiện lần 2 (11/11/2026): timeout 15 giây bị Riverpod thử lại che mất

Tài khoản staff, chặn riêng request `runAggregationQuery` trong tab (giả lập
mất kết nối tới Firestore) rồi bấm Làm mới: sau **hơn 3 phút** màn vẫn ở
"Đang đếm số liệu…", số request bị chặn tăng dần (20 → 70). Nguyên nhân:
Riverpod 3 mặc định **tự thử lại provider lỗi tới 10 lần**
(`ProviderContainer.defaultRetry`, chờ 0,2 → 6,4 giây) và giữ trạng thái
`AsyncLoading` trong lúc thử lại; `TimeoutException` không phải `Error` nên
cũng bị thử lại. Vì vậy bản sửa "chờ tối đa 15 giây" ở trên chưa có tác dụng
trên bản deploy. Đã sửa: cả hai app dùng `ProviderScope(retry: noRetry)`, test
`web_admin/test/dashboard_error_test.dart`. Ảnh trạng thái lỗi chụp sau khi
bản này được deploy.
