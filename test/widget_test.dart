import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_expense_ocr/main.dart';

void main() {
  testWidgets('ExpenseManagerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app title rendered
    expect(find.text('Quản Lý Chi Tiêu'), findsOneWidget);
  });
}
