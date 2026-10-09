import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../models/expense_item.dart';
import '../services/receipt_parser.dart';
import '../state/expense_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String expenseId;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(expenseProvider);

    return expenseAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Chi Tiêu')),
        body: Center(child: Text('Lỗi: $err')),
      ),
      data: (expenses) {
        final expense = expenses.firstWhere(
          (e) => e.id == expenseId,
          orElse: () => ExpenseItem(
            id: '',
            merchantName: 'Không tìm thấy',
            amount: 0,
            category: 'Khác',
            timestamp: DateTime.now(),
          ),
        );

        if (expense.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi Tiết Chi Tiêu')),
            body: const Center(child: Text('Không tìm thấy bản ghi chi tiêu.')),
          );
        }

        final color = AppConstants.categoryColors[expense.category] ?? Colors.grey;
        final icon = AppConstants.categoryIcons[expense.category] ?? Icons.category;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi Tiết Chi Tiêu'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Chỉnh sửa',
                onPressed: () => _showEditDialog(context, ref, expense),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa',
                onPressed: () => _confirmDelete(context, ref, expense),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card with Amount and Merchant
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          expense.merchantName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.formatCurrency(expense.amount),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Chip(
                          avatar: Icon(icon, color: color, size: 16),
                          label: Text(
                            expense.category,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: color.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Details Card (Date, ID)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          context,
                          label: 'Ngày giao dịch',
                          value: AppConstants.formatDate(expense.timestamp),
                          icon: Icons.calendar_today,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          context,
                          label: 'Mã bản ghi',
                          value: expense.id,
                          icon: Icons.fingerprint,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Receipt Image (if present)
                if (expense.imagePath != null &&
                    File(expense.imagePath!).existsSync()) ...[
                  const Text(
                    'Ảnh Hóa Đơn',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(expense.imagePath!),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Raw OCR Text Collapsible (Section 23 requirement)
                if (expense.rawOcrText != null &&
                    expense.rawOcrText!.isNotEmpty) ...[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: ExpansionTile(
                      leading: const Icon(Icons.text_snippet_outlined),
                      title: const Text(
                        'Nhật Ký Văn Bản OCR Gốc',
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
                              expense.rawOcrText!,
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, ExpenseItem expense) {
    final merchantCtrl = TextEditingController(text: expense.merchantName);
    final amountCtrl =
        TextEditingController(text: expense.amount.toStringAsFixed(0));
    String category = expense.category;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh Sửa Chi Tiêu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: merchantCtrl,
                decoration: const InputDecoration(labelText: 'Tên đơn vị / Cửa hàng'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VND)',
                  suffixText: 'VNĐ',
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setStateDialog) =>
                    DropdownButtonFormField<String>(
                  initialValue: AppConstants.categories.contains(category)
                      ? category
                      : AppConstants.categoryOther,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: AppConstants.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateDialog(() {
                        category = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newMerchant = merchantCtrl.text.trim();
              final parsedAmount =
                  ReceiptParser.normalizeAndParseNumber(amountCtrl.text.trim());

              if (newMerchant.isNotEmpty &&
                  parsedAmount != null &&
                  parsedAmount > 0) {
                final updatedItem = expense.copyWith(
                  merchantName: newMerchant,
                  amount: parsedAmount,
                  category: category,
                );

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);

                await ref
                    .read(expenseProvider.notifier)
                    .updateExpense(updatedItem);

                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật chi tiêu!')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ExpenseItem expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Chi Tiêu'),
        content: Text('Bạn có chắc chắn muốn xóa "${expense.merchantName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              Navigator.pop(ctx);
              await ref.read(expenseProvider.notifier).deleteExpense(expense.id);
              router.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Đã xóa khoản chi tiêu')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
