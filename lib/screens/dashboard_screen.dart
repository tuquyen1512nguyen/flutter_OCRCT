import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/expense_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/donut_chart.dart';
import '../widgets/expense_card.dart';
import '../widgets/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(expenseProvider);
    final totalSpent = ref.watch(totalExpensesProvider);
    final monthlySpent = ref.watch(monthlyExpensesProvider);
    final transactionCount = ref.watch(expenseCountProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Chi Tiêu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Tất cả chi tiêu',
            onPressed: () => context.push('/expenses'),
          ),
        ],
      ),
      body: expenseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi tải chi tiêu: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(expenseProvider.notifier).loadExpenses(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return EmptyStateWidget(
              onAction: () => context.push('/scan'),
            );
          }

          final recentExpenses = expenses.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(expenseProvider.notifier).loadExpenses();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  SummaryCard(
                    totalSpent: totalSpent,
                    transactionCount: transactionCount,
                    monthlySpent: monthlySpent,
                  ),

                  const SizedBox(height: 16),

                  // Donut Chart Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phân bổ theo danh mục',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DonutChart(
                              categoryTotals: categoryTotals,
                              totalAmount: totalSpent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent Expenses Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Giao dịch gần đây',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/expenses'),
                          child: const Text('Xem tất cả'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Recent Expenses List
                  ...recentExpenses.map((expense) {
                    return ExpenseCard(
                      expense: expense,
                      onTap: () => context.push('/expense/${expense.id}'),
                      onDelete: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(expenseProvider.notifier).deleteExpense(expense.id);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Đã xóa khoản chi tiêu')),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Quét Hóa Đơn'),
      ),
    );
  }
}
