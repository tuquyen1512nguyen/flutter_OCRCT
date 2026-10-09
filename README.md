# Flutter Expense Manager — Receipt OCR

A university Mini-Project 3 Flutter application for tracking expenses with automatic receipt scanning using Google ML Kit OCR, regex heuristics for Vietnamese currency parsing, Riverpod 2 state management, GoRouter declarative routing, SQLite local persistence, and a custom animated donut chart built with `CustomPainter`.

---

## 1. Project Overview

**Expense Manager OCR** is designed to streamline personal financial management by replacing manual data entry with image-based receipt recognition. It targets Vietnamese receipt formats (handling `.`, `,`, `đ`, `VNĐ`, and keywords like `Tổng tiền`, `Thanh toán`, `TOTAL`) while enforcing a strict human-in-the-loop review mechanism before storing records in a local SQLite database.

---

## 2. Features

- 📸 **Receipt Image Capture & Gallery Pick**: Uses `image_picker` to take receipt photos or choose existing images.
- 🔤 **On-Device ML Kit OCR**: High performance on-device Latin text recognition using `google_mlkit_text_recognition`.
- 🧮 **Smart Vietnamese Regex Parsing**: Case-insensitive heuristics for extracting total amounts and merchant names from noisy text.
- 🛡️ **Review & Verification Screen**: Mandatory confirmation screen ensuring users verify and correct OCR results before saving.
- 💾 **SQLite Persistence**: Safe local storage using `sqflite` with full CRUD operations.
- 📊 **Animated Donut Chart**: Custom painter animation showing spending distribution by category without third-party chart libraries.
- ⚡ **Riverpod 2 State Management**: Immutable reactive state updates and computed statistics (`totalExpenses`, `monthlyExpenses`, `categoryTotals`).
- 🧭 **Declarative Navigation**: Clean URL routing powered by `go_router`.
- 🌓 **Material 3 UI**: Full support for both Light and Dark themes with responsive UI cards and status indicators.

---

## 3. Architecture

The codebase strictly follows clean architecture principles separating models, services, state management, router, and UI widgets:

```
lib/
├── main.dart                      # App entry point with ProviderScope & ThemeData
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart     # Categories, colors, icons, currency formatters
│   ├── database/
│   │   └── database_helper.dart   # SQLite singleton database helper
│   └── router/
│       └── app_router.dart        # GoRouter navigation configuration
│
├── models/
│   ├── expense_item.dart          # Main expense entity for database & UI
│   └── parsed_receipt.dart        # Intermediate OCR extraction result entity
│
├── services/
│   ├── ocr_service.dart           # ML Kit Text Recognition wrapper
│   └── receipt_parser.dart        # Regex parser & merchant heuristics
│
├── state/
│   ├── expense_provider.dart      # Riverpod AsyncNotifier & computed providers
│   └── ocr_provider.dart          # OCR process notifier & lifecycle state
│
├── screens/
│   ├── dashboard_screen.dart      # Expense metrics & animated donut chart
│   ├── scanner_screen.dart        # Camera/Gallery pick & quick test samples
│   ├── review_receipt_screen.dart # Form validation & OCR confirmation
│   ├── expense_detail_screen.dart # Individual expense view, edit, & delete
│   └── expense_list_screen.dart   # Searchable & filterable list view
│
└── widgets/
    ├── expense_card.dart          # Reusable item card
    ├── summary_card.dart          # Gradient summary widget
    ├── donut_chart.dart           # CustomPainter animated chart
    ├── empty_state.dart           # Empty list fallback widget
    └── loading_overlay.dart       # Scanning indicator overlay
```

---

## 4. Tech Stack & Dependencies

| Dependency | Purpose | Why Chosen |
|---|---|---|
| `flutter_riverpod` | State Management | Modern, type-safe Riverpod 2 provider model with AsyncNotifier support |
| `go_router` | Routing | Declarative routing with typed parameters and route state |
| `image_picker` | Image Capture | Standard Flutter plugin for camera and photo gallery access |
| `google_mlkit_text_recognition` | OCR | Fast, offline, privacy-friendly on-device text recognition |
| `sqflite` & `path` | Local Storage | Reliable cross-platform SQLite database engine |
| `intl` | Formatting | Vietnamese currency (`vi_VN` `đ`) and date formatting |
| `uuid` | ID Generation | Unique string key generation for SQLite records |

---

## 5. Main Processing Pipeline

