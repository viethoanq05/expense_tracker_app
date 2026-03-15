import 'package:expense_tracker_app/controllers/app_preferences_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker_app/main.dart';

void main() {
  testWidgets('app shell renders dashboard tab', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = await AppPreferencesController.load();

    await tester.pumpWidget(ExpenseTrackerApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.textContaining('Recent'), findsOneWidget);
  });
}
