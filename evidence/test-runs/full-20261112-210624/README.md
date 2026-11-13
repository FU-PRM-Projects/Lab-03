# Full test — 12/11/2026

Đợt đang chạy; chưa phải báo cáo hoàn tất. Mã nguồn và thiết bị ghi trong `manifest.json`.

- App: 305/305; Web admin: 14/14; Core: 5/5. Log `flutter-*.txt`.
- Firestore Rules: 30/30 trên project demo, cổng 8180. Log `firestore-rules-8180.txt`. Cổng 8080 bận nên lượt đầu không chạy được.
- ARTEMIS chuẩn đang chạy mỗi ca 3 lần. Log `artemis-standard.txt`; JUnit có khi pytest kết thúc.
- T15/T16: đã chuẩn bị tài khoản email test riêng; cần xác nhận gửi thông tin đăng nhập cho model OpenRouter trước khi thực thi. Không có mật khẩu trong thư mục minh chứng.
- T19 cần chạy riêng khi AI đã tắt bằng Remote Config; CLI hiện chưa đăng nhập. Không thay giá trị AI giữa lúc bộ chuẩn đang chạy.
- X01 khám phá là phiên riêng, chưa bắt đầu trong đợt này.
