import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_expense_ocr/services/receipt_parser.dart';
import 'package:flutter_expense_ocr/core/constants/app_constants.dart';

void main() {
  group('ReceiptParser Tests (Yêu Cầu Tuần 8)', () {
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

    test('Example 4: Không có dòng tổng -> null', () {
      const rawText = '''
ABC SHOP
Items...
No total line
''';
      final receipt = ReceiptParser.parse(rawText);
      expect(receipt.merchantName, 'ABC SHOP');
      expect(receipt.totalAmount, isNull);
    });

    test('Kiểm tra nhận diện danh mục tự động', () {
      expect(
        ReceiptParser.detectCategory('Highlands Coffee', 'Cà phê đá'),
        AppConstants.categoryFood,
      );
      expect(
        ReceiptParser.detectCategory('Grab Taxi', 'Chuyến đi GrabCar'),
        AppConstants.categoryTransport,
      );
    });
  });
}
