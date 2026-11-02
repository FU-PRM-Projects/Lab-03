# Nốt — Technical Conference Slides (Reveal.js + React)

Slide thuyết trình kỹ thuật theo phong cách **Technical Conference** cho dự án **Nốt — PRM393 Lab 3** (Flutter, Riverpod 3, Firebase).

Được xây dựng dựa trên:
- **`@revealjs/react`** (Official React bindings cho Reveal.js v6.x) — [Reveal.js React Docs](https://revealjs.com/react/)
- **`reveal.js`** — [Reveal.js Installation & Guide](https://revealjs.com/installation/)
- **Vite + React + TypeScript** cho Hot Module Replacement (HMR) và compile siêu tốc.

---

## 🎨 Theme Được Chọn: `dracula`

Theo yêu cầu tạo slide theo dạng **Technical Conference** cho dự án Nốt:
- **Lý do chọn theme `dracula`:**
  - **Tương phản code tối ưu:** Chế độ dark mode nền tím xám đậm (`#282a36`) làm nổi bật khối mã Dart, Riverpod Providers, Firebase rules và terminal logs.
  - **Đồng điệu với bảng màu dự án:** Hài hoà với màu chủ đạo của Nốt (Indigo `#3D4FD6`, `#7A88EA`) kết hợp các dải màu điểm nhấn (heat colors: mint, amber, coral).
  - **Chuẩn hội nghị công nghệ:** Phong cách hiện đại thường thấy ở các hội thảo quốc tế như Fluttercon, Google I/O Extended, AWS re:Invent.
- **Tuỳ biến linh hoạt:** Nếu muốn đổi sang theme `night` hoặc `moon`, chỉ cần đổi 1 dòng trong `src/App.tsx`:
  ```tsx
  import 'reveal.js/theme/dracula.css'; // đổi thành night.css hoặc moon.css
  ```

---

## 🚀 Cách Chạy Slide

### 1. Chế độ Phát triển (Dev Server có HMR)

```sh
cd slide
npm install      # (đã cài đặt sẵn)
npm run dev
```

Mở trình duyệt tại: `http://localhost:5173`

### 2. Build bản tĩnh (Production Build)

```sh
npm run build
npm run preview  # xem thử bản build ở http://localhost:4173
```
Bản build xuất ra thư mục `slide/dist/`, có thể deploy lên GitHub Pages, Firebase Hosting hoặc Vercel.

### 3. Bản Standalone không cần Node.js

Mở trực tiếp file `slide/index-standalone.html` bằng trình duyệt bất kỳ (Chrome, Edge, Firefox). File này nạp Reveal.js qua CDN, không cần chạy terminal.

---

## ⌨️ Phím Tắt Khi Thuyết Trình

| Phím | Chức năng |
|---|---|
| `Space` / `→` / `←` | Chuyển slide kế tiếp / quay lại |
| `↓` / `↑` | Di chuyển giữa các slide con trong Stack dọc |
| `ESC` / `O` | Bật/tắt chế độ **Overview** (nhìn toàn bộ lưới slide) |
| `S` | Mở cửa sổ **Speaker View** (có đồng hồ đếm giờ, slide tiếp theo và Speaker Notes) |
| `F` | Bật chế độ Fullscreen |
| `Alt + Click` | Zoom vào một phần nội dung (nhờ plugin Zoom) |
| `Ctrl + Shift + F` | Tìm kiếm từ khóa trên các slide |
| `?` | Xem bảng trợ giúp phím tắt |

---

## 📁 Cấu Trúc Thư Mục

```text
slide/
├── src/
│   ├── App.tsx          # Toàn bộ nội dung các slide hội thảo kỹ thuật
│   ├── slides.css       # Style tùy biến cho card, grid, badge và diagram
│   ├── main.tsx         # Điểm gắn React root
│   └── index.css        # Khung viewport toàn màn hình
├── public/
│   └── assets/          # Mascot SVG và icons lấy từ dự án Nốt
├── index.html           # HTML template cho Vite
├── index-standalone.html # Phiên bản chạy độc lập bằng CDN không cần build
├── package.json         # Dependencies: reveal.js, @revealjs/react, lucide-react
└── vite.config.ts       # Cấu hình Vite
```

---

## 📝 Cách Thêm Slide Mới trong `src/App.tsx`

```tsx
import { Slide, Stack, Fragment, Code } from '@revealjs/react';

// Thêm slide ngang thông thường:
<Slide notes="Ghi chú người thuyết trình...">
  <h2>Tiêu Đề Slide</h2>
  <p>Nội dung trình bày</p>
</Slide>

// Thêm slide có code highlight từng dòng:
<Slide>
  <Code language="dart" lineNumbers="1-3|5-10">
    {`void main() {
  print("Hello Nốt");
}`}
  </Code>
</Slide>

// Thêm nhóm slide dọc (Stack):
<Stack>
  <Slide>Slide cha</Slide>
  <Slide>Slide con (nhấn phím mũi tên xuống để xem)</Slide>
</Stack>
```
