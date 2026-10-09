import '../models/parsed_receipt.dart';
import '../core/constants/app_constants.dart';

class ReceiptParser {
  /// Main method to parse raw OCR text into a [ParsedReceipt] object.
  static ParsedReceipt parse(String rawText, {String? imagePath}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchantName = extractMerchant(lines);
    final totalAmount = extractTotal(lines, rawText);
    final category = detectCategory(merchantName, rawText);

    return ParsedReceipt(
      merchantName: merchantName,
      totalAmount: totalAmount,
      category: category,
      rawText: rawText,
      imagePath: imagePath,
    );
  }

  /// Extracts merchant name using heuristics
  static String extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Cửa hàng không xác định';

    final ignorePatterns = [
      RegExp(r'^(đt|sđt|tel|phone|fax|mst|mã số thuế|add|địa chỉ|ngày|date|giờ|time|hóa đơn|phiếu|receipt)\s*:?$', caseSensitive: false),
      RegExp(r'^\d+$'), // Only digits
      RegExp(r'^\d{2}[/\.-]\d{2}[/\.-]\d{2,4}'), // Dates
      RegExp(r'^(tổng|total|thanh toán|hàng|tiền)', caseSensitive: false),
    ];

    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i];
      if (line.length < 2) continue;

      bool shouldIgnore = false;
      for (final pattern in ignorePatterns) {
        if (pattern.hasMatch(line)) {
          shouldIgnore = true;
          break;
        }
      }

      if (!shouldIgnore) {
        return line;
      }
    }

    return lines.first;
  }

  /// Extracts total amount using regex matching Vietnamese receipt patterns
  static double? extractTotal(List<String> lines, String rawText) {
    // Priority keywords indicating total payment line
    final keywords = [
      'tổng thanh toán',
      'tong thanh toan',
      'thanh toán',
      'thanh toan',
      'tổng tiền',
      'tong tien',
      'tổng cộng',
      'tong cong',
      'total due',
      'amount due',
      'total',
      'tri gia',
      'trị giá',
      'cộng tiền',
      'cong tien',
      'sum',
    ];

    // Search lines from bottom to top for total keywords first
    for (int i = lines.length - 1; i >= 0; i--) {
      final lineLower = lines[i].toLowerCase();
      for (final kw in keywords) {
        if (lineLower.contains(kw)) {
          final amount = _parseAmountFromLine(lines[i]);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }
    }

    // Fallback: If no line with keyword had a valid number, look for any line with currency symbol 'đ' or 'vnd'
    final currencyRegex = RegExp(r'(\d[\d\.,\s]*)\s*(đ|vnd|vnđ)', caseSensitive: false);
    final matches = currencyRegex.allMatches(rawText);
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      final rawNumStr = lastMatch.group(1);
      if (rawNumStr != null) {
        final parsed = normalizeAndParseNumber(rawNumStr);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }

    return null;
  }

  /// Parses the numeric amount from a single line of text
  static double? _parseAmountFromLine(String line) {
    final numRegex = RegExp(r'(\d{1,3}(?:[\.,]\d{3})+|\d+)');
    final matches = numRegex.allMatches(line).toList();

    if (matches.isEmpty) return null;

    for (int i = matches.length - 1; i >= 0; i--) {
      final matchStr = matches[i].group(0);
      if (matchStr != null) {
        final parsed = normalizeAndParseNumber(matchStr);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }
    return null;
  }

  /// Normalizes Vietnamese number format into standard double
  static double? normalizeAndParseNumber(String rawNumber) {
    String cleanStr = rawNumber.trim();

    if (cleanStr.contains('.') && cleanStr.contains(',')) {
      if (cleanStr.lastIndexOf('.') > cleanStr.lastIndexOf(',')) {
        cleanStr = cleanStr.replaceAll(',', '');
      } else {
        cleanStr = cleanStr.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (cleanStr.contains('.')) {
      final parts = cleanStr.split('.');
      if (parts.length > 1 && parts.sublist(1).every((p) => p.length == 3)) {
        cleanStr = cleanStr.replaceAll('.', '');
      } else if (parts.length == 2 && parts[1].length != 3) {
      } else {
        cleanStr = cleanStr.replaceAll('.', '');
      }
    } else if (cleanStr.contains(',')) {
      final parts = cleanStr.split(',');
      if (parts.length > 1 && parts.sublist(1).every((p) => p.length == 3)) {
        cleanStr = cleanStr.replaceAll(',', '');
      } else if (parts.length == 2 && parts[1].length != 3) {
        cleanStr = cleanStr.replaceAll(',', '.');
      } else {
        cleanStr = cleanStr.replaceAll(',', '');
      }
    }

    return double.tryParse(cleanStr);
  }

  /// Heuristic to detect expense category based on merchant & text keywords
  static String detectCategory(String merchant, String rawText) {
    final combined = '$merchant $rawText'.toLowerCase();

    if (combined.contains('grab') ||
        combined.contains('be ') ||
        combined.contains('gojek') ||
        combined.contains('taxi') ||
        combined.contains('xăng') ||
        combined.contains('gas') ||
        combined.contains('parking') ||
        combined.contains('giữ xe')) {
      return AppConstants.categoryTransport;
    }

    if (combined.contains('coffee') ||
        combined.contains('cà phê') ||
        combined.contains('cafe') ||
        combined.contains('highlands') ||
        combined.contains('starbucks') ||
        combined.contains('phúc long') ||
        combined.contains('trà sữa') ||
        combined.contains('nhà hàng') ||
        combined.contains('restaurant') ||
        combined.contains('phở') ||
        combined.contains('bún') ||
        combined.contains('cơm') ||
        combined.contains('food') ||
        combined.contains('mart') ||
        combined.contains('winmart') ||
        combined.contains('co.op') ||
        combined.contains('bách hóa')) {
      return AppConstants.categoryFood;
    }

    if (combined.contains('shopee') ||
        combined.contains('lazada') ||
        combined.contains('tiki') ||
        combined.contains('zara') ||
        combined.contains('uniqlo') ||
        combined.contains('fashion') ||
        combined.contains('quần áo') ||
        combined.contains('giày')) {
      return AppConstants.categoryShopping;
    }

    if (combined.contains('điện') ||
        combined.contains('nước') ||
        combined.contains('internet') ||
        combined.contains('viettel') ||
        combined.contains('vnpt') ||
        combined.contains('fpt') ||
        combined.contains('hóa đơn')) {
      return AppConstants.categoryBills;
    }

    if (combined.contains('cgv') ||
        combined.contains('lotte') ||
        combined.contains('cinema') ||
        combined.contains('rạp') ||
        combined.contains('phim') ||
        combined.contains('karaoke') ||
        combined.contains('game')) {
      return AppConstants.categoryEntertainment;
    }

    return AppConstants.categoryFood; // Default category
  }
}
