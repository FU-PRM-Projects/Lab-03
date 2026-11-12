# Cách vẽ sơ đồ dữ liệu (ERD)

Hai sơ đồ dữ liệu của dự án dùng **một** ký hiệu và tách đúng hai mức chi tiết.

| | Mức khái niệm (conceptual) | Mức vật lý (physical) |
|---|---|---|
| Nơi | Slide "Database design: conceptual" | [`erd.svg`](erd.svg), slide "Database design: physical" |
| Thực thể | Danh từ số ít, kèm một câu định nghĩa ngắn | Tên collection thật (`challengeSubmissions`, `users/{uid}/inbox`) |
| Thuộc tính, khoá, kiểu | **Không có** | Có: PK ở ngăn riêng, FK ghi `→ collection`, kiểu và giới hạn |
| Nhãn đường nối | Động từ ("sends", "reviews"), đọc từ thực thể này sang thực thể kia | Tên trường FK (`uid`, `submissionId`) |
| Chỉ mục, ràng buộc | Không | Chỉ mục ghép (`firestore.indexes.json`); ràng buộc ở `firestore.rules` và `data-model.md` |

## Ký hiệu: crow's foot (Information Engineering)

- Hai vạch `||` = đúng một.
- Vòng tròn + vạch `o|` = không hoặc một.
- Vòng tròn + chân chim `o<` = không hoặc nhiều.
- Kiểu nét (liền / đứt) **không mang nghĩa**; mọi đường đều liền. (Nét đứt chỉ có nghĩa "tuỳ chọn" trong ký hiệu Barker, không dùng ở đây.)

## Quy tắc bố cục

- Mọi đường nối đều có nhãn; đường chỉ đi ngang hoặc dọc, không chung đoạn, hạn chế cắt nhau.
- Các hộp cùng chiều rộng, căn thẳng hàng; sơ đồ lớn chia thành nhóm (khung nét đứt = subcollection `users/{uid}/…`).
- Firestore không có ký hiệu chuẩn: collection là thực thể, subcollection nằm trong khung của document cha, tham chiếu giữa document vẽ như khoá ngoại.
- `erd.svg` sinh bằng script; khi đổi `firestore.rules` thì vẽ lại cho khớp.

## Nguồn

- [What is an entity relationship diagram (Lucidchart)](https://lucid.co/diagram/erd/tutorial): ba mức conceptual / logical / physical, crow's foot.
- [Comprehensive guide to ER modeling (Visual Paradigm)](https://s.visual-paradigm.com/guide/the-comprehensive-guide-to-er-modeling-erds/): mức khái niệm không có thuộc tính, khoá, kiểu.
- [Cardinality symbols in ER diagrams (Creately)](https://creately.com/guides/cardinality-symbols/): ý nghĩa vòng tròn, vạch, chân chim; so sánh với Barker.
- [ERD best practices (Dataedo)](https://docs.dataedo.com/data-catalog/database-diagrams/erd-best-practices) và [ERD style notes (Napier)](https://bdavison.napier.ac.uk/db/Practicals/Drawio/erd/): tên số ít, nhãn là động từ, đường vuông góc, PK/FK nhất quán.
- [Cloud Firestore data model](https://firebase.google.com/docs/firestore/data-model): collection, document, subcollection.
