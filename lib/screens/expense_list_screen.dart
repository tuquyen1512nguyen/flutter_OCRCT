import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../state/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/empty_state.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _searchQuery = '';
  String _selectedCategoryFilter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final expenseAsync = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất Cả Chi Tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Xóa tất cả chi tiêu',
            onPressed: () => _confirmDeleteAll(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cửa hàng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('Tất cả'),
                ...AppConstants.categories.map((cat) => _buildFilterChip(cat)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Expense List Items
          Expanded(
            child: expenseAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
              data: (expenses) {
                final filtered = expenses.where((item) {
                  final matchesQuery =
                      item.merchantName.toLowerCase().contains(_searchQuery);
                  final matchesCategory = _selectedCategoryFilter == 'Tất cả' ||
                      item.category == _selectedCategoryFilter;
                  return matchesQuery && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    title: expenses.isEmpty
                        ? 'Chưa có bản ghi chi tiêu nào'
                        : 'Không tìm thấy chi tiêu phù hợp',
                    subtitle: expenses.isEmpty
                        ? 'Quét hóa đơn để bắt đầu theo dõi.'
                        : 'Thử xóa từ khóa tìm kiếm hoặc bộ lọc danh mục.',
                    onAction: () => context.push('/scan'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ExpenseCard(
                      expense: item,
                      onTap: () => context.push('/expense/${item.id}'),
                      onDelete: () => _confirmDelete(context, item.id, item.merchantName),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategoryFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryFilter = label;
          });
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String merchant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Chi Tiêu'),
        content: Text('Bạn có chắc chắn muốn xóa "$merchant"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ref.read(expenseProvider.notifier).deleteExpense(id);
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

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Tất Cả Chi Tiêu'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa TẤT CẢ bản ghi chi tiêu? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await ref.read(expenseProvider.notifier).deleteAllExpenses();
              messenger.showSnackBar(
                const SnackBar(content: Text('Đã xóa tất cả khoản chi tiêu')),
              );
            },
            child: const Text('Xóa Tất Cả', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
