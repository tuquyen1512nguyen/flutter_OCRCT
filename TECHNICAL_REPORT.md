# BÁO CÁO KỸ THUẬT: MINI-PROJECT 3 — FLUTTER EXPENSE MANAGER OCR
**Học phần:** Phát triển ứng dụng di động đa nền tảng (Cross-Platform Mobile App Development)  
**Giảng viên:** TS. Nguyễn Thanh Tuấn — Khoa Khoa học Máy tính, VKU  
**Sinh viên thực hiện:** Nhóm thực hiện / Sinh viên VKU  

---

## 1. TỔNG QUAN HỆ THỐNG & MỤC TIÊU DỰ ÁN

### 1.1. Bối cảnh & Vấn đề
Việc quản lý tài chính cá nhân thông qua việc nhập liệu hóa đơn thủ công thường tốn nhiều thời gian và dễ gây sai sót. Dự án **Expense Manager OCR** xây dựng một ứng dụng Flutter hoàn chỉnh giúp tự động hóa quá trình nhận diện hóa đơn thông qua máy ảnh (Camera) hoặc thư viện ảnh (Gallery), áp dụng Google ML Kit OCR on-device cùng bộ quy tắc Regular Expressions (Regex) tối ưu cho hóa đơn tại Việt Nam (hỗ trợ các định dạng tiền tệ `đ`, `VNĐ`, dấu chấm/phẩy phân tách hàng nghìn).

### 1.2. Các yêu cầu kỹ thuật trọng tâm (Tuần 8)
1. **Quản lý trạng thái (State Management):** Sử dụng **Riverpod 2** (`AsyncNotifier`, `NotifierProvider`, `ConsumerWidget`, `ref.watch`, `ref.read`) thay thế cho `setState()` và `Provider` truyền thống nhằm bảo đảm Type-safe và không gây rebuild thừa thãi.
2. **Điều hướng khai báo (Declarative Routing):** Sử dụng **GoRouter** quản lý luồng điều hướng màn hình, đồng bộ URL, hỗ trợ truyền tham số (Path Parameters & Extra objects).
3. **Biểu mẫu & Xác thực (Form & Validation):** Triển khai cơ chế **Human-in-the-Loop** thông qua màn hình *Review & Verification Screen* với `GlobalKey<FormState>`, `TextEditingController` để người dùng xác nhận và sửa lỗi OCR trước khi lưu trữ.
4. **Vẽ đồ họa tùy biến (Custom Canvas Drawing):** Sử dụng `CustomPainter` kết hợp `AnimationController` để vẽ biểu đồ tròn Donut Chart phân tích chi tiêu theo danh mục với hiệu ứng chuyển động mượt mà (60–120 FPS).
5. **Kênh nền tảng (Platform Channels):** Cấu hình `MethodChannel` (`vn.edu.vku/device_info`) tương tác native code Android (Kotlin) và iOS (Swift).
6. **Lưu trữ cục bộ (Local Persistence):** Quản lý cơ sở dữ liệu SQLite an toàn thông qua `sqflite` với đầy đủ các thao tác CRUD.

---

## 2. KIẾN TRÚC HỆ THỐNG & LUỒNG XỬ LÝ DỮ LIỆU

### 2.1. Cấu trúc thư mục Clean Architecture
```
lib/
├── main.dart                      # Điểm khởi động ứng dụng, ProviderScope, cấu hình Material 3 Theme
├── core/
│   ├── constants/
│   │   └── app_constants.dart     # Danh mục, bảng màu, icon, hàm định dạng tiền tệ & ngày tháng
│   ├── database/
│   │   └── database_helper.dart   # Quản lý kết nối và thao tác SQLite (CRUD)
│   └── router/
│       └── app_router.dart        # Cấu hình định tuyến GoRouter
├── models/
│   ├── expense_item.dart          # Entity khoản chi tiêu lưu trữ trong SQLite
│   └── parsed_receipt.dart        # DTO trung gian sau khi OCR & Regex trích xuất
├── services/
│   ├── ocr_service.dart           # Wrapper giao tiếp Google ML Kit Text Recognition
│   ├── receipt_parser.dart        # Engine Regex & Heuristics phân tích tên quán & số tiền
│   └── platform_channel_service.dart # Giao tiếp MethodChannel với Native Android/iOS
├── state/
│   ├── expense_provider.dart      # Riverpod AsyncNotifier quản lý danh sách & thống kê chi tiêu
│   └── ocr_provider.dart          # Riverpod StateNotifier quản lý trạng thái xử lý ảnh OCR
├── screens/
│   ├── dashboard_screen.dart      # Màn hình chính: Thống kê tổng quan & Biểu đồ Donut Chart
│   ├── scanner_screen.dart        # Màn hình chụp/chọn ảnh & danh sách mẫu hóa đơn thử nghiệm
│   ├── review_receipt_screen.dart # Màn hình duyệt & chỉnh sửa dữ liệu trích xuất (Human-in-the-loop)
│   ├── expense_list_screen.dart   # Màn hình danh sách có tìm kiếm & lọc theo danh mục
│   └── expense_detail_screen.dart # Màn hình xem chi tiết, chỉnh sửa & xóa bản ghi
└── widgets/
    ├── donut_chart.dart           # CustomPainter vẽ biểu đồ Donut Chart kèm animation
    ├── expense_card.dart          # Thẻ hiển thị khoản chi tiêu
    ├── summary_card.dart          # Thẻ tổng hợp chi tiêu tháng & tổng chi tiêu
    ├── empty_state.dart           # Trạng thái rỗng
    └── loading_overlay.dart       # Lớp phủ loading khi OCR đang quét
```

