import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_expense_ocr/models/expense_item.dart';
import 'package:flutter_expense_ocr/models/parsed_receipt.dart';

void main() {
  group('ExpenseItem Model Tests', () {
    test('toMap and fromMap work correctly', () {
      final now = DateTime.now();
      final item = ExpenseItem(
        id: '123',
        merchantName: 'Highlands Coffee',
        amount: 55000,
        category: 'Ăn uống',
        timestamp: now,
        rawOcrText: 'Highlands Coffee\n55.000',
        imagePath: '/path/to/img.png',
      );

      final map = item.toMap();
      expect(map['id'], '123');
      expect(map['merchantName'], 'Highlands Coffee');
      expect(map['amount'], 55000.0);
      expect(map['category'], 'Ăn uống');
      expect(map['timestamp'], now.toIso8601String());
      expect(map['rawOcrText'], 'Highlands Coffee\n55.000');
      expect(map['imagePath'], '/path/to/img.png');

      final reconstructed = ExpenseItem.fromMap(map);
      expect(reconstructed.id, item.id);
      expect(reconstructed.merchantName, item.merchantName);
      expect(reconstructed.amount, item.amount);
      expect(reconstructed.category, item.category);
      expect(reconstructed.timestamp.toIso8601String(), item.timestamp.toIso8601String());
      expect(reconstructed.rawOcrText, item.rawOcrText);
      expect(reconstructed.imagePath, item.imagePath);
    });

    test('copyWith updates specified fields only', () {
      final now = DateTime.now();
      final item = ExpenseItem(
        id: '123',
        merchantName: 'Store A',
        amount: 100000,
        category: 'Ăn uống',
        timestamp: now,
      );

      final updated = item.copyWith(
        merchantName: 'Store B',
        amount: 200000,
      );

      expect(updated.id, '123');
      expect(updated.merchantName, 'Store B');
      expect(updated.amount, 200000);
      expect(updated.category, 'Ăn uống');
    });
  });

  group('ParsedReceipt Model Tests', () {
    test('creates ParsedReceipt instance correctly', () {
      const receipt = ParsedReceipt(
        merchantName: 'WinMart',
        totalAmount: 120000,
        category: 'Mua sắm',
        rawText: 'WinMart\n120.000',
        imagePath: '/path/img.jpg',
      );

      expect(receipt.merchantName, 'WinMart');
      expect(receipt.totalAmount, 120000);
      expect(receipt.category, 'Mua sắm');
      expect(receipt.rawText, 'WinMart\n120.000');
      expect(receipt.imagePath, '/path/img.jpg');
    });
  });
}
