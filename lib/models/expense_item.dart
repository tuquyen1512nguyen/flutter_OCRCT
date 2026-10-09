class ExpenseItem {
  final String id;
  final String merchantName;
  final double amount;
  final String category;
  final DateTime timestamp;
  final String? rawOcrText;
  final String? imagePath;

  const ExpenseItem({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.category,
    required this.timestamp,
    this.rawOcrText,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantName': merchantName,
      'amount': amount,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'rawOcrText': rawOcrText,
      'imagePath': imagePath,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      merchantName: map['merchantName'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      rawOcrText: map['rawOcrText'] as String?,
      imagePath: map['imagePath'] as String?,
    );
  }

  ExpenseItem copyWith({
    String? id,
    String? merchantName,
    double? amount,
    String? category,
    DateTime? timestamp,
    String? rawOcrText,
    String? imagePath,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          merchantName == other.merchantName &&
          amount == other.amount &&
          category == other.category &&
          timestamp == other.timestamp &&
          rawOcrText == other.rawOcrText &&
          imagePath == other.imagePath;

  @override
  int get hashCode =>
      id.hashCode ^
      merchantName.hashCode ^
      amount.hashCode ^
      category.hashCode ^
      timestamp.hashCode ^
      rawOcrText.hashCode ^
      imagePath.hashCode;
}
