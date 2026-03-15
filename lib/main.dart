import 'package:flutter/material.dart';
import 'package:expense_tracker_app/screens/app_shell_screen.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_app/providers/expense_provider.dart';
import 'package:expense_tracker_app/screens/statistics_screen.dart';
import 'package:expense_tracker_app/services/firebase_bootstrap.dart';
import 'package:expense_tracker_app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShellScreen(),
      ),
    );
  }
}
