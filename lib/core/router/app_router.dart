import 'package:go_router/go_router.dart';
import '../../models/parsed_receipt.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/scanner_screen.dart';
import '../../screens/review_receipt_screen.dart';
import '../../screens/expense_list_screen.dart';
import '../../screens/expense_detail_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/review',
        name: 'review',
        builder: (context, state) {
          final receipt = state.extra as ParsedReceipt?;
          if (receipt == null) {
            // Fallback if accessed without extra data
            return const DashboardScreen();
          }
          return ReviewReceiptScreen(parsedReceipt: receipt);
        },
      ),
      GoRoute(
        path: '/expenses',
        name: 'expenses',
        builder: (context, state) => const ExpenseListScreen(),
      ),
      GoRoute(
        path: '/expense/:id',
        name: 'expense_detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ExpenseDetailScreen(expenseId: id);
        },
      ),
    ],
  );
}