```
Camera / Gallery
       ↓
Google ML Kit OCR (OcrService)
       ↓
Raw Text Extraction
       ↓
ReceiptParser (Regex & Heuristics)
       ↓
Review & Verification Screen (Human-in-the-Loop)
       ↓
User Confirms or Edits Data
       ↓
Riverpod ExpenseNotifier
       ↓
SQLite (DatabaseHelper)
       ↓
Dashboard & Animated Donut Chart
```

---

## 6. Regex Parsing Logic

The `ReceiptParser` implements case-insensitive regex parsing specifically tuned for Vietnamese receipt conventions:

### Total Extraction Strategy
1. **Keyword Priority Search**: Searches lines from bottom to top matching keywords:
   - `tổng thanh toán`, `thanh toán`, `tổng tiền`, `tổng cộng`, `total due`, `amount due`, `total`, `tri gia`, `sum`.
2. **Number Normalization**: Handles Vietnamese thousand separators (`.`, `,`):
   - `150.000` ➔ `150000.0`
   - `85,000 đ` ➔ `85000.0`
   - `1.250.000` ➔ `1250000.0`
   - `150000` ➔ `150000.0`
3. **Fallback Handling**: If no keyword line matches, returns `null` (preventing false total guesses).

### Regex Table & Test Scenarios

| Sample Text | Extracted Merchant | Extracted Total | Status |
|---|---|---|---|
| `ABC MART\nMilk\nTOTAL: 150.000` | `ABC MART` | `150000.0` | Passed |
| `Cửa hàng XYZ\nTổng tiền: 85,000 đ` | `Cửa hàng XYZ` | `85000.0` | Passed |
| `ABC SHOP\nThanh toán: 1.250.000` | `ABC SHOP` | `1250000.0` | Passed |
| `ABC SHOP\nItems...\nNo total` | `ABC SHOP` | `null` | Passed |

---

## 7. SQLite Database Schema

Table Name: `expenses`

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

### Database Operations (`DatabaseHelper`)
- `insertExpense(ExpenseItem)`
- `getAllExpenses()`
- `getExpenseById(id)`
- `updateExpense(ExpenseItem)`
- `deleteExpense(id)`
- `deleteAllExpenses()`

---

## 8. Riverpod 2 State Management

State is managed reactively via `ExpenseNotifier` (`AsyncNotifier<List<ExpenseItem>>`):

- **State Providers**:
  - `expenseProvider`: Main list of expenses loaded from SQLite.
  - `totalExpensesProvider`: Computed sum of all expenses.
  - `monthlyExpensesProvider`: Computed sum of expenses in the current calendar month.
  - `expenseCountProvider`: Total count of expense records.
  - `categoryTotalsProvider`: Map of spending grouped by category (`Map<String, double>`).

---

## 9. GoRouter Configuration

- `/`: `DashboardScreen`
- `/scan`: `ScannerScreen`
- `/review`: `ReviewReceiptScreen` (Receives `ParsedReceipt` extra parameter)
- `/expenses`: `ExpenseListScreen`
- `/expense/:id`: `ExpenseDetailScreen` (Path parameter `id`)

---

## 10. CustomPainter Donut Chart

The donut chart is implemented from scratch without chart packages using Flutter's `CustomPainter` and `AnimationController`:

- **Key Methods**:
  - `paint(Canvas canvas, Size size)`: Draws background track circle and sweeps colored arcs (`drawArc`) for each category proportional to `amount / totalAmount * 2 * pi * progress`.
  - `shouldRepaint()`: Re-paints smoothly whenever amounts or animation progress changes.
- **Entrance Animation**: 1000ms `CurvedAnimation` (`Curves.easeOutCubic`) triggering arc expansion on dashboard initialization or data change.

---

## 11. Installation & Running

### Prerequisites
- Flutter SDK (v3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- Android device or emulator (API 21+)

### Quick Setup

```bash
# 1. Get dependencies
flutter pub get

# 2. Run automated unit tests
flutter test

# 3. Analyze code quality
flutter analyze

# 4. Run application
flutter run
```

---

## 12. Technical Report & Limitations

### Known Technical Limitations
1. **OCR Noise**: Poor lighting or crumpled receipts can lead to character misreads (e.g. `0` read as `O`).
2. **Layout Variance**: Non-standard receipts without standard total keywords require manual total entry.
3. **Merchant Name Heuristics**: Store names located below header logos or addresses may require user edit.
4. **Human-in-the-Loop Requirement**: Automatic database insertion is intentionally prohibited to guarantee data accuracy.

---

## 13. Future Improvements

- [ ] Cloud sync / export to CSV / Excel.
- [ ] Multi-currency conversion (USD to VND).
- [ ] ML Kit Entity Extraction for invoice dates & VAT tax codes.
- [ ] Receipt cropping tool prior to OCR execution.
