import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'Quản Lý Chi Tiêu OCR';

  // Category Names in Vietnamese
  static const String categoryFood = 'Ăn uống';
  static const String categoryTransport = 'Di chuyển';
  static const String categoryShopping = 'Mua sắm';
  static const String categoryBills = 'Hóa đơn';
  static const String categoryEntertainment = 'Giải trí';
  static const String categoryOther = 'Khác';

  static const List<String> categories = [
    categoryFood,
    categoryTransport,
    categoryShopping,
    categoryBills,
    categoryEntertainment,
    categoryOther,
  ];

  // Category Icons Mapping
  static const Map<String, IconData> categoryIcons = {
    categoryFood: Icons.restaurant,
    categoryTransport: Icons.directions_car,
    categoryShopping: Icons.shopping_bag,
    categoryBills: Icons.receipt_long,
    categoryEntertainment: Icons.movie,
    categoryOther: Icons.category,
  };

  // Category Colors Mapping
  static const Map<String, Color> categoryColors = {
    categoryFood: Color(0xFFFF6B6B),
    categoryTransport: Color(0xFF4ECDC4),
    categoryShopping: Color(0xFFFFD166),
    categoryBills: Color(0xFF06D6A0),
    categoryEntertainment: Color(0xFF118AB2),
    categoryOther: Color(0xFF8338EC),
  };

  // Currency Formatter for Vietnamese Dong (VND)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Date Formatter
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
