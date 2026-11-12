# App mobile (Final): chạy trên máy thật

Chạy ngày 10/11/2026 trên **Samsung Galaxy A70 (SM-A705F, Android 11)**, bản
debug từ `main` (commit `1aec01a`, sau PR #65–#68), nối Firebase thật
`prm393-not-lab3`. App Check: debug provider, debug token của máy đã đăng ký
cho `lab03 (android)`; Firebase AI Logic đang Enforce App Check.

## Onboarding (A2, S13a–g)

| Ảnh | Cho thấy |
|---|---|
| [`01-onboarding-q1.png`](01-onboarding-q1.png) | Câu 1/4: mức ngại bắt chuyện với người lạ |
| [`02-onboarding-q4.png`](02-onboarding-q4.png) | Câu 4/4: chọn tối đa 2 mục tiêu |
| [`03-onboarding-starter-plan.png`](03-onboarding-starter-plan.png) | Hồ sơ khởi đầu "Bạn nhỏ thân thiện", 3 thẻ đầu tiên, giờ nhắc 21:00 theo câu trả lời "buổi tối" |

## Nốt AI · Kể tự do (A1, S03b) với Gemini thật

| Ảnh | Cho thấy |
|---|---|
| [`04-ai-consent.png`](04-ai-consent.png) | Lần đầu dùng: sheet nói rõ gửi gì cho Gemini, không gửi gì, tắt ở đâu |
| [`05-ai-free-tell-result.png`](05-ai-free-tell-result.png) | Gemini tách đoạn kể thành 3 nốt (Chiến thắng / Tự chủ / Nhật ký) và tâm trạng "Ổn"; nhãn **"Gợi ý từ Nốt AI · kiểm tra trước khi lưu"**, đổi được loại, sửa được tiêu đề, bỏ chọn được |
| [`06-ai-notes-saved.png`](06-ai-notes-saved.png) | "Đã lưu 3 nốt vào hũ", hũ tăng từ 11 lên 14 nốt, chuỗi ngày bắt đầu |

Đoạn kể nhập qua `adb shell input text` nên không dấu ("Sang nay minh day som
chay bo 2km quanh ho…"); Gemini vẫn hiểu và trả tiêu đề có dấu. Model:
`gemini-flash-lite-latest` (mặc định trong code, Remote Config chưa ghi đè).

## Thẻ tuần PDF (S11b, D-06): lưu và chia sẻ trên máy

| Ảnh / file | Cho thấy |
|---|---|
| [`07-weekly-card.png`](07-weekly-card.png) | Thẻ tuần 09/11–15/11 có nút "Lưu thẻ tuần (PDF)" |
| [`08-pdf-share-sheet.png`](08-pdf-share-sheet.png) | Hộp chia sẻ của Android mở với `weekly-2026-W46.pdf`, đủ màn hình (chụp lại 11/11/2026; hàng danh bạ Messenger đã làm mờ) |
| [`09-pdf-saved.png`](09-pdf-saved.png) | "Đã lưu thẻ tuần vào máy. weekly-2026-W46.pdf · 15,4 KB" và nút "Chia sẻ PDF" |
| [`10-pdf-file.png`](10-pdf-file.png), [`weekly-2026-W46.pdf`](weekly-2026-W46.pdf) | File thật lấy từ máy (`adb exec-out run-as com.quanphungg.lab03 cat app_flutter/reports/weekly-2026-W46.pdf`), 15 775 byte, tiếng Việt đúng |

File nằm ở thư mục riêng của app (`app_flutter/reports/`), không lên Cloud
Storage. Metadata ghi ở Firestore `users/{uid}/reports/2026-W46`.

## Tắt AI bằng Remote Config

| Ảnh | Cho thấy |
|---|---|
| [`11-ai-off-remote-config.png`](11-ai-off-remote-config.png) | Đặt `ai_enabled = false` (Boolean) trên Remote Config rồi Publish, mở lại app: Kể tự do hiện "Nốt AI đang nghỉ. Bạn vẫn ghi nốt tay như thường nhé.", không còn nút gọi Gemini, chỉ còn "Ghi tay". Luồng ghi nốt vẫn chạy khi không có AI |

Sau khi chụp, đặt lại `ai_enabled = true`.

## Từ chối tài khoản sai vai trò (đề Final mục 6)

Chạy ngày 11/11/2026 trên Galaxy A70, bản debug có `WrongRoleScreen` (nhánh
`docs/test-report`), tài khoản Google có `role = admin`.

| Ảnh | Cho thấy |
|---|---|
| [`12-wrong-role-admin.png`](12-wrong-role-admin.png) | Mở app bằng tài khoản admin: màn "Tài khoản này dành cho web admin", địa chỉ web admin, nút Đăng xuất, không có thanh tab |
| [`13-wrong-role-signed-out.png`](13-wrong-role-signed-out.png) | Bấm Đăng xuất: về S01 (Tiếp tục với Google / Đăng nhập bằng email) |

## Tài khoản user và nháp nhật ký (P4)

Chạy ngày 11/11/2026 trên Galaxy A70, bản **release** build từ `main` sau
PR #75 và #76, tài khoản "Thị Kim Thúy Đoàn" (`role = user`).

| Ảnh | Cho thấy |
|---|---|
| [`14-user-account-today.png`](14-user-account-today.png) | Tài khoản `user` mở app: vào thẳng S02 Hôm nay, có thanh tab, không bị màn từ chối chặn |
| [`15-journal-draft-typing.png`](15-journal-draft-typing.png) | Đang viết nhật ký (29 ký tự), chưa bấm Xong |
| [`16-journal-draft-resume.png`](16-journal-draft-resume.png) | Tắt hẳn app (`adb shell am force-stop`), mở lại rồi vào Viết nhật ký: hỏi "Tiếp tục bản nháp?" kèm số ký tự, nút "Bắt đầu trang mới" / "Viết tiếp" |
| [`17-journal-draft-restored.png`](17-journal-draft-restored.png) | Bấm Viết tiếp: chữ cũ được điền lại đúng |

Sau đó bấm Đóng → **Bỏ**, mở lại Viết nhật ký thì không còn hỏi: nháp đã bị
xoá. Không có nốt thử nào được lưu vào tài khoản.
