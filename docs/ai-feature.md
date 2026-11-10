# Tính năng AI: Nốt AI (Gemini qua Firebase AI Logic)

Final Assignment, mục 8. App gọi Gemini qua **Firebase AI Logic** (Gemini
Developer API, package `firebase_ai`), không có server riêng. Cùng một lớp
`AiService` phục vụ ba chỗ trong các luồng Lab 2:

| Tính năng | Màn (Figma) | Luồng Lab 2 | Mức của đề |
|---|---|---|---|
| **Nốt sắp xếp giúp** (chính) | S03b "Kể tự do" | A1: ghi nốt buổi tối | **Mức 2**: JSON có schema → `AiSortResult`, người dùng xem, sửa, chọn rồi mới lưu |
| Hồ sơ khởi đầu | S13f | A2: làm quen | Mức 2: JSON → `StarterPlan`, người dùng xem rồi bấm "Bắt đầu" |
| Câu chào cho phòng chung | S08d | D2: thử thách cấp 3 | Mức 2 (nhẹ): JSON `{lines[3]}`, người dùng chọn hoặc sửa trước khi sao chép |

## Luồng chính: Kể tự do

1. "Ghi nốt" hoặc nút + → sheet "Hôm nay bạn muốn ghi gì?" → **Kể tự do · Nốt AI**.
2. Người dùng kể một đoạn (tối đa `ai_max_chars`), bấm **Nhờ Tụi Nốt sắp xếp**.
3. Lần đầu: sheet **"Nốt AI sắp xếp giúp"** nói rõ gửi gì, không gửi gì; "Đồng ý và sắp xếp" bật `private/settings.aiEnabled` (tắt lại ở Cài đặt).
4. Tụi Nốt đang đọc (có nút Huỷ) → danh sách gợi ý có nhãn **"Gợi ý từ Nốt AI · kiểm tra trước khi lưu"**: mỗi nốt đổi được loại, sửa được tiêu đề, bỏ chọn được; tâm trạng gợi ý sửa được.
5. **Lưu N nốt** → các nốt vào hũ như nốt ghi tay. Đoạn kể không được lưu ở đâu.
6. `needs_support = true` → dialog "Hình như hôm nay hơi nặng nề" (người bạn tin, phòng tư vấn của trường, 115), dùng lại nội dung dialog P6.

Schema gửi kèm (`responseMimeType: application/json`, `responseSchema`):

```json
{
  "notes": [{ "type": "chien_thang | tu_chu | nhat_ky", "title": "string" }],
  "mood": "vui | on | binh_thuong | met | roi | null",
  "needs_support": "boolean"
}
```

Kết quả còn được kiểm tra lại trong app (`FirebaseAiService.sortNotes`): tối đa
5 nốt, tiêu đề ≤ 40 ký tự (dài hơn thì cắt), loại lạ bị bỏ, không có nốt nào
và không cần hỗ trợ thì coi là lỗi `parse`. Loại `thu_thach` không được AI tạo
vì nốt thử thách cần kết quả thử thách đi kèm.

## Yêu cầu của đề và cách đáp ứng

| Yêu cầu | Cách làm |
|---|---|
| App Check | `FirebaseAppCheck.activate` lúc khởi động (`firebase_bootstrap.dart`): debug provider ở bản debug, Play Integrity ở bản release, reCAPTCHA Enterprise (Fraud Defense) trên web khi build với `--dart-define=RECAPTCHA_SITE_KEY=…`. `firebase_ai` tự gắn token App Check vào mỗi lời gọi |
| Model, prompt, cờ bật / tắt từ Remote Config | `ai_enabled`, `ai_onboarding_enabled`, `ai_model` (mặc định `gemini-flash-lite-latest`), `ai_timeout_ms` (8000), `ai_max_chars` (500), `ai_prompt_sort`, `ai_prompt_onboarding`, `ai_prompt_greeting`. Đọc lại mỗi lần gọi (`AiConfig`), nên đổi trên Console có tác dụng sau khi tải lại cấu hình |
| Hết quota, mất mạng vẫn chạy | Mọi lỗi thành `AiException(reason)`. Kể tự do: giữ đoạn kể, câu báo theo lý do, nút **Thử lại** và **Ghi tay**. Làm quen: dùng bảng luật `StarterPlanRules` (S13g "Nốt AI đang nghỉ"). Câu chào: câu có sẵn `discord_greetings` (biến thể "AI nghỉ") |
| Không gửi dữ liệu cá nhân | Kể tự do: chỉ gửi đoạn kể, đã che email và số điện thoại (`scrubForAi`), cắt còn `ai_max_chars`; không gửi uid, tên, email tài khoản, ảnh, nốt cũ; prompt yêu cầu không lặp lại tên người. Làm quen: chỉ gửi các lựa chọn khảo sát và tên thẻ trong kho. Câu chào: chỉ tên thẻ và tên phòng |
| Gắn nhãn kết quả AI, cho sửa | Nhãn "Gợi ý từ Nốt AI · kiểm tra trước khi lưu" (S03b), "Tụi Nốt AI viết giúp · sửa thoải mái trước khi gửi" (S08d); mọi trường sửa được trước khi lưu / gửi |
| Analytics | `ai_request {feature, char_count}`, `ai_result_accepted {feature, item_count, edited_count}`, `ai_error {feature, reason}` với `reason` ∈ `disabled, quota, network, timeout, parse, blocked` |

Giới hạn còn lại: tên người viết trong đoạn kể không được che tự động (tiếng
Việt khó nhận diện tên chắc chắn); sheet đồng ý nói rõ điều này bằng việc ghi
"Gửi tới Gemini: đoạn bạn vừa kể", và prompt yêu cầu không lặp lại tên trong
tiêu đề.

