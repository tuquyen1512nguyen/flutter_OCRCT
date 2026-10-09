import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../models/expense_item.dart';

class ExpenseNotifier extends AsyncNotifier<List<ExpenseItem>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<ExpenseItem>> build() async {
    try {
      final items = await _dbHelper.getAllExpenses();
      if (items.isEmpty) return DatabaseHelper.getDemoExpenses();
      return items;
    } catch (_) {
      return DatabaseHelper.getDemoExpenses();
    }
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _dbHelper.getAllExpenses());
  }

  Future<void> addExpense(ExpenseItem expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _dbHelper.insertExpense(expense);
      return await _dbHelper.getAllExpenses();
    });
  }

  Future<void> updateExpense(ExpenseItem expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _dbHelper.updateExpense(expense);
      return await _dbHelper.getAllExpenses();
    });
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _dbHelper.deleteExpense(id);
      return await _dbHelper.getAllExpenses();
    });
  }

  Future<void> deleteAllExpenses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _dbHelper.deleteAllExpenses();
      return <ExpenseItem>[];
    });
  }
}

// Main Expense Provider
final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<ExpenseItem>>(() {
  return ExpenseNotifier();
});

// Computed Providers

final totalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  return expenses.fold(0.0, (sum, item) => sum + item.amount);
});

final monthlyExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final now = DateTime.now();
  final currentMonthExpenses = expenses.where(
    (item) => item.timestamp.year == now.year && item.timestamp.month == now.month,
  );
  return currentMonthExpenses.fold(0.0, (sum, item) => sum + item.amount);
});

final expenseCountProvider = Provider<int>((ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  return expenses.length;
});

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expenseProvider).value ?? [];
  final Map<String, double> totals = {};
  for (final item in expenses) {
    totals[item.category] = (totals[item.category] ?? 0.0) + item.amount;
  }
  return totals;
});