### 2.2. Sơ đồ Pipeline xử lý dữ liệu
```
[Camera / Gallery] 
       │ (image_picker)
       ▼
[Google ML Kit TextRecognizer] 
       │ (On-Device OCR)
       ▼
[Raw OCR Text]
       │
       ▼
[ReceiptParser Regex Engine] ──────────► [ParsedReceipt DTO]
                                                │
                                                ▼
                                    [Review & Verification Screen]
                                    (User audit & manual edits)
                                                │
                                                ▼
                                    [Riverpod ExpenseNotifier]
                                                │
                                       ┌────────┴────────┐
                                       ▼                 ▼
                              [SQLite Database]    [Animated Donut Chart]
                              (Local Persistence)    (CustomPainter)
```

---

## 3. CHI TIẾT KỸ THUẬT & TRIỂN KHAI

### 3.1. Quản lý trạng thái với Riverpod 2
Ứng dụng sử dụng `AsyncNotifier<List<ExpenseItem>>` để quản lý trạng thái tải bất đồng bộ từ SQLite:
- **`expenseProvider`**: Nguồn dữ liệu danh sách chi tiêu đồng bộ hai chiều với SQLite.
- **Computed Selectors**:
  - `totalExpensesProvider`: Tính tổng chi tiêu toàn thời gian (`fold`).
  - `monthlyExpensesProvider`: Tự động lọc các khoản chi trong tháng hiện tại.
  - `expenseCountProvider`: Đếm tổng số giao dịch.
  - `categoryTotalsProvider`: Nhóm tổng số tiền chi tiêu theo từng danh mục (`Map<String, double>`).

### 3.2. Thuật toán Regex Heuristics trích xuất Hóa đơn Việt Nam
Xử lý dữ liệu văn bản phi cấu trúc và nhiễu bằng thuật toán 2 bước trong `ReceiptParser`:
1. **Tìm kiếm dòng chứa từ khóa ưu tiên (Từ dưới lên trên):**
   - Từ khóa: `tổng thanh toán`, `thanh toán`, `tổng tiền`, `tổng cộng`, `total due`, `amount due`, `total`, `tri gia`, `trị giá`, `cộng tiền`, `sum`.
2. **Chuẩn hóa số tiền Việt Nam (`normalizeAndParseNumber`):**
   - Định dạng `150.000` ➔ `150000.0`
   - Định dạng `85,000 đ` ➔ `85000.0`
   - Định dạng `1.250.000` ➔ `1250000.0`
   - Nhận diện đơn vị tiền tệ đuôi (`đ`, `vnd`, `vnđ`).

#### Bảng kịch bản kiểm thử Regex (Test Scenarios Matrix)

| STT | Dữ liệu văn bản OCR đầu vào | Kết quả Tên cửa hàng | Kết quả Số tiền (VND) | Danh mục tự động | Trạng thái Unit Test |
|:---:|:---|:---|:---:|:---:|:---:|
| 1 | `ABC MART\nMilk\nBread\nTOTAL: 150.000` | `ABC MART` | `150,000` | Mua sắm | **PASS** |
| 2 | `Cửa hàng XYZ\nNước uống\nTổng tiền: 85,000 đ` | `Cửa hàng XYZ` | `85,000` | Ăn uống | **PASS** |
| 3 | `ABC SHOP\nThanh toán: 1.250.000` | `ABC SHOP` | `1,250,000` | Mua sắm | **PASS** |
| 4 | `Highlands Coffee\nCà phê sữa đá\nTổng cộng: 59.000 đ` | `Highlands Coffee` | `59,000` | Ăn uống | **PASS** |
| 5 | `GrabCar\nChuyến đi đường dài\nThanh toán: 120.000` | `GrabCar` | `120,000` | Di chuyển | **PASS** |
| 6 | `ABC SHOP\nItems list...\nNo total line` | `ABC SHOP` | `null` (Bắt buộc người dùng nhập) | Mua sắm | **PASS** |

