import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_expense_ocr/services/receipt_parser.dart';
import 'package:flutter_expense_ocr/core/constants/app_constants.dart';

void main() {
  group('ReceiptParser Tests (Hóa đơn Tiếng Việt & Đuôi VNĐ/đ/VND)', () {
    test('Example 1: TOTAL: 150.000 -> 150000', () {
      const rawText = '''
ABC MART
Milk
Bread
TOTAL: 150.000
''';
      final receipt = ReceiptParser.parse(rawText);
      expect(receipt.merchantName, 'ABC MART');
      expect(receipt.totalAmount, 150000.0);
    });

    test('Example 2: Tổng tiền: 85,000 đ -> 85000', () {
      const rawText = '''
Cửa hàng XYZ
Nước uống
Tổng tiền: 85,000 đ
''';
      final receipt = ReceiptParser.parse(rawText);
      expect(receipt.merchantName, 'Cửa hàng XYZ');
      expect(receipt.totalAmount, 85000.0);
    });

    test('Example 3: Thanh toán: 1.250.000 -> 1250000', () {
      const rawText = '''
ABC SHOP
Thanh toán: 1.250.000
''';
      final receipt = ReceiptParser.parse(rawText);
      expect(receipt.merchantName, 'ABC SHOP');
      expect(receipt.totalAmount, 1250000.0);
    });

    test('Example 4: Đuôi VNĐ viết hoa (250.000 VNĐ)', () {
      const rawText = '''
Highlands Coffee
Cà phê sữa đá
Tổng cộng: 250.000 VNĐ
''';
      final receipt = ReceiptParser.parse(rawText);
      expect(receipt.merchantName, 'Highlands Coffee');
      expect(receipt.totalAmount, 250000.0);
    });

    test('Example 5: Đuôi đ dính liền số (65.000đ)', () {
      const rawText = '''
Trà Sữa Phúc Long
Trà đào cam sả
Khách phải trả: 65.000đ
''';
      final receipt = ReceiptParser.parse(rawText);
      expect(receipt.merchantName, 'Trà Sữa Phúc Long');
      expect(receipt.totalAmount, 65000.0);
    });

    test('Example 6: Phân biệt Tổng tiền với Tiền khách đưa & Tiền thừa', () {
      const rawText = '''
WinMart Da Nang
Đ/C: 123 Nguyen Van Linh
SĐT: 0905123456
Cộng tiền hàng: 180.000 đ
Tổng tiền thanh toán: 180.000 VNĐ
Tiền khách đưa: 500.000 đ
Tiền thừa: 320.000 đ
''';
      final receipt = ReceiptParser.parse(rawText);
      expect(receipt.merchantName, 'WinMart Da Nang');
      expect(receipt.totalAmount, 180000.0);
    });

    test('Example 7: Không có dòng tổng -> null', () {
      const rawText = '''
ABC SHOP
Items...
No total line
''';
      final receipt = ReceiptParser.parse(rawText);
      expect(receipt.merchantName, 'ABC SHOP');
      expect(receipt.totalAmount, isNull);
    });

    test('Kiểm tra nhận diện danh mục tự động tiếng Việt', () {
      expect(
        ReceiptParser.detectCategory('Highlands Coffee', 'Cà phê đá'),
        AppConstants.categoryFood,
      );
      expect(
        ReceiptParser.detectCategory('Grab Taxi', 'Chuyến đi GrabCar'),
        AppConstants.categoryTransport,
      );
      expect(
        ReceiptParser.detectCategory('Shop Quần Áo Uniqlo', 'Áo thun polo'),
        AppConstants.categoryShopping,
      );
      expect(
        ReceiptParser.detectCategory('Điện Lực Đà Nẵng', 'Hóa đơn tiền điện'),
        AppConstants.categoryBills,
      );
      expect(
        ReceiptParser.detectCategory('CGV Vincom', 'Vé xem phim 2D'),
        AppConstants.categoryEntertainment,
      );
    });
  });
}
