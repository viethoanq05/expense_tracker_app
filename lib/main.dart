import 'package:flutter/material.dart';
import 'package:expense_tracker_app/screens/app_shell_screen.dart';
import 'package:expense_tracker_app/theme/app_theme.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShellScreen(),
    );
  }
}