### 3.3. Biểu đồ CustomPainter Donut Chart & Animation
Thay vì sử dụng thư viện bên thứ ba gây phình to kích thước ứng dụng, ứng dụng tự xây dựng `DonutChartPainter` kế thừa `CustomPainter`:
- Phương thức `paint(Canvas canvas, Size size)`:
  - Tính bán kính: `min(size.width / 2, size.height / 2) - 12`.
  - Vẽ vòng tròn nền `drawCircle` với nét vẽ `PaintingStyle.stroke`, `strokeWidth = 24.0`.
  - Duyệt qua từng danh mục, tính góc quét `sweepAngle = (amount / totalAmount) * 2 * pi * progress`.
  - Vẽ từng cung phân đoạn `canvas.drawArc` bắt đầu từ đỉnh `-pi / 2`.
- Kết nối `AnimationController` thời lượng `1000ms`, đường cong `Curves.easeOutCubic` tạo hiệu ứng mở rộng mượt mà mỗi khi dữ liệu cập nhật.

### 3.4. Kênh giao tiếp Native (Platform Channels)
- **Tên kênh:** `vn.edu.vku/device_info`
- **Phương thức gọi:** `getBatteryLevel`
- **Mã nguồn Android (Kotlin - `MainActivity.kt`):**
  Lấy dung lượng pin thông qua `BatteryManager.BATTERY_PROPERTY_CAPACITY`.
- **Mã nguồn iOS (Swift - `AppDelegate.swift`):**
  Lấy dung lượng pin qua `UIDevice.current.batteryLevel`.

### 3.5. Cơ sở dữ liệu SQLite
- Bảng: `expenses`
- Lược đồ cơ sở dữ liệu:
```sql
CREATE TABLE expenses (
  id TEXT PRIMARY KEY,
  merchantName TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  rawOcrText TEXT,
  imagePath TEXT
);
```

---

## 4. GIAO DIỆN & TRẢI NGHIỆM NGƯỜI DÙNG (UI/UX)
- **Hỗ trợ giao diện Sáng / Tối (Light & Dark Theme):** Tự động thích ứng theo hệ điều hành với bảng màu Material 3 Teal chủ đạo (`#00897B`).
- **Màn hình Review & Verification:** Hiển thị trực quan ảnh chụp hóa đơn, form xác thực dữ liệu đầu vào, dropdown phân loại danh mục, và mục thu gọn (Accordion) xem chi tiết văn bản thô OCR phục vụ việc kiểm tra và kiểm thử.
- **Tìm kiếm & Bộ lọc linh hoạt:** Cho phép tìm kiếm nhanh theo tên cửa hàng và lọc tức thời theo từng nhóm danh mục chi tiêu.

---

## 5. CÁC HẠN CHẾ KỸ THUẬT & HƯỚNG PHÁT TRIỂN

### 5.1. Hạn chế hiện tại
1. **Chất lượng ảnh đầu vào:** Hóa đơn bị nhàu, mờ hoặc thiếu sáng có thể làm giảm độ chính xác của ML Kit OCR (nhầm lẫn số `0` với chữ `O`).
2. **Hóa đơn không theo chuẩn:** Một số hóa đơn viết tay hoặc không có dòng tổng kết quả tiền tệ đòi hỏi người dùng phải tự điền vào màn hình xác nhận.
3. **Môi trường giả lập Desktop:** Trên môi trường Windows/Linux, máy ảnh thiết bị thực được giả lập qua tính năng chọn ảnh mẫu (Sample Chips) hoặc chọn file từ máy tính.

### 5.2. Hướng phát triển tiếp theo
- Tích hợp công cụ cắt xoay hóa đơn (Image Cropper & Perspective Correction) trước khi đưa vào bộ nhận diện OCR.
- Tích hợp AI mô hình ngôn ngữ lớn (Gemini Nano on-device) để trích xuất danh sách chi tiết từng món hàng (Line items).
- Hỗ trợ xuất báo cáo tài chính định dạng Excel / PDF và đồng bộ sao lưu đám mây.

---

## 6. DANH MỤC SẢN PHẨM BÀN GIAO (DELIVERABLES CHECKLIST)

- [x] **1. Mã nguồn hoàn chỉnh:** Cấu trúc Clean Architecture, chuẩn lint, không lỗi biên dịch (`flutter analyze` 0 issues).
- [x] **2. Bộ Unit Test & Widget Test:** Toàn bộ 9/9 test cases kiểm thử Regex, Models và UI đều vượt qua (`All tests passed!`).
- [x] **3. Platform Channels:** Cấu hình đầy đủ Kotlin (Android) và Swift (iOS).
- [x] **4. CustomPainter Chart:** Biểu đồ Donut Chart tự vẽ kèm animation 1000ms.
- [x] **5. Báo cáo kỹ thuật chi tiết (`TECHNICAL_REPORT.md` / README):** Đầy đủ sơ đồ kiến trúc, bảng regex, phân tích kỹ thuật.
