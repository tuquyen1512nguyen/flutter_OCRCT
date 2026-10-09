import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/expense_item.dart';
import '../models/parsed_receipt.dart';
import '../services/receipt_parser.dart';
import '../state/expense_provider.dart';

class ReviewReceiptScreen extends ConsumerStatefulWidget {
  final ParsedReceipt parsedReceipt;

  const ReviewReceiptScreen({
    super.key,
    required this.parsedReceipt,
  });

  @override
  ConsumerState<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends ConsumerState<ReviewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late String _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedReceipt.merchantName,
    );

    _amountController = TextEditingController(
      text: widget.parsedReceipt.totalAmount != null
          ? widget.parsedReceipt.totalAmount!.toStringAsFixed(0)
          : '',
    );

    _selectedCategory = widget.parsedReceipt.category;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onConfirmAndSave() async {
    if (_formKey.currentState!.validate()) {
      final rawAmountStr = _amountController.text.trim();
      final parsedAmount = ReceiptParser.normalizeAndParseNumber(rawAmountStr);

      if (parsedAmount == null || parsedAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ lớn hơn 0')),
        );
        return;
      }

      final newItem = ExpenseItem(
        id: const Uuid().v4(),
        merchantName: _merchantController.text.trim(),
        amount: parsedAmount,
        category: _selectedCategory,
        timestamp: _selectedDate,
        rawOcrText: widget.parsedReceipt.rawText,
        imagePath: widget.parsedReceipt.imagePath,
      );

      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      await ref.read(expenseProvider.notifier).addExpense(newItem);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã lưu chi tiêu cho ${newItem.merchantName}!'),
          backgroundColor: Colors.green,
        ),
      );
      router.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.parsedReceipt.imagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Nhận & Kiểm Tra Hóa Đơn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Preview Card (if image available)
              if (imagePath != null && File(imagePath).existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(imagePath),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Info Alert Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vui lòng kiểm tra kỹ thông tin đã trích xuất trước khi lưu vào cơ sở dữ liệu.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Merchant Name Field
              TextFormField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: 'Tên đơn vị / Cửa hàng *',
                  prefixIcon: const Icon(Icons.storefront),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên đơn vị / cửa hàng';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Total Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tổng tiền (VND) *',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'VNĐ',
                  hintText: 'Ví dụ: 150000 hoặc 150.000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tổng tiền';
                  }
                  final parsed = ReceiptParser.normalizeAndParseNumber(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Vui lòng nhập số tiền hợp lệ lớn hơn 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: AppConstants.categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : AppConstants.categoryOther,
                decoration: InputDecoration(
                  labelText: 'Danh mục *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: AppConstants.categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(
                          AppConstants.categoryIcons[cat],
                          size: 20,
                          color: AppConstants.categoryColors[cat],
                        ),
                        const SizedBox(width: 10),
                        Text(cat),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Date Picker Field
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(Icons.calendar_today),
                title: const Text('Ngày & Giờ'),
                subtitle: Text(AppConstants.formatDate(_selectedDate)),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        _selectedDate.hour,
                        _selectedDate.minute,
                      );
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // Collapsible Section: Raw OCR Text (Section 23 requirement)
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: const Text(
                    'Văn Bản OCR Gốc (Kiểm Tra & Debug)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.parsedReceipt.rawText.isNotEmpty
                              ? widget.parsedReceipt.rawText
                              : 'Không có văn bản OCR gốc.',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Confirm and Cancel Buttons
              ElevatedButton.icon(
                onPressed: _onConfirmAndSave,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Xác Nhận & Lưu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Hủy bỏ'),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
