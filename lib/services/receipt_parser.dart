import '../models/parsed_receipt.dart';
import '../core/constants/app_constants.dart';

class ReceiptParser {
  /// Phương thức chính phân tích toàn bộ văn bản OCR sang đối tượng [ParsedReceipt].
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

  /// Trích xuất tên đơn vị / cửa hàng từ các dòng đầu hóa đơn tiếng Việt
  static String extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Cửa hàng không xác định';

    final ignorePatterns = [
      RegExp(r'^(đt|sđt|tel|phone|fax|mst|mã số thuế|add|địa chỉ|ngày|date|giờ|time|hóa đơn|phiếu|receipt|thu ngân|nhân viên|bàn|khách hàng|so hd|số hđ|phiếu thanh toán)\s*:?.*$', caseSensitive: false),
      RegExp(r'^\d+$'), // Chỉ gồm chữ số
      RegExp(r'^\d{1,2}[/\.-]\d{1,2}[/\.-]\d{2,4}'), // Ngày tháng
      RegExp(r'^(tổng|total|thanh toán|hàng|tiền|cộng|chiết khấu|giảm giá)', caseSensitive: false),
    ];

    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i].trim();
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

  /// Trích xuất tổng tiền ưu tiên tiếng Việt và các định dạng đuôi VNĐ, đ, VND, đồng
  static double? extractTotal(List<String> lines, String rawText) {
    // Danh sách từ khóa tổng tiền tiếng Việt (sắp xếp theo độ ưu tiên từ cao xuống thấp)
    final vietnameseTotalKeywords = [
      'tổng tiền thanh toán',
      'tong tien thanh toan',
      'tổng thanh toán',
      'tong thanh toan',
      'tổng tiền',
      'tong tien',
      'tổng cộng',
      'tong cong',
      'khách phải trả',
      'khach phai tra',
      'phải thanh toán',
      'phai thanh toan',
      'cần thanh toán',
      'can thanh toan',
      'tiền thanh toán',
      'tien thanh toan',
      'thành tiền',
      'thanh tien',
      'cộng tiền hàng',
      'cong tien hang',
      'tổng hóa đơn',
      'tổng hoá đơn',
      'tong hoa don',
      'tổng chi phí',
      'tong chi phi',
      'trị giá',
      'tri gia',
      'cộng tiền',
      'cong tien',
      'thanh toán',
      'thanh toan',
      'total due',
      'amount due',
      'grand total',
      'total',
      'sum',
    ];

    // Các từ khóa loại trừ (tiền thừa, tiền khách đưa, mã số thuế, số điện thoại, ngày...)
    final negativeKeywords = [
      'tiền thừa',
      'tien thua',
      'tiền thối',
      'tien thoi',
      'khách đưa',
      'khach dua',
      'tiền khách đưa',
      'tien khach dua',
      'tiền trả lại',
      'tien tra lai',
      'sđt',
      'điện thoại',
      'mst',
      'mã số thuế',
      'ngày',
      'ngay',
      'date',
      'giờ',
      'time',
      'số lượng',
      'so luong',
      'đơn giá',
      'don gia',
      'chiết khấu',
      'chiet khau',
      'giảm giá',
      'giam gia',
    ];

    // Regex nhận diện số tiền có đuôi đ, vnđ, vnd, VNĐ, đồng
    final currencySuffixPattern = RegExp(
      r'([\d\.,OosS]{1,12})\s*(đ|vnd|vnđ|d|đồng|dong)(?:\b|[^\w]|$)',
      caseSensitive: false,
    );

    // =========================================================================
    // BƯỚC 1: Tìm dòng chứa từ khóa TỔNG TIỀN Tiếng Việt KÈM đuôi tiền tệ (đ / VNĐ)
    // Duyệt từ dưới lên trên (vì tổng tiền luôn nằm ở gần cuối hóa đơn)
    // =========================================================================
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      final lineLower = line.toLowerCase();

      // Bỏ qua dòng chứa từ khóa loại trừ như tiền thừa, tiền khách đưa
      if (_isNegativeLine(lineLower, negativeKeywords)) continue;

      for (final kw in vietnameseTotalKeywords) {
        if (lineLower.contains(kw)) {
          // Ưu tiên trích xuất số có gắn đuôi tiền tệ trên dòng này
          final match = currencySuffixPattern.firstMatch(line);
          if (match != null) {
            final rawNum = match.group(1);
            if (rawNum != null) {
              final val = normalizeAndParseNumber(rawNum);
              if (val != null && val > 0 && !_isLikelyPhoneNumberOrDate(val, rawNum)) {
                return val;
              }
            }
          }

          // Nếu không có đuôi tiền tệ trực tiếp, trích xuất số tiền hợp lệ trên dòng này
          final amount = _parseAmountFromLine(line);
          if (amount != null && amount > 0 && !_isLikelyPhoneNumberOrDate(amount, line)) {
            return amount;
          }
        }
      }
    }

    // =========================================================================
    // BƯỚC 2: Tìm dòng chứa từ khóa TỔNG TIỀN (kể cả dòng tiếp theo chứa số tiền)
    // =========================================================================
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      final lineLower = line.toLowerCase();

      if (_isNegativeLine(lineLower, negativeKeywords)) continue;

      for (final kw in vietnameseTotalKeywords) {
        if (lineLower.contains(kw)) {
          // Kiểm tra chính dòng này
          final amount = _parseAmountFromLine(line);
          if (amount != null && amount > 0 && !_isLikelyPhoneNumberOrDate(amount, line)) {
            return amount;
          }

          // Kiểm tra dòng ngay tiếp theo (trường hợp nhãn "Tổng tiền" ở dòng trên, số ở dòng dưới)
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1].trim();
            final nextAmount = _parseAmountFromLine(nextLine);
            if (nextAmount != null && nextAmount > 0 && !_isLikelyPhoneNumberOrDate(nextAmount, nextLine)) {
              return nextAmount;
            }
          }
        }
      }
    }

    // =========================================================================
    // BƯỚC 3: Quét tìm bất kỳ số nào có đuôi đơn vị tiền tệ (đ, vnđ, VNĐ, vnd, đồng)
    // Loại trừ các dòng thông tin phụ, lấy số có đuôi đ/VNĐ từ dưới lên
    // =========================================================================
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      final lineLower = line.toLowerCase();

      if (_isNegativeLine(lineLower, negativeKeywords)) continue;

      final matches = currencySuffixPattern.allMatches(line).toList();
      if (matches.isNotEmpty) {
        // Lấy số cuối cùng trên dòng
        for (int m = matches.length - 1; m >= 0; m--) {
          final rawNum = matches[m].group(1);
          if (rawNum != null) {
            final val = normalizeAndParseNumber(rawNum);
            if (val != null && val > 0 && !_isLikelyPhoneNumberOrDate(val, rawNum)) {
              return val;
            }
          }
        }
      }
    }

    // =========================================================================
    // BƯỚC 4: Fallback - Tìm mẫu đuôi tiền tệ trong toàn bộ rawText
    // =========================================================================
    final allMatches = currencySuffixPattern.allMatches(rawText).toList();
    for (int i = allMatches.length - 1; i >= 0; i--) {
      final rawNum = allMatches[i].group(1);
      if (rawNum != null) {
        final parsed = normalizeAndParseNumber(rawNum);
        if (parsed != null && parsed > 0 && !_isLikelyPhoneNumberOrDate(parsed, rawNum)) {
          return parsed;
        }
      }
    }

    return null; // Không tìm thấy dòng tổng -> để người dùng nhập tay tại màn hình Review
  }

  static bool _isNegativeLine(String lineLower, List<String> negativeKeywords) {
    for (final neg in negativeKeywords) {
      if (lineLower.contains(neg)) {
        return true;
      }
    }
    return false;
  }

  static bool _isLikelyPhoneNumberOrDate(double amount, String text) {
    // SĐT 10-11 số (VD: 0905123456, 0935..., 08..., 07..., 03...)
    final clean = text.replaceAll(RegExp(r'[^\d]'), '');
    if ((clean.startsWith('09') ||
            clean.startsWith('08') ||
            clean.startsWith('07') ||
            clean.startsWith('03') ||
            clean.startsWith('05') ||
            clean.startsWith('84')) &&
        (clean.length == 10 || clean.length == 11)) {
      return true;
    }

    // Năm hoặc ngày tháng đơn lẻ (VD: 2024, 2025, 2026)
    if (amount >= 2020 && amount <= 2030 && !text.contains('.') && !text.contains(',')) {
      return true;
    }

    return false;
  }

  /// Trích xuất số tiền từ một dòng văn bản
  static double? _parseAmountFromLine(String line) {
    // Khử nhiễu OCR: 'O', 'o' thay cho số '0'
    final sanitizedLine = line
        .replaceAll(RegExp(r'(?<=\d)[Oo](?=\d|\b)'), '0')
        .replaceAll(RegExp(r'(?<=\.)[Oo]{3}'), '000')
        .replaceAll(RegExp(r'(?<=,)[Oo]{3}'), '000');

    final numRegex = RegExp(r'(\d{1,3}(?:[\.,\s]\d{3})+|\d+)');
    final matches = numRegex.allMatches(sanitizedLine).toList();

    if (matches.isEmpty) return null;

    for (int i = matches.length - 1; i >= 0; i--) {
      final matchStr = matches[i].group(0);
      if (matchStr != null) {
        final parsed = normalizeAndParseNumber(matchStr);
        if (parsed != null && parsed > 0 && !_isLikelyPhoneNumberOrDate(parsed, matchStr)) {
          return parsed;
        }
      }
    }
    return null;
  }

  /// Chuẩn hóa số tiền Việt Nam (hỗ trợ 150.000, 85,000, 1.250.000, 150 000, 150000)
  static double? normalizeAndParseNumber(String rawNumber) {
    String cleanStr = rawNumber.trim();

    // Thay thế chữ O/o thường bị OCR đọc nhầm thành số 0
    cleanStr = cleanStr.replaceAll(RegExp(r'[Oo]'), '0');
    // Bỏ khoảng trắng giữa các chữ số: '150 000' -> '150000'
    cleanStr = cleanStr.replaceAll(RegExp(r'\s+'), '');

    if (cleanStr.contains('.') && cleanStr.contains(',')) {
      if (cleanStr.lastIndexOf('.') > cleanStr.lastIndexOf(',')) {
        // Định dạng châu Âu: 1,250.00 -> 1250.00
        cleanStr = cleanStr.replaceAll(',', '');
      } else {
        // Định dạng Việt Nam: 1.250,00 -> 1250.00
        cleanStr = cleanStr.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (cleanStr.contains('.')) {
      final parts = cleanStr.split('.');
      if (parts.length > 1 && parts.sublist(1).every((p) => p.length == 3)) {
        // 150.000 hoặc 1.250.000
        cleanStr = cleanStr.replaceAll('.', '');
      } else if (parts.length == 2 && parts[1].length != 3) {
        // Số thập phân lẻ
      } else {
        cleanStr = cleanStr.replaceAll('.', '');
      }
    } else if (cleanStr.contains(',')) {
      final parts = cleanStr.split(',');
      if (parts.length > 1 && parts.sublist(1).every((p) => p.length == 3)) {
        // 85,000 hoặc 1,250,000
        cleanStr = cleanStr.replaceAll(',', '');
      } else if (parts.length == 2 && parts[1].length != 3) {
        cleanStr = cleanStr.replaceAll(',', '.');
      } else {
        cleanStr = cleanStr.replaceAll(',', '');
      }
    }

    return double.tryParse(cleanStr);
  }

  /// Tự động nhận diện danh mục dựa trên từ khóa tiếng Việt
  static String detectCategory(String merchant, String rawText) {
    final combined = '$merchant $rawText'.toLowerCase();

    // 1. Giải trí (Rạp phim, Karaoke, Game, Ca nhạc)
    if (combined.contains('cgv') ||
        combined.contains('lotte') ||
        combined.contains('cinema') ||
        combined.contains('bhd') ||
        combined.contains('galaxy') ||
        combined.contains('rạp') ||
        combined.contains('rap') ||
        combined.contains('phim') ||
        combined.contains('xem phim') ||
        combined.contains('karaoke') ||
        combined.contains('game') ||
        combined.contains('bida') ||
        combined.contains('bowling')) {
      return AppConstants.categoryEntertainment;
    }

    // 2. Di chuyển (Giao thông, Taxi, Xăng xe)
    if (combined.contains('grab') ||
        combined.contains('be ') ||
        combined.contains('gojek') ||
        combined.contains('taxi') ||
        combined.contains('xăng') ||
        combined.contains('xang') ||
        combined.contains('petrolimex') ||
        combined.contains('gas') ||
        combined.contains('parking') ||
        combined.contains('gửi xe') ||
        combined.contains('gui xe') ||
        combined.contains('giữ xe') ||
        combined.contains('vé xe ') ||
        combined.contains('ve xe ') ||
        combined.contains('vé tàu') ||
        combined.contains('vé máy bay')) {
      return AppConstants.categoryTransport;
    }

    // 2. Ăn uống (Cà phê, Trà sữa, Nhà hàng, Quán ăn, Siêu thị thực phẩm)
    if (combined.contains('coffee') ||
        combined.contains('cà phê') ||
        combined.contains('ca phe') ||
        combined.contains('cafe') ||
        combined.contains('highlands') ||
        combined.contains('starbucks') ||
        combined.contains('phúc long') ||
        combined.contains('phuc long') ||
        combined.contains('trà sữa') ||
        combined.contains('tra sua') ||
        combined.contains('tocotoco') ||
        combined.contains('nhà hàng') ||
        combined.contains('nha hang') ||
        combined.contains('restaurant') ||
        combined.contains('quán ăn') ||
        combined.contains('quan an') ||
        combined.contains('quán') ||
        combined.contains('phở') ||
        combined.contains('pho') ||
        combined.contains('bún') ||
        combined.contains('bun') ||
        combined.contains('cơm') ||
        combined.contains('com') ||
        combined.contains('bánh') ||
        combined.contains('banh') ||
        combined.contains('mì') ||
        combined.contains('mi') ||
        combined.contains('lẩu') ||
        combined.contains('nướng') ||
        combined.contains('food') ||
        combined.contains('mart') ||
        combined.contains('winmart') ||
        combined.contains('co.op') ||
        combined.contains('coop') ||
        combined.contains('bách hóa') ||
        combined.contains('bach hoa')) {
      return AppConstants.categoryFood;
    }

    // 3. Mua sắm (Thời trang, Quần áo, Sàn TMĐT)
    if (combined.contains('shopee') ||
        combined.contains('lazada') ||
        combined.contains('tiki') ||
        combined.contains('sendo') ||
        combined.contains('zara') ||
        combined.contains('uniqlo') ||
        combined.contains('h&m') ||
        combined.contains('fashion') ||
        combined.contains('quần áo') ||
        combined.contains('quan ao') ||
        combined.contains('giày') ||
        combined.contains('giay') ||
        combined.contains('mỹ phẩm') ||
        combined.contains('my pham') ||
        combined.contains('shop')) {
      return AppConstants.categoryShopping;
    }

    // 4. Hóa đơn (Điện, Nước, Internet, Viễn thông)
    if (combined.contains('điện') ||
        combined.contains('dien') ||
        combined.contains('nước') ||
        combined.contains('nuoc') ||
        combined.contains('internet') ||
        combined.contains('viettel') ||
        combined.contains('vnpt') ||
        combined.contains('fpt') ||
        combined.contains('mobifone') ||
        combined.contains('vinaphone') ||
        combined.contains('hóa đơn') ||
        combined.contains('hoa don') ||
        combined.contains('cước')) {
      return AppConstants.categoryBills;
    }

    // 5. Giải trí (Rạp phim, Karaoke, Game, Ca nhạc)
    if (combined.contains('cgv') ||
        combined.contains('lotte') ||
        combined.contains('cinema') ||
        combined.contains('bhd') ||
        combined.contains('galaxy') ||
        combined.contains('rạp') ||
        combined.contains('rap') ||
        combined.contains('phim') ||
        combined.contains('karaoke') ||
        combined.contains('game') ||
        combined.contains('bida') ||
        combined.contains('bowling')) {
      return AppConstants.categoryEntertainment;
    }

    return AppConstants.categoryFood; // Mặc định là Ăn uống
  }
}