## Kiểm thử

- `test/screens/free_tell_flow_test.dart` (AI giả): đồng ý lần đầu → gợi ý →
  bỏ một nốt, sửa một tiêu đề → lưu đúng 2 nốt và ghi `ai_result_accepted`;
  lỗi timeout giữ đoạn kể và hiện "Thử lại" / "Ghi tay"; `needs_support` hiện
  dialog hỗ trợ; `scrubForAi` che email và số điện thoại.
- `test/screens/onboarding_flow_test.dart`: AI tắt (mặc định trong test) thì
  dùng bảng luật và hiện "Nốt AI đang nghỉ".
- Firebase AI Logic và App Check không có trên Emulator: chạy với
  `USE_FIREBASE_EMULATOR=true` thì app dùng `DisabledAiService`, mọi flow đi
  nhánh dự phòng.

## Ví dụ thật

Chạy ngày 10/11/2026 qua Firebase AI Logic (Gemini Developer API), model
`gemini-flash-lite-latest`, đúng prompt `ai_prompt_sort` và response schema
của `FirebaseAiService.sortNotes`, kèm App Check token (debug token của web
app). Mỗi lần trả lời khoảng 2 giây. Đầu ra là JSON, app chuyển thành
`AiSortResult` và hiện từng nốt có nhãn **"Gợi ý của Nốt AI"** để người dùng
sửa loại, sửa tiêu đề hoặc bỏ trước khi lưu.

| # | Đầu vào (đoạn kể tự do) | Đầu ra của Gemini | Nhận xét |
|---|---|---|---|
| 1 | "Sáng nay mình dậy sớm chạy bộ 2km quanh hồ. Chiều lỡ ăn thêm gói snack dù đã định nhịn, nhưng tối mình không tự trách mà ngồi thở vài phút rồi bình tĩnh lại." | `chien_thang` "Chạy bộ 2km quanh hồ"; `nhat_ky` "Lỡ ăn thêm gói snack dù định nhịn"; `tu_chu` "Không tự trách và bình tĩnh lại"; mood `binh_thuong`; `needs_support` false | Tách đúng 3 loại nốt. Nốt 2 nên là nhật ký như AI chọn (không phải chiến thắng), người dùng giữ nguyên |
| 2 | "Hôm nay ở thư viện mình hỏi một bạn lạ chỗ để sạc pin, tim đập nhanh lắm nhưng bạn ấy chỉ rất vui vẻ. Về nhà mình viết vài dòng nhật ký cho buổi chiều mưa." | `chien_thang` "Lấy hết can đảm hỏi mượn chỗ sạc pin"; `nhat_ky` "Ghi lại vài dòng cảm xúc buổi chiều mưa"; mood `vui`; `needs_support` false | Đúng ý: hỏi người lạ là chiến thắng nhỏ. Tiêu đề 1 viết lại thành "hỏi mượn chỗ sạc pin" (câu gốc là hỏi chỗ sạc), người dùng có thể sửa |
| 3 | "Mấy hôm nay mình thấy mệt, làm gì cũng không nổi, tối nằm nghĩ lung tung tới khuya. Hôm nay chỉ dọn được cái bàn học thôi." | `chien_thang` "Mình đã dọn dẹp được cái bàn học"; `nhat_ky` "Mấy hôm nay thấy mệt và làm gì cũng không nổi"; `nhat_ky` "Tối nằm suy nghĩ lung tung đến khuya"; mood `met`; `needs_support` false | Biến việc nhỏ thành chiến thắng, đúng tinh thần app. `needs_support` false là hợp lý vì đoạn kể chỉ ở mức mệt; thẻ hỗ trợ dành cho dấu hiệu nặng hơn |

Đầu vào chỉ là đoạn kể (đã qua `scrubForAi`: bỏ email, số điện thoại), không
có tên, email hay ảnh người.

### Một lỗi đã xử lý: model ngừng hoạt động

Lần gọi đầu với model mặc định cũ `gemini-2.5-flash` trả
`HTTP 404 This model models/gemini-2.5-flash is no longer available to new
users`. Trước đó, khi chưa có App Check token, API trả `HTTP 401 Firebase App
Check token is invalid` (AI Logic đã bật Enforce).

Cách app xử lý: mọi lỗi không phải hết lượt hay hết giờ đi vào nhánh
`AiErrorReason.network` của `FirebaseAiService`. App log `ai_error`
(`reason = network`), giữ nguyên đoạn kể và hiện *"Tụi Nốt chưa đọc được vì
mạng chậm. Kiểm tra Wi-Fi rồi thử lại, hoặc ghi tay."* cùng nút ghi tay, nên
người dùng vẫn lưu được nốt. Cách sửa không cần phát hành app: đổi `ai_model`
trên Remote Config. Code đổi mặc định sang `gemini-flash-lite-latest`
(`gemini-3.8-flash` không trả lời trong 60 giây nên không hợp với giới hạn
`ai_timeout_ms` 8 giây).

## Cần bật trên Firebase Console

1. **AI Logic** → Get started → **Gemini Developer API**.
2. **App Check**: đăng ký app Android (Play Integrity; bản debug thêm debug
   token in ra logcat: `DebugAppCheckProvider: Enter this debug secret…`) và web
   app (Fraud Defense / reCAPTCHA Enterprise). Bật Enforce cho **Firebase AI Logic** và **Cloud
   Firestore** sau khi Metrics cho thấy request đã được xác minh.
3. **Remote Config**: thêm các tham số `ai_*` ở trên (giá trị mặc định có sẵn
   trong app nên không thêm vẫn chạy).
