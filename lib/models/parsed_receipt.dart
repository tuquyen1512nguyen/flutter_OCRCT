class ParsedReceipt {
  final String merchantName;
  final double? totalAmount; // Nullable as total detection might fail
  final String category;
  final String rawText;
  final String? imagePath;

  const ParsedReceipt({
    required this.merchantName,
    this.totalAmount,
    required this.category,
    required this.rawText,
    this.imagePath,
  });

  ParsedReceipt copyWith({
    String? merchantName,
    double? totalAmount,
    String? category,
    String? rawText,
    String? imagePath,
  }) {
    return ParsedReceipt(
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      category: category ?? this.category,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
